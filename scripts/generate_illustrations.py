#!/usr/bin/env python3
"""Generate the stretch illustration PNGs and the drawables resource XML.

Each stretch is drawn as a friendly, readable human figure -- a white body
with a dark outline, an orange two-piece outfit (top + shorts), simple hair
and red motion arrows -- in the spirit of a printed stretching chart.

Poses are authored in a fixed 140-unit logical space via a small skeleton
(the ``Figure`` class), rendered on a supersampled canvas, then downscaled
to one PNG per screen-size bucket so the artwork looks crisp and
proportional on every device from the 208x208 Forerunner 55 up to the
416x416 Venu 2.

Usage:
    python3 scripts/generate_illustrations.py

Outputs, per size bucket:
    assets/illus<size>/drawables.xml         (resource declarations)
    assets/illus<size>/stretches/<id>.png    (one per stretch)
Shared:
    resources/drawables/launcher_icon.png    (app launcher icon)
    resources/drawables/drawables.xml        (launcher icon declaration)
    scripts/resource_paths.jungle            (per-product resourcePath map)
"""

import math
import os

from PIL import Image, ImageDraw, ImageOps

# ---------------------------------------------------------------------------
# Rendering constants
# ---------------------------------------------------------------------------

SCALE = 5                # supersampling factor
LOGICAL = 140            # coordinate space poses are authored in
S = LOGICAL * SCALE       # working canvas edge

# Palette. All channels are multiples of 0x55 so the colors survive
# quantization to the 64-color Garmin MIP palette.
OUTLINE = (0, 0, 0, 255)
BODY = (255, 255, 255, 255)       # skin/limbs: white, defined by the outline
OUTFIT = (255, 170, 0, 255)       # orange top + shorts (#FFAA00)
HAIR = (170, 85, 0, 255)          # brown (#AA5500)
ARROW = (255, 0, 0, 255)
CARD = (255, 255, 255, 255)
WALL = (170, 170, 170, 255)       # props (wall / floor)

# Muscle-group card border colors (kept meaningful: they match the app).
GROUPS = {
    "neck": (0, 170, 255, 255),      # #00AAFF
    "wrist": (255, 170, 0, 255),     # #FFAA00
    "shoulder": (170, 85, 255, 255), # #AA55FF
    "torso": (0, 170, 85, 255),      # #00AA55
    "legs": (255, 85, 0, 255),       # #FF5500
}

# Stroke widths (logical units).
LIMB_W = 12
ARM_W = 10
NECK_W = 11
OUTLINE_W = 3            # half-thickness of the dark outline around fills


# ---------------------------------------------------------------------------
# Device resolutions -> per-bucket PNG sizes
# ---------------------------------------------------------------------------

DEVICE_RES = {
    "fr55": (208, 208),
    "fr255s": (218, 218), "fr255sm": (218, 218), "vivoactive4s": (218, 218),
    "fr245": (240, 240), "fr245m": (240, 240), "fr745": (240, 240),
    "fr945": (240, 240), "fenix6s": (240, 240), "fenix6spro": (240, 240),
    "fenix7s": (240, 240), "venusq": (240, 240), "venusqm": (240, 240),
    "fr255": (260, 260), "fr255m": (260, 260), "fr955": (260, 260),
    "fenix6": (260, 260), "fenix6pro": (260, 260), "fenix7": (260, 260),
    "vivoactive4": (260, 260),
    "fenix6xpro": (280, 280), "fenix7x": (280, 280),
    "venusq2": (320, 360), "venusq2m": (320, 360),
    "venu2s": (360, 360),
    "venu": (390, 390),
    "venu2": (416, 416), "venu2plus": (416, 416),
}


def device_size(w, h):
    """Illustration edge for a screen: ~47% of height, capped by width so it
    fits the workout screen's illustration band on every device."""
    return min(round(0.47 * h), round(0.50 * w))


def buckets():
    """Return {size: [devices]} grouping devices that share a PNG size."""
    out = {}
    for device, (w, h) in DEVICE_RES.items():
        out.setdefault(device_size(w, h), []).append(device)
    return out


