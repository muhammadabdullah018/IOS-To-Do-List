#!/usr/bin/env python3
"""Generates Skyday's original pixel-art header scenes into the asset catalog.

Each scene is painted at ART resolution (1 px = 1 art pixel) and displayed in SwiftUI with
`.interpolation(.none)`, so edges stay razor sharp at any device scale and files stay tiny.
Everything is drawn procedurally from the brand palette; there are no third-party assets.

Scenes: SkyToday (day), SkyTodaySunset, SkyTodayNight, SkyLists, SkyProgress.
Usage: python3 Tools/make_sky_art.py [repo_root]   (requires Pillow)
"""
import json
import math
import os
import random
import sys
from PIL import Image

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
ASSETS = os.path.join(ROOT, "Skyday/Resources/Assets.xcassets")

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.img = Image.new("RGB", (w, h))
        self.px = self.img.load()

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[x, y] = c

    def get(self, x, y):
        return self.px[x, y]

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1):
            for x in range(x0, x1):
                self.set(x, y, c)


def sky(cv, stops, bands=9):
    """Banded vertical gradient with ordered dithering between bands (classic 8-bit sky)."""
    for y in range(cv.h):
        t = y / (cv.h - 1)
        # locate stop segment
        for i in range(len(stops) - 1):
            if stops[i][0] <= t <= stops[i + 1][0]:
                lt = (t - stops[i][0]) / max(1e-6, stops[i + 1][0] - stops[i][0])
                a, b = stops[i][1], stops[i + 1][1]
                break
        q = lt * bands
        lo = math.floor(q) / bands
        hi = min(1, lo + 1 / bands)
        frac = q - math.floor(q)
        for x in range(cv.w):
            use_hi = frac * 16 > BAYER[y % 4][x % 4]
            cv.set(x, y, lerp(a, b, hi if use_hi else lo))


def disc(cv, cx, cy, r, c):
    for y in range(int(cy - r) - 1, int(cy + r) + 2):
        for x in range(int(cx - r) - 1, int(cx + r) + 2):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                cv.set(x, y, c)


def cloud(cv, cx, cy, w, h, top=hexc("FFFFFF"), mid=hexc("EAF7FF"), low=hexc("C2E6F8"), seed=0, flat_bottom=True):
    """Puffy pixel cloud: union of circles, shaded top->bottom, with a flat base."""
    rnd = random.Random(seed)
    blobs = []
    n = max(3, int(w / 7))
    for i in range(n):
        bx = cx - w / 2 + (i + 0.5) * w / n + rnd.uniform(-1.5, 1.5)
        edge = 1 - abs((i + 0.5) / n - 0.5) * 2  # taller in the middle
        br = h * (0.45 + 0.55 * edge) * rnd.uniform(0.75, 1.0)
        blobs.append((bx, cy - br * 0.35, br))
    ymin = int(min(b[1] - b[2] for b in blobs)) - 1
    ymax = int(cy + h * 0.35)
    for y in range(ymin, ymax + 1):
        for x in range(int(cx - w / 2 - h), int(cx + w / 2 + h)):
            inside = any((x - bx) ** 2 + (y - by) ** 2 <= br * br for bx, by, br in blobs)
            if flat_bottom and y > cy + h * 0.25:
                inside = inside and (cx - w / 2 <= x <= cx + w / 2)
            if not inside:
                continue
            t = (y - ymin) / max(1, ymax - ymin)
            c = top if t < 0.45 else (mid if t < 0.78 else low)
            cv.set(x, y, c)


def cloud_bank(cv, base_y, seed, colors, height=14, step=18):
    rnd = random.Random(seed)
    x = -10
    while x < cv.w + 20:
        w = rnd.randint(step, step + 16)
        cloud(cv, x + w / 2, base_y - rnd.randint(0, 4), w, rnd.randint(height - 4, height + 3), *colors, seed=rnd.randint(0, 9999))
        x += w - 6
    cv.rect(0, base_y + 2, cv.w, cv.h, colors[2])


def sparkle(cv, x, y, c, big=False):
    cv.set(x, y, c)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        cv.set(x + dx, y + dy, c)
    if big:
        for dx, dy in ((2, 0), (-2, 0), (0, 2), (0, -2)):
            cv.set(x + dx, y + dy, c)


def island(cv, cx, top_y, w, seed=1):
    """Floating island: grass cap, layered earth, stepped rocky underside, a few vines."""
    rnd = random.Random(seed)
    grass_hi, grass, grass_lo = hexc("9BDB6A"), hexc("6CBF4B"), hexc("4E9A3A")
    dirt_hi, dirt, rock, rock_lo = hexc("B98A62"), hexc("94694A"), hexc("7C6A63"), hexc("5C4D49")
    half = w // 2
    depth = int(w * 0.55)
    for y in range(top_y, top_y + depth):
        t = (y - top_y) / depth
        span = int(half * (1 - t ** 1.6) + (1 if t < 0.1 else 0))
        span += rnd.randint(-1, 0) if t > 0.3 else 0
        for x in range(cx - span, cx + span + 1):
            if y < top_y + 3:
                c = grass_hi if y == top_y else (grass if y == top_y + 1 else grass_lo)
            elif y < top_y + 7:
                c = dirt_hi if (x + y) % 5 else dirt
            else:
                c = rock if (x * 3 + y) % 7 else rock_lo
                if x > cx + span - 2:
                    c = rock_lo
            cv.set(x, y, c)
    # grass tufts on the rim
    for x in range(cx - half, cx + half + 1, 3):
        if rnd.random() < 0.6:
            cv.set(x, top_y - 1, grass_hi)
    # vines
    for _ in range(4):
        vx = cx + rnd.randint(-half + 3, half - 3)
        for vy in range(top_y + 3, top_y + 3 + rnd.randint(4, 9)):
            cv.set(vx, vy, grass_lo)


