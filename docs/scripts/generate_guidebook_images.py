# Modified by NetHackJP contributor @satokiyon; latest change date: 2026-10-24.
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_guidebook_images.py

Guidebook 内の主要なアスキーアート（図1: 画面全体、図2: ステータス行、図3: 移動キー）を
等幅フォントを用いてスマートフォンや Web で読みやすいダークスタイルの WebP 画像として生成します。

出力先: Guidebook/images/fig1.webp, fig2.webp, fig3.webp
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont

def get_monospace_font(font_size=16):
    """環境に応じた等幅フォントを取得する"""
    candidates = [
        r"C:\Windows\Fonts\msgothic.ttc",
        r"C:\Windows\Fonts\consola.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/noto/NotoSansMono-Regular.ttf",
    ]
    for p in candidates:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, font_size)
            except Exception:
                continue
    return ImageFont.load_default()

def render_ascii_to_image(ascii_lines, output_path, font_size=16, padding=10):
    font = get_monospace_font(font_size)
    
    # 1文字あたりのセルサイズを計測
    bbox = font.getbbox("M")
    char_w = bbox[2] - bbox[0]
    char_h = bbox[3] - bbox[1] + 6  # 行間マージン

    max_cols = max(len(line) for line in ascii_lines)
    num_rows = len(ascii_lines)

    img_w = max_cols * char_w + padding * 2
    img_h = num_rows * char_h + padding * 2

    # ダークテーマの背景 (#1e1e1e)
    bg_color = (30, 30, 30)
    fg_color = (220, 220, 220)
    border_color = (60, 60, 60)

    img = Image.new("RGB", (img_w, img_h), color=bg_color)
    draw = ImageDraw.Draw(img)

    # 枠線
    draw.rectangle([padding // 2, padding // 2, img_w - padding // 2, img_h - padding // 2], outline=border_color, width=1)

    y = padding
    for line in ascii_lines:
        x = padding
        draw.text((x, y), line, font=font, fill=fg_color)
        y += char_h

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, "WEBP", quality=90)
    print(f"Generated: {output_path} ({img_w}x{img_h})")

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    images_dir = os.path.join(root_dir, "Guidebook", "images")
    os.makedirs(images_dir, exist_ok=True)

    fig1_text = """+---------------------------------------------------------------+
|The bat bites!                                                 |
|                                                               |
|    ------                                                     |
|    |....|    ----------                                       |
|    |.<..|####...@...$.|                                       |
|    |....-#   |...B....+                                       |
|    |....|    |.d......|                                       |
|    ------    -------|--                                       |
|                                                               |
|                                                               |
|                                                               |
|Player the Rambler   St:12 Dx:7 Co:18 In:11 Wi:9 Ch:15 Neutral |
|Dlvl:1 $:993 HP:9(12) Pw:3(3) AC:10 Exp:1/19 T:752 Hungry Conf |
+---------------------------------------------------------------+"""

    fig2_text = """+---------------------------------------------------------------+
|Player the Rambler   St:12 Dx:7 Co:18 In:11 Wi:9 Ch:15         |
|Neutral $:993 HP:9(12) Pw:3(3) AC:10 Exp:1/19 Hungry           |
|Dlvl:1 T:752                                  Conf             |
+---------------------------------------------------------------+"""

    fig3_text = """+------------------------------------------+
|     y  k  u                7  8  9       |
|      \\ | /                  \\ | /        |
|     h- . -l                4- . -6       |
|      / | \\                  / | \\        |
|     b  j  n                1  2  3       |
| (number_pad off)      (number_pad on)    |
+------------------------------------------+"""

    render_ascii_to_image([l.strip() for l in fig1_text.strip().split("\n")], os.path.join(images_dir, "fig1.webp"))
    render_ascii_to_image([l.strip() for l in fig2_text.strip().split("\n")], os.path.join(images_dir, "fig2.webp"))
    render_ascii_to_image([l.strip() for l in fig3_text.strip().split("\n")], os.path.join(images_dir, "fig3.webp"))
    print("All Guidebook images generated successfully.")

if __name__ == "__main__":
    main()

