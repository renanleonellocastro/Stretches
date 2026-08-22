#!/usr/bin/env python3
"""Generate a square social-media promo image for the Stretches app.

Composes a 1080x1080 graphic in the app's orange identity: a headline
wordmark, the tapered lunge figure, a round watch mock-up showing the real
Home screen, a tagline and a footer of feature badges. Intended for
Instagram / WhatsApp / general sharing (the store hero is better for
LinkedIn's landscape crop).

Usage:
    python3 scripts/generate_social_promo.py
Output:
    docs/images/promo-instagram.png
"""

import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = "/System/Library/Fonts/Supplemental"

W = H = 1080
ORANGE = (255, 85, 0)
AMBER = (255, 170, 0)
WHITE = (245, 245, 245)
DIM = (165, 158, 152)
BG_TOP = (18, 13, 10)
BG_BOTTOM = (5, 4, 4)


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


def render_figure(size, color):
    """The same tapered lunge silhouette used by the app icon, at any size."""
    ss = 8
    edge = 80 * ss
    img = Image.new("RGBA", (edge, edge), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def taper(a, b, ra, rb, steps=90):
        for i in range(steps + 1):
            t = i / steps
            x = (a[0] + (b[0] - a[0]) * t) * ss
            y = (a[1] + (b[1] - a[1]) * t) * ss
            r = (ra + (rb - ra) * t) * ss
            d.ellipse([x - r, y - r, x + r, y + r], fill=color)

    def chain(pts, rad):
        for i in range(len(pts) - 1):
            taper(pts[i], pts[i + 1], rad[i], rad[i + 1])

    def blob(cx, cy, r):
        d.ellipse([(cx - r) * ss, (cy - r) * ss, (cx + r) * ss, (cy + r) * ss], fill=color)

    dx = 4
    def sh(pts):
        return [(x + dx, y) for x, y in pts]

    blob(40 + dx, 13, 7.0)
    chain(sh([(40, 19), (38, 44)]), [3.6, 5.0])
    chain(sh([(38, 44), (54, 52), (55, 73), (61, 74)]), [5.2, 3.4, 1.9, 1.5])
    chain(sh([(38, 44), (24, 58), (13, 72), (8, 71)]), [5.2, 3.2, 1.7, 1.5])
    chain(sh([(39, 24), (49, 32), (56, 42)]), [3.6, 2.0, 0.9])
    chain(sh([(39, 24), (30, 31), (24, 38)]), [3.6, 2.0, 0.9])
    return img.resize((size, size), Image.LANCZOS)


def radial_glow(size, center, radius, color, strength):
    w, h = size
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius],
              fill=color + (strength,))
    return layer.filter(ImageFilter.GaussianBlur(radius // 2))


def draw_watch(base, cx, cy, r, face_path):
    """Round watch body with the real screenshot inset and an orange ring."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # Soft drop shadow.
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ds = ImageDraw.Draw(sh)
    ds.ellipse([cx - r - 14, cy - r - 8, cx + r + 14, cy + r + 22], fill=(0, 0, 0, 150))
    sh = sh.filter(ImageFilter.GaussianBlur(26))
    base.alpha_composite(sh)
    # Bezel.
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(17, 17, 19, 255))
    # Face (circular crop of the screenshot).
    face = Image.open(face_path).convert("RGBA")
    fr = int(r * 0.9)
    face = face.resize((fr * 2, fr * 2), Image.LANCZOS)
    mask = Image.new("L", (fr * 2, fr * 2), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, fr * 2, fr * 2], fill=255)
    layer.paste(face, (cx - fr, cy - fr), mask)
    # Orange accent ring.
    d.arc([cx - r + 4, cy - r + 4, cx + r - 4, cy + r - 4], -60, 210,
          fill=ORANGE, width=10)
    base.alpha_composite(layer)


def pill_width(d, text, fnt, pad_x=28):
    return d.textlength(text, font=fnt) + pad_x * 2


def pill(d, cx, cy, text, fnt, fg, bg, pad_x=28):
    tw = d.textlength(text, font=fnt)
    half_h = 30
    box = [cx - tw / 2 - pad_x, cy - half_h, cx + tw / 2 + pad_x, cy + half_h]
    d.rounded_rectangle(box, radius=half_h, fill=bg)
    d.text((cx, cy), text, font=fnt, fill=fg, anchor="mm")


def pill_row(d, cy, items, fnt, gap=22):
    widths = [pill_width(d, t, fnt) for t, _, _ in items]
    total = sum(widths) + gap * (len(items) - 1)
    x = W / 2 - total / 2
    for (text, fg, bg), wd in zip(items, widths):
        pill(d, x + wd / 2, cy, text, fnt, fg, bg)
        x += wd + gap


def main():
    img = vgradient((W, H), BG_TOP, BG_BOTTOM).convert("RGBA")
    # Warm ambient glows.
    img.alpha_composite(radial_glow((W, H), (W // 2, 470), 520, ORANGE, 60))
    img.alpha_composite(radial_glow((W, H), (860, 180), 300, AMBER, 40))
    d = ImageDraw.Draw(img)

    # --- Header: icon + wordmark, centered as one lockup ---
    f_word = font("Arial Black.ttf", 96)
    word = "STRETCHES"
    tw = d.textlength(word, font=f_word)
    fig_sz, gap = 104, 26
    group_w = fig_sz + gap + tw
    start_x = (W - group_w) / 2
    hy = 132
    fig = render_figure(fig_sz, ORANGE)
    img.alpha_composite(fig, (int(start_x), int(hy - fig_sz / 2)))
    d.text((start_x + fig_sz + gap, hy), word, font=f_word, fill=WHITE, anchor="lm")

    # --- Center: watch mock-up showing the real Home screen ---
    draw_watch(img, W // 2, 470, 220, os.path.join(ROOT, "docs/images/screenshots/home.png"))

    # --- Tagline ---
    f_tag = font("Arial Bold.ttf", 52)
    d.text((W / 2, 762), "Your watch is your", font=f_tag, fill=WHITE, anchor="mm")
    f_tag2 = font("Arial Black.ttf", 56)
    d.text((W / 2, 822), "stretching coach.", font=f_tag2, fill=ORANGE, anchor="mm")

    # --- Sub copy ---
    f_sub = font("Arial.ttf", 34)
    d.text((W / 2, 892),
           "Build a routine. Get reminded. Follow guided, illustrated stretches.",
           font=f_sub, fill=DIM, anchor="mm")

    # --- Footer badges ---
    f_badge = font("Arial Bold.ttf", 32)
    pill_row(d, 985, [
        ("Free", (12, 10, 9), AMBER),
        ("Open source", (12, 10, 9), AMBER),
        ("Garmin Connect IQ", WHITE, (40, 30, 24)),
    ], f_badge)
    f_dev = font("Arial.ttf", 26)
    d.text((W / 2, 1042), "34 guided stretches  ·  6 languages  ·  saves to Garmin Connect",
           font=f_dev, fill=DIM, anchor="mm")

    out = os.path.join(ROOT, "docs/images/promo-instagram.png")
    img.convert("RGB").save(out, quality=95)
    print("wrote", out, img.size)


if __name__ == "__main__":
    main()
