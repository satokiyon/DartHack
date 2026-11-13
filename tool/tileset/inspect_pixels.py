# -*- coding: utf-8 -*-
import os
from PIL import Image

def analyze_sheet_pixels(rel_path):
    path = os.path.join(r"c:\Users\satok\DartHack_private\tmp\DawnLike", rel_path)
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    cols = w // 16
    rows = h // 16
    print(f"=== {rel_path} ({cols} cols x {rows} rows) ===")
    for r in range(rows):
        tiles_in_row = []
        for c in range(cols):
            box = (c * 16, r * 16, (c + 1) * 16, (r + 1) * 16)
            tile = img.crop(box)
            # 透明以外のピクセル数
            non_empty = sum(1 for p in tile.getdata() if p[3] > 0)
            tiles_in_row.append(f"{non_empty:3d}")
        print(f"Row {r:2d}: " + " ".join(tiles_in_row))

analyze_sheet_pixels(r"Characters\Pest0.png")
analyze_sheet_pixels(r"Characters\Dog0.png")
analyze_sheet_pixels(r"Characters\Cat0.png")
analyze_sheet_pixels(r"Characters\Rodent0.png")
