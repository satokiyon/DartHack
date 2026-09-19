#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
server.py
NetHack / DartHack サウンドキュレーター ローカルWebサーバー。
外部ライブラリ不要（Python 標準ライブラリ http.server ベース）。
"""

import os
import sys
import json
import mimetypes
import shutil
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

from database import load_or_init_database, save_database, generate_attributions, SOUNDS_DIR
from process_audio import normalize_and_convert
from check_volumes import check_all_volumes, fix_volume, measure_volume, resolve_sounds_dir

CUR_DIR = Path(__file__).resolve().parent
STATIC_DIR = CUR_DIR / "static"
TEMP_DIR = CUR_DIR / "temp"

HOST = "127.0.0.1"
PORT = 8765

class CuratorHTTPRequestHandler(BaseHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_HEAD(self):
        self.do_GET(head_only=True)

    def do_GET(self, head_only=False):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/" or path == "/index.html":
            self.serve_file(STATIC_DIR / "index.html", "text/html; charset=utf-8", head_only=head_only)
        elif path.startswith("/static/"):
            rel_path = path[len("/static/"):]
            file_path = STATIC_DIR / rel_path
            self.serve_file(file_path, head_only=head_only)
        elif path.startswith("/sounds/"):
            filename = path[len("/sounds/"):]
            file_path = SOUNDS_DIR / urllib.parse.unquote(filename)
            self.serve_file(file_path, head_only=head_only)
        elif path == "/api/sounds":
            db = load_or_init_database()
            self.send_json(db)
        elif path == "/api/stats":
            db = load_or_init_database()
            total = len(db)
            ready = sum(1 for x in db if x["status"] == "ready")
            by_category = {}
            for item in db:
                cat = item["category"]
                if cat not in by_category:
                    by_category[cat] = {"total": 0, "ready": 0}
                by_category[cat]["total"] += 1
                if item["status"] == "ready":
                    by_category[cat]["ready"] += 1

            self.send_json({
                "total": total,
                "ready": ready,
                "pending": total - ready,
                "percent": round((ready / total * 100) if total > 0 else 0, 1),
                "by_category": by_category
            })
        elif path == "/api/volume_check":
            self.handle_volume_check(parsed)
        else:
            self.send_error(404, "File not found")

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/api/upload_and_assign":
            self.handle_upload_and_assign()
        elif path == "/api/delete_assign":
            self.handle_delete_assign()
        elif path == "/api/volume_fix":
            self.handle_volume_fix()
        else:
            self.send_error(404, "Endpoint not found")

    def handle_volume_check(self, parsed):
        """全音源または指定音源の音量測定結果を返す"""
        try:
            query_params = urllib.parse.parse_qs(parsed.query)
            target = query_params.get("target", [None])[0]

            sounds_dir = resolve_sounds_dir()
            results = check_all_volumes(
                sounds_dir=sounds_dir,
                warn_only=False,
                auto_fix=False,
                as_json=False,
                target_file=target
            )

            counts = {"OK": 0, "CLIP": 0, "WARN": 0, "ERROR": 0}
            for r in results:
                st = r.get("status", "ERROR")
                counts[st] = counts.get(st, 0) + 1

            self.send_json({
                "total": len(results),
                "counts": counts,
                "results": results
            })
        except Exception as e:
            self.send_json({"error": f"音量診断エラー: {e}"}, status=500)

    def handle_volume_fix(self):
        """音量適正化を実行する"""
        try:
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            req = json.loads(body.decode("utf-8")) if length > 0 else {}
        except Exception:
            self.send_json({"error": "Invalid JSON"}, status=400)
            return

        target = req.get("target", "all")
        sounds_dir = resolve_sounds_dir()

        fixed_results = []
        if target == "all" or target == "warn_or_error":
            # 問題のある音源を一括適正化
            all_res = check_all_volumes(sounds_dir=sounds_dir)
            for r in all_res:
                if r["status"] in ("WARN", "ERROR", "CLIP"):
                    fpath = Path(r["path"])
                    if fix_volume(fpath):
                        new_info = measure_volume(fpath)
                        new_info["fixed"] = True
                        fixed_results.append(new_info)
        else:
            # 個別指定
            fpath = sounds_dir / target
            if not fpath.exists():
                fpath = sounds_dir / f"{target}.ogg"
            if fpath.exists():
                if fix_volume(fpath):
                    new_info = measure_volume(fpath)
                    new_info["fixed"] = True
                    fixed_results.append(new_info)
            else:
                self.send_json({"error": f"File not found: {target}"}, status=404)
                return

        self.send_json({
            "success": True,
            "fixed_count": len(fixed_results),
            "results": fixed_results
        })

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def serve_file(self, file_path: Path, content_type=None, head_only=False):
        if not file_path.exists() or file_path.is_dir():
            self.send_error(404, "File not found")
            return

        if not content_type:
            content_type, _ = mimetypes.guess_type(str(file_path))
            if not content_type:
                content_type = "application/octet-stream"

        try:
            stat = file_path.stat()
            file_size = stat.st_size
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(file_size))
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()

            if not head_only:
                with open(file_path, "rb") as f:
                    shutil.copyfileobj(f, self.wfile)
        except Exception as e:
            self.send_error(500, f"Error serving file: {e}")

    def handle_upload_and_assign(self):
        """マルチパートアップロードのパースと処理"""
        content_type = self.headers.get("Content-Type", "")
        if "multipart/form-data" not in content_type:
            self.send_json({"error": "Expected multipart/form-data"}, status=400)
            return

        # boundary の取得
        boundary = None
        for part in content_type.split(";"):
            part = part.strip()
            if part.startswith("boundary="):
                boundary = part[len("boundary="):].strip('"').encode("ascii")
                break

        if not boundary:
            self.send_json({"error": "Missing boundary"}, status=400)
            return

        try:
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)

            # 簡易 multipart パーサー
            parts = body.split(b"--" + boundary)
            fields = {}
            file_bytes = None
            orig_filename = "uploaded_sound"

            for part in parts:
                if not part or part == b"--\r\n" or part == b"--":
                    continue
                if b"\r\n\r\n" not in part:
                    continue

                header_raw, content_raw = part.split(b"\r\n\r\n", 1)
                # 末尾の \r\n を除去
                if content_raw.endswith(b"\r\n"):
                    content_raw = content_raw[:-2]

                header_text = header_raw.decode("utf-8", errors="ignore")
                lines = header_text.split("\r\n")
                disposition = ""
                for line in lines:
                    if line.lower().startswith("content-disposition:"):
                        disposition = line

                if 'filename="' in disposition:
                    # ファイルパート
                    orig_filename = disposition.split('filename="')[1].split('"')[0]
                    file_bytes = content_raw
                elif 'name="' in disposition:
                    # テキストフィールド
                    field_name = disposition.split('name="')[1].split('"')[0]
                    fields[field_name] = content_raw.decode("utf-8", errors="ignore")

            sound_id = fields.get("id")
            if not sound_id or not file_bytes:
                self.send_json({"error": "Missing sound id or file data"}, status=400)
                return

            db = load_or_init_database()
            target_item = None
            for item in db:
                if item["id"] == sound_id or item["filename"] == sound_id:
                    target_item = item
                    break

            if not target_item:
                self.send_json({"error": f"Sound not found: {sound_id}"}, status=404)
                return

            # アップロードファイルを一時保存
            TEMP_DIR.mkdir(parents=True, exist_ok=True)
            ext = Path(orig_filename).suffix or ".wav"
            temp_input = TEMP_DIR / f"upload_{target_item['filename']}{ext}"
            temp_input.write_bytes(file_bytes)

            target_ogg = SOUNDS_DIR / target_item["filename"]
            is_stereo = fields.get("is_stereo") == "true" or target_item["category"] in ["achievement", "instrument"]

            # 戦闘効果音は -16.0 LUFS & 80Hzハイパスフィルター（スマホ音割れ防止・高頻度再生向け）
            is_combat = (
                target_item.get("category") == "combat"
                or target_item["filename"].startswith("se_combat_")
                or target_item["filename"].startswith("se_mon_")
            )
            target_lufs = -16.0 if is_combat else -14.0
            highpass_cutoff = 80 if is_combat else None

            # ffmpeg で無音トリム・ハイパス・EBU R128正規化・Opus変換
            success = normalize_and_convert(
                temp_input,
                target_ogg,
                target_lufs=target_lufs,
                highpass_cutoff=highpass_cutoff,
                is_stereo=is_stereo
            )
            if not success:
                self.send_json({"error": "FFmpeg audio processing failed"}, status=500)
                return

            # データベース更新
            target_item["status"] = "ready"
            target_item["source_site"] = fields.get("source_site", "Unknown")
            target_item["author"] = fields.get("author", "Unknown")
            target_item["source_url"] = fields.get("source_url", "")
            target_item["license"] = fields.get("license", "CC0")
            target_item["notes"] = fields.get("notes", "")

            save_database(db)
            generate_attributions(db)

            self.send_json({
                "success": True,
                "filename": target_item["filename"],
                "status": "ready",
                "item": target_item
            })
        except Exception as e:
            self.send_json({"error": f"アップロード処理エラー: {e}"}, status=500)

    def handle_delete_assign(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            req = json.loads(body.decode("utf-8"))
        except Exception:
            self.send_json({"error": "Invalid JSON"}, status=400)
            return

        sound_id = req.get("id")
        db = load_or_init_database()
        target_item = None
        for item in db:
            if item["id"] == sound_id or item["filename"] == sound_id:
                target_item = item
                break

        if not target_item:
            self.send_json({"error": "Sound not found"}, status=404)
            return

        target_ogg = SOUNDS_DIR / target_item["filename"]
        if target_ogg.exists():
            target_ogg.unlink()

        target_item["status"] = "pending"
        target_item["source_site"] = ""
        target_item["author"] = ""
        target_item["source_url"] = ""
        target_item["license"] = ""
        target_item["notes"] = ""

        save_database(db)
        generate_attributions(db)

        self.send_json({"success": True, "item": target_item})

def run_server():
    server_address = (HOST, PORT)
    httpd = HTTPServer(server_address, CuratorHTTPRequestHandler)
    print(f"===========================================================")
    print(f" NetHack / DartHack サウンドキュレーター サーバー起動")
    print(f" URL: http://localhost:{PORT}")
    print(f"===========================================================")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nサーバーを停止しました。")

if __name__ == "__main__":
    run_server()
