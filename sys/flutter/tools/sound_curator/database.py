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
SOUNDS_DIR = CUR_DIR.parent.parent / "assets" / "sounds"
ATTRIBUTIONS_PATH = SOUNDS_DIR / "attributions.txt"

def load_or_init_database() -> List[Dict[str, Any]]:
    """データベースを読み込む。存在しない場合は definitions から初期化する"""
    if DATABASE_PATH.exists():
        try:
            return json.loads(DATABASE_PATH.read_text(encoding="utf-8"))
        except Exception:
            pass

    definitions = json.loads(DEFINITIONS_PATH.read_text(encoding="utf-8"))
    db = []

    for item in definitions:
        filename = item["filename"]
        target_ogg = SOUNDS_DIR / filename
        is_ready = target_ogg.exists() and target_ogg.stat().st_size > 0

        record = {
            "no": item["no"],
            "filename": filename,
            "id": item["id"],
            "description": item["description"],
            "caller": item["caller"],
            "category": item["category"],
            "sub_category": item["sub_category"],
            "status": "ready" if is_ready else "pending",
            "source_site": "FluidR3 GM (FluidSynth)" if is_ready and item["category"] == "instrument" else "",
            "author": "Frank Wen" if is_ready and item["category"] == "instrument" else "",
            "source_url": "https://raw.githubusercontent.com/urish/cinto/master/media/FluidR3%20GM.sf2" if is_ready and item["category"] == "instrument" else "",
            "license": "MIT / GPL" if is_ready and item["category"] == "instrument" else "",
            "notes": "SoundFont auto-sampled note" if is_ready and item["category"] == "instrument" else ""
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
