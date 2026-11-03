#!/usr/bin/env python3
"""Approximate preview of the v2 Today screen, drawn with Pillow from the same tokens,
sprite grids, sizes and copy the SwiftUI code uses (Skyday/DesignSystem, TodayView).

It is NOT an iOS screenshot: fonts are DejaVu (not SF Pro Rounded), there is no real text
layout engine, and sample tasks are illustrative. Use it to judge composition and colour.
Usage: python3 Tools/render_today_preview.py [repo_root]   -> docs/today-preview.png
"""
import re
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
S = 3  # render scale (points -> pixels)
W, H = 393, 852

art = open(f"{ROOT}/Skyday/DesignSystem/PixelArt.swift").read()
sprites = {n: re.findall(r'"([^"]*)"', b) for n, b in re.findall(r"static let (\w+) = PixelSpriteData\(rows: \[(.*?)\]\)", art, re.S)}

C = {
    "canvas": (11, 22, 32), "raised": (22, 37, 47), "raisedHigh": (31, 49, 61),
    "onCanvas": (252, 255, 255), "onCanvas2": (157, 180, 195),
    "sky": (5, 147, 198), "pink": (216, 57, 149), "cardInk": (11, 27, 38), "cardInk2": (52, 80, 95),
    "skyPastel": (205, 239, 252), "pinkPastel": (249, 215, 234), "cloudPastel": (234, 248, 253),
    "steelPastel": (206, 219, 232), "deepPink": (184, 40, 124),
}

img = Image.new("RGB", (W * S, H * S), C["canvas"])
d = ImageDraw.Draw(img)


def font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    try:
        return ImageFont.truetype(name, int(size * S))
    except OSError:
        return ImageFont.load_default()


def rr(x, y, w, h, r, fill, outline=None, width=1):
    d.rounded_rectangle([x * S, y * S, (x + w) * S, (y + h) * S], radius=r * S, fill=fill,
                        outline=outline, width=int(width * S))


def text(x, y, s, size, fill, bold=False, anchor="la"):
    d.text((x * S, y * S), s, fill=fill, font=font(size, bold), anchor=anchor)


def circle(cx, cy, r, fill, outline=None, width=1):
    d.ellipse([(cx - r) * S, (cy - r) * S, (cx + r) * S, (cy + r) * S], fill=fill, outline=outline, width=int(width * S))


def sprite(name, x, y, px, palette):
    for ry, row in enumerate(sprites[name]):
        for rx, ch in enumerate(row):
            if ch in palette:
                d.rectangle([(x + rx * px) * S, (y + ry * px) * S, (x + (rx + 1) * px) * S - 1, (y + (ry + 1) * px) * S - 1], fill=palette[ch])


def check(cx, cy, size, fill):
    pts = [(cx - size * 0.45, cy), (cx - size * 0.1, cy + size * 0.35), (cx + size * 0.5, cy - size * 0.35)]
    d.line([(p[0] * S, p[1] * S) for p in pts], fill=fill, width=int(2.6 * S), joint="curve")


# Status bar
text(36, 18, "9:41", 16, C["onCanvas"], bold=True)
text(357, 18, "100%", 13, C["onCanvas"], bold=True, anchor="ra")

# Hero card
hx, hy, hw, hh = 16, 56, 361, 270
rr(hx, hy, hw, hh, 34, C["sky"])
white = (255, 255, 255)
strip_right = hx + hw - 20 - 46 - 8          # mirrors HeroCard: padding lg + avatar + xs
sprite("cloudSmall", strip_right - 42, hy + 22 + 6, 3, {"W": (232, 246, 252), "S": (130, 200, 228)})
sprite("twinkle", strip_right - 74 - 6, hy + 22, 2, {"T": white})
text(hx + 20, hy + 22, "TUESDAY, NOV 3", 12, C["cardInk"], bold=True)
text(hx + 20, hy + 41, "Good morning,", 14, C["cardInk"], bold=True)
text(hx + 20, hy + 59, "Abdullah", 14, C["cardInk"], bold=True)  # wraps: text stays left of the cloud strip
circle(hx + hw - 20 - 23, hy + 20 + 23, 23, C["cardInk"], outline=(255, 255, 255), width=2)
text(hx + hw - 20 - 23, hy + 43, "A", 19, C["skyPastel"], bold=True, anchor="mm")
text(hx + 20, hy + 96, "You have 3 tasks", 26, C["cardInk"], bold=True)
text(hx + 20, hy + 128, "left today", 26, C["cardInk"], bold=True)
bx, by, bw = hx + 20, hy + 176, hw - 40
rr(bx, by, bw, 10, 5, (26, 113, 150))
rr(bx, by, bw * 0.4, 10, 5, C["cardInk"])
text(hx + 20, hy + 210, "Next: Finish portfolio case study", 14, C["cardInk"], bold=True)
text(hx + 20, hy + 229, "4:00 PM · 1 carried over", 14, C["cardInk"], bold=True)
circle(hx + hw - 20 - 23, hy + 222, 23, C["cardInk"])
rr(hx + hw - 20 - 33, hy + 214, 20, 17, 3, None, outline=C["onCanvas"], width=2)