# ---------------------------------------------------------------------------
# Drawing canvas
# ---------------------------------------------------------------------------

class Canvas:
    """Wraps the PIL primitives, working in the logical coordinate space."""

    def __init__(self, edge=S):
        self.S = edge
        self.img = Image.new("RGBA", (edge, edge), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.img)

    # -- low level ---------------------------------------------------------
    def _pts(self, points):
        return [(x * SCALE, y * SCALE) for x, y in points]

    def _thick(self, points, width, color):
        pts = self._pts(points)
        w = int(width * SCALE)
        if len(pts) >= 2:
            self.draw.line(pts, fill=color, width=w, joint="curve")
        r = w // 2
        for x, y in pts:  # round caps / joints
            self.draw.ellipse([x - r, y - r, x + r, y + r], fill=color)

    # -- shapes ------------------------------------------------------------
    def card(self, border_color):
        radius = 26 * SCALE
        self.draw.rounded_rectangle(
            [3 * SCALE, 3 * SCALE, self.S - 3 * SCALE, self.S - 3 * SCALE],
            radius=radius, fill=CARD, outline=border_color, width=4 * SCALE)

    def limb(self, points, width=LIMB_W, fill=BODY):
        """Outlined capsule (or chain of capsules)."""
        self._thick(points, width + 2 * OUTLINE_W, OUTLINE)
        self._thick(points, width, fill)

    def poly(self, points, fill=OUTFIT, outline=OUTLINE):
        pts = self._pts(points)
        self.draw.polygon(pts, fill=outline)  # outline base
        # inset fill: shrink polygon slightly toward its centroid
        cx = sum(p[0] for p in pts) / len(pts)
        cy = sum(p[1] for p in pts) / len(pts)
        k = OUTLINE_W * SCALE
        inner = []
        for x, y in pts:
            dx, dy = cx - x, cy - y
            d = math.hypot(dx, dy) or 1
            inner.append((x + dx / d * k, y + dy / d * k))
        self.draw.polygon(inner, fill=fill)

    def blob(self, cx, cy, r, fill=BODY, outline=OUTLINE):
        x, y = cx * SCALE, cy * SCALE
        rr = r * SCALE
        ow = OUTLINE_W * SCALE
        self.draw.ellipse([x - rr - ow, y - rr - ow, x + rr + ow, y + rr + ow],
                          fill=outline)
        self.draw.ellipse([x - rr, y - rr, x + rr, y + rr], fill=fill)

    def prop_line(self, points, width, color=WALL):
        self._thick(points, width, color)

    def arrow(self, points, color=ARROW, width=8):
        self._thick(points, width, color)
        (x1, y1), (x2, y2) = points[-2], points[-1]
        ang = math.atan2(y2 - y1, x2 - x1)
        size = 8
        for side in (-1, 1):
            a = ang + math.pi + side * 0.5
            end = (x2 + size * math.cos(a), y2 + size * math.sin(a))
            self._thick([(x2, y2), end], width, color)

    def arc_arrow(self, cx, cy, r, start_deg, end_deg, color=ARROW, width=8):
        steps = 16
        pts = []
        for i in range(steps + 1):
            a = math.radians(start_deg + (end_deg - start_deg) * i / steps)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
        self.arrow(pts, color=color, width=width)

    def save(self, path, target, mirror=False):
        img = ImageOps.mirror(self.img) if mirror else self.img
        img.resize((target, target), Image.LANCZOS).save(path)


# ---------------------------------------------------------------------------
# Figure: a small skeleton rendered as a white, outlined body in an orange
# two-piece outfit. Poses set joints, then call draw().
# ---------------------------------------------------------------------------

