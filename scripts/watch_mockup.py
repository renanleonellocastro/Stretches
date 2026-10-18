"""Round watch mock-up shared by the social generators.

A soft drop shadow on the base image, then a dark bezel with a circular crop
of a real screenshot and an orange accent ring. Each generator keeps its own
proportions through a ``WatchStyle``.
"""

from dataclasses import dataclass

from PIL import Image, ImageDraw, ImageFilter

TRANSPARENT = (0, 0, 0, 0)
SHADOW_COLOR = (0, 0, 0, 150)
SHADOW_RISE = 8            # the shadow starts this far above the bezel
BEZEL_COLOR = (17, 17, 19, 255)
FACE_SHARE = 0.9           # screenshot radius as a share of the bezel radius
RING_START_DEGREES = -60
RING_END_DEGREES = 210


@dataclass(frozen=True)
class WatchStyle:
    shadow_spread: int     # how far the shadow reaches past each side of the bezel
    shadow_drop: int       # how far the shadow reaches below the bezel
    shadow_blur: int
    ring_inset: int
    ring_width: int
    ring_color: tuple


def draw_watch(base, center, radius, face_path, style):
    """Composite the watch onto ``base`` around ``center``."""
    _draw_shadow(base, center, radius, style)
    layer = Image.new("RGBA", base.size, TRANSPARENT)
    _draw_bezel(layer, center, radius)
    _paste_face(layer, center, radius, face_path)
    _draw_ring(layer, center, radius, style)
    base.alpha_composite(layer)


def _draw_shadow(base, center, radius, style):
    cx, cy = center
    shadow = Image.new("RGBA", base.size, TRANSPARENT)
    box = [cx - radius - style.shadow_spread, cy - radius - SHADOW_RISE,
           cx + radius + style.shadow_spread, cy + radius + style.shadow_drop]
    ImageDraw.Draw(shadow).ellipse(box, fill=SHADOW_COLOR)
    base.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(style.shadow_blur)))


def _draw_bezel(layer, center, radius):
    ImageDraw.Draw(layer).ellipse(_circle_box(center, radius), fill=BEZEL_COLOR)


def _paste_face(layer, center, radius, face_path):
    """Circular crop of the screenshot, centered in the bezel."""
    face_radius = int(radius * FACE_SHARE)
    edge = face_radius * 2
    face = Image.open(face_path).convert("RGBA").resize((edge, edge), Image.LANCZOS)
    mask = Image.new("L", (edge, edge), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, edge, edge], fill=255)
    layer.paste(face, (center[0] - face_radius, center[1] - face_radius), mask)


def _draw_ring(layer, center, radius, style):
    box = _circle_box(center, radius - style.ring_inset)
    ImageDraw.Draw(layer).arc(box, RING_START_DEGREES, RING_END_DEGREES,
                              fill=style.ring_color, width=style.ring_width)


def _circle_box(center, radius):
    cx, cy = center
    return [cx - radius, cy - radius, cx + radius, cy + radius]
