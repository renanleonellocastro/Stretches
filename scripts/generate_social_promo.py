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

import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from lunge_figure import render_lunge

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = "/System/Library/Fonts/Supplemental"
HOME_SCREENSHOT = os.path.join(ROOT, "docs/images/screenshots/home.png")
OUTPUT_PATH = os.path.join(ROOT, "docs/images/promo-instagram.png")

W = H = 1080
WATCH_CENTER_Y = 470
ORANGE = (255, 85, 0)
AMBER = (255, 170, 0)
WHITE = (245, 245, 245)
DIM = (165, 158, 152)
BG_TOP = (18, 13, 10)
FIGURE_SUPERSAMPLING = 8
FIGURE_STEPS = 90
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
    return render_lunge(size, color, FIGURE_SUPERSAMPLING, FIGURE_STEPS)


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


def compose_background():
    img = vgradient((W, H), BG_TOP, BG_BOTTOM).convert("RGBA")
    # Warm ambient glows.
    img.alpha_composite(radial_glow((W, H), (W // 2, WATCH_CENTER_Y), 520, ORANGE, 60))
    img.alpha_composite(radial_glow((W, H), (860, 180), 300, AMBER, 40))
    return img


def draw_header(img, d):
    """Icon and wordmark, centered as one lockup."""
    f_word = font("Arial Black.ttf", 96)
    word = "STRETCHES"
    tw = d.textlength(word, font=f_word)
    fig_sz, gap = 104, 26
    start_x = (W - (fig_sz + gap + tw)) / 2
    hy = 132
    img.alpha_composite(render_figure(fig_sz, ORANGE), (int(start_x), int(hy - fig_sz / 2)))
    d.text((start_x + fig_sz + gap, hy), word, font=f_word, fill=WHITE, anchor="lm")


def draw_tagline(d):
    d.text((W / 2, 762), "Your watch is your", font=font("Arial Bold.ttf", 52), fill=WHITE, anchor="mm")
    d.text((W / 2, 822), "stretching coach.", font=font("Arial Black.ttf", 56), fill=ORANGE, anchor="mm")
    d.text((W / 2, 892),
           "Build a routine. Get reminded. Follow guided, illustrated stretches.",
           font=font("Arial.ttf", 34), fill=DIM, anchor="mm")


def draw_footer(d):
    pill_row(d, 985, [
        ("Free", (12, 10, 9), AMBER),
        ("Open source", (12, 10, 9), AMBER),
        ("Garmin Connect IQ", WHITE, (40, 30, 24)),
    ], font("Arial Bold.ttf", 32))
    d.text((W / 2, 1042), "34 guided stretches  ·  6 languages  ·  saves to Garmin Connect",
           font=font("Arial.ttf", 26), fill=DIM, anchor="mm")


def main():
    img = compose_background()
    d = ImageDraw.Draw(img)
    draw_header(img, d)
    draw_watch(img, W // 2, WATCH_CENTER_Y, 220, HOME_SCREENSHOT)
    draw_tagline(d)
    draw_footer(d)
    img.convert("RGB").save(OUTPUT_PATH, quality=95)
    print("wrote", OUTPUT_PATH, img.size)


if __name__ == "__main__":
    main()