class Figure:
    def __init__(self, c):
        self.c = c
        # Default: front-facing standing figure, centered.
        self.head = (70, 24)
        self.head_r = 13
        self.face = 90            # nose direction in degrees (90 = toward viewer/down)
        self.neck = (70, 38)
        self.shoulderL = (55, 49)
        self.shoulderR = (85, 49)
        self.elbowL = (50, 72)
        self.elbowR = (90, 72)
        self.handL = (50, 92)
        self.handR = (90, 92)
        self.hipL = (61, 88)
        self.hipR = (79, 88)
        self.kneeL = (59, 108)
        self.kneeR = (81, 108)
        self.footL = (57, 126)
        self.footR = (83, 126)
        self.profile = False      # side view: draw one arm/leg, torso slimmer

    # convenience ----------------------------------------------------------
    def mid(self, a, b, t=0.5):
        return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)

    def torso_quad(self):
        return [self.shoulderL, self.shoulderR, self.hipR, self.hipL]

    def draw(self):
        c = self.c
        # Legs (skin), back leg first for a bit of depth.
        c.limb([self.hipR, self.kneeR, self.footR], LIMB_W)
        c.limb([self.hipL, self.kneeL, self.footL], LIMB_W)
        c.blob(*self.footR, 4)
        c.blob(*self.footL, 4)

        # Torso (white base) then the orange two-piece over it.
        c.poly(self.torso_quad(), fill=BODY)
        topL = self.mid(self.shoulderL, self.hipL, 0.02)
        topR = self.mid(self.shoulderR, self.hipR, 0.02)
        braL = self.mid(self.shoulderL, self.hipL, 0.42)
        braR = self.mid(self.shoulderR, self.hipR, 0.42)
        c.poly([topL, topR, braR, braL], fill=OUTFIT)          # sports top
        shoTop_L = self.mid(self.shoulderL, self.hipL, 0.66)
        shoTop_R = self.mid(self.shoulderR, self.hipR, 0.66)
        c.poly([shoTop_L, shoTop_R, self.hipR, self.hipL], fill=OUTFIT)  # waistband
        # Shorts wrap onto the upper thighs.
        thighL = self.mid(self.hipL, self.kneeL, 0.32)
        thighR = self.mid(self.hipR, self.kneeR, 0.32)
        c.limb([self.mid(self.hipL, self.hipR, 0.30), thighL], LIMB_W + 2, fill=OUTFIT)
        c.limb([self.mid(self.hipL, self.hipR, 0.70), thighR], LIMB_W + 2, fill=OUTFIT)

        # Arms (skin), in front of the torso.
        c.limb([self.shoulderR, self.elbowR, self.handR], ARM_W)
        c.limb([self.shoulderL, self.elbowL, self.handL], ARM_W)
        c.blob(*self.handR, 4)
        c.blob(*self.handL, 4)

        # Neck + head.
        c.limb([self.neck, (self.head[0], self.head[1] + self.head_r - 2)], NECK_W)
        self.draw_head()

    def draw_head(self):
        c = self.c
        hx, hy = self.head
        r = self.head_r
        c.blob(hx, hy, r, fill=BODY)
        # Hair: a filled cap over the top ~two thirds of the head.
        bbox = [(hx - r) * SCALE, (hy - r) * SCALE, (hx + r) * SCALE, (hy + r) * SCALE]
        c.draw.pieslice(bbox, 180, 360, fill=HAIR)             # top dome
        c.draw.pieslice(bbox, 300, 360, fill=HAIR)             # side fringe
        c.draw.pieslice(bbox, 180, 240, fill=HAIR)
        # Nose bump in the facing direction.
        a = math.radians(self.face)
        n1 = ((hx + r * math.cos(a - 0.3)) * SCALE, (hy + r * math.sin(a - 0.3)) * SCALE)
        n2 = ((hx + r * math.cos(a + 0.3)) * SCALE, (hy + r * math.sin(a + 0.3)) * SCALE)
        tip = ((hx + r * 1.28 * math.cos(a)) * SCALE, (hy + r * 1.28 * math.sin(a)) * SCALE)
        c.draw.polygon([n1, tip, n2], fill=BODY)
        c.draw.line([n1, tip, n2], fill=OUTLINE, width=OUTLINE_W * SCALE)


# ---------------------------------------------------------------------------
# Poses (base = right/forward variants; left variants are mirrored)
# ---------------------------------------------------------------------------

