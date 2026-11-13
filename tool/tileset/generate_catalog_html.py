# -*- coding: utf-8 -*-
import os
import base64
from io import BytesIO
from PIL import Image

DAWN_DIR = r"c:\Users\satok\DartHack_private\tmp\DawnLike"

def generate_preview_html():
    html = ["<!DOCTYPE html><html><head><meta charset='utf-8'>",
            "<style>",
            "body { font-family: monospace; background: #222; color: #eee; padding: 20px; }",
            ".sheet { margin-bottom: 30px; background: #333; padding: 10px; border-radius: 8px; }",
            "table { border-collapse: collapse; margin-top: 10px; }",
            "td { border: 1px solid #555; padding: 4px; text-align: center; }",
            ".tile-img { image-rendering: pixelated; width: 32px; height: 32px; background: #444; }",
            ".coord { font-size: 10px; color: #aaa; }",
            "</style></head><body><h1>DawnLike Tiles Catalog</h1>"]

    for cat in ["Characters", "Items", "Objects"]:
        html.append(f"<h2>{cat}</h2>")
        p = os.path.join(DAWN_DIR, cat)
        files = sorted([f for f in os.listdir(p) if f.endswith(".png") and not f.endswith("1.png")])
        for f in files:
            full_p = os.path.join(p, f)
            img = Image.open(full_p).convert("RGBA")
            cols = img.size[0] // 16
            rows = img.size[1] // 16
            html.append(f"<div class='sheet'><h3>{cat}/{f} ({cols}x{rows})</h3><table>")
            
            # ヘッダー (列番号)
            html.append("<tr><th></th>" + "".join(f"<th>{c}</th>" for c in range(cols)) + "</tr>")
            
            for r in range(rows):
                html.append(f"<tr><th>{r}</th>")
                for c in range(cols):
                    box = (c * 16, r * 16, (c + 1) * 16, (r + 1) * 16)
                    tile = img.crop(box)
                    non_empty = sum(1 for p in tile.get_flattened_data() if p[3] > 0)
                    if non_empty > 0:
                        buf = BytesIO()
                        tile.save(buf, format="PNG")
                        b64 = base64.b64encode(buf.getvalue()).decode("ascii")
                        html.append(f"<td><img class='tile-img' src='data:image/png;base64,{b64}'><br><span class='coord'>{c},{r}</span></td>")
                    else:
                        html.append("<td style='background:#2a2a2a;'><span class='coord' style='color:#555;'>-</span></td>")
                html.append("</tr>")
            html.append("</table></div>")
            
    html.append("</body></html>")
    out_path = os.path.join(os.path.dirname(__file__), "dawnlike_catalog.html")
    with open(out_path, "w", encoding="utf-8") as f_out:
        f_out.write("\n".join(html))
    print(f"Catalog HTML generated: {out_path}")

if __name__ == "__main__":
    generate_preview_html()
