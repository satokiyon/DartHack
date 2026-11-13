# -*- coding: utf-8 -*-
import json

with open('tool/tileset/nethack_tiles.json', 'r', encoding='utf-8') as f:
    tiles = json.load(f)

print("=== First 30 monsters ===")
for t in tiles[:30]:
    print(f"{t['id']:4d}: {t['clean_name']} [{t['gender']}] (orig: {t['desc']})")

print("\n=== Objects around boundaries ===")
# objects start at 789
for t in tiles[789:810]:
    print(f"{t['id']:4d}: {t['clean_name']} (orig: {t['desc']})")

print("\n=== Other around boundaries ===")
# other start at 1272
for t in tiles[1272:1295]:
    print(f"{t['id']:4d}: {t['clean_name']} (orig: {t['desc']})")