def base_standing(c):
    return Figure(c)


# -- Neck --------------------------------------------------------------------

def neck_tilt_right(c):
    f = base_standing(c)
    f.head = (76, 27); f.face = 90
    f.draw()
    c.arc_arrow(70, 40, 34, -80, -30)


def neck_tilt_down(c):
    f = base_standing(c)
    f.head = (70, 30); f.face = 90
    f.draw()
    c.arrow([(96, 22), (96, 40)])


def neck_tilt_up(c):
    f = base_standing(c)
    f.head = (70, 22); f.face = 70
    f.draw()
    c.arrow([(96, 42), (96, 24)])


def neck_rot_right(c):
    f = base_standing(c)
    f.face = 40
    f.draw()
    c.arc_arrow(70, 24, 22, -70, 0)


def neck_rot_right_down(c):
    f = base_standing(c)
    f.head = (72, 28); f.face = 55
    f.draw()
    c.arrow([(98, 22), (104, 40)])


def neck_rot_right_up(c):
    f = base_standing(c)
    f.head = (72, 22); f.face = 25
    f.draw()
    c.arrow([(100, 42), (106, 24)])


def neck_chest_rot_right_up(c):
    f = base_standing(c)
    f.head = (73, 22); f.face = 25
    # Left hand pins the chest, right stays low.
    f.elbowL = (60, 60); f.handL = (70, 58)
    f.draw()
    c.blob(70, 58, 4)
    c.arrow([(62, 60), (62, 74)])          # pull chest down
    c.arrow([(100, 40), (106, 24)])        # head up + turned


# -- Wrist / forearm ---------------------------------------------------------

def wrist_flexor_right(c):
    f = base_standing(c)
    f.face = 0
    # Right arm straight out, palm up/forward; left hand pulls the fingers.
    f.shoulderR = (82, 50); f.elbowR = (104, 54); f.handR = (120, 54)
    f.shoulderL = (58, 50); f.elbowL = (86, 60); f.handL = (116, 50)
    f.draw()
    c.limb([(120, 54), (120, 42)], ARM_W - 2)   # fingers up
    c.arrow([(128, 46), (122, 40)])


def wrist_extensor_right(c):
    f = base_standing(c)
    f.face = 0
    f.shoulderR = (82, 50); f.elbowR = (104, 54); f.handR = (120, 54)
    f.shoulderL = (58, 50); f.elbowL = (86, 62); f.handL = (116, 58)
    f.draw()
    c.limb([(120, 54), (120, 66)], ARM_W - 2)   # fingers down
    c.arrow([(128, 62), (122, 68)])


# -- Shoulder / chest / upper back ------------------------------------------

def shoulder_cross_right(c):
    f = base_standing(c)
    # Right arm straight across the chest; left forearm hooks it.
    f.shoulderR = (85, 50); f.elbowR = (58, 56); f.handR = (44, 58)
    f.shoulderL = (55, 50); f.elbowL = (60, 66); f.handL = (64, 54)
    f.draw()
    c.arrow([(92, 66), (68, 70)])


def triceps_right(c):
    f = base_standing(c)
    # Right arm bent behind head; left hand pulls the elbow.
    f.shoulderR = (85, 50); f.elbowR = (86, 20); f.handR = (66, 30)
    f.shoulderL = (55, 50); f.elbowL = (60, 34); f.handL = (82, 20)
    f.draw()
    c.blob(86, 20, 4)
    c.arrow([(100, 26), (90, 20)])


def chest_opener(c):
    f = base_standing(c)
    f.face = 0
    # Hands clasped behind the back, chest lifting.
    f.shoulderL = (58, 50); f.elbowL = (52, 70); f.handL = (70, 84)
    f.shoulderR = (78, 50); f.elbowR = (86, 70); f.handR = (72, 86)
    f.draw()
    c.blob(71, 85, 4)
    c.arrow([(44, 52), (34, 42)])          # chest up / forward


