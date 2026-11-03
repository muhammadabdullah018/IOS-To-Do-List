#!/usr/bin/env python3
"""Approximate preview of Today, Lists and Progress (docs/screens-preview.png).

Composites the REAL header art from the asset catalog (scaled like SwiftUI scaledToFill,
nearest-neighbour) with the same tokens, sizes and copy as the SwiftUI views. It is not an
iOS screenshot: fonts are DejaVu instead of SF Pro Rounded, icons are simple stand-ins for
SF Symbols, and the tasks are sample data.
Usage: python3 Tools/render_screens_preview.py [repo_root]
"""
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
A = f"{ROOT}/Skyday/Resources/Assets.xcassets"
S = 3
W, H = 393, 852
TOP = 59  # status bar / Dynamic Island safe area

C = dict(sky=(5, 147, 198), deep=(4, 121, 165), pink=(216, 57, 149), pinkText=(184, 40, 124), lightSky=(215, 242, 255),
         softPink=(255, 230, 244), ink=(18, 54, 74), ink2=(85, 115, 133), page=(242, 250, 254), white=(255, 255, 255),
         border=(221, 236, 244), flame=(242, 145, 61), star=(245, 185, 50), partial=(158, 216, 242))


def font(size, bold=False):
    try:
        return ImageFont.truetype("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf", int(size * S))
    except OSError:
        return ImageFont.load_default()


class Screen:
    def __init__(self):
        self.img = Image.new("RGB", (W * S, H * S), C["page"])
        self.d = ImageDraw.Draw(self.img, "RGBA")

    def rr(self, x, y, w, h, r, fill, outline=None, width=1):
        self.d.rounded_rectangle([x * S, y * S, (x + w) * S, (y + h) * S], radius=r * S, fill=fill, outline=outline, width=int(width * S))

    def text(self, x, y, s, size, fill, bold=False, anchor="la", shadow=False):
        if shadow:
            self.d.text((x * S, (y + 1) * S), s, fill=(3, 80, 111, 110), font=font(size, bold), anchor=anchor)
        self.d.text((x * S, y * S), s, fill=fill, font=font(size, bold), anchor=anchor)

    def circle(self, cx, cy, r, fill=None, outline=None, width=1):
        self.d.ellipse([(cx - r) * S, (cy - r) * S, (cx + r) * S, (cy + r) * S], fill=fill, outline=outline, width=int(width * S))

    def card(self, x, y, w, h, r=16, fill=None):
        self.rr(x, y + 3, w, h, r, (5, 147, 198, 22))
        self.rr(x, y, w, h, r, fill or C["white"])

    def header(self, name, height):
        art = Image.open(f"{A}/{name}.imageset/{name}.png").convert("RGB")
        total = height + TOP
        scale = max(W / art.width, total / art.height)
        aw, ah = round(art.width * scale * S), round(art.height * scale * S)
        big = art.resize((aw, ah), Image.NEAREST)
        left = (aw - W * S) // 2
        self.img.paste(big.crop((left, 0, left + W * S, total * S)), (0, 0))
        for i in range(36):  # fade into the page, like SkyHeader's gradient
            a = int(255 * (i / 35))
            self.d.rectangle([0, (total - 36 + i) * S, W * S, (total - 35 + i) * S], fill=C["page"] + (a,))
        self.text(36, 18, "9:41", 16, C["white"], bold=True)
        return total

    def check(self, cx, cy, size, fill, width=2.4):
        pts = [(cx - size * 0.45, cy), (cx - size * 0.1, cy + size * 0.35), (cx + size * 0.5, cy - size * 0.35)]
        self.d.line([(p[0] * S, p[1] * S) for p in pts], fill=fill, width=int(width * S), joint="curve")

    def checkbox(self, x, y, on):
        if on:
            self.rr(x, y, 24, 24, 7, C["sky"])
            self.check(x + 12, y + 12, 12, C["white"])
        else:
            self.rr(x, y, 24, 24, 7, C["white"], outline=(5, 147, 198, 190), width=2)

    def tabbar(self, selected):
        y = H - 83
        self.d.rectangle([0, y * S, W * S, H * S], fill=(250, 252, 253))
        self.d.line([0, y * S, W * S, y * S], fill=C["border"], width=S)
        for i, label in enumerate(["Today", "Lists", "Progress"]):
            cx = W / 6 + i * W / 3
            col = C["sky"] if i == selected else (140, 150, 158)
            if i == 0:
                self.d.polygon([((cx - 11) * S, (y + 21) * S), (cx * S, (y + 11) * S), ((cx + 11) * S, (y + 21) * S)], outline=col, width=int(2 * S))
                self.d.rectangle([(cx - 8) * S, (y + 21) * S, (cx + 8) * S, (y + 31) * S], outline=col, width=int(2 * S))
            elif i == 1:
                for k in range(3):
                    self.rr(cx - 10, y + 12 + k * 6, 20, 5, 2, None, outline=col, width=1.6)
            else:
                for k, hgt in enumerate((8, 14, 20)):
                    self.d.rectangle([(cx - 9 + k * 7) * S, (y + 32 - hgt) * S, (cx - 4 + k * 7) * S, (y + 32) * S], outline=col, width=int(1.6 * S))
            self.text(cx, y + 40, label, 10, col, bold=i == selected, anchor="mm")
        self.rr(130, H - 12, 133, 5, 2.5, (20, 20, 20))


