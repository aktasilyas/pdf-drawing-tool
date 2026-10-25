"""Generates the launcher icon source art: one ink-blue pen stroke on warm paper."""
import math
from PIL import Image, ImageDraw

S = 1024
INK = (0x2B, 0x4C, 0x7E, 255)
PAPER = (0xF4, 0xF1, 0xEA, 255)


def stroke(color, scale=1.0, width=96):
    """Draws an S-shaped stroke inside the adaptive-icon safe zone (centre 66%)."""
    img = Image.new("RGBA", (S * 2, S * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = []
    for i in range(121):
        t = i / 120
        x = (0.5 + 0.20 * math.sin(t * math.pi * 2 + 0.6) * scale + (t - 0.5) * 0.26 * scale) * S * 2
        y = (0.5 + (t - 0.5) * 0.52 * scale) * S * 2
        pts.append((x, y))
    w = width * 2
    for (x, y) in pts:
        d.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=color)
    d.line(pts, fill=color, width=w, joint="curve")
    return img.resize((S, S), Image.LANCZOS)


out = "assets/images/"
fg = stroke(INK)
fg.save(out + "elyanotes_icon_foreground.png")
stroke((0, 0, 0, 255)).save(out + "elyanotes_icon_monochrome.png")
full = Image.new("RGBA", (S, S), PAPER)
full.alpha_composite(fg)
full.save(out + "elyanotes_app_icon.png")
fg.save(out + "elyanotes_splash.png")
