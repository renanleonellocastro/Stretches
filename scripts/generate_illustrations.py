#!/usr/bin/env python3
"""Generate the stretch illustration PNGs and the drawables resource XML.

Every stretch in the catalog gets a clean, high-contrast line drawing
rendered as a stick figure on a white rounded card. Drawings are rendered
at 4x and downscaled for crisp anti-aliased strokes on MIP displays
(e.g. Forerunner 55, 208x208, 64 colors).

Usage:
    python3 scripts/generate_illustrations.py

Outputs:
    resources/drawables/stretches/<id>.png   (one per stretch, 140x140)
    resources/drawables/launcher_icon.png    (app launcher icon)
    resources/drawables/drawables.xml        (resource declarations)
"""

import math
import os

from PIL import Image, ImageDraw, ImageOps

# ---------------------------------------------------------------------------
# Rendering constants
# ---------------------------------------------------------------------------

SCALE = 4               # supersampling factor
OUT = 140               # final image edge in pixels
S = OUT * SCALE         # working canvas edge (560)

INK = (10, 10, 10, 255)             # figure strokes
ARROW = (255, 0, 0, 255)            # motion arrows (pure red, MIP-safe)
CARD = (255, 255, 255, 255)         # card background
BODY_W = 16                         # stroke width for body parts (canvas px)
HEAD_R = 40                         # head radius (canvas px)

# Muscle-group accent colors. All channels are multiples of 0x55 so the
# colors survive quantization to the 64-color Garmin MIP palette.
GROUPS = {
    "neck": (0, 170, 255, 255),      # #00AAFF
    "wrist": (255, 170, 0, 255),     # #FFAA00
    "shoulder": (170, 85, 255, 255), # #AA55FF
    "torso": (0, 170, 85, 255),      # #00AA55
    "legs": (255, 85, 0, 255),       # #FF5500
}


