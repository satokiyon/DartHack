# -*- coding: utf-8 -*-
"""
DawnLike 素材から NetHack 5.0 (DartHack) 準拠の 16x16 透過タイルシート (WebP) をビルドするスクリプト

仕様:
- 横40列 x 縦58行 = 2320セル (画像サイズ: 640x928)
- 透過タイルセット (isTransparent: true)
- タイル 0〜788: モンスター
- タイル 789〜1271: アイテム
- タイル 1272〜1514: ダンジョン地形・エフェクト・トラップ
- タイル 1515〜2303: モンスター石像 (0〜788 のグレースケール変換)
- タイル 2304〜2306: デカール (delimiter, petmark, pilemark)
- 未割り当てタイルは default_16x16.webp から自動フォールバック
"""
import os
import json
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
DAWN_DIR = r"c:\Users\satok\DartHack_private\tmp\DawnLike"
DEFAULT_TILE_PATH = os.path.join(PROJECT_ROOT, "sys", "flutter", "assets", "tiles", "default_16x16.webp")
OUT_TILE_PATH = os.path.join(PROJECT_ROOT, "sys", "flutter", "assets", "tiles", "dawnlike_16x16.webp")
MAPPING_PATH = os.path.join(SCRIPT_DIR, "dawnlike_mapping.json")

TILE_W = 16
TILE_H = 16
COLS = 40
ROWS = 58
TOTAL_CELLS = COLS * ROWS  # 2320

def get_tile_box(tile_id):
    col = tile_id % COLS
    row = tile_id // COLS
    x = col * TILE_W
    y = row * TILE_H
    return (x, y, x + TILE_W, y + TILE_H)

def to_grayscale(img_tile):
    """RGBA 画像のアルファチャンネルを保持したままグレースケール変換"""
    data = img_tile.get_flattened_data()
    new_data = []
    for r, g, b, a in data:
        if a == 0:
            new_data.append((0, 0, 0, 0))
        else:
            # Rec. 601 輝度式
            y = int(0.299 * r + 0.587 * g + 0.114 * b)
            new_data.append((y, y, y, a))
    res = Image.new("RGBA", img_tile.size)
    res.putdata(new_data)
    return res

def build_tileset():
    print(f"Loading default base tileset: {DEFAULT_TILE_PATH}")
    if not os.path.exists(DEFAULT_TILE_PATH):
        raise FileNotFoundError(f"Base tileset not found: {DEFAULT_TILE_PATH}")
    base_img = Image.open(DEFAULT_TILE_PATH).convert("RGBA")
    
    # サイズ検証 (640, 928)
    expected_w = COLS * TILE_W
    expected_h = ROWS * TILE_H
    if base_img.size != (expected_w, expected_h):
        print(f"Warning: base image size is {base_img.size}, expected {(expected_w, expected_h)}. Resizing canvas.")
        canvas = Image.new("RGBA", (expected_w, expected_h), (0, 0, 0, 0))
        canvas.paste(base_img, (0, 0))
    else:
        canvas = base_img.copy()

    # マッピング読み込み
    with open(MAPPING_PATH, "r", encoding="utf-8") as f:
        mapping = json.load(f)
    print(f"Loaded {len(mapping)} tile mappings from {MAPPING_PATH}")

    # シートキャッシュ
    sheet_cache = {}
    def load_sheet(rel_path):
        if rel_path not in sheet_cache:
            full_path = os.path.join(DAWN_DIR, rel_path)
            sheet_cache[rel_path] = Image.open(full_path).convert("RGBA")
        return sheet_cache[rel_path]

    # 透明クリア用タイル (16x16)
    clear_tile = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))

    # 1. マッピングされたタイルの合成 (0〜1514)
    applied_count = 0
    for tid_str, item in mapping.items():
        tid = int(tid_str)
        sheet_path = item["sheet"]
        col = item["col"]
        row = item["row"]

        sheet = load_sheet(sheet_path)
        crop_box = (col * TILE_W, row * TILE_H, (col + 1) * TILE_W, (row + 1) * TILE_H)
        sprite = sheet.crop(crop_box)

        # ターゲット位置
        dest_box = get_tile_box(tid)
        
        # DawnLike は透過タイルセットなので、セルの黒背景をクリアして透過スプライトを配置
        canvas.paste(clear_tile, dest_box)
        canvas.alpha_composite(sprite, (dest_box[0], dest_box[1]))
        applied_count += 1

    print(f"Applied {applied_count} DawnLike sprites to canvas (0〜1514).")

    # 2. モンスター石像タイルの生成 (1515〜2303, 計789枚)
    statue_count = 0
    for mon_id in range(789):
        # 元モンスターのタイルを canvas から取得
        mon_box = get_tile_box(mon_id)
        mon_tile = canvas.crop(mon_box)
        
        # グレースケール変換
        statue_tile = to_grayscale(mon_tile)
        
        # 石像のターゲット位置
        statue_id = 1515 + mon_id
        statue_box = get_tile_box(statue_id)
        
        # 配置
        canvas.paste(clear_tile, statue_box)
        canvas.alpha_composite(statue_tile, (statue_box[0], statue_box[1]))
        statue_count += 1

    print(f"Generated {statue_count} statue tiles (1515〜2303).")

    # 3. 未使用領域（2307〜2319）を完全クリア
    for unused_id in range(2307, TOTAL_CELLS):
        dest_box = get_tile_box(unused_id)
        canvas.paste(clear_tile, dest_box)

    # 4. 保存
    os.makedirs(os.path.dirname(OUT_TILE_PATH), exist_ok=True)
    print(f"Saving tileset to: {OUT_TILE_PATH}")
    canvas.save(OUT_TILE_PATH, "WEBP", lossless=True)
    
    file_size = os.path.getsize(OUT_TILE_PATH)
    print(f"Successfully generated: {OUT_TILE_PATH}")
    print(f"  Dimensions: {canvas.size[0]}x{canvas.size[1]} px")
    print(f"  File size: {file_size / 1024:.1f} KB")

if __name__ == "__main__":
    build_tileset()
