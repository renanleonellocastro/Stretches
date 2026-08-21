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

import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "docs", "images")
FONT_DIR = "/System/Library/Fonts/Supplemental"

TEAL = (0, 170, 170)
TEAL_BRIGHT = (0, 190, 190)
WHITE = (255, 255, 255)
BG = (8, 18, 22)


def rounded_line(draw, points, width, color):
    draw.line(points, fill=color, width=width, joint="curve")
    r = width // 2
    for x, y in points:
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)


def draw_stretch_figure(draw, cx, cy, scale, color):
    """Brand mark: a chunky FILLED silhouette in a forward-stretch (toe-touch)
    pose, matching the app launcher icon and Garmin's own flat activity figures.
    Authored in 0..80 space, centered on (cx, cy), scaled so the figure height
    maps to `scale`."""
    u = scale / 42.0

    def pt(x, y):             # 0..80 authoring space -> pixels, centered
        return (cx + (x - 44) * u, cy + (y - 48) * u)

    def limb(points, w):
        rounded_line(draw, [pt(x, y) for x, y in points], int(w * u), color)

    limb([(34, 32), (53, 41)], 16)             # thick folded trunk
    limb([(36, 35), (32, 60)], 11)             # arms hanging toward shins
    limb([(53, 41), (49, 68)], 12)             # leg
    limb([(53, 41), (57, 68)], 12)             # leg
    hr = 9 * u
    hx, hy = pt(27, 28)                          # head
    draw.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=color)


def render_icon(size):
    """Solid brand-teal disk + white filled stretch figure (no gradient, no
    outline), supersampled for crisp edges."""
    ss = 4
    edge = size * ss
    img = Image.new("RGBA", (edge, edge), (0, 0, 0, 0))
    ImageDraw.Draw(img).ellipse([0, 0, edge - 1, edge - 1], fill=(0, 170, 170, 255))
    draw_stretch_figure(ImageDraw.Draw(img), edge / 2, edge * 0.52,
                        edge * 0.60, WHITE + (255,))
    return img.resize((size, size), Image.LANCZOS)


def quantize_to_garmin_64(img):
    """Snap every channel to the nearest of {0, 85, 170, 255} — the 64-color
    MIP palette."""
    rgb = img.convert("RGB")
    px = rgb.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            px[x, y] = tuple(round(v / 85) * 85 for v in px[x, y])
    return rgb


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
           fill=TEAL_BRIGHT, anchor="mm")
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
    render_icon(128).convert("RGB").save(icon24)

    icon64 = os.path.join(OUT_DIR, "store-icon-64color.png")
    quantize_to_garmin_64(render_icon(128)).save(icon64)

    for p in (cover, icon24, icon64):
        report(p)


if __name__ == "__main__":
    main()
