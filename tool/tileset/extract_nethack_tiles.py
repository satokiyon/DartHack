# -*- coding: utf-8 -*-
"""
NetHack 5.0 の monsters.txt, objects.txt, other.txt をパースして
全タイルのメタデータを JSON 形式で出力するスクリプト
"""
import os
import re
import json

def parse_txt(path, offset=0, category=""):
    tiles = []
    with open(path, "r", encoding="latin1") as f:
        for line in f:
            m = re.match(r"^#\s*tile\s+(\d+)\s*\((.*?)\)", line)
            if m:
                local_id = int(m.group(1))
                desc = m.group(2).strip()
                # 性別情報の抽出 (male / female / nogender)
                gender = None
                clean_name = desc
                if "," in desc:
                    parts = desc.rsplit(",", 1)
                    if parts[1].strip() in ("male", "female", "nogender"):
                        clean_name = parts[0].strip()
                        gender = parts[1].strip()
                
                tiles.append({
                    "id": offset + local_id,
                    "local_id": local_id,
                    "category": category,
                    "desc": desc,
                    "clean_name": clean_name,
                    "gender": gender
                })
    return tiles

def main():
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    share_dir = os.path.join(root, "c_core", "nethack_en", "win", "share")
    
    mons = parse_txt(os.path.join(share_dir, "monsters.txt"), offset=0, category="monster")
    objs = parse_txt(os.path.join(share_dir, "objects.txt"), offset=len(mons), category="object")
    oths = parse_txt(os.path.join(share_dir, "other.txt"), offset=len(mons) + len(objs), category="other")
    
    all_tiles = mons + objs + oths
    print(f"Total tiles parsed: {len(all_tiles)} (Monsters: {len(mons)}, Objects: {len(objs)}, Other: {len(oths)})")
    
    out_path = os.path.join(os.path.dirname(__file__), "nethack_tiles.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(all_tiles, f, ensure_ascii=False, indent=2)
    print(f"Saved to {out_path}")

if __name__ == "__main__":
    main()
