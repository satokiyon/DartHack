#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
database.py
サウンドメタデータデータベース (sound_database.json) の管理および
attributions.txt の自動生成。
"""

import json
from pathlib import Path
from typing import Dict, List, Any

CUR_DIR = Path(__file__).resolve().parent
DEFINITIONS_PATH = CUR_DIR / "sound_definitions.json"
DATABASE_PATH = CUR_DIR / "sound_database.json"

def resolve_sounds_dir() -> Path:
    """音声ファイルの保存先ディレクトリを解決する。
    DartHack_private が存在すればそちらを優先し、なければ DartHack 側にフォールバックする。
    """
    private_sounds = Path(r"C:\Users\satok\DartHack_private\sys\flutter\assets\sounds")
    if private_sounds.parent.exists():
        private_sounds.mkdir(parents=True, exist_ok=True)
        return private_sounds
    fallback = CUR_DIR.parent.parent / "assets" / "sounds"
    fallback.mkdir(parents=True, exist_ok=True)
    return fallback

SOUNDS_DIR = resolve_sounds_dir()
ATTRIBUTIONS_PATH = SOUNDS_DIR / "attributions.txt"

SF2_EFFECT_FILES = {
    "se_horn_being_played.ogg",
    "se_shrill_whistle.ogg",
    "se_magic_whistle.ogg",
}

NETHACK_OFFICIAL_FILES = {
    "se_squeak_A.ogg",
    "se_squeak_B.ogg",
    "se_squeak_B_flat.ogg",
    "se_squeak_C.ogg",
    "se_squeak_D.ogg",
    "se_squeak_D_flat.ogg",
    "se_squeak_E.ogg",
    "se_squeak_E_flat.ogg",
    "se_squeak_F.ogg",
    "se_squeak_F_sharp.ogg",
    "se_squeak_G.ogg",
    "se_squeak_G_sharp.ogg",
}

def load_or_init_database() -> List[Dict[str, Any]]:
    """データベースを読み込む。新定義があれば既存の入力状態を保持しつつ自動統合する"""
    definitions = json.loads(DEFINITIONS_PATH.read_text(encoding="utf-8"))
    existing_map = {}
    if DATABASE_PATH.exists():
        try:
            existing_db = json.loads(DATABASE_PATH.read_text(encoding="utf-8"))
            existing_map = {item["filename"]: item for item in existing_db}
        except Exception:
            pass

    db = []
    for item in definitions:
        filename = item["filename"]
        target_ogg = SOUNDS_DIR / filename
        is_ready = target_ogg.exists() and target_ogg.stat().st_size > 0
        is_sf2 = (item["category"] == "instrument") or (filename in SF2_EFFECT_FILES)
        is_official = filename in NETHACK_OFFICIAL_FILES

        if filename in existing_map:
            record = existing_map[filename]
            # 新しいメタデータをマージ（カテゴリ、サブカテゴリ、キーワード等）
            for k in ["no", "id", "description", "caller", "category", "sub_category", "sub_category_ja", "keywords_ja", "keywords_en"]:
                if k in item:
                    record[k] = item[k]
            if is_ready:
                record["status"] = "ready"
                if is_official:
                    record["source_site"] = "NetHack Official Win32 Audio Set"
                    record["author"] = "NetHack DevTeam"
                    record["source_url"] = "https://www.nethack.org/"
                    record["license"] = "NetHack General Public License (NGPL)"
                    record["notes"] = "Official squeaky board trap pitch samples (converted from se_squeak_*.wav)"
                elif is_sf2 and not record.get("source_site"):
                    record["source_site"] = "FluidR3 GM (FluidSynth)"
                    record["author"] = "Frank Wen"
                    record["source_url"] = "https://raw.githubusercontent.com/urish/cinto/master/media/FluidR3%20GM.sf2"
                    record["license"] = "MIT / GPL"
                    record["notes"] = "SoundFont auto-sampled instrument/effect"
        else:
            if is_ready and is_official:
                site = "NetHack Official Win32 Audio Set"
                author = "NetHack DevTeam"
                url = "https://www.nethack.org/"
                license_str = "NetHack General Public License (NGPL)"
                notes = "Official squeaky board trap pitch samples (converted from se_squeak_*.wav)"
            elif is_ready and is_sf2:
                site = "FluidR3 GM (FluidSynth)"
                author = "Frank Wen"
                url = "https://raw.githubusercontent.com/urish/cinto/master/media/FluidR3%20GM.sf2"
                license_str = "MIT / GPL"
                notes = "SoundFont auto-sampled instrument/effect"
            else:
                site = ""
                author = ""
                url = ""
                license_str = ""
                notes = ""

            record = {
                "no": item["no"],
                "filename": filename,
                "id": item["id"],
                "description": item["description"],
                "caller": item["caller"],
                "category": item["category"],
                "sub_category": item.get("sub_category", ""),
                "sub_category_ja": item.get("sub_category_ja", ""),
                "keywords_ja": item.get("keywords_ja", ""),
                "keywords_en": item.get("keywords_en", ""),
                "status": "ready" if is_ready else "pending",
                "source_site": site,
                "author": author,
                "source_url": url,
                "license": license_str,
                "notes": notes
            }
        db.append(record)

    save_database(db)
    generate_attributions(db)
    return db

def save_database(db: List[Dict[str, Any]]):
    """データベースを保存する"""
    DATABASE_PATH.write_text(json.dumps(db, ensure_ascii=False, indent=2), encoding="utf-8")

def generate_attributions(db: List[Dict[str, Any]]):
    """ready な音源から attributions.txt を生成する"""
    SOUNDS_DIR.mkdir(parents=True, exist_ok=True)
    lines = [
        "NetHack 5.0 / DartHack Sound Attributions and Credits",
        "=======================================================",
        "This file contains licensing and credit information for all audio assets used in DartHack.",
        "",
    ]

    ready_count = 0
    for item in db:
        if item["status"] != "ready":
            continue

        ready_count += 1
        lines.append(f"File:        {item['filename']}")
        lines.append(f"Description: {item['description']}")
        lines.append(f"Source:      {item.get('source_site', 'Unknown')} ({item.get('source_url', 'N/A')})")
        lines.append(f"Author:      {item.get('author', 'Unknown')}")
        lines.append(f"License:     {item.get('license', 'Unknown')}")
        if item.get("notes"):
            lines.append(f"Notes:       {item['notes']}")
        lines.append("-" * 55)

    lines.append(f"\nTotal ready assets documented: {ready_count} / {len(db)}")
    ATTRIBUTIONS_PATH.write_text("\n".join(lines), encoding="utf-8")

if __name__ == "__main__":
    db = load_or_init_database()
    ready_count = sum(1 for x in db if x["status"] == "ready")
    print(f"データベース初期化完了: 全 {len(db)} 件 (確定済: {ready_count} 件)")
