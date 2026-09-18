#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_volumes.py
DartHack 全音声アセットの音量・音圧バランス検査＆自動適正化ツール。
- 再生時間、ピーク音量 (max_volume)、平均実効音量 (mean_volume) を計測。
- OK / CLIP / WARN / ERROR の4段階で自動判定。
- --fix オプションによる自動リノーマライズ（ピーク -1.5 dBFS）。
"""

import sys
import os
import json
import argparse
import subprocess
from pathlib import Path
from typing import Dict, List, Any, Optional

CUR_DIR = Path(__file__).resolve().parent

# ANSI カラーコード
COLOR_RESET = "\033[0m"
COLOR_GREEN = "\033[32m"
COLOR_YELLOW = "\033[33m"
COLOR_RED = "\033[31m"
COLOR_CYAN = "\033[36m"
COLOR_BOLD = "\033[1m"
COLOR_DIM = "\033[2m"

# 判定しきい値 (dBFS)
THRESH_ERROR_PEAK = -12.0
THRESH_ERROR_MEAN = -35.0
THRESH_WARN_PEAK = -5.0
THRESH_WARN_MEAN = -25.0
THRESH_CLIP_PEAK = -0.05
TARGET_PEAK_FIX = -1.5

def resolve_sounds_dir() -> Path:
    """音声ファイルの保存先ディレクトリを解決する"""
    private_sounds = Path(r"C:\Users\satok\DartHack_private\sys\flutter\assets\sounds")
    if private_sounds.exists():
        return private_sounds
    fallback = CUR_DIR.parent.parent / "assets" / "sounds"
    return fallback

def get_public_sounds_dir() -> Optional[Path]:
    """公開リポジトリ側の同期先ディレクトリ"""
    pub = CUR_DIR.parent.parent / "assets" / "sounds"
    return pub if pub.exists() else None

def measure_volume(ogg_path: Path) -> Dict[str, Any]:
    """1つの ogg ファイルの音響特性を測定する"""
    result = {
        "filename": ogg_path.name,
        "path": str(ogg_path),
        "duration": 0.0,
        "max_volume": -99.0,
        "mean_volume": -99.0,
        "status": "ERROR",
        "message": ""
    }

    if not ogg_path.exists() or ogg_path.stat().st_size == 0:
        result["message"] = "ファイルが存在しないかサイズが0です"
        return result

    probe_cmd = [
        "ffprobe", "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        str(ogg_path)
    ]
    try:
        p_res = subprocess.run(probe_cmd, capture_output=True, text=True, check=True)
        result["duration"] = float(p_res.stdout.strip())
    except Exception:
        pass

    det_cmd = ["ffmpeg", "-i", str(ogg_path), "-af", "volumedetect", "-f", "null", "-"]
    try:
        d_res = subprocess.run(det_cmd, capture_output=True, text=True)
        for line in d_res.stderr.splitlines():
            if "max_volume:" in line:
                val = line.split("max_volume:")[1].replace("dB", "").strip()
                result["max_volume"] = float(val)
            elif "mean_volume:" in line:
                val = line.split("mean_volume:")[1].replace("dB", "").strip()
                result["mean_volume"] = float(val)
    except Exception as e:
        result["message"] = f"測定エラー: {e}"
        return result

    max_v = result["max_volume"]
    mean_v = result["mean_volume"]

    if max_v < THRESH_ERROR_PEAK or mean_v < THRESH_ERROR_MEAN:
        result["status"] = "ERROR"
        result["message"] = "ほぼ無音・不良音源（過小音量）"
    elif max_v < THRESH_WARN_PEAK or mean_v < THRESH_WARN_MEAN:
        result["status"] = "WARN"
        result["message"] = "音量が小さすぎる可能性あり（要確認）"
    elif max_v >= THRESH_CLIP_PEAK:
        result["status"] = "CLIP"
        result["message"] = "0dB頭打ち（音割れリスクあり）"
    else:
        result["status"] = "OK"
        result["message"] = "適正音量バランス"

    return result

def fix_volume(ogg_path: Path, target_peak: float = TARGET_PEAK_FIX) -> bool:
    """音量を適正化（無音トリム＋コンプレッション＋ピーク -1.5 dBFS）して上書きする"""
    try:
        temp_out = ogg_path.parent / f"{ogg_path.stem}_temp_fix.ogg"
        
        base_filter = "silenceremove=start_periods=1:start_duration=0.01:start_threshold=-45dB:stop_periods=1:stop_duration=0.08:stop_threshold=-45dB"
        comp_filter = "acompressor=threshold=-15dB:ratio=2.5:attack=5:release=80:makeup=2dB"
        detect_chain = f"{base_filter},{comp_filter},volumedetect"

        cmd_det = ["ffmpeg", "-i", str(ogg_path), "-af", detect_chain, "-f", "null", "-"]
        res = subprocess.run(cmd_det, capture_output=True, text=True)
        max_v = 0.0
        for l in res.stderr.splitlines():
            if "max_volume:" in l:
                max_v = float(l.split("max_volume:")[1].replace("dB", "").strip())
                break

        gain = target_peak - max_v
        final_filter = f"{base_filter},{comp_filter},volume={gain:.2f}dB"

        cmd_conv = [
            "ffmpeg", "-y", "-i", str(ogg_path),
            "-af", final_filter,
            "-c:a", "libopus", "-b:a", "64k", "-ar", "48000",
            str(temp_out)
        ]
        subprocess.run(cmd_conv, check=True, capture_output=True)

        import shutil
        shutil.move(str(temp_out), str(ogg_path))

        pub = get_public_sounds_dir()
        if pub and pub != ogg_path.parent:
            pub_target = pub / ogg_path.name
            if pub_target.parent.exists():
                shutil.copy2(str(ogg_path), str(pub_target))

        return True
    except Exception as e:
        print(f"修正失敗 ({ogg_path.name}): {e}", file=sys.stderr)
        return False

def check_all_volumes(
    sounds_dir: Path,
    warn_only: bool = False,
    auto_fix: bool = False,
    as_json: bool = False,
    target_file: Optional[str] = None
) -> List[Dict[str, Any]]:
    """全音源（または指定音源）をチェックする"""
    all_files = sorted(sounds_dir.glob("*.ogg"))
    if target_file:
        all_files = [p for p in all_files if p.name == target_file or p.stem == target_file]

    results = []
    fixed_count = 0

    for f in all_files:
        info = measure_volume(f)

        if auto_fix and info["status"] in ("WARN", "ERROR", "CLIP"):
            success = fix_volume(f)
            if success:
                fixed_count += 1
                info = measure_volume(f)
                info["fixed"] = True

        results.append(info)

    if as_json:
        print(json.dumps(results, ensure_ascii=False, indent=2))
        return results

    print(f"\n{COLOR_BOLD}=== DartHack 音声アセット音量・音圧診断レポート ==={COLOR_RESET}")
    print(f"検査対象ディレクトリ: {sounds_dir}")
    print(f"総ファイル数: {len(results)} 件\n")

    header = f"{'状態':6s} | {'ファイル名':30s} | {'時間':6s} | {'ピーク':9s} | {'平均音量':9s} | {'診断メッセージ'}"
    print(header)
    print("-" * 90)

    stats = {"OK": 0, "CLIP": 0, "WARN": 0, "ERROR": 0}

    for r in results:
        status = r["status"]
        stats[status] = stats.get(status, 0) + 1

        if warn_only and status == "OK":
            continue

        if status == "OK":
            color = COLOR_GREEN
            st_text = "[ OK ]"
        elif status == "CLIP":
            color = COLOR_YELLOW
            st_text = "[CLIP]"
        elif status == "WARN":
            color = COLOR_YELLOW
            st_text = "[WARN]"
        else:
            color = COLOR_RED
            st_text = "[ERR ]"

        fname = r["filename"]
        if len(fname) > 30:
            fname = fname[:27] + "..."

        line = (
            f"{color}{st_text:6s}{COLOR_RESET} | "
            f"{fname:30s} | "
            f"{r['duration']:5.2f}s | "
            f"{r['max_volume']:+6.1f} dB | "
            f"{r['mean_volume']:+6.1f} dB | "
            f"{COLOR_DIM}{r['message']}{COLOR_RESET}"
        )
        if r.get("fixed"):
            line += f" {COLOR_CYAN}[自動修復済]{COLOR_RESET}"

        print(line)

    print("-" * 90)
    print(f"{COLOR_BOLD}診断サマリー:{COLOR_RESET}")
    print(f"  {COLOR_GREEN}OK (適正):{COLOR_RESET}     {stats.get('OK', 0):3d} 件")
    print(f"  {COLOR_YELLOW}CLIP (頭打ち):{COLOR_RESET} {stats.get('CLIP', 0):3d} 件")
    print(f"  {COLOR_YELLOW}WARN (過小):{COLOR_RESET}   {stats.get('WARN', 0):3d} 件")
    print(f"  {COLOR_RED}ERROR (無音等):{COLOR_RESET} {stats.get('ERROR', 0):3d} 件")

    if auto_fix:
        print(f"\n{COLOR_CYAN}自動修復完了:{COLOR_RESET} {fixed_count} 件の音源をピーク {TARGET_PEAK_FIX} dBFS に適正化しました。")
    elif stats.get("WARN", 0) > 0 or stats.get("ERROR", 0) > 0:
        print(f"\n{COLOR_YELLOW}ヒント: `python check_volumes.py --fix` を実行すると、WARN/ERRORの音源を一括で適正音量に自動修正できます。{COLOR_RESET}")

    return results

def main():
    parser = argparse.ArgumentParser(description="DartHack 音声アセット音量バランス診断ツール")
    parser.add_argument("--dir", type=str, default="", help="対象音声ディレクトリ（省略時は自動検知）")
    parser.add_argument("--warn-only", action="store_true", help="問題のある音源（WARN/ERROR/CLIP）のみ表示")
    parser.add_argument("--fix", action="store_true", help="問題のある音源を自動的にピーク -1.5 dBFS に適正化")
    parser.add_argument("--json", action="store_true", help="結果をJSON形式で出力")
    parser.add_argument("--target", type=str, default="", help="特定のファイル名のみを検査/修復")

    args = parser.parse_args()

    target_dir = Path(args.dir) if args.dir else resolve_sounds_dir()
    if not target_dir.exists():
        print(f"エラー: 音声ディレクトリが見つかりません: {target_dir}", file=sys.stderr)
        sys.exit(1)

    check_all_volumes(
        sounds_dir=target_dir,
        warn_only=args.warn_only,
        auto_fix=args.fix,
        as_json=args.json,
        target_file=args.target if args.target else None
    )

if __name__ == "__main__":
    main()
