import os
import glob
from PIL import Image

def convert_assets():
    assets_dir = r"c:\Users\satok\DartHack\sys\flutter\assets"
    images_dir = os.path.join(assets_dir, "images")
    tiles_dir = os.path.join(assets_dir, "tiles")

    print("--- Converting images ---")
    for filepath in glob.glob(os.path.join(images_dir, "*.png")):
        filename = os.path.basename(filepath)
        name, _ = os.path.splitext(filename)
        webp_path = os.path.join(images_dir, f"{name}.webp")

        with Image.open(filepath) as img:
            orig_w, orig_h = img.size
            max_size = 1920
            if orig_w > max_size or orig_h > max_size:
                if orig_w >= orig_h:
                    new_w = max_size
                    new_h = int(orig_h * (max_size / orig_w))
                else:
                    new_h = max_size
                    new_w = int(orig_w * (max_size / orig_h))
                img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
                print(f"Resized {filename}: {orig_w}x{orig_h} -> {new_w}x{new_h}")
            else:
                print(f"Keeping resolution for {filename}: {orig_w}x{orig_h}")

            img.save(webp_path, "WEBP", quality=90)
            orig_size = os.path.getsize(filepath)
            new_size = os.path.getsize(webp_path)
            print(f"Saved {name}.webp: {orig_size / 1024 / 1024:.2f} MB -> {new_size / 1024 / 1024:.2f} MB")

    print("\n--- Converting tiles (lossless, original resolution) ---")
    for filepath in glob.glob(os.path.join(tiles_dir, "*.png")):
        filename = os.path.basename(filepath)
        name, _ = os.path.splitext(filename)
        webp_path = os.path.join(tiles_dir, f"{name}.webp")

        with Image.open(filepath) as img:
            orig_w, orig_h = img.size
            print(f"Keeping resolution for tile {filename}: {orig_w}x{orig_h}")
            img.save(webp_path, "WEBP", lossless=True)
            orig_size = os.path.getsize(filepath)
            new_size = os.path.getsize(webp_path)
            print(f"Saved tile {name}.webp: {orig_size / 1024 / 1024:.2f} MB -> {new_size / 1024 / 1024:.2f} MB")

if __name__ == "__main__":
    convert_assets()
