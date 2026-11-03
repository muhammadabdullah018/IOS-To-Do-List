#!/usr/bin/env python3
"""Renders docs/design-system-sheet.png from the real Swift sources:
sprite grids parsed from Skyday/DesignSystem/PixelArt.swift and light-mode colour tokens
parsed from Skyday/DesignSystem/Theme.swift, with WCAG contrast ratios against #FCFFFF.
This is a token/sprite sheet, not a screenshot of the app."""
import re, sys
from PIL import Image, ImageDraw, ImageFont

root = sys.argv[1] if len(sys.argv) > 1 else "."
art = open(f"{root}/Skyday/DesignSystem/PixelArt.swift").read()
theme = open(f"{root}/Skyday/DesignSystem/Theme.swift").read()

sprites = {}
for name, body in re.findall(r"static let (\w+) = PixelSpriteData\(rows: \[(.*?)\]\)", art, re.S):
    sprites[name] = re.findall(r'"([^"]*)"', body)
for name, body in re.findall(r"case \.(\w+): return PixelSpriteData\(rows: \[(.*?)\]\)", art, re.S):
    sprites["badge." + name] = re.findall(r'"([^"]*)"', body)

palette = {"W": (255, 255, 255), "S": (198, 232, 246), "T": (127, 203, 232), "B": (5, 147, 198),
           "D": (4, 121, 165), "P": (216, 57, 149), "Y": (230, 169, 46)}

tokens = []
for name, hexv in re.findall(r"static let (\w+) = Color\(hex: 0x([0-9A-Fa-f]{6})\)", theme):
    tokens.append((name, hexv))
for name, hexv in re.findall(r"static let (\w+) = Color\.dynamic\(light: 0x([0-9A-Fa-f]{6})", theme):
    tokens.append((name, hexv))

def lum(h):
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    c = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]

def contrast(a, b="FCFFFF"):
    la, lb = sorted([lum(a), lum(b)], reverse=True)
    return (la + 0.05) / (lb + 0.05)

W, H = 1400, 880
img = Image.new("RGB", (W, H), (252, 255, 255))
d = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype("DejaVuSans.ttf", 18)
    big = ImageFont.truetype("DejaVuSans-Bold.ttf", 28)
except OSError:
    font = big = ImageFont.load_default()
ink = (18, 54, 74)
d.text((40, 28), "Skyday design system (rendered from Swift source)", fill=ink, font=big)

# Sprites on a sky swatch so white clouds are visible.
x, y, rowh = 40, 90, 0
for name, rows in sprites.items():
    px = 6
    w = max(len(r) for r in rows) * px
    h = len(rows) * px
    if x + w + 40 > W:
        x, y = 40, y + rowh + 50
        rowh = 0
    d.rectangle([x - 10, y - 10, x + w + 10, y + h + 10], fill=(221, 245, 254))
    for ry, r in enumerate(rows):
        for rx, ch in enumerate(r):
            if ch in palette:
                d.rectangle([x + rx * px, y + ry * px, x + (rx + 1) * px - 1, y + (ry + 1) * px - 1], fill=palette[ch])
    d.text((x - 10, y + h + 14), name, fill=ink, font=font)
    x += max(w, 120) + 50
    rowh = max(rowh, h)

# Tokens with contrast vs page white.
y = y + rowh + 80
d.text((40, y), "Colour tokens (light) - contrast vs #FCFFFF; AA small text needs 4.5:1", fill=ink, font=font)
y += 36
x = 40
for i, (name, hexv) in enumerate(tokens):
    if x + 300 > W:
        x, y = 40, y + 70
    rgb = tuple(int(hexv[j:j + 2], 16) for j in (0, 2, 4))
    d.rectangle([x, y, x + 52, y + 52], fill=rgb, outline=(221, 236, 244))
    ratio = contrast(hexv)
    verdict = "AA text" if ratio >= 4.5 else ("large/UI" if ratio >= 3 else "decor only")
    d.text((x + 62, y + 2), f"{name}  #{hexv.upper()}", fill=ink, font=font)
    d.text((x + 62, y + 26), f"{ratio:.2f}:1  {verdict}", fill=(85, 115, 133), font=font)
    x += 330
img.save(f"{root}/docs/design-system-sheet.png")
print(f"{len(sprites)} sprites, {len(tokens)} tokens")