def upper_back_reach(c):
    f = base_standing(c)
    f.face = 0
    # Rounded upper back, arms reaching forward, hands clasped.
    f.shoulderL = (58, 54); f.shoulderR = (74, 52)
    f.elbowL = (86, 62); f.handL = (108, 66)
    f.elbowR = (88, 66); f.handR = (108, 68)
    f.head = (56, 34)
    f.draw()
    c.blob(108, 67, 4)
    c.arrow([(112, 80), (122, 84)])


# -- Torso / back ------------------------------------------------------------

def side_bend_right(c):
    f = base_standing(c)
    # Trunk leans right; left arm arcs overhead, right arm down the side.
    f.shoulderL = (60, 52); f.shoulderR = (92, 46)
    f.hipL = (62, 88); f.hipR = (80, 88)
    f.head = (92, 30); f.face = 90
    f.elbowL = (66, 30); f.handL = (92, 18)
    f.elbowR = (96, 66); f.handR = (98, 84)
    f.draw()
    c.arc_arrow(74, 50, 46, -62, -14)


def torso_twist_right(c):
    f = base_standing(c)
    f.face = 30
    # Shoulders rotated over square hips.
    f.shoulderL = (54, 52); f.shoulderR = (86, 46)
    f.elbowL = (52, 70); f.handL = (64, 78)
    f.elbowR = (96, 60); f.handR = (92, 74)
    f.draw()
    c.arc_arrow(70, 70, 30, 150, 30)


def lower_back_child_pose(c):
    f = base_standing(c)
    # Child's pose, side view: knees folded, torso down, arms forward.
    f.hipR = (96, 108); f.kneeR = (110, 122); f.footR = (118, 122)
    f.hipL = (94, 108); f.kneeL = (108, 122); f.footL = (116, 122)
    f.shoulderR = (86, 108); f.shoulderL = (86, 110)
    f.elbowR = (60, 114); f.handR = (30, 120)
    f.elbowL = (60, 116); f.handL = (30, 122)
    f.neck = (78, 110)
    f.head = (44, 112); f.head_r = 11; f.face = 180
    c.prop_line([(14, 126), (126, 126)], 4, WALL)   # floor
    f.draw()
    c.arrow([(44, 100), (28, 106)])


# -- Legs --------------------------------------------------------------------

def hamstring_fold(c):
    f = base_standing(c)
    # Standing forward fold, side view.
    f.hipL = (74, 78); f.hipR = (76, 78)
    f.kneeL = (74, 102); f.kneeR = (76, 102)
    f.footL = (72, 126); f.footR = (80, 126)
    f.shoulderL = (72, 80); f.shoulderR = (74, 80)
    f.elbowL = (66, 98); f.handL = (70, 118)
    f.elbowR = (68, 98); f.handR = (72, 120)
    f.neck = (70, 78)
    f.head = (60, 92); f.head_r = 11; f.face = 200
    c.prop_line([(14, 126), (126, 126)], 4, WALL)
    f.draw()
    c.arrow([(52, 78), (56, 96)])


def quad_right(c):
    f = base_standing(c)
    # Standing quad stretch, side view: right heel to glute, hand holds it.
    f.face = 180
    f.head = (60, 24)
    f.hipL = (62, 88); f.hipR = (64, 88)
    f.kneeL = (60, 108); f.footL = (58, 126)
    f.kneeR = (78, 104); f.footR = (72, 86)      # bent leg, heel up
    f.shoulderL = (60, 50); f.shoulderR = (64, 50)
    f.elbowL = (58, 68); f.handL = (56, 84)
    f.elbowR = (72, 70); f.handR = (74, 86)      # hand grabs ankle
    f.draw()
    c.blob(73, 86, 4)
    c.arrow([(86, 102), (80, 88)])


def calf_right(c):
    f = base_standing(c)
    # Wall calf stretch, side view: hands on wall, back leg straight.
    f.face = 180
    f.head = (74, 26)
    f.shoulderL = (66, 50); f.shoulderR = (70, 50)
    f.elbowL = (48, 52); f.handL = (30, 52)
    f.elbowR = (48, 64); f.handR = (30, 64)
    f.hipL = (66, 88); f.hipR = (70, 88)
    f.kneeL = (52, 108); f.footL = (44, 126)     # front leg bent
    f.kneeR = (86, 112); f.footR = (98, 126)     # back leg straight
    c.prop_line([(24, 18), (24, 126)], 6, WALL)  # wall
    c.prop_line([(24, 126), (126, 126)], 4, WALL)
    f.draw()
    c.arrow([(104, 112), (100, 124)])


