# -*- coding: utf-8 -*-
"""
NetHack 5.0 タイルと DawnLike 素材の精密マッピングジェネレータ（拡張版）
"""
import json
import os
import re

def enrich_mappings(mapping, tiles):
    # ダンジョン壁スキン対応 (Wall.png: 20列 x 51行)
    # col 0..10: 各壁形状 (vertical, horizontal, corners, cross, T-junctions)
    # row 0: 通常石壁 (main walls)
    # row 4: 鉱山・洞窟風壁 (mines walls)
    # row 8: 溶岩・赤煉瓦壁 (gehennom walls)
    # row 12: 黄色・金風壁 (knox walls)
    # row 16: 青・クリスタル風壁 (sokoban walls)
    WALL_VARIANTS = {
        "main walls": 0,
        "mines walls": 4,
        "gehennom walls": 8,
        "knox walls": 12,
        "sokoban walls": 16,
    }
    WALL_SHAPES = {
        "vertical": 0,
        "horizontal": 1,
        "tlcorn": 2,
        "trcorn": 3,
        "blcorn": 4,
        "brcorn": 5,
        "cross wall": 6,
        "tuwall": 7,
        "tdwall": 8,
        "tlwall": 9,
        "trwall": 10,
    }

    # アイテムのキーワード対応
    WEAPON_KEYWORDS = {
        "polearm": ("Items/LongWep.png", 0, 3),
        "halberd": ("Items/LongWep.png", 1, 3),
        "bardiche": ("Items/LongWep.png", 2, 3),
        "voulge": ("Items/LongWep.png", 3, 3),
        "glaive": ("Items/LongWep.png", 4, 3),
        "guisarme": ("Items/LongWep.png", 5, 3),
        "bill-guisarme": ("Items/LongWep.png", 6, 3),
        "lucern hammer": ("Items/LongWep.png", 7, 3),
        "bec de corbin": ("Items/LongWep.png", 0, 4),
        "fauchard": ("Items/LongWep.png", 1, 4),
        "partisan": ("Items/LongWep.png", 2, 4),
        "spetum": ("Items/LongWep.png", 3, 4),
        "ranseur": ("Items/LongWep.png", 4, 4),
        "lance": ("Items/LongWep.png", 5, 4),
        "scythe": ("Items/LongWep.png", 6, 4),
        "sword": ("Items/LongWep.png", 0, 1),
        "blade": ("Items/LongWep.png", 1, 1),
        "saber": ("Items/LongWep.png", 7, 1),
        "dagger": ("Items/ShortWep.png", 0, 0),
        "knife": ("Items/ShortWep.png", 6, 0),
        "axe": ("Items/MedWep.png", 0, 0),
        "mace": ("Items/MedWep.png", 1, 1),
        "flail": ("Items/MedWep.png", 3, 1),
        "hammer": ("Items/MedWep.png", 4, 1),
        "club": ("Items/MedWep.png", 0, 1),
        "staff": ("Items/LongWep.png", 0, 2),
        "bow": ("Items/Ammo.png", 0, 2),
        "sling": ("Items/Ammo.png", 4, 2),
        "crossbow": ("Items/Ammo.png", 5, 2),
        "arrow": ("Items/Ammo.png", 0, 0),
        "bolt": ("Items/Ammo.png", 5, 0),
        "dart": ("Items/Ammo.png", 0, 1),
        "shuriken": ("Items/Ammo.png", 1, 1),
        "boomerang": ("Items/Ammo.png", 2, 1),
        "whip": ("Items/LongWep.png", 7, 4),
    }

    ARMOR_KEYWORDS = {
        "cloak": ("Items/Armor.png", 0, 2),
        "robe": ("Items/Armor.png", 1, 2),
        "apron": ("Items/Armor.png", 2, 2),
        "shirt": ("Items/Armor.png", 3, 2),
        "suit": ("Items/Armor.png", 0, 0),
        "mail": ("Items/Armor.png", 3, 0),
        "armor": ("Items/Armor.png", 1, 0),
        "dragon scale": ("Items/Armor.png", 5, 1),
        "dragon scales": ("Items/Armor.png", 6, 1),
        "helm": ("Items/Hat.png", 1, 0),
        "hat": ("Items/Hat.png", 0, 0),
        "cap": ("Items/Hat.png", 0, 0),
        "crown": ("Items/Hat.png", 0, 1),
        "boot": ("Items/Boot.png", 0, 0),
        "shoes": ("Items/Boot.png", 1, 0),
        "glove": ("Items/Glove.png", 0, 0),
        "gauntlet": ("Items/Glove.png", 1, 0),
        "shield": ("Items/Shield.png", 0, 0),
    }

    for t in tiles:
        tid = t["id"]
        tid_str = str(tid)
        if tid_str in mapping:
            continue
            
        desc = t["desc"].lower()
        clean = t["clean_name"].lower()
        cat = t["category"]
        assigned = None
        
        if cat == "other":
            # 壁バリエーションの判定
            for wall_type, base_row in WALL_VARIANTS.items():
                if wall_type in desc:
                    for shape, col in WALL_SHAPES.items():
                        if shape in desc:
                            assigned = ("Objects/Wall.png", col, base_row)
                            break
                    if not assigned:
                        assigned = ("Objects/Wall.png", 0, base_row)
                    break
            
            # 罠 (Trap0.png: 8x5)
            if not assigned and "trap" in desc:
                col = (tid % 8)
                row = ((tid // 8) % 3)
                assigned = ("Objects/Trap0.png", col, row)
                
            # エフェクト・ビーム (Objects/Effect0.png: 8x26)
            if not assigned and ("beam" in desc or "zap" in desc or "ray" in desc or "explosion" in desc):
                col = (tid % 8)
                row = ((tid // 8) % 20)
                assigned = ("Objects/Effect0.png", col, row)
                
        elif cat == "object":
            # 武器
            for kw, val in WEAPON_KEYWORDS.items():
                if kw in desc or kw in clean:
                    assigned = val
                    break
            # 防具
            if not assigned:
                for kw, val in ARMOR_KEYWORDS.items():
                    if kw in desc or kw in clean:
                        assigned = val
                        break
            # 食料・死体
            if not assigned and ("corpse" in desc or "glob of" in desc):
                assigned = ("Items/Flesh.png", (tid % 8), ((tid // 8) % 9))
            # スクロール
            if not assigned and "scroll" in desc:
                assigned = ("Items/Scroll.png", (tid % 8), ((tid // 8) % 6))
            # 魔法書
            if not assigned and ("book" in desc or "spellbook" in desc):
                assigned = ("Items/Book.png", (tid % 8), ((tid // 8) % 9))
            # 薬
            if not assigned and "potion" in desc:
                assigned = ("Items/Potion.png", (tid % 8), ((tid // 8) % 5))
            # 杖
            if not assigned and "wand" in desc:
                assigned = ("Items/Wand.png", (tid % 8), ((tid // 8) % 7))
            # 指輪
            if not assigned and "ring" in desc:
                assigned = ("Items/Ring.png", (tid % 8), ((tid // 8) % 6))
            # 宝石・石
            if not assigned and ("gem" in desc or "stone" in desc or "rock" in desc):
                assigned = ("Items/Rock.png", (tid % 8), 0)
                
        elif cat == "monster":
            # モンスターのシンボル系統フォールバック
            if "dragon" in desc:
                assigned = ("Characters/Reptile0.png", (tid % 8), 2)
            elif "giant" in desc:
                assigned = ("Characters/Humanoid0.png", (tid % 8), 6)
            elif "demon" in desc or "devil" in desc:
                assigned = ("Characters/Demon0.png", (tid % 8), 2)
            elif "zombie" in desc:
                assigned = ("Characters/Undead0.png", (tid % 8), 4)
            elif "mummy" in desc:
                assigned = ("Characters/Undead0.png", (tid % 8), 1)
            elif "golem" in desc:
                assigned = ("Characters/Humanoid0.png", (tid % 8), 12)
            elif "elf" in desc or "elven" in desc:
                assigned = ("Characters/Humanoid0.png", (tid % 8), 0)
            elif "orc" in desc or "orcish" in desc:
                assigned = ("Characters/Humanoid0.png", (tid % 8), 3)
            elif "guard" in desc or "soldier" in desc or "mercenary" in desc:
                assigned = ("Characters/Humanoid0.png", 2, 14)
            elif "priest" in desc:
                assigned = ("Characters/Player0.png", 6, 0)
            elif "wizard" in desc or "mage" in desc:
                assigned = ("Characters/Player0.png", 4, 1)

        if assigned:
            mapping[tid_str] = {
                "tile_id": tid,
                "desc": t["desc"],
                "sheet": assigned[0],
                "col": assigned[1],
                "row": assigned[2]
            }

if __name__ == "__main__":
    with open("tool/tileset/dawnlike_mapping.json", "r", encoding="utf-8") as f:
        mapping = json.load(f)
    with open("tool/tileset/nethack_tiles.json", "r", encoding="utf-8") as f:
        tiles = json.load(f)
        
    before = len(mapping)
    enrich_mappings(mapping, tiles)
    after = len(mapping)
    
    print(f"Enriched mapping: {before} -> {after} / {len(tiles)} ({after*100//len(tiles)}%)")
    
    with open("tool/tileset/dawnlike_mapping.json", "w", encoding="utf-8") as f:
        json.dump(mapping, f, ensure_ascii=False, indent=2)
    print("Updated dawnlike_mapping.json")