def torii(cv, x, ground_y):
    red, red_dk, black = hexc("D9464E"), hexc("A3303A"), hexc("3A2430")
    h = 13
    for y in range(ground_y - h, ground_y):  # pillars
        cv.set(x, y, red); cv.set(x + 1, y, red_dk)
        cv.set(x + 9, y, red); cv.set(x + 10, y, red_dk)
    cv.rect(x - 2, ground_y - h - 2, x + 13, ground_y - h, black)  # kasagi
    cv.rect(x - 1, ground_y - h, x + 12, ground_y - h + 1, red)
    cv.rect(x, ground_y - h + 4, x + 11, ground_y - h + 5, red)  # nuki


def blossom_tree(cv, x, ground_y, seed=3):
    """Dense pixel cherry tree: shaded canopy (two lobes) on a short trunk."""
    rnd = random.Random(seed)
    trunk, trunk_dk = hexc("7A5242"), hexc("5A3A30")
    petal_hi, petal, petal_lo = hexc("FFD6EA"), hexc("F7A8CC"), hexc("E07FB0")
    for y in range(ground_y - 10, ground_y):
        cv.set(x, y, trunk); cv.set(x + 1, y, trunk_dk)
    cv.set(x - 1, ground_y - 8, trunk); cv.set(x + 2, ground_y - 9, trunk_dk)
    for cx, cy, r in ((x - 3, ground_y - 14, 6.5), (x + 4, ground_y - 15, 6.0), (x + 1, ground_y - 19, 5.0)):
        for py in range(int(cy - r) - 1, int(cy + r) + 2):
            for px in range(int(cx - r) - 1, int(cx + r) + 2):
                d = math.hypot(px - cx, (py - cy) * 1.15)
                if d <= r - (rnd.random() < 0.25):
                    shade = petal_hi if py < cy - r * 0.3 else (petal if py < cy + r * 0.4 else petal_lo)
                    if rnd.random() < 0.08:
                        shade = petal_hi
                    cv.set(px, py, shade)


def petals(cv, seed, n, area):
    rnd = random.Random(seed)
    x0, y0, x1, y1 = area
    for _ in range(n):
        x, y = rnd.randint(x0, x1), rnd.randint(y0, y1)
        c = hexc("F7A8CC") if rnd.random() < 0.6 else hexc("FFD6EA")
        cv.set(x, y, c)
        if rnd.random() < 0.4:
            cv.set(x + 1, y, c)


def mountains(cv, base_y, seed, far=hexc("8DB9E3"), near=hexc("6A9FD6"), snow=hexc("FFFFFF")):
    rnd = random.Random(seed)
    for layer, color, peaks, amp in ((0, far, 3, 34), (1, near, 4, 24)):
        heights = [0] * cv.w
        for p in range(peaks):
            px = rnd.randint(0, cv.w)
            ph = amp * rnd.uniform(0.7, 1.0)
            slope = rnd.uniform(0.75, 1.1)
            for x in range(cv.w):
                heights[x] = max(heights[x], ph - abs(x - px) * slope)
        for x in range(cv.w):
            hgt = int(heights[x])
            if hgt <= 0:
                continue
            top = base_y - hgt - (8 if layer == 0 else 0)
            for y in range(top, base_y + 1):
                c = color
                if y - top < (5 if layer == 0 else 3) and hgt > amp * 0.55:
                    c = snow if (x + y) % 3 else lerp(snow, color, 0.3)
                cv.set(x, y, c)


def stars(cv, seed, n, area, colors=(hexc("FFFFFF"), hexc("CFE8FF"))):
    rnd = random.Random(seed)
    x0, y0, x1, y1 = area
    for i in range(n):
        x, y = rnd.randint(x0, x1), rnd.randint(y0, y1)
        if i % 9 == 0:
            sparkle(cv, x, y, colors[0])
        else:
            cv.set(x, y, colors[i % 2])