def hip_flexor_right(c):
    f = base_standing(c)
    # Kneeling lunge, side view.
    f.face = 180
    f.head = (66, 26)
    f.shoulderL = (64, 50); f.shoulderR = (68, 50)
    f.elbowL = (60, 66); f.handL = (58, 80)
    f.elbowR = (70, 66); f.handR = (72, 82)
    f.hipL = (66, 86); f.hipR = (68, 86)
    f.kneeL = (44, 102); f.footL = (44, 126)     # front foot planted
    f.kneeR = (94, 118); f.footR = (114, 116)    # back knee down
    c.prop_line([(14, 126), (126, 126)], 4, WALL)
    f.draw()
    c.blob(94, 118, 4)
    c.arrow([(80, 98), (70, 108)])


# ---------------------------------------------------------------------------
# Catalog: id -> (group, pose function, mirror?)
# ---------------------------------------------------------------------------

CATALOG = {
    "neck_tilt_right":         ("neck", neck_tilt_right, False),
    "neck_tilt_left":          ("neck", neck_tilt_right, True),
    "neck_tilt_down":          ("neck", neck_tilt_down, False),
    "neck_tilt_up":            ("neck", neck_tilt_up, False),
    "neck_rot_right":          ("neck", neck_rot_right, False),
    "neck_rot_left":           ("neck", neck_rot_right, True),
    "neck_rot_right_down":     ("neck", neck_rot_right_down, False),
    "neck_rot_left_down":      ("neck", neck_rot_right_down, True),
    "neck_rot_right_up":       ("neck", neck_rot_right_up, False),
    "neck_rot_left_up":        ("neck", neck_rot_right_up, True),
    "neck_chest_rot_right_up": ("neck", neck_chest_rot_right_up, False),
    "neck_chest_rot_left_up":  ("neck", neck_chest_rot_right_up, True),
    "wrist_flexor_right":      ("wrist", wrist_flexor_right, False),
    "wrist_flexor_left":       ("wrist", wrist_flexor_right, True),
    "wrist_extensor_right":    ("wrist", wrist_extensor_right, False),
    "wrist_extensor_left":     ("wrist", wrist_extensor_right, True),
    "shoulder_cross_right":    ("shoulder", shoulder_cross_right, False),
    "shoulder_cross_left":     ("shoulder", shoulder_cross_right, True),
    "triceps_right":           ("shoulder", triceps_right, False),
    "triceps_left":            ("shoulder", triceps_right, True),
    "chest_opener":            ("shoulder", chest_opener, False),
    "upper_back_reach":        ("shoulder", upper_back_reach, False),
    "side_bend_right":         ("torso", side_bend_right, False),
    "side_bend_left":          ("torso", side_bend_right, True),
    "torso_twist_right":       ("torso", torso_twist_right, False),
    "torso_twist_left":        ("torso", torso_twist_right, True),
    "lower_back_child_pose":   ("torso", lower_back_child_pose, False),
    "hamstring_fold":          ("legs", hamstring_fold, False),
    "quad_right":              ("legs", quad_right, False),
    "quad_left":               ("legs", quad_right, True),
    "calf_right":              ("legs", calf_right, False),
    "calf_left":               ("legs", calf_right, True),
    "hip_flexor_right":        ("legs", hip_flexor_right, False),
    "hip_flexor_left":         ("legs", hip_flexor_right, True),
}


# ---------------------------------------------------------------------------
# Launcher icon
# ---------------------------------------------------------------------------

