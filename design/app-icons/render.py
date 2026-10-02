#!/usr/bin/env python3
"""Render the alternate app icons from their SVG sources.

Every alternate icon is authored as a 1024x1024 full-bleed SVG in ./svg.
This script rasterises each source with librsvg, flattens it to opaque RGB
and writes the five loose PNG sizes the app bundle registers under
CFBundleAlternateIcons (60, 120, 180, 76 and 152 px). It also writes a contact
sheet that shows every icon at 180 px and as a 60 px home screen row with the
iOS squircle mask applied.

Requirements: rsvg-convert (brew install librsvg) and Pillow.

    python3 design/app-icons/render.py              # render everything
    python3 design/app-icons/render.py AlternateNeon # render one icon
    python3 design/app-icons/render.py --sheet-only  # rebuild the sheet only
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SVG_DIR = HERE / "svg"
OUT_DIR = REPO / "Resources" / "AlternateIcons"
PRIMARY = REPO / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"
SHEET = HERE / "contact-sheet.png"

# Suffix -> pixel size. Matches the files referenced by CFBundleIconFiles.
SIZES = {
    "@1x": 60,
    "@2x": 120,
    "@3x": 180,
    "~ipad": 76,
    "@2x~ipad": 152,
}

# Order mirrors AppIconPresentationPolicy.choices.
# (iconName, picker title, source kind)
#   "svg"   : rendered from svg/<iconName>.svg and downscaled from 1024 px
#   "pixel" : pixel art; rendered at its native grid and scaled without blur
#   "png"   : hand-finished artwork kept as committed PNGs (no SVG source)
ICONS = [
    ("AlternateIcon", "kağıt", "svg"),
    ("AlternateDictionary", "sözlük", "svg"),
    ("AlternateNoir", "noir", "svg"),
    ("AlternateTerminal", "terminal", "svg"),
    ("AlternateNeon", "neon", "svg"),
    ("AlternateAurora", "aurora", "svg"),
    ("AlternateBosphorus", "boğaz", "svg"),
    ("AlternateForest", "orman", "svg"),
    ("AlternateLemon", "limon", "svg"),
    ("AlternateCoffee", "kahve", "svg"),
    ("AlternateGold", "altın", "svg"),
    ("AlternateDepth", "kil", "svg"),
    ("AlternatePixel", "8-bit", "pixel"),
    ("AlternateKlasik", "ornament", "png"),
]

MASTER = 1024
PIXEL_GRID = 20  # svg/AlternatePixel.svg uses a 20x20 grid: 3/6/9 px cells at 60/120/180


def rsvg(svg: Path, size: int) -> Image.Image:
    rsvg_bin = shutil.which("rsvg-convert")
    if rsvg_bin is None:
        sys.exit("rsvg-convert not found (brew install librsvg)")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "out.png"
        subprocess.run(
            [rsvg_bin, "-w", str(size), "-h", str(size), "-f", "png", "-o", str(out), str(svg)],
            check=True,
        )
        image = Image.open(out)
        image.load()
    return flatten(image)


def flatten(image: Image.Image) -> Image.Image:
    """Return an opaque RGB image (App Store icons may not carry alpha)."""
    image = image.convert("RGBA")
    base = Image.new("RGBA", image.size, (0, 0, 0, 255))
    base.alpha_composite(image)
    return base.convert("RGB")


def render_master(name: str, kind: str) -> Image.Image:
    svg = SVG_DIR / f"{name}.svg"
    if kind == "pixel":
        grid = rsvg(svg, PIXEL_GRID)
        return grid.resize((MASTER, MASTER), Image.NEAREST)
    return rsvg(svg, MASTER)


def scaled(name: str, kind: str, master: Image.Image, size: int) -> Image.Image:
    if kind == "pixel":
        grid = rsvg(SVG_DIR / f"{name}.svg", PIXEL_GRID)
        if size % PIXEL_GRID == 0:
            return grid.resize((size, size), Image.NEAREST)
        # Non-integer cell sizes: upscale crisply first, then resample once.
        factor = -(-size * 4 // PIXEL_GRID)
        big = grid.resize((PIXEL_GRID * factor, PIXEL_GRID * factor), Image.NEAREST)
        return big.resize((size, size), Image.LANCZOS)
    return master.resize((size, size), Image.LANCZOS)


def render_icon(name: str, kind: str) -> None:
    if kind == "png":
        return
    master = render_master(name, kind)
    for suffix, size in SIZES.items():
        image = scaled(name, kind, master, size)
        assert image.mode == "RGB" and image.size == (size, size)
        image.save(OUT_DIR / f"{name}{suffix}.png", optimize=True)
    print(f"rendered {name}")


# --- contact sheet -----------------------------------------------------------

def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size, index=1 if bold else 0)
        except (OSError, ValueError):
            continue
    return ImageFont.load_default()


def squircle_mask(size: int, supersample: int = 4) -> Image.Image:
    """Approximate the iOS continuous-corner icon mask with a superellipse."""
    big = size * supersample
    mask = Image.new("L", (big, big), 0)
    pixels = mask.load()
    n = 5.0
    half = big / 2
    for y in range(big):
        ny = abs((y + 0.5 - half) / half)
        for x in range(big):
            nx = abs((x + 0.5 - half) / half)
            if nx ** n + ny ** n <= 1.0:
                pixels[x, y] = 255
    return mask.resize((size, size), Image.LANCZOS)


def build_sheet() -> Path:
    entries = [("oldschool", Image.open(PRIMARY).convert("RGB").resize((180, 180), Image.LANCZOS))]
    homescreen = [("oldschool", Image.open(PRIMARY).convert("RGB").resize((180, 180), Image.LANCZOS))]
    for name, title, _ in ICONS:
        entries.append((title, Image.open(OUT_DIR / f"{name}@3x.png").convert("RGB")))
        homescreen.append((title, Image.open(OUT_DIR / f"{name}@3x.png").convert("RGB")))

    cols = 5
    tile = 180
    gap = 36
    label_h = 44
    margin = 56
    rows = -(-len(entries) // cols)
    grid_w = cols * tile + (cols - 1) * gap
    grid_h = rows * (tile + label_h) + (rows - 1) * gap

    # Home screen mock: 60 pt icons drawn at 2x (120 px) on a wallpaper.
    hs_cols = 5
    hs_icon = 120
    hs_gap_x = 56
    hs_gap_y = 60
    hs_rows = -(-len(homescreen) // hs_cols)
    hs_w = hs_cols * hs_icon + (hs_cols - 1) * hs_gap_x + 2 * 48
    hs_h = hs_rows * (hs_icon + 30) + (hs_rows - 1) * (hs_gap_y - 30) + 2 * 48

    width = margin * 2 + grid_w + 72 + hs_w
    height = margin * 2 + 70 + max(grid_h, hs_h)
    sheet = Image.new("RGB", (width, height), (244, 242, 236))
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, margin - 8), "ek$ilik app icons", fill=(21, 22, 19), font=font(34, bold=True))
    draw.text(
        (margin + grid_w + 72, margin - 2),
        "home screen 60pt (masked)",
        fill=(110, 106, 98),
        font=font(22),
    )

    top = margin + 70
    label_font = font(22, bold=True)
    for index, (title, image) in enumerate(entries):
        col, row = index % cols, index // cols
        x = margin + col * (tile + gap)
        y = top + row * (tile + label_h + gap)
        sheet.paste(image, (x, y))
        bbox = draw.textbbox((0, 0), title, font=label_font)
        draw.text((x + (tile - (bbox[2] - bbox[0])) / 2, y + tile + 10), title, fill=(21, 22, 19), font=label_font)

    # Wallpaper for the home screen mock.
    hs_x = margin + grid_w + 72
    hs_y = top
    wallpaper = Image.new("RGB", (hs_w, hs_h))
    wp = ImageDraw.Draw(wallpaper)
    for yy in range(hs_h):
        t = yy / max(1, hs_h - 1)
        wp.line(
            [(0, yy), (hs_w, yy)],
            fill=(int(58 + 40 * t), int(64 + 18 * t), int(92 - 20 * t)),
        )
    round_mask = Image.new("L", (hs_w, hs_h), 0)
    ImageDraw.Draw(round_mask).rounded_rectangle([0, 0, hs_w - 1, hs_h - 1], radius=48, fill=255)
    sheet.paste(wallpaper, (hs_x, hs_y), round_mask)

    mask = squircle_mask(hs_icon)
    small_font = font(17)
    for index, (title, image) in enumerate(homescreen):
        col, row = index % hs_cols, index // hs_cols
        x = hs_x + 48 + col * (hs_icon + hs_gap_x)
        y = hs_y + 48 + row * (hs_icon + hs_gap_y)
        # Simulate the 60 pt rendition: 120 px (@2x) art.
        icon = image.resize((hs_icon, hs_icon), Image.LANCZOS)
        sheet.paste(icon, (x, y), mask)
        bbox = draw.textbbox((0, 0), title, font=small_font)
        draw.text(
            (x + (hs_icon - (bbox[2] - bbox[0])) / 2, y + hs_icon + 8),
            title,
            fill=(255, 255, 255),
            font=small_font,
        )

    sheet.save(SHEET, optimize=True)
    print(f"wrote {SHEET.relative_to(REPO)}")
    return SHEET


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("names", nargs="*", help="iconName(s) to render (default: all)")
    parser.add_argument("--sheet-only", action="store_true", help="only rebuild the contact sheet")
    parser.add_argument("--sheet-copy", type=Path, help="also copy the contact sheet to this path")
    args = parser.parse_args()

    known = {name: kind for name, _, kind in ICONS}
    if not args.sheet_only:
        targets = args.names or list(known)
        for name in targets:
            if name not in known:
                sys.exit(f"unknown icon {name}; known: {', '.join(known)}")
            render_icon(name, known[name])
    sheet = build_sheet()
    if args.sheet_copy:
        shutil.copyfile(sheet, args.sheet_copy)
        print(f"copied sheet to {args.sheet_copy}")


if __name__ == "__main__":
    main()
