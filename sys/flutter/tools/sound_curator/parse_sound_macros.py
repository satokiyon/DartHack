#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sound_macros_list.md を解析し、全274音の構造化メタデータを sound_definitions.json に出力するスクリプト。
"""

import json
from pathlib import Path

def parse_sound_macros(md_path: Path) -> list:
    content = md_path.read_text(encoding="utf-8")
    lines = content.splitlines()

    current_category = "effect"
    sub_category = ""
    items = []

    for line in lines:
        line_str = line.strip()
        if not line_str:
            continue

        if line_str.startswith("### 1-A."):
            current_category = "effect"
            sub_category = "Soundeffect"
            continue
        elif line_str.startswith("### 1-B."):
            current_category = "achievement"
            sub_category = "Achievement"
            continue
        elif line_str.startswith("#### 1-B-i."):
            current_category = "achievement"
            sub_category = "SystemEvent"
            continue
        elif line_str.startswith("#### 1-B-ii."):
            current_category = "achievement"
            sub_category = "GameAchievement"
            continue
        elif line_str.startswith("#### 1-C.") or line_str.startswith("### 1-C."):
            current_category = "instrument"
            sub_category = "HeroPlaynotes"
            continue
        elif line_str.startswith("#### 音階バリエーションあり楽器"):
            current_category = "instrument"
            sub_category = "VariablePitch"
            continue
        elif line_str.startswith("#### 固定演奏楽器"):
            current_category = "instrument"
            sub_category = "FixedPitch"
            continue
        elif line_str.startswith("### 1-D."):
            current_category = "voice"
            sub_category = "SetVoice"
            continue
        elif line_str.startswith("## 第2部"):
            break

        if line_str.startswith("|") and not line_str.startswith("| No.") and not line_str.startswith("| :---"):
            cols = [c.strip() for c in line_str.split("|")[1:-1]]
            if len(cols) >= 5:
                no_str = cols[0]
                filename = cols[1].strip("` ")
                sound_id = cols[2].strip("` ")
                desc = cols[3]
                caller = cols[4]

                if not filename.endswith(".ogg"):
                    continue

                items.append({
                    "no": int(no_str) if no_str.isdigit() else len(items) + 1,
                    "filename": filename,
                    "id": sound_id,
                    "description": desc,
                    "caller": caller,
                    "category": current_category,
                    "sub_category": sub_category
                })

    return items

def main():
    root = Path(__file__).resolve().parent
    md_path = root.parent.parent / "doc" / "sound_macros_list.md"
    if not md_path.exists():
        md_path = Path("sys/flutter/doc/sound_macros_list.md")
    
    items = parse_sound_macros(md_path)
    output_path = root / "sound_definitions.json"
    output_path.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"成功: {len(items)} 件のサウンド定義を {output_path} に書き出しました。")

    from collections import Counter
    counts = Counter(item["category"] for item in items)
    for cat, count in counts.items():
        print(f" - {cat}: {count} 件")

if __name__ == "__main__":
    main()
