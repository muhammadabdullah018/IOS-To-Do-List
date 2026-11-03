#!/usr/bin/env python3
# Usage: python3 Tools/make_app_icon.py Skyday/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png  (requires Pillow)
"""Generates Skyday's original app icon: a stepped pixel cloud with a check on brand sky blue.
Drawn on a 32x32 art grid, scaled with nearest-neighbour to 1024 px (32 px per art pixel)."""
import sys
from PIL import Image

SKY = (5, 147, 198)        # #0593C6 brand
DEEP = (4, 121, 165)       # derived deep sky (horizon bands)
WHITE = (252, 255, 255)    # #FCFFFF brand
SHADE = (198, 232, 246)    # cloud underside
PINK = (216, 57, 149)      # #D83995 brand
TWINKLE = (159, 224, 248)

grid = [
"................................",
"................................",
"................................",
"....T...................T.......",
"...TTT.................TTT......",
"....T...................T.......",
"................................",
"............WWWWWW..............",
"..........WWWWWWWWWW............",
".........WWWWWWWWWWWW...........",
"......WWWWWWWWWWWWWWWW.WWW......",
".....WWWWWWWWWWWWWWWWWWWWWWW....",
"....WWWWWWWWWWWWWWWWWWWWPPWWW...",
"...WWWWWWWWWWWWWWWWWWWWPPPWWWW..",
"...WWWWWWWWWWWWWWWWWWWPPPWWWWW..",
"...WWWWWWPPWWWWWWWWWWPPPWWWWWW..",
"...WWWWWWPPPWWWWWWWWPPPWWWWWWW..",
"...WWWWWWWPPPWWWWWWPPPWWWWWWWW..",
"...WWWWWWWWPPPWWWWPPPWWWWWWWWW..",
"....WWWWWWWWPPPWWPPPWWWWWWWWW...",
".....WWWWWWWWPPPPPPWWWWWWWWW....",
"......WWWWWWWWPPPPWWWWWWWWW.....",
".......SSSSSSSSSSSSSSSSSSS......",
".........SSSSSSSSSSSSSSS........",
"................................",
"................................",
"................................",
"DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD",
"DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD",
"DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD",
"DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD",
"DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD",
]
colors = {".": SKY, "W": WHITE, "S": SHADE, "P": PINK, "D": DEEP, "T": TWINKLE}
assert all(len(r) == 32 for r in grid) and len(grid) == 32
img = Image.new("RGB", (32, 32))
for y, row in enumerate(grid):
    for x, c in enumerate(row):
        img.putpixel((x, y), colors[c])
img.resize((1024, 1024), Image.NEAREST).save(sys.argv[1], "PNG")
