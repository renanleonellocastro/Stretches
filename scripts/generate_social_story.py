#!/usr/bin/env python3
"""Generate a vertical Instagram Story image for the Stretches app.

Produces a 1080x1920 (9:16) graphic in the app's orange identity, with the
top and bottom safe zones kept clear for the Instagram interface and a clear
lower area reserved for the link sticker. Portuguese copy to match the feed
post.

Usage:
    python3 scripts/generate_social_story.py
Output:
    docs/images/promo-story.png
"""

import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from lunge_figure import render_lunge
from watch_mockup import WatchStyle, draw_watch

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = "/System/Library/Fonts/Supplemental"
HOME_SCREENSHOT = os.path.join(ROOT, "docs/images/screenshots/home.png")
OUTPUT_PATH = os.path.join(ROOT, "docs/images/promo-story.png")

W, H = 1080, 1920
WATCH_CENTER_Y = 980
ORANGE = (255, 85, 0)
AMBER = (255, 170, 0)
WHITE = (245, 245, 245)
DIM = (170, 162, 156)
BG_TOP = (20, 14, 11)
FIGURE_SUPERSAMPLING = 8
FIGURE_STEPS = 90
WATCH_STYLE = WatchStyle(shadow_spread=16, shadow_drop=26, shadow_blur=30, ring_inset=5,
                         ring_width=12, ring_color=ORANGE)
BG_BOTTOM = (4, 3, 3)


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


def pill_width(d, text, fnt, pad_x=30):
    return d.textlength(text, font=fnt) + pad_x * 2


def pill(d, cx, cy, text, fnt, fg, bg, pad_x=30):
    tw = d.textlength(text, font=fnt)
    half_h = 34
    d.rounded_rectangle([cx - tw / 2 - pad_x, cy - half_h, cx + tw / 2 + pad_x, cy + half_h],
                        radius=half_h, fill=bg)
    d.text((cx, cy), text, font=fnt, fill=fg, anchor="mm")


def pill_row(d, cy, items, fnt, gap=24):
    widths = [pill_width(d, t, fnt) for t, _, _ in items]
    total = sum(widths) + gap * (len(items) - 1)
    x = W / 2 - total / 2
    for (text, fg, bg), wd in zip(items, widths):
        pill(d, x + wd / 2, cy, text, fnt, fg, bg)
        x += wd + gap


def compose_background():
    img = vgradient((W, H), BG_TOP, BG_BOTTOM).convert("RGBA")
    img.alpha_composite(radial_glow((W, H), (W // 2, 900), 620, ORANGE, 55))
    img.alpha_composite(radial_glow((W, H), (820, 360), 320, AMBER, 38))
    return img


def draw_header(img, d):
    """Icon and wordmark lockup, inside the top safe zone."""
    f_word = font("Arial Black.ttf", 88)
    word = "STRETCHES"
    tw = d.textlength(word, font=f_word)
    fig_sz, gap = 96, 24
    start_x = (W - (fig_sz + gap + tw)) / 2
    hy = 320
    img.alpha_composite(render_figure(fig_sz, ORANGE), (int(start_x), int(hy - fig_sz / 2)))
    d.text((start_x + fig_sz + gap, hy), word, font=f_word, fill=WHITE, anchor="lm")


def draw_tagline(d):
    d.text((W / 2, 470), "Seu relógio vira seu", font=font("Arial Bold.ttf", 58), fill=WHITE, anchor="mm")
    d.text((W / 2, 548), "treinador de alongamento", font=font("Arial Black.ttf", 66), fill=ORANGE,
           anchor="mm")


def draw_value_line(d):
    f_sub = font("Arial.ttf", 40)
    d.text((W / 2, 1360), "Monte sua rotina. Seja lembrado.", font=f_sub, fill=WHITE, anchor="mm")
    d.text((W / 2, 1414), "Alongue guiado pelo relógio.", font=f_sub, fill=DIM, anchor="mm")


def draw_badges(d):
    pill_row(d, 1510, [
        ("Grátis", (12, 10, 9), AMBER),
        ("Open source", (12, 10, 9), AMBER),
        ("Garmin", WHITE, (40, 30, 24)),
    ], font("Arial Bold.ttf", 34))


def draw_link_cue(d):
    """Keeps the very bottom clear for the Instagram reply bar."""
    d.text((W / 2, 1660), "Toque no link para instalar", font=font("Arial Bold.ttf", 44), fill=WHITE,
           anchor="mm")
    d.text((W / 2, 1716), "▼", font=font("Arial.ttf", 46), fill=ORANGE, anchor="mm")


def main():
    img = compose_background()
    d = ImageDraw.Draw(img)
    draw_header(img, d)
    draw_tagline(d)
    draw_watch(img, (W // 2, WATCH_CENTER_Y), 300, HOME_SCREENSHOT, WATCH_STYLE)
    draw_value_line(d)
    draw_badges(d)
    draw_link_cue(d)
    img.convert("RGB").save(OUTPUT_PATH, quality=95)
    print("wrote", OUTPUT_PATH, img.size)


if __name__ == "__main__":
    main()
