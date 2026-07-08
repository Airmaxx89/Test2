#!/usr/bin/env python3
"""
Generates all original pixel-art textures for Nordmark Legends.
Everything here is procedurally drawn from scratch (simple shapes + per-pixel
noise dithering) - no copyrighted or third-party artwork is used or referenced.

Run: python3 tools/generate_textures.py
Output: assets/textures/atlas.png, assets/textures/icons/*.png
"""
import random
from pathlib import Path
from PIL import Image

random.seed(1337)

ROOT = Path(__file__).resolve().parent.parent
TEX_DIR = ROOT / "assets" / "textures"
ICON_DIR = TEX_DIR / "icons"
TEX_DIR.mkdir(parents=True, exist_ok=True)
ICON_DIR.mkdir(parents=True, exist_ok=True)

TILE = 16


def shade(color, delta):
    return tuple(max(0, min(255, c + delta)) for c in color)


def noisy_fill(img, base, variance=10, seed_offset=0):
    px = img.load()
    r = random.Random(seed_offset)
    for y in range(img.height):
        for x in range(img.width):
            d = r.randint(-variance, variance)
            px[x, y] = shade(base, d)


def speckle(img, color, count, size=1):
    px = img.load()
    r = random.Random(hash(color) & 0xffff)
    for _ in range(count):
        x = r.randint(0, img.width - size)
        y = r.randint(0, img.height - size)
        for dx in range(size):
            for dy in range(size):
                px[x + dx, y + dy] = color


def tile_grass_top():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (86, 141, 63), 14, 1)
    speckle(img, (70, 120, 50), 10)
    speckle(img, (110, 160, 80), 8)
    return img


def tile_grass_side():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (110, 82, 52), 10, 2)
    for y in range(0, 5):
        for x in range(TILE):
            img.putpixel((x, y), shade((86, 141, 63), random.randint(-10, 10)))
    speckle(img, (70, 120, 50), 6)
    return img


def tile_dirt():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (110, 82, 52), 12, 3)
    speckle(img, (90, 65, 40), 12)
    return img


def tile_stone():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (128, 128, 132), 10, 4)
    speckle(img, (100, 100, 105), 14)
    speckle(img, (150, 150, 155), 8)
    return img


def tile_sand():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (216, 196, 140), 8, 5)
    speckle(img, (196, 176, 120), 10)
    return img


def tile_water():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (58, 96, 158), 10, 6)
    for x in range(0, TILE, 4):
        for y in range(TILE):
            if (x + y) % 8 < 2:
                img.putpixel((x % TILE, y), shade((80, 120, 180), 10))
    return img


def tile_wood_side():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (96, 66, 40), 8, 7)
    for x in range(0, TILE, 3):
        for y in range(TILE):
            img.putpixel((x, y), shade((80, 54, 32), -6))
    return img


def tile_wood_top():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (150, 110, 70), 6, 8)
    cx, cy = TILE // 2, TILE // 2
    for radius in range(1, 8, 2):
        for angle in range(0, 360, 8):
            import math
            x = int(cx + radius * math.cos(math.radians(angle)))
            y = int(cy + radius * math.sin(math.radians(angle)))
            if 0 <= x < TILE and 0 <= y < TILE:
                img.putpixel((x, y), shade((120, 85, 50), -10))
    return img


def tile_leaves():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (58, 104, 48), 16, 9)
    speckle(img, (40, 80, 35), 20)
    speckle(img, (80, 130, 60), 10)
    return img


def tile_snow():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (232, 236, 240), 6, 10)
    speckle(img, (210, 215, 222), 8)
    return img


def tile_path():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (150, 130, 100), 10, 11)
    speckle(img, (120, 100, 75), 14)
    return img


def tile_planks():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (168, 128, 84), 6, 12)
    for y in range(0, TILE, 4):
        for x in range(TILE):
            img.putpixel((x, y), shade((130, 95, 60), -14))
    return img


def tile_ore():
    img = tile_stone()
    speckle(img, (210, 175, 60), 6, size=1)
    return img


def tile_dark_stone():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (58, 58, 64), 8, 13)
    speckle(img, (40, 40, 46), 12)
    return img


def tile_roof():
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (140, 60, 46), 8, 14)
    for y in range(0, TILE, 3):
        for x in range(TILE):
            img.putpixel((x, y), shade((110, 45, 34), -10))
    return img


def tile_fachwerk():
    """Half-timber wall pattern, typical for a medieval German-style village."""
    img = Image.new("RGB", (TILE, TILE))
    noisy_fill(img, (232, 222, 198), 6, 15)
    beam = (70, 50, 34)
    for x in range(TILE):
        img.putpixel((x, 0), beam)
        img.putpixel((x, TILE - 1), beam)
    for y in range(TILE):
        img.putpixel((0, y), beam)
        img.putpixel((TILE - 1, y), beam)
    for i in range(TILE):
        if 0 <= i < TILE and 0 <= i < TILE:
            img.putpixel((i, i), beam)
    return img


TILES = [
    tile_grass_top, tile_grass_side, tile_dirt, tile_stone,
    tile_sand, tile_water, tile_wood_side, tile_wood_top,
    tile_leaves, tile_snow, tile_path, tile_planks,
    tile_ore, tile_dark_stone, tile_roof, tile_fachwerk,
]