def today():
    s = Screen()
    h = s.header("SkyToday", 236)
    s.text(20, TOP + 8, "TUESDAY, NOV 3", 12, C["white"], bold=True, shadow=True)
    s.text(20, TOP + 28, "Good Afternoon,", 26, C["white"], bold=True, shadow=True)
    s.text(20, TOP + 60, "Abdullah", 26, C["white"], bold=True, shadow=True)
    s.circle(172, TOP + 74, 10, C["star"])
    s.circle(351, TOP + 30, 22, (255, 255, 255, 242))
    s.rr(341, TOP + 22, 20, 17, 3, None, outline=C["deep"], width=2)
    by = TOP + 8 + (236 - 8 - 44) - 44
    s.rr(20, by, 152, 40, 20, C["softPink"], outline=C["white"], width=1.5)
    s.circle(42, by + 20, 7, C["flame"])
    s.text(56, by + 11, "12 Day Streak", 14, C["ink"], bold=True)
    y = h - 30
    s.card(16, y, 361, 88, 22)
    s.circle(60, y + 44, 25, None, outline=C["lightSky"], width=6)
    s.d.arc([35 * S, (y + 19) * S, 85 * S, (y + 69) * S], start=-90, end=-90 + 240, fill=C["sky"], width=6 * S)
    s.text(60, y + 44, "67%", 12, C["ink"], bold=True, anchor="mm")
    s.text(100, y + 26, "4 of 6 Tasks", 17, C["ink"], bold=True)
    s.text(100, y + 50, "completed today", 13, C["ink2"])
    s.circle(347, y + 44, 15, C["lightSky"])
    s.text(347, y + 44, "›", 18, C["deep"], bold=True, anchor="mm")
    y += 88 + 24
    s.text(16, y, "Today", 22, C["ink"], bold=True)
    s.rr(337, y - 4, 36, 36, 10, C["sky"])
    s.text(355, y + 14, "+", 24, C["white"], bold=True, anchor="mm")
    y += 44
    rows = [("Finish IR assignment", "Due Today", True, False, "flag"),
            ("Gym – Push Day", "6:00 PM · Repeats", False, False, "chev"),
            ("Read 20 pages", "Due Today", True, False, "chev"),
            ("Update Sazaan deck", "Done 9:12 AM", False, True, None)]
    for title, sub, urgent, done, trail in rows:
        s.card(16, y, 361, 58, 16)
        s.checkbox(30, y + 17, done)
        s.text(66, y + 12, title, 15, C["ink2"] if done else C["ink"], bold=True)
        if done:
            tw = s.d.textlength(title, font=font(15, True)) / S
            s.d.line([66 * S, (y + 21) * S, (66 + tw) * S, (y + 21) * S], fill=C["ink2"], width=int(1.4 * S))
        s.text(66, y + 33, sub, 11, C["pinkText"] if urgent else C["ink2"], bold=urgent)
        if trail == "flag":
            s.d.polygon([(353 * S, (y + 21) * S), (366 * S, (y + 25) * S), (353 * S, (y + 29) * S)], fill=C["pink"])
            s.d.line([353 * S, (y + 20) * S, 353 * S, (y + 38) * S], fill=C["pink"], width=int(2 * S))
        elif trail == "chev":
            s.text(358, y + 29, "›", 16, (150, 170, 182), bold=True, anchor="mm")
        y += 66
    s.tabbar(0)
    return s.img


