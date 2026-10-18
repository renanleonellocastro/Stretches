"""The app's stretch mark: a tapered lunge (hip flexor stretch) silhouette.

The single source of truth for the figure drawn by the illustration, store and
social generators. Limbs narrow to their extremities like Garmin's own activity
icons. The pose is authored in an 80 unit square; each caller decides how those
units map to pixels and how finely the tapered strokes are sampled.
"""

from dataclasses import dataclass
from functools import partial
from typing import Callable

from PIL import Image, ImageDraw

FIGURE_SPACE = 80          # edge of the square the pose is authored in
CENTERING_SHIFT = 4        # nudge right so the pose sits centered in its square
TRANSPARENT = (0, 0, 0, 0)

# (center, radius) of the head, then (points, radius at each point) per limb,
# in drawing order.
HEAD = ((40, 13), 7.0)
LIMBS = (
    (((40, 19), (38, 44)), (3.6, 5.0)),                                  # torso
    (((38, 44), (54, 52), (55, 73), (61, 74)), (5.2, 3.4, 1.9, 1.5)),    # front leg
    (((38, 44), (24, 58), (13, 72), (8, 71)), (5.2, 3.2, 1.7, 1.5)),     # back leg
    (((39, 24), (49, 32), (56, 42)), (3.6, 2.0, 0.9)),                   # front arm
    (((39, 24), (30, 31), (24, 38)), (3.6, 2.0, 0.9)),                   # back arm
)


@dataclass(frozen=True)
class TaperedPen:
    """Draws strokes as a run of dots whose radius eases from start to end."""

    draw: ImageDraw.ImageDraw
    color: tuple
    to_pixels: Callable[[float, float], tuple[float, float]]
    unit: float
    steps: int

    def dot(self, point, radius):
        x, y = self.to_pixels(*point)
        pixel_radius = radius * self.unit
        self.draw.ellipse([x - pixel_radius, y - pixel_radius, x + pixel_radius, y + pixel_radius],
                          fill=self.color)

    def stroke(self, start, end, start_radius, end_radius):
        for step in range(self.steps + 1):
            t = step / self.steps
            point = (start[0] + (end[0] - start[0]) * t, start[1] + (end[1] - start[1]) * t)
            self.dot(point, start_radius + (end_radius - start_radius) * t)

    def chain(self, points, radii):
        for index in range(len(points) - 1):
            self.stroke(points[index], points[index + 1], radii[index], radii[index + 1])


def draw_lunge(pen, shift=0):
    (head_x, head_y), head_radius = HEAD
    pen.dot((head_x + shift, head_y), head_radius)
    for points, radii in LIMBS:
        pen.chain([(x + shift, y) for x, y in points], radii)


def scaled_pixels(scale, x, y):
    return (x * scale, y * scale)


def render_lunge(size, color, supersampling, steps):
    """The figure alone on a transparent square of `size` pixels."""
    edge = FIGURE_SPACE * supersampling
    img = Image.new("RGBA", (edge, edge), TRANSPARENT)
    to_pixels = partial(scaled_pixels, supersampling)
    pen = TaperedPen(ImageDraw.Draw(img), color, to_pixels, supersampling, steps)
    draw_lunge(pen, CENTERING_SHIFT)
    return img.resize((size, size), Image.LANCZOS)