class Canvas:
    """Small helper wrapping the PIL drawing primitives we need."""

    def __init__(self):
        self.img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.img)

    def card(self, border_color):
        radius = 26 * SCALE
        self.draw.rounded_rectangle(
            [3 * SCALE, 3 * SCALE, S - 3 * SCALE, S - 3 * SCALE],
            radius=radius, fill=CARD, outline=border_color, width=4 * SCALE,
        )

    def line(self, points, width=BODY_W, color=INK):
        pts = [(x * SCALE, y * SCALE) for x, y in points]
        self.draw.line(pts, fill=color, width=width * SCALE // 4, joint="curve")
        for p in pts:  # round caps
            r = width * SCALE // 8
            self.draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=color)

    def head(self, cx, cy, r=HEAD_R // 4, nose=None, color=INK):
        """Draw the head outline. `nose` is an angle in degrees (0 = right,
        90 = down) adding a small nose bump to show which way the face points."""
        x, y, rr = cx * SCALE, cy * SCALE, r * SCALE
        w = BODY_W * SCALE // 4
        self.draw.ellipse([x - rr, y - rr, x + rr, y + rr], outline=color, width=w)
        if nose is not None:
            a = math.radians(nose)
            n1 = (x + rr * math.cos(a - 0.34), y + rr * math.sin(a - 0.34))
            n2 = (x + rr * math.cos(a + 0.34), y + rr * math.sin(a + 0.34))
            tip = (x + rr * 1.5 * math.cos(a), y + rr * 1.5 * math.sin(a))
            self.draw.polygon([n1, tip, n2], fill=color)

    def dot(self, x, y, r=4, color=INK):
        x, y, r = x * SCALE, y * SCALE, r * SCALE
        self.draw.ellipse([x - r, y - r, x + r, y + r], fill=color)

    def arrow(self, points, color=ARROW, width=9):
        """Poly-line arrow whose head sits on the last point."""
        self.line(points, width=width, color=color)
        (x1, y1), (x2, y2) = points[-2], points[-1]
        ang = math.atan2(y2 - y1, x2 - x1)
        size = 7
        for side in (-1, 1):
            a = ang + math.pi + side * 0.5
            end = (x2 + size * math.cos(a), y2 + size * math.sin(a))
            self.line([(x2, y2), end], width=width, color=color)

    def arc_arrow(self, cx, cy, r, start_deg, end_deg, color=ARROW, width=9):
        """Curved arrow along a circle arc, head at end_deg."""
        steps = 14
        pts = []
        for i in range(steps + 1):
            a = math.radians(start_deg + (end_deg - start_deg) * i / steps)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
        self.arrow(pts, color=color, width=width)

    def floor(self, y=126):
        self.line([(14, y), (126, y)], width=8, color=(120, 120, 120, 255))

    def save(self, path, mirror=False):
        img = self.img
        if mirror:
            img = ImageOps.mirror(img)
        img = img.resize((OUT, OUT), Image.LANCZOS)
        img.save(path)


# ---------------------------------------------------------------------------
# Figure helpers (all coordinates are in final-image units, 0..140)
# ---------------------------------------------------------------------------

def front_body(c, arms="down", legs=True):
    """Standing figure seen from the front, head drawn separately."""
    c.line([(70, 50), (70, 92)])                      # spine
    c.line([(48, 56), (92, 56)])                      # shoulders
    if legs:
        c.line([(58, 92), (82, 92)])                  # hips
        c.line([(58, 92), (56, 126)])                 # left leg
        c.line([(82, 92), (84, 126)])                 # right leg
    if arms == "down":
        c.line([(48, 56), (44, 88)])
        c.line([(92, 56), (96, 88)])


def front_head(c, dx=0, dy=0, nose=None):
    front_body_head_y = 34
    c.head(70 + dx, front_body_head_y + dy, nose=nose)


# ---------------------------------------------------------------------------
# Pose functions — one per stretch (right-side variants; left = mirrored)
# ---------------------------------------------------------------------------

def neck_tilt_right(c):
    front_body(c)
    front_head(c, dx=12, dy=5)
    c.arc_arrow(70, 60, 36, -84, -30)


def neck_tilt_down(c):
    front_body(c)
    front_head(c, dy=7, nose=None)
    c.arrow([(104, 20), (104, 36)])


def neck_tilt_up(c):
    front_body(c)
    front_head(c, dy=-5)
    c.arrow([(104, 40), (104, 22)])


def neck_rot_right(c):
    front_body(c)
    front_head(c, nose=0)          # facing viewer-right
    c.arc_arrow(70, 34, 22, -60, 5)


def neck_rot_right_down(c):
    front_body(c)
    front_head(c, dy=5, nose=35)   # rotated right and looking down
    c.arrow([(102, 22), (108, 40)])


def neck_rot_right_up(c):
    front_body(c)
    front_head(c, dy=-3, nose=-35)  # rotated right and looking up
    c.arrow([(102, 42), (108, 22)])


def neck_chest_rot_right_up(c):
    front_body(c, arms="none")
    front_head(c, dy=-3, nose=-35)
    c.line([(48, 56), (44, 88)])                 # left arm down
    c.line([(92, 56), (78, 66), (70, 60)])       # right hand pinned on chest
    c.dot(70, 60, r=3)
    c.arrow([(60, 66), (60, 80)])                # pulling chest down
    c.arrow([(100, 40), (106, 22)])              # head up and rotated


def wrist_flexor_right(c):
    """Side view: arm extended, palm forward, fingers up, pulled back."""
    c.line([(34, 52), (34, 96)])                     # torso
    c.head(34, 36, nose=0)
    c.line([(34, 96), (28, 126)])                    # back leg
    c.line([(34, 96), (44, 126)])                    # front leg
    c.line([(34, 58), (100, 58)])                    # extended arm
    c.line([(100, 58), (100, 40)])                   # fingers up (palm out)
    c.line([(34, 70), (74, 68), (98, 44)], width=12) # other arm pulls fingers
    c.dot(99, 43, r=3)
    c.arrow([(114, 52), (106, 44)])


def wrist_extensor_right(c):
    """Side view: arm extended, back of hand forward, fingers down."""
    c.line([(34, 52), (34, 96)])
    c.head(34, 36, nose=0)
    c.line([(34, 96), (28, 126)])
    c.line([(34, 96), (44, 126)])
    c.line([(34, 58), (100, 58)])
    c.line([(100, 58), (100, 76)])                   # fingers down
    c.line([(34, 70), (74, 84), (99, 74)], width=12) # other arm pulls fingers
    c.dot(100, 74, r=3)
    c.arrow([(114, 66), (106, 72)])


def shoulder_cross_right(c):
    """Right arm straight across the chest, hooked by the left arm."""
    front_body(c, arms="none")
    front_head(c)
    c.line([(92, 56), (42, 64)])                     # right arm across chest
    c.line([(48, 56), (62, 76), (68, 62)], width=12) # left arm hooks it
    c.arrow([(94, 78), (70, 84)])


def triceps_right(c):
    """Right arm overhead, bent behind the head; left hand pulls the elbow."""
    front_body(c, arms="none")
    front_head(c)
    c.line([(48, 56), (44, 88)])                     # left arm down
    c.line([(92, 56), (94, 22), (72, 16)])           # right arm bent overhead
    c.dot(94, 22, r=4)                               # elbow being pulled
    c.arrow([(108, 32), (96, 24)])


def chest_opener(c):
    """Side view, hands clasped behind the back, chest opening up."""
    c.line([(62, 52), (62, 96)])
    c.head(62, 36, nose=180)
    c.line([(62, 96), (56, 126)])
    c.line([(62, 96), (70, 126)])
    c.line([(62, 58), (92, 84), (98, 92)])           # near arm behind, clasped
    c.line([(62, 62), (90, 88)])                     # far arm behind
    c.dot(98, 92, r=4)
    c.arrow([(40, 60), (30, 48)])                    # chest lifts up/forward


def upper_back_reach(c):
    """Side view, arms clasped forward, upper back rounded."""
    c.line([(60, 96), (60, 70), (54, 56)])           # rounded spine
    c.head(48, 42, nose=0)
    c.line([(60, 96), (54, 126)])
    c.line([(60, 96), (68, 126)])
    c.line([(56, 60), (108, 70)])                    # arms reaching forward
    c.dot(108, 70, r=4)
    c.arrow([(108, 84), (122, 86)])


def side_bend_right(c):
    """Trunk leaning to the right, opposite arm arcing overhead."""
    c.line([(70, 92), (78, 54)])                     # tilted spine
    c.line([(58, 92), (82, 92)])
    c.line([(58, 92), (56, 126)])
    c.line([(82, 92), (84, 126)])
    c.line([(58, 60), (96, 50)])                     # shoulder line tilted
    c.head(84, 36)
    c.line([(96, 50), (98, 82)])                     # right arm down the side
    c.line([(58, 60), (56, 28), (90, 18)])           # left arm arcs overhead
    c.arc_arrow(70, 50, 46, -64, -14)


def torso_twist_right(c):
    """Shoulders rotated right over square hips, arrow wrapping the waist."""
    front_head(c, nose=0)
    c.line([(70, 50), (70, 92)])
    c.line([(52, 60), (88, 52)])                     # rotated shoulder line
    c.line([(52, 60), (44, 84)])                     # arm forward
    c.line([(88, 52), (100, 74)])                    # arm back
    c.line([(58, 92), (82, 92)])
    c.line([(58, 92), (56, 126)])
    c.line([(82, 92), (84, 126)])
    c.arc_arrow(70, 78, 30, 150, 30)


def lower_back_child_pose(c):
    """Child's pose on the floor, side view."""
    c.floor()
    c.line([(94, 124), (112, 124)])                  # shin along the floor
    c.line([(94, 124), (90, 104)])                   # thigh, hips over heels
    c.line([(90, 104), (58, 114)])                   # folded torso
    c.head(48, 117, r=8)
    c.line([(58, 114), (24, 122)])                   # arms stretched forward
    c.arrow([(40, 100), (24, 108)])


def hamstring_fold(c):
    """Standing forward fold, side view."""
    c.floor()
    c.line([(78, 126), (78, 78)])                    # straight legs
    c.line([(78, 78), (52, 100)])                    # folded torso
    c.head(48, 110, r=8)
    c.line([(62, 92), (68, 122)])                    # arms reaching the feet
    c.arrow([(34, 84), (38, 102)])


def quad_right(c):
    """Standing quad stretch: heel pulled to the glute, side view."""
    c.floor()
    c.line([(62, 52), (62, 92)])
    c.head(62, 36, nose=180)
    c.line([(62, 92), (60, 126)])                    # standing leg
    c.line([(62, 92), (70, 112), (78, 90)])          # bent leg, heel to glute
    c.line([(62, 58), (80, 88)], width=12)           # arm holding the ankle
    c.dot(78, 90, r=4)
    c.arrow([(92, 106), (86, 92)])


def calf_right(c):
    """Wall calf stretch: hands on the wall, back leg straight, side view."""
    c.floor()
    c.line([(24, 20), (24, 126)], width=10, color=(120, 120, 120, 255))  # wall
    c.line([(74, 52), (58, 96)])                     # leaning torso
    c.head(78, 38, nose=180)
    c.line([(70, 60), (28, 52)])                     # arms to the wall
    c.line([(70, 70), (28, 66)])
    c.line([(58, 96), (44, 126)])                    # front leg bent
    c.line([(58, 96), (94, 126)])                    # back leg straight
    c.arrow([(104, 110), (98, 122)])


def hip_flexor_right(c):
    """Kneeling lunge, side view: right leg forward, left knee down."""
    c.floor()
    c.line([(64, 44), (64, 84)])                     # upright torso
    c.head(64, 30, nose=180)
    c.line([(64, 50), (56, 76)])                     # arms relaxed
    c.line([(64, 84), (40, 100), (40, 126)])         # front leg bent 90
    c.line([(64, 84), (96, 122), (118, 118)])        # back leg, knee down
    c.dot(96, 122, r=4)
    c.arrow([(80, 94), (68, 104)])


# ---------------------------------------------------------------------------
# Catalog: id -> (group, pose function, mirror?)
# ---------------------------------------------------------------------------

def mirrored(fn):
    return (fn, True)


CATALOG = {
    # --- Neck ---
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
    # --- Wrist / forearm ---
    "wrist_flexor_right":      ("wrist", wrist_flexor_right, False),
    "wrist_flexor_left":       ("wrist", wrist_flexor_right, True),
    "wrist_extensor_right":    ("wrist", wrist_extensor_right, False),
    "wrist_extensor_left":     ("wrist", wrist_extensor_right, True),
    # --- Shoulder / chest / upper back ---
    "shoulder_cross_right":    ("shoulder", shoulder_cross_right, False),
    "shoulder_cross_left":     ("shoulder", shoulder_cross_right, True),
    "triceps_right":           ("shoulder", triceps_right, False),
    "triceps_left":            ("shoulder", triceps_right, True),
    "chest_opener":            ("shoulder", chest_opener, False),
    "upper_back_reach":        ("shoulder", upper_back_reach, False),
    # --- Torso / back ---
    "side_bend_right":         ("torso", side_bend_right, False),
    "side_bend_left":          ("torso", side_bend_right, True),
    "torso_twist_right":       ("torso", torso_twist_right, False),
    "torso_twist_left":        ("torso", torso_twist_right, True),
    "lower_back_child_pose":   ("torso", lower_back_child_pose, False),
    # --- Legs ---
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
    """White side-bend figure on a bright accent disk."""
    c = Canvas()
    c.draw.ellipse([0, 0, S - 1, S - 1], fill=(0, 170, 255, 255))
    white = (255, 255, 255, 255)
    c.line([(64, 92), (72, 54)], width=18, color=white)   # tilted spine
    c.line([(52, 92), (76, 92)], width=18, color=white)   # hips
    c.line([(52, 92), (50, 122)], width=18, color=white)  # legs
    c.line([(76, 92), (80, 122)], width=18, color=white)
    c.line([(54, 58), (90, 48)], width=18, color=white)   # shoulders
    c.line([(90, 48), (94, 78)], width=18, color=white)   # arm down
    c.line([(54, 58), (52, 28), (86, 18)], width=18, color=white)  # arm overhead
    c.head(80, 34, color=white)
    c.img = c.img.resize((80, 80), Image.LANCZOS)
    c.img.save(path)


# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

def render_all(out_dir):
    stretch_dir = os.path.join(out_dir, "stretches")
    os.makedirs(stretch_dir, exist_ok=True)
    for sid, (group, fn, mirror) in CATALOG.items():
        c = Canvas()
        c.card(GROUPS[group])
        fn(c)
        c.save(os.path.join(stretch_dir, f"{sid}.png"), mirror=mirror)
    render_launcher_icon(os.path.join(out_dir, "launcher_icon.png"))


def write_drawables_xml(out_dir):
    lines = ['<drawables>']
    lines.append('    <bitmap id="LauncherIcon" filename="launcher_icon.png"/>')
    for sid in CATALOG:
        lines.append(f'    <bitmap id="i_{sid}" filename="stretches/{sid}.png"/>')
    lines.append('</drawables>')
    with open(os.path.join(out_dir, "drawables.xml"), "w") as f:
        f.write("\n".join(lines) + "\n")


def write_montage(out_dir, path):
    """Contact sheet used to review all illustrations at once (not shipped)."""
    ids = list(CATALOG)
    cols = 6
    rows = (len(ids) + cols - 1) // cols
    cell = OUT + 26
    sheet = Image.new("RGB", (cols * cell, rows * cell), (30, 30, 30))
    d = ImageDraw.Draw(sheet)
    for i, sid in enumerate(ids):
        img = Image.open(os.path.join(out_dir, "stretches", f"{sid}.png"))
        x, y = (i % cols) * cell, (i // cols) * cell
        sheet.paste(img, (x + 13, y + 4), img)
        d.text((x + 6, y + OUT + 8), sid, fill=(255, 255, 255))
    sheet.save(path)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_dir = os.path.join(root, "resources", "drawables")
    os.makedirs(out_dir, exist_ok=True)
    render_all(out_dir)
    write_drawables_xml(out_dir)
    montage = os.environ.get("MONTAGE_PATH")
    if montage:
        write_montage(out_dir, montage)
    print(f"Rendered {len(CATALOG)} illustrations + launcher icon -> {out_dir}")


if __name__ == "__main__":
    main()