def lists():
    s = Screen()
    h = s.header("SkyLists", 150)
    s.text(20, TOP + 8, "Lists", 32, C["white"], bold=True, shadow=True)
    s.text(20, TOP + 50, "5 lists · 22 open tasks", 14, C["white"], bold=True, shadow=True)
    s.circle(351, TOP + 30, 22, (255, 255, 255, 242))
    s.text(351, TOP + 29, "+", 24, C["deep"], bold=True, anchor="mm")
    y = h - 24
    s.card(16, y, 361, 52, 16)
    s.circle(40, y + 24, 7, None, outline=C["ink2"], width=2)
    s.text(56, y + 17, "Search tasks and lists", 14, C["ink2"])
    y += 52 + 16
    items = [("University", "8 tasks", (79, 127, 174), C["lightSky"]), ("Work", "5 tasks", (58, 169, 201), (214, 239, 246)),
             ("Personal", "3 tasks", C["pink"], C["softPink"]), ("Fitness", "4 tasks", (42, 157, 143), (214, 238, 235)),
             ("Reading", "2 tasks", (217, 150, 43), (249, 236, 214))]
    for name, count, col, tint in items:
        grad = Image.new("RGB", (361 * S, 64 * S))
        gd = ImageDraw.Draw(grad)
        for x in range(361 * S):
            t = x / (361 * S)
            gd.line([(x, 0), (x, 64 * S)], fill=tuple(round(255 + (tint[i] - 255) * t) for i in range(3)))
        mask = Image.new("L", grad.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, grad.width - 1, grad.height - 1], radius=16 * S, fill=255)
        s.rr(16, y + 3, 361, 64, 16, (5, 147, 198, 22))
        s.img.paste(grad, (16 * S, int(y * S)), mask)
        s.rr(30, y + 18, 28, 28, 8, col)
        s.text(74, y + 14, name, 16, C["ink"], bold=True)
        s.text(74, y + 37, count, 12, C["ink2"])
        s.text(358, y + 32, "›", 20, C["ink2"], bold=True, anchor="mm")
        y += 64 + 12
    s.rr(16, y + 4, 361, 52, 16, C["lightSky"])
    s.text(196, y + 30, "+  Create a list", 15, C["deep"], bold=True, anchor="mm")
    s.tabbar(1)
    return s.img


def progress():
    s = Screen()
    h = s.header("SkyProgress", 262)
    s.text(20, TOP + 8, "Progress", 32, C["white"], bold=True, shadow=True)
    s.circle(351, TOP + 30, 22, (255, 255, 255, 242))
    s.circle(351, TOP + 30, 8, None, outline=C["deep"], width=3)
    bw, bh = 196, 110
    bx, byy = (W - bw) / 2, TOP + 262 - 8 - 76 - bh
    s.rr(bx, byy + 5, bw, bh, 26, (3, 80, 111, 40))
    s.rr(bx, byy, bw, bh, 26, C["white"])
    s.circle(bx + 62, byy + 36, 15, C["flame"])
    s.text(bx + 84, byy + 12, "12", 40, C["ink"], bold=True)
    s.text(bw / 2 + bx, byy + 70, "Day Streak", 14, C["ink"], bold=True, anchor="mm")
    s.text(bw / 2 + bx, byy + 92, "Next: 14 days · Best 15", 10.5, C["ink2"], anchor="mm")
    y = h - 26
    stats = [("36", "Tasks Done", C["sky"]), ("78%", "This Week", C["sky"]), ("3", "Milestones", C["star"])]
    cw = (361 - 24) / 3
    for i, (v, cap, col) in enumerate(stats):
        x = 16 + i * (cw + 12)
        s.card(x, y, cw, 118, 16)
        s.rr(x + cw / 2 - 13, y + 16, 26, 26, 6, col)
        s.text(x + cw / 2, y + 66, v, 22, C["ink"], bold=True, anchor="mm")
        s.text(x + cw / 2, y + 94, cap, 11, C["ink2"], anchor="mm")
    y += 118 + 24
    s.text(16, y, "Weekly Activity", 20, C["ink"], bold=True)
    y += 36
    s.card(16, y, 361, 200, 22)
    vals = [3, 5, 2, 6, 4, 3, 1]
    days = ["M", "T", "W", "T", "F", "S", "S"]
    for i, v in enumerate(vals):
        x = 40 + i * 47
        hh = 18 * v
        col = C["pink"] if i == 3 else (C["sky"] if v >= 3 else C["partial"])
        s.rr(x, y + 150 - hh, 28, hh, 10, col)
        s.text(x + 14, y + 172, days[i], 11, C["pink"] if i == 3 else C["ink2"], bold=i == 3, anchor="mm")
    s.d.line([32 * S, (y + 150 - 54) * S, 362 * S, (y + 150 - 54) * S], fill=(85, 115, 133, 90), width=int(1.5 * S))
    s.tabbar(2)
    return s.img


screens = [today(), lists(), progress()]
gap = 40 * S
out = Image.new("RGB", (W * S * 3 + gap * 4, H * S + gap * 2), (14, 110, 160))
for i, im in enumerate(screens):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.width - 1, im.height - 1], radius=48 * S, fill=255)
    out.paste(im, (gap + i * (W * S + gap), gap), mask)
out = out.resize((out.width * 2 // S, out.height * 2 // S), Image.LANCZOS)
out.save(f"{ROOT}/docs/screens-preview.png")
print("wrote docs/screens-preview.png")
