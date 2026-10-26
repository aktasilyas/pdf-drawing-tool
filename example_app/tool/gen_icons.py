"""Generates the launcher icon source art: one ink-blue pen stroke on warm paper."""
import math
from PIL import Image, ImageDraw

S = 1024
INK = (0x2B, 0x4C, 0x7E, 255)
PAPER = (0xF4, 0xF1, 0xEA, 255)


def centerline():
    """One continuous gesture: the bar of a lowercase "e", then the loop round and out."""
    pts = []
    n = 60
    for i in range(n + 1):  # bar, rising slightly to the right
        t = i / n
        pts.append((-0.92 + 1.9 * t, 0.16 - 0.24 * t))
    m = 160
    for i in range(1, m + 1):  # counter-clockwise loop: over the top, down the left, round the bottom
        a = math.radians(-5 - 325 * (i / m))
        r = 1.0 - 0.06 * (i / m)
        pts.append((r * math.cos(a), 0.95 * r * math.sin(a)))
    return pts


def pressure(t):
    """Thin entry, fuller body, tapered exit (same shape the ink engine's pressure curve gives)."""
    if t < 0.2:
        return 0.35 + 0.65 * math.sin(t / 0.2 * math.pi / 2)
    if t > 0.7:
        return 0.2 + 0.8 * math.cos((t - 0.7) / 0.3 * math.pi / 2) ** 1.5
    return 1.0


def stroke(color, width=104):
    """Pressure-tapered "e" stroke inside the adaptive-icon safe zone (centre 66%)."""
    k = 2
    img = Image.new("RGBA", (S * k, S * k), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = centerline()
    # Resample densely so the stamped discs read as a smooth variable-width outline.
    dense = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        for j in range(8):
            f = j / 8
            dense.append((x0 + (x1 - x0) * f, y0 + (y1 - y0) * f))
    scale = 0.29 * S * k
    for i, (x, y) in enumerate(dense):
        w = width * k * pressure(i / len(dense)) / 2
        cx, cy = S * k / 2 + x * scale, S * k / 2 + y * scale
        d.ellipse((cx - w, cy - w, cx + w, cy + w), fill=color)
    return img.resize((S, S), Image.LANCZOS)


out = "assets/images/"
fg = stroke(INK)
fg.save(out + "elyanotes_icon_foreground.png")
stroke((0, 0, 0, 255)).save(out + "elyanotes_icon_monochrome.png")
full = Image.new("RGBA", (S, S), PAPER)
full.alpha_composite(fg)
full.save(out + "elyanotes_app_icon.png")
fg.save(out + "elyanotes_splash.png")

for px in (48, 72, 96):  # launcher-size previews (1dp = 1px at mdpi)
    full.resize((px, px), Image.LANCZOS).save(out + f"elyanotes_app_icon_{px}.png")