def render_launcher_icon(path):
    """Garmin-style activity icon: a chunky, FILLED white silhouette in a
    forward-stretch (toe-touch) pose on a solid brand-teal disk — no gradient
    and no outline, mirroring the flat single-color figures Garmin uses for its
    own activity icons. Authored in 0..80 space and supersampled."""
    ss = 8
    edge = 80 * ss

    img = Image.new("RGBA", (edge, edge), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, edge - 1, edge - 1], fill=(0, 170, 170, 255))  # solid disk

    white = (255, 255, 255, 255)

    def limb(points, w):                       # thick filled capsule chain
        pts = [(x * ss, y * ss) for x, y in points]
        d.line(pts, fill=white, width=int(w * ss), joint="curve")
        r = int(w * ss) // 2
        for x, y in pts:
            d.ellipse([x - r, y - r, x + r, y + r], fill=white)

    limb([(34, 32), (53, 41)], 16)             # thick folded trunk
    limb([(36, 35), (32, 60)], 11)             # arms hanging toward shins
    limb([(53, 41), (49, 68)], 12)             # leg
    limb([(53, 41), (57, 68)], 12)             # leg
    hr = 9 * ss
    hx, hy = 27 * ss, 28 * ss                   # head
    d.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=white)

    img.resize((80, 80), Image.LANCZOS).save(path)


# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

def render_bucket(size, out_dir):
    stretch_dir = os.path.join(out_dir, "stretches")
    os.makedirs(stretch_dir, exist_ok=True)
    for sid, (group, fn, mirror) in CATALOG.items():
        c = Canvas()
        c.card(GROUPS[group])
        fn(c)
        c.save(os.path.join(stretch_dir, f"{sid}.png"), size, mirror=mirror)
    lines = ['<drawables>']
    for sid in CATALOG:
        lines.append(f'    <bitmap id="i_{sid}" filename="stretches/{sid}.png"/>')
    lines.append('</drawables>')
    with open(os.path.join(out_dir, "drawables.xml"), "w") as f:
        f.write("\n".join(lines) + "\n")


def write_base_drawables(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    render_launcher_icon(os.path.join(out_dir, "launcher_icon.png"))
    with open(os.path.join(out_dir, "drawables.xml"), "w") as f:
        f.write('<drawables>\n'
                '    <bitmap id="LauncherIcon" filename="launcher_icon.png"/>\n'
                '</drawables>\n')


def write_jungle_fragment(root, size_map):
    lines = []
    for device in sorted(size_map):
        size = size_map[device]
        lines.append(
            f"{device}.resourcePath = $({device}.resourcePath);assets/illus{size}")
    frag = os.path.join(root, "scripts", "resource_paths.jungle")
    with open(frag, "w") as f:
        f.write("\n".join(lines) + "\n")


def write_montage(size, out_dir, path):
    ids = list(CATALOG)
    cols = 6
    rows = (len(ids) + cols - 1) // cols
    cell = size + 26
    sheet = Image.new("RGB", (cols * cell, rows * cell), (30, 30, 30))
    d = ImageDraw.Draw(sheet)
    for i, sid in enumerate(ids):
        img = Image.open(os.path.join(out_dir, "stretches", f"{sid}.png"))
        x, y = (i % cols) * cell, (i // cols) * cell
        sheet.paste(img, (x + 13, y + 4), img)
        d.text((x + 6, y + size + 8), sid, fill=(255, 255, 255))
    sheet.save(path)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    write_base_drawables(os.path.join(root, "resources", "drawables"))
    grouped = buckets()
    for size, devices in sorted(grouped.items()):
        render_bucket(size, os.path.join(root, "assets", f"illus{size}"))
    size_map = {d: device_size(w, h) for d, (w, h) in DEVICE_RES.items()}
    write_jungle_fragment(root, size_map)
    montage = os.environ.get("MONTAGE_PATH")
    if montage:
        smallest = min(grouped)
        write_montage(smallest, os.path.join(root, "assets", f"illus{smallest}"),
                      montage)
    sizes = ", ".join(str(s) for s in sorted(grouped))
    print(f"Rendered {len(CATALOG)} illustrations x {len(grouped)} sizes "
          f"({sizes}) + launcher icon")


if __name__ == "__main__":
    main()
