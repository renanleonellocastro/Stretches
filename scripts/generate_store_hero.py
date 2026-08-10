#!/usr/bin/env python3
"""Generate the marketing hero/banner image for the Connect IQ store.

Composes an attractive banner: brand color background, app name + tagline
and feature highlights on the left, and two round watch mock-ups (Home and
a Stretch in progress) on the right. Real stretch artwork is pulled from the
generated illustration assets.

Usage:
    python3 scripts/generate_store_hero.py
Output:
    docs/images/store-hero.png
"""

import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = "/System/Library/Fonts/Supplemental"

BG_TOP = (10, 22, 26)
BG_BOTTOM = (6, 12, 14)
TEAL = (0, 190, 190)
WHITE = (255, 255, 255)
DIM = (170, 180, 182)
ORANGE = (255, 170, 0)
GREEN = (0, 200, 110)
GROUP_TEAL = (0, 170, 255)

W, H = 1600, 840


def font(name, size):
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)


def vgradient(size, top, bottom):
    w, h = size
    base = Image.new("RGB", (1, h))
    px = base.load()
    for y in range(h):
        t = y / max(1, h - 1)
        px[0, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
    return base.resize((w, h))


def center_text(d, cx, y, text, fnt, fill, anchor="mm"):
    d.text((cx, y), text, font=fnt, fill=fill, anchor=anchor)


def rounded(d, box, r, **kw):
    d.rounded_rectangle(box, radius=r, **kw)


def draw_watch(cx, cy, r, render):
    """Draw a round watch body and call render(draw, cx, cy, r) for the face."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - r - 26, cy - r - 26, cx + r + 26, cy + r + 26],
              fill=(28, 30, 33, 255))                       # case
    d.ellipse([cx - r - 14, cy - r - 14, cx + r + 14, cy + r + 14],
              fill=(12, 13, 15, 255))                       # bezel
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(0, 0, 0, 255))  # screen
    render(d, cx, cy, r)
    return layer


def arc(d, cx, cy, r, a0, a1, color, width):
    d.arc([cx - r, cy - r, cx + r, cy + r], a0, a1, fill=color, width=width)


def pill(d, cx, cy, text, fnt, color):
    tw = d.textlength(text, font=fnt)
    th = fnt.size
    bw, bh = tw + 34, th + 18
    rounded(d, [cx - bw / 2, cy - bh / 2, cx + bw / 2, cy + bh / 2],
            r=bh / 2, outline=color, width=3)
    center_text(d, cx, cy, text, fnt, color)


def render_home(d, cx, cy, r):
    top = cy - r
    arc(d, cx, cy, r - 8, -110, -70, TEAL, 9)                  # brand arc
    center_text(d, cx, top + r * 0.34, "STRETCHES", font("Arial Bold.ttf", 26), TEAL)
    center_text(d, cx, top + r * 0.62, "NEXT SESSION", font("Arial.ttf", 20), DIM)
    center_text(d, cx, cy + r * 0.02, "07:30", font("Arial Black.ttf", 92), WHITE)
    center_text(d, cx, cy + r * 0.46, "6 stretches  4 min", font("Arial.ttf", 22), DIM)
    pill(d, cx, cy + r * 0.72, "MENU", font("Arial Bold.ttf", 22), TEAL)


def render_stretch(d, cx, cy, r):
    top = cy - r
    d.arc([cx - r + 8, cy - r + 8, cx + r - 8, cy + r - 8], -90, 40,
          fill=GROUP_TEAL, width=10)                            # progress ring
    center_text(d, cx, top + r * 0.30, "1 / 6", font("Arial.ttf", 20), DIM)
    center_text(d, cx, top + r * 0.46, "Neck Tilt Right", font("Arial Bold.ttf", 24), WHITE)
    _paste_illustration(cx, cy - int(r * 0.05), int(r * 0.9))
    center_text(d, cx, cy + r * 0.66, "28", font("Arial Black.ttf", 64), GROUP_TEAL)


_ILLUS_LAYER = None


def _paste_illustration(cx, cy, size):
    global _ILLUS_LAYER
    path = os.path.join(ROOT, "assets", "illus183", "stretches", "neck_tilt_right.png")
    if not os.path.exists(path):
        return
    img = Image.open(path).convert("RGBA").resize((size, size), Image.LANCZOS)
    _ILLUS_LAYER = (img, (cx - size // 2, cy - size // 2))


def main():
    canvas = vgradient((W, H), BG_TOP, BG_BOTTOM).convert("RGBA")
    d = ImageDraw.Draw(canvas)

    # Left column: brand, tagline, feature highlights.
    x = 90
    d.text((x, 150), "Stretches", font=font("Arial Black.ttf", 120), fill=WHITE)
    d.text((x, 285), "Your guided stretching coach", font=font("Arial Bold.ttf", 42), fill=TEAL)
    d.text((x, 350), "on Garmin", font=font("Arial Bold.ttf", 42), fill=TEAL)

    feats = [
        (GROUP_TEAL, "34 illustrated stretches, 5 muscle groups"),
        (ORANGE, "Custom routines & daily reminders"),
        (GREEN, "Heart rate & calories in Garmin Connect"),
        (WHITE, "6 languages  ·  free & open source"),
    ]
    fy = 470
    for color, text in feats:
        d.ellipse([x + 6, fy + 12, x + 26, fy + 32], fill=color)
        d.text((x + 46, fy), text, font=font("Arial.ttf", 34), fill=(225, 230, 232))
        fy += 62

    # Right column: two watch mock-ups, lightly overlapping.
    home = draw_watch(1130, 236, 176, render_home)
    stretch = draw_watch(1372, 590, 190, render_stretch)
    canvas.alpha_composite(home)
    canvas.alpha_composite(stretch)
    if _ILLUS_LAYER is not None:
        canvas.alpha_composite(_ILLUS_LAYER[0].resize(_ILLUS_LAYER[0].size),
                               _ILLUS_LAYER[1])

    out = os.path.join(ROOT, "docs", "images", "store-hero.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    canvas.convert("RGB").save(out)
    print("Wrote", out, canvas.size)


if __name__ == "__main__":
    main()