# Status pills
py = hy + hh + 16
pw = (361 - 16) / 3
pills = [("4", "This week", C["skyPastel"], "cal"), ("7d", "Day streak", C["pinkPastel"], "star"), ("2", "Done today", C["cloudPastel"], "check")]
for i, (val, cap, tint, icon) in enumerate(pills):
    x = 16 + i * (pw + 8)
    rr(x, py, pw, 52, 26, C["raised"], outline=(40, 56, 66))
    circle(x + 26, py + 26, 20, tint)
    if icon == "star":
        sprite("streakStar", x + 26 - 10.5, py + 26 - 10.5, 3, {"P": C["pink"]})
    elif icon == "check":
        check(x + 26, py + 26, 14, C["cardInk"])
    else:
        rr(x + 18, py + 19, 16, 14, 3, None, outline=C["cardInk"], width=2)
    text(x + 52, py + 9, val, 16, C["onCanvas"], bold=True)
    text(x + 52, py + 30, cap, 11, C["onCanvas2"])

# Section header
sy = py + 52 + 22
text(16, sy, "Today tasks", 21, C["onCanvas"], bold=True)
text(377, sy + 5, "See all", 14, (76, 195, 238), bold=True, anchor="ra")

# Task cards
cards = [
    (C["pinkPastel"], "Overdue · Yesterday", True, "Submit lab report draft", "Upload to the course portal", "University", 3, None),
    (C["skyPastel"], "Today · 4:00 PM", False, "Finish portfolio case study", "Export final screenshots", "Work", 2, (2, 4)),
    (C["steelPastel"], "Today · 8:00 PM", False, "Review SwiftUI notes", None, "Personal", 0, None),
]
cy = sy + 40
for fill, status, overdue, title, notes, list_name, prio, subs in cards:
    ch = 170 if notes else 148
    if subs:
        ch += 20
    if cy > H - 20:
        break
    rr(16, cy, 361, ch, 28, fill)
    x0, y0 = 36, cy + 20
    sw = len(status) * 6.6 + 34
    if overdue:
        rr(x0, y0, sw, 26, 13, C["deepPink"])
        text(x0 + 12, y0 + 6, "! " + status, 11, white, bold=True)
    else:
        rr(x0, y0, sw, 26, 13, None, outline=(80, 100, 112), width=1)
        text(x0 + 12, y0 + 6, status, 11, C["cardInk"], bold=True)
    for lv in range(1, 4):
        col = (C["pink"] if prio == 3 else C["cardInk"]) if lv <= prio else (190, 205, 212)
        d.rectangle([(353 - (3 - lv) * 6 - 4) * S, (y0 + 18 - (4 + lv * 3)) * S, (353 - (3 - lv) * 6) * S, (y0 + 18) * S], fill=col)
    text(x0, y0 + 40, title, 18, C["cardInk"], bold=True)
    ty = y0 + 68
    if notes:
        text(x0, ty, notes, 13, C["cardInk2"])
        ty += 24
    if subs:
        rr(x0, ty + 4, 220, 6, 3, (180, 205, 215))
        rr(x0, ty + 4, 220 * subs[0] / subs[1], 6, 3, C["cardInk"])
        text(x0 + 230, ty - 2, f"{subs[0]}/{subs[1]}", 12, C["cardInk"], bold=True)
        ty += 22
    lw = len(list_name) * 7 + 34
    rr(x0, ty, lw, 26, 13, None, outline=(80, 100, 112), width=1)
    text(x0 + 12, ty + 6, list_name, 11, C["cardInk"], bold=True)
    circle(377 - 16 - 26, cy + ch - 16 - 26, 26, C["cardInk"])
    check(377 - 16 - 26, cy + ch - 16 - 26, 16, (230, 240, 245))
    cy += ch + 12

# Floating tab bar (over content, like the real safe-area inset with scrolling content)
fy = H - 34 - 62
d.rectangle([0, (fy - 14) * S, W * S, H * S], fill=C["canvas"])
rr(16, fy, 361 - 62 - 12, 62, 31, C["raisedHigh"], outline=(45, 62, 74))
rr(22, fy + 6, 112, 50, 25, C["sky"])
text(78, fy + 31, "☀  Today", 15, C["cardInk"], bold=True, anchor="mm")
for i, glyph in enumerate(["▤", "▮▮"]):
    text(170 + i * 60, fy + 31, glyph, 17, C["onCanvas2"], bold=True, anchor="mm")
circle(377 - 31, fy + 31, 31, C["pink"])
text(377 - 31, fy + 29, "+", 34, white, bold=True, anchor="mm")
rr(130, H - 12, 133, 5, 2.5, (230, 235, 240))

img = img.resize((W * 2, H * 2), Image.LANCZOS)
img.save(f"{ROOT}/docs/today-preview.png")
print("wrote docs/today-preview.png")
