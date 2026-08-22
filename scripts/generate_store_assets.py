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
ORANGE = (255, 85, 0)
BG = (8, 18, 22)


def draw_stretch_figure(draw, cx, cy, scale, color):
    """The app's stretch mark: a smooth, tapered silhouette in a lunge
    (hip-flexor stretch) pose whose limbs narrow to their extremities, like
    Garmin's own activity figures. Authored in 0..80 space, centered on
    (cx, cy), scaled so the figure height maps to `scale`."""
    u = scale / 68.0

    def pt(x, y):             # 0..80 authoring space -> pixels, centered on bbox
        return (cx + (x - 34.5) * u, cy + (y - 40) * u)

    def taper(a, b, ra, rb, steps=70):
        for i in range(steps + 1):
            t = i / steps
            px, py = pt(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
            r = (ra + (rb - ra) * t) * u
            draw.ellipse([px - r, py - r, px + r, py + r], fill=color)

    def chain(pts, rad):
        for i in range(len(pts) - 1):
            taper(pts[i], pts[i + 1], rad[i], rad[i + 1])

    def blob(x, y, r):
        px, py = pt(x, y)
        rr = r * u
        draw.ellipse([px - rr, py - rr, px + rr, py + rr], fill=color)

    blob(40, 13, 7.0)                                             # head
    chain([(40, 19), (38, 44)], [3.6, 5.0])                       # torso
    chain([(38, 44), (54, 52), (55, 73), (61, 74)], [5.2, 3.4, 1.9, 1.5])  # front leg
    chain([(38, 44), (24, 58), (13, 72), (8, 71)], [5.2, 3.2, 1.7, 1.5])   # back leg
    chain([(39, 24), (49, 32), (56, 42)], [3.6, 2.0, 0.9])        # front arm
    chain([(39, 24), (30, 31), (24, 38)], [3.6, 2.0, 0.9])        # back arm


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