COLS = 8
ROWS = 2
atlas = Image.new("RGB", (COLS * TILE, ROWS * TILE))
for idx, fn in enumerate(TILES):
    tile_img = fn()
    x = (idx % COLS) * TILE
    y = (idx // COLS) * TILE
    atlas.paste(tile_img, (x, y))

atlas.save(TEX_DIR / "atlas.png")
print(f"Wrote {TEX_DIR / 'atlas.png'} ({atlas.width}x{atlas.height}, {len(TILES)} tiles)")


# ---------------------------------------------------------------------------
# Item icons (32x32), simple original silhouettes on transparent background.
# ---------------------------------------------------------------------------

def new_icon():
    return Image.new("RGBA", (32, 32), (0, 0, 0, 0))


def rect(img, x0, y0, x1, y1, color):
    px = img.load()
    for y in range(y0, y1):
        for x in range(x0, x1):
            if 0 <= x < img.width and 0 <= y < img.height:
                px[x, y] = color


def icon_sword():
    img = new_icon()
    rect(img, 14, 4, 18, 20, (200, 200, 210, 255))
    rect(img, 15, 4, 17, 18, (230, 230, 240, 255))
    rect(img, 10, 20, 22, 24, (110, 70, 40, 255))
    rect(img, 14, 24, 18, 30, (70, 45, 25, 255))
    return img


def icon_bow():
    img = new_icon()
    for y in range(6, 26):
        w = int(5 * abs((y - 16) / 10))
        rect(img, 10 - w, y, 12 - w, y + 1, (120, 80, 45, 255))
    for y in range(6, 26):
        img.putpixel((16, y), (210, 210, 210, 255))
    return img


def icon_staff():
    img = new_icon()
    rect(img, 15, 8, 17, 28, (90, 60, 35, 255))
    rect(img, 12, 4, 20, 10, (90, 160, 220, 255))
    rect(img, 14, 6, 18, 8, (160, 210, 240, 255))
    return img


def icon_potion(color):
    img = new_icon()
    rect(img, 13, 4, 19, 8, (150, 150, 160, 255))
    rect(img, 10, 10, 22, 26, (210, 210, 220, 200))
    rect(img, 11, 14, 21, 25, color)
    return img


def icon_pelt():
    img = new_icon()
    noisy = random.Random(42)
    for y in range(8, 24):
        for x in range(6, 26):
            if noisy.random() > 0.15:
                img.putpixel((x, y), (150, 120, 90, 255))
    return img


def icon_tusk():
    img = new_icon()
    rect(img, 12, 8, 16, 24, (240, 235, 220, 255))
    rect(img, 16, 10, 20, 22, (220, 215, 200, 255))
    return img


def icon_coin():
    img = new_icon()
    for y in range(6, 26):
        for x in range(6, 26):
            dx, dy = x - 16, y - 16
            if dx * dx + dy * dy <= 100:
                img.putpixel((x, y), (222, 178, 60, 255))
    return img


def icon_scroll():
    img = new_icon()
    rect(img, 6, 10, 26, 22, (224, 210, 170, 255))
    rect(img, 6, 8, 26, 10, (200, 185, 145, 255))
    rect(img, 6, 22, 26, 24, (200, 185, 145, 255))
    return img


def icon_ore():
    img = new_icon()
    r = random.Random(7)
    for y in range(8, 24):
        for x in range(8, 24):
            if r.random() > 0.3:
                img.putpixel((x, y), (110, 110, 116, 255))
    for _ in range(10):
        x, y = r.randint(9, 23), r.randint(9, 23)
        img.putpixel((x, y), (210, 175, 60, 255))
    return img


def icon_cloth():
    img = new_icon()
    rect(img, 7, 8, 25, 24, (235, 235, 230, 255))
    for y in range(8, 24, 3):
        rect(img, 7, y, 25, y + 1, (210, 210, 205, 255))
    return img


def icon_leather():
    img = new_icon()
    rect(img, 7, 8, 25, 24, (150, 100, 60, 255))
    rect(img, 9, 10, 23, 22, (170, 120, 75, 255))
    return img


def icon_log():
    img = new_icon()
    rect(img, 6, 12, 26, 20, (130, 95, 60, 255))
    rect(img, 6, 12, 8, 20, (170, 130, 90, 255))
    rect(img, 24, 12, 26, 20, (170, 130, 90, 255))
    return img


def icon_apple():
    img = new_icon()
    for y in range(10, 24):
        for x in range(9, 23):
            dx, dy = x - 16, y - 17
            if dx * dx + dy * dy <= 64:
                img.putpixel((x, y), (196, 48, 48, 255))
    rect(img, 15, 5, 17, 10, (90, 60, 30, 255))
    return img


def icon_bread():
    img = new_icon()
    for y in range(12, 22):
        for x in range(7, 25):
            img.putpixel((x, y), (196, 148, 84, 255))
    rect(img, 9, 14, 23, 16, (170, 122, 62, 255))
    return img


ICONS = {
    "sword": icon_sword,
    "bow": icon_bow,
    "staff": icon_staff,
    "health_potion": lambda: icon_potion((190, 40, 50, 255)),
    "mana_potion": lambda: icon_potion((60, 90, 200, 255)),
    "wolf_pelt": icon_pelt,
    "boar_tusk": icon_tusk,
    "coin": icon_coin,
    "quest_scroll": icon_scroll,
    "iron_ore": icon_ore,
    "cloth": icon_cloth,
    "leather": icon_leather,
    "wood_log": icon_log,
    "apple": icon_apple,
    "bread": icon_bread,
}

for name, fn in ICONS.items():
    fn().save(ICON_DIR / f"{name}.png")

print(f"Wrote {len(ICONS)} item icons to {ICON_DIR}")
