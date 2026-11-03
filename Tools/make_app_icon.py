#!/usr/bin/env python3
# Usage: python3 Tools/make_app_icon.py Skyday/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png  (requires Pillow)
"""Skyday app icon: pixel cloud in front of a pink pixel sun, sparkles, on Sky Blue.
Painted on a 32x32 art grid, scaled nearest-neighbour to 1024 px. Original artwork."""
import math
import sys
from PIL import Image

N = 32
SKY_TOP, SKY_BOTTOM = (5, 147, 198), (70, 182, 232)
SUN, SUN_HI = (255, 143, 196), (255, 179, 214)
WHITE, CLOUD_MID, CLOUD_LOW = (252, 255, 255), (232, 246, 255), (194, 230, 248)
SPARK = (252, 255, 255)

img = Image.new("RGB", (N, N))
px = img.load()
for y in range(N):
    t = y / (N - 1)
    band = round(t * 4) / 4  # four stepped bands
    c = tuple(round(SKY_TOP[i] + (SKY_BOTTOM[i] - SKY_TOP[i]) * band) for i in range(3))
    for x in range(N):
        px[x, y] = c

def disc(cx, cy, r, col):
    for y in range(N):
        for x in range(N):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                px[x, y] = col

disc(19.5, 11.5, 7.2, SUN)
disc(18.5, 10.5, 4.6, SUN_HI)

# Cloud: union of circles with a flat base, shaded top -> bottom.
blobs = [(9.5, 19.5, 4.6), (15.5, 16.5, 6.0), (21.5, 18.5, 4.8), (26, 21, 3.4), (6, 22, 3.2)]
for y in range(N):
    for x in range(N):
        inside = any((x + 0.5 - bx) ** 2 + (y + 0.5 - by) ** 2 <= r * r for bx, by, r in blobs)
        if inside and y <= 21 and 3 <= x <= 28:
            px[x, y] = WHITE if y < 18 else (CLOUD_MID if y < 22 else CLOUD_LOW)

# Solid flat base with stepped rounded ends.
for y in range(19, 25):
    inset = {19: 0, 20: 0, 21: 0, 22: 0, 23: 1, 24: 2}[y]
    for x in range(4 + inset, 28 - inset):
        px[x, y] = WHITE if y < 18 else (CLOUD_MID if y < 22 else CLOUD_LOW)

for sx, sy in ((6, 7), (26, 4), (28, 13)):
    for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
        px[sx + dx, sy + dy] = SPARK

img.resize((1024, 1024), Image.NEAREST).save(sys.argv[1], "PNG")
