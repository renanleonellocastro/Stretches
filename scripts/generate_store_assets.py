#!/usr/bin/env python3
"""Generate the Connect IQ store form assets.

Outputs (docs/images/):
    store-cover.png        500x500  — store listing cover (web/mobile)
    store-icon-24bit.png   128x128  — on-device store icon, full color
    store-icon-64color.png 128x128  — same icon quantized to the Garmin
                                      64-color MIP palette (channels in
                                      {0, 85, 170, 255})

Usage:
    python3 scripts/generate_store_assets.py
"""

import os
from functools import partial

from PIL import Image, ImageDraw, ImageFont

from lunge_figure import TaperedPen, draw_lunge

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "docs", "images")
FONT_DIR = "/System/Library/Fonts/Supplemental"

TEAL = (0, 170, 170)
TEAL_BRIGHT = (0, 190, 190)
WHITE = (255, 255, 255)
ORANGE = (255, 85, 0)
BG = (8, 18, 22)

FIGURE_CENTER = (34.5, 40)   # bounding box center of the pose, authoring units
FIGURE_HEIGHT = 68.0         # pose height, authoring units
FIGURE_STEPS = 70


def figure_pixels(cx, cy, unit, x, y):
    """Authoring space to pixels, with the pose's bounding box centered on (cx, cy)."""
    return (cx + (x - FIGURE_CENTER[0]) * unit, cy + (y - FIGURE_CENTER[1]) * unit)


def draw_stretch_figure(draw, cx, cy, scale, color):
    """The app's stretch mark (see lunge_figure.py), centered on (cx, cy) and
    scaled so the figure height maps to `scale`."""
    unit = scale / FIGURE_HEIGHT
    to_pixels = partial(figure_pixels, cx, cy, unit)
    draw_lunge(TaperedPen(draw, color, to_pixels, unit, FIGURE_STEPS))


def render_icon(size):
    """Orange tapered stretch figure on a TRANSPARENT background, supersampled."""
    ss = 4
    edge = size * ss
    img = Image.new("RGBA", (edge, edge), (0, 0, 0, 0))
    draw_stretch_figure(ImageDraw.Draw(img), edge / 2, edge * 0.5,
                        edge * 0.82, ORANGE + (255,))
    return img.resize((size, size), Image.LANCZOS)


def quantize_to_garmin_64(img):
    """Snap RGB to the 64-color MIP palette ({0,85,170,255} per channel) while
    preserving the alpha channel (the icon has a transparent background)."""
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            px[x, y] = (round(r / 85) * 85, round(g / 85) * 85, round(b / 85) * 85, a)
    return img


def render_cover():
    """500x500 cover: dark background, big icon, app name."""
    size = 500
    img = Image.new("RGB", (size, size), BG)
    d = ImageDraw.Draw(img)
    icon = render_icon(300)
    img.paste(icon, ((size - 300) // 2, 55), icon)
    title = ImageFont.truetype(os.path.join(FONT_DIR, "Arial Black.ttf"), 58)
    sub = ImageFont.truetype(os.path.join(FONT_DIR, "Arial.ttf"), 22)
    d.text((size / 2, 405), "Stretches", font=title, fill=WHITE, anchor="mm")
    d.text((size / 2, 455), "Guided stretching for Garmin devices", font=sub,
           fill=(255, 170, 85), anchor="mm")
    return img


def report(path):
    kb = os.path.getsize(path) / 1024
    with Image.open(path) as im:
        print(f"{os.path.basename(path):26} {im.size[0]}x{im.size[1]}  {kb:6.1f} KB")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    cover = os.path.join(OUT_DIR, "store-cover.png")
    render_cover().save(cover)

    icon24 = os.path.join(OUT_DIR, "store-icon-24bit.png")
    render_icon(128).save(icon24)                       # keep alpha (transparent bg)

    icon64 = os.path.join(OUT_DIR, "store-icon-64color.png")
    quantize_to_garmin_64(render_icon(128)).save(icon64)

    for p in (cover, icon24, icon64):
        report(p)


if __name__ == "__main__":
    main()
