# -*- coding: utf-8 -*-
"""
DawnLike の各ミニシートから 16x16 タイルの情報を抽出し、
インデックス化するカタログツール
"""
import os
from PIL import Image

DAWN_DIR = r"c:\Users\satok\DartHack_private\tmp\DawnLike"

def get_sheet_info(rel_path):
    full_path = os.path.join(DAWN_DIR, rel_path)
    if not os.path.exists(full_path):
        return None
    img = Image.open(full_path)
    w, h = img.size
    cols = w // 16
    rows = h // 16
    return {
        "rel_path": rel_path,
        "width": w,
        "height": h,
        "cols": cols,
        "rows": rows,
        "total_tiles": cols * rows
    }

def extract_tile(rel_path, col, row):
    full_path = os.path.join(DAWN_DIR, rel_path)
    img = Image.open(full_path).convert("RGBA")
    box = (col * 16, row * 16, (col + 1) * 16, (row + 1) * 16)
    return img.crop(box)

if __name__ == "__main__":
    for cat in ["Characters", "Items", "Objects"]:
        p = os.path.join(DAWN_DIR, cat)
        files = sorted([f for f in os.listdir(p) if f.endswith(".png") and not f.endswith("1.png")])
        print(f"=== {cat} (Frame 0 files) ===")
        for f in files:
            info = get_sheet_info(os.path.join(cat, f))
            print(f"  {info['rel_path']:25s}: {info['cols']}x{info['rows']} = {info['total_tiles']} tiles")