def save(cv, name):
    folder = os.path.join(ASSETS, f"{name}.imageset")
    os.makedirs(folder, exist_ok=True)
    cv.img.save(os.path.join(folder, f"{name}.png"), optimize=True)
    with open(os.path.join(folder, "Contents.json"), "w") as f:
        json.dump({
            "images": [{"filename": f"{name}.png", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1},
            # Pixel art: keep it as authored; SwiftUI draws it with .interpolation(.none).
            "properties": {"preserves-vector-representation": False, "template-rendering-intent": "original"},
        }, f, indent=2)


W = 220  # art pixels wide (~2pt per art pixel on a 393pt-wide phone, cropped on narrower ones)

# --- Today (day): brand-blue sky, pink sun, floating island with torii + blossom tree ---
cv = Canvas(W, 160)
sky(cv, [(0, hexc("0593C6")), (0.55, hexc("39AEE0")), (1, hexc("D7F2FF"))])
disc(cv, 196, 30, 9, hexc("FF9CCB")); disc(cv, 196, 30, 7, hexc("FFB3D6"))
cloud(cv, 186, 44, 30, 11, seed=11)
cloud(cv, 56, 110, 40, 13, seed=12)
cloud(cv, 140, 116, 30, 10, seed=13)
island(cv, 176, 84, 60, seed=4)
torii(cv, 158, 84)
blossom_tree(cv, 188, 84, seed=5)
petals(cv, 6, 22, (135, 60, 215, 120))
cloud_bank(cv, 138, 21, (hexc("FFFFFF"), hexc("EEF9FF"), hexc("D7F2FF")))
sparkle(cv, 120, 22, hexc("FFFFFF"), big=True); sparkle(cv, 205, 64, hexc("FFFFFF")); sparkle(cv, 98, 58, hexc("FFE6F4"))
save(cv, "SkyToday")

# --- Today (sunset) ---
cv = Canvas(W, 160)
sky(cv, [(0, hexc("4A63C8")), (0.45, hexc("C77AC4")), (0.8, hexc("FF9EB8")), (1, hexc("FFD3B0"))])
disc(cv, 92, 112, 16, hexc("FFC3A0")); disc(cv, 92, 112, 13, hexc("FFE0B8"))
for y in range(112, 126, 3):  # sun bands
    cv.rect(72, y, 112, y + 1, hexc("FF9EB8"))
cloud(cv, 50, 104, 38, 11, hexc("FFE6F4"), hexc("F4B6D8"), hexc("D98AC0"), seed=31)
cloud(cv, 196, 52, 30, 9, hexc("FFE6F4"), hexc("F4B6D8"), hexc("D98AC0"), seed=32)
island(cv, 176, 88, 60, seed=4)
torii(cv, 158, 88)
blossom_tree(cv, 188, 88, seed=5)
cloud_bank(cv, 140, 33, (hexc("FFE6F4"), hexc("F6C2DD"), hexc("E7A6CF")))
sparkle(cv, 112, 26, hexc("FFE6F4"), big=True)
save(cv, "SkyTodaySunset")

# --- Today (night) ---
cv = Canvas(W, 160)
sky(cv, [(0, hexc("0B1E4A")), (0.7, hexc("1F3F86")), (1, hexc("3B63A8"))])
stars(cv, 41, 60, (0, 0, W - 1, 110))
disc(cv, 186, 32, 9, hexc("FFF4C8")); disc(cv, 190, 29, 8, hexc("0B1E4A"))  # crescent
cloud(cv, 60, 110, 40, 12, hexc("C9D6F2"), hexc("8FA6D8"), hexc("5F7DBD"), seed=42)
island(cv, 176, 86, 60, seed=4)
torii(cv, 158, 86)
blossom_tree(cv, 188, 86, seed=5)
cloud_bank(cv, 140, 43, (hexc("8FA6D8"), hexc("6F8BC9"), hexc("4E6DB0")))
save(cv, "SkyTodayNight")

# --- Lists: calm clouds only ---
cv = Canvas(W, 120)
sky(cv, [(0, hexc("0593C6")), (0.6, hexc("4DB6E6")), (1, hexc("D7F2FF"))])
cloud(cv, 172, 74, 40, 13, seed=51)
cloud(cv, 120, 92, 26, 8, seed=52)
cloud_bank(cv, 102, 53, (hexc("FFFFFF"), hexc("EEF9FF"), hexc("D7F2FF")), height=12)
sparkle(cv, 200, 20, hexc("FFFFFF"), big=True); sparkle(cv, 118, 30, hexc("FFE6F4"))
save(cv, "SkyLists")

# --- Progress: mountains, floating island for the streak badge, clouds ---
cv = Canvas(W, 170)
sky(cv, [(0, hexc("0593C6")), (0.6, hexc("4DB6E6")), (1, hexc("D7F2FF"))])
cloud(cv, 34, 96, 30, 10, seed=61)
cloud(cv, 200, 102, 28, 9, seed=62)
mountains(cv, 120, 63)
cloud(cv, 30, 112, 40, 10, seed=64)
cloud(cv, 196, 116, 36, 10, seed=65)
island(cv, 110, 128, 74, seed=7)
petals(cv, 8, 10, (60, 100, 160, 126))
cloud_bank(cv, 152, 66, (hexc("FFFFFF"), hexc("EEF9FF"), hexc("D7F2FF")), height=12)
sparkle(cv, 80, 18, hexc("FFFFFF"), big=True); sparkle(cv, 152, 30, hexc("FFE6F4"))
save(cv, "SkyProgress")

print("wrote SkyToday, SkyTodaySunset, SkyTodayNight, SkyLists, SkyProgress")
