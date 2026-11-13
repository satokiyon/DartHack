# -*- coding: utf-8 -*-
import json

with open('tool/tileset/nethack_tiles.json', 'r', encoding='utf-8') as f:
    tiles = json.load(f)

# モンスターのユニーク種別（male/femaleの重複を除く）を取得
unique_mons = []
seen = set()
for t in tiles[:789]:
    name = t['clean_name']
    if name not in seen:
        seen.add(name)
        unique_mons.append(name)

print(f"Total unique monsters in NetHack 5.0: {len(unique_mons)}")

# 最初のいくつかを表示
print("First 40 unique monsters:")
for i, name in enumerate(unique_mons[:40]):
    print(f"  {i:2d}: {name}")
