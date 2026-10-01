#!/usr/bin/env python3
"""Build the website's section images from the App Store screenshot sources.

Each section gets one transparent WebP "scene": a device with a real capture, plus an enlarged
card and a duck where it fits (the same composition as the App Store screenshots). Sources live in
the app repo this site is a submodule of: docs/ASO/screenshots/source and docs/ASO/DuckPNG.

    python3 scripts/build_images.py            # from the website root, inside MyDictionary-App
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SITE = Path(__file__).resolve().parent.parent
ASO = SITE.parent / "docs" / "ASO"
SRC = ASO / "screenshots" / "source"
DUCKS = ASO / "DuckPNG"
OUT = SITE / "images" / "site"

SHADOW = (20, 37, 26)


def load(path):
    return Image.open(path).convert("RGBA")


def rounded(im, radius):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), radius, fill=255)
    out = im.copy()
    out.putalpha(Image.composite(im.getchannel("A"), mask, mask))
    return out


def phone(capture, width):
    """A capture inside the iPhone frame (frame 980 × 2000, screen 880 × 1912 at 50, 44)."""
    frame = load(SRC / "app" / "iphone-frame.png")
    screen = rounded(load(capture).resize((880, 1912), Image.LANCZOS), 110)
    body = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle((50, 44, 930, 1956), 140, fill=(0, 0, 0, 255))
    body.alpha_composite(screen, (50, 44))
    body.alpha_composite(frame)
    return body.resize((width, round(width * frame.height / frame.width)), Image.LANCZOS)


def macbook(window, width):
    """The MacBook frame with our wallpaper and a window centred on the screen."""
    frame = load(SRC / "app" / "macbook-pro-14.png")          # 3648 × 2205, screen at 373.5, 54, 2901 × 1884
    sx, sy, sw, sh = 374, 54, 2901, 1884
    canvas = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    wall = Image.new("RGBA", (sw, sh))
    px = wall.load()
    for y in range(sh):
        for x in range(0, sw, 4):
            t = (x / sw + y / sh) / 2
            c = tuple(round(a + (b - a) * t) for a, b in zip((232, 240, 216), (140, 203, 120)))
            for dx in range(4):
                if x + dx < sw:
                    px[x + dx, y] = c + (255,)
    win = load(window)
    box = win.getchannel("A").point(lambda v: 255 if v > 250 else 0).getbbox()
    scale = min(sh * 0.86 / (box[3] - box[1]), sw * 0.9 / (box[2] - box[0]))
    win = win.resize((round(win.width * scale), round(win.height * scale)), Image.LANCZOS)
    wx = (sw - (box[2] - box[0]) * scale) / 2 - box[0] * scale
    wy = (sh - (box[3] - box[1]) * scale) / 2 - box[1] * scale + sh * 0.02
    wall.alpha_composite(win, (round(wx), round(wy)))
    canvas.alpha_composite(rounded(wall, 30), (sx, sy))
    # draw the frame over the wallpaper, but keep our wallpaper where the frame's own one was
    framed = frame.copy()
    framed.paste((0, 0, 0, 0), (sx, sy, sx + sw, sy + sh))
    canvas.alpha_composite(framed)
    notch = ImageDraw.Draw(canvas)
    notch.rounded_rectangle((1647, sy - 6, 1647 + 352, sy + 58), 24, fill=(0, 0, 0, 255))
    return canvas.resize((width, round(width * frame.height / frame.width)), Image.LANCZOS)


def card(path, width, radius_ratio=0.035, outline=None):
    im = load(path)
    im = im.resize((width, round(width * im.height / im.width)), Image.LANCZOS)
    im = rounded(im, round(width * radius_ratio))
    if outline:
        ImageDraw.Draw(im).rounded_rectangle((0, 0, im.width - 1, im.height - 1), round(width * radius_ratio),
                                             outline=outline, width=max(4, width // 90))
    return im


def duck(name, width):
    im = load(DUCKS / f"{name}.png")
    return im.resize((width, round(width * im.height / im.width)), Image.LANCZOS)


def place(canvas, layer, x, y, rotate=0, shadow=0.26, blur=36, offset=24):
    if rotate:
        layer = layer.rotate(-rotate, resample=Image.BICUBIC, expand=True)
    if shadow:
        a = layer.getchannel("A").point(lambda v: round(v * shadow))
        sh = Image.new("RGBA", layer.size, SHADOW + (0,))
        sh.putalpha(a)
        pad = blur * 2
        big = Image.new("RGBA", (layer.width + pad * 2, layer.height + pad * 2), SHADOW + (0,))
        big.alpha_composite(sh, (pad, pad))
        big = big.filter(ImageFilter.GaussianBlur(blur))
        canvas.alpha_composite(big, (x - pad, y - pad + offset))
    canvas.alpha_composite(layer, (x, y))


def check_badge(size):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((0, 0, size - 1, size - 1), fill=(11, 138, 26, 255))
    w = max(6, size // 12)
    d.line([(size * .27, size * .52), (size * .43, size * .68), (size * .74, size * .34)], fill=(255, 253, 245, 255), width=w, joint="curve")
    return im


def save(canvas, name, widths=(720, 1440)):
    OUT.mkdir(parents=True, exist_ok=True)
    bbox = canvas.getchannel("A").getbbox()
    canvas = canvas.crop(bbox)
    for w in widths:
        im = canvas.resize((w, round(w * canvas.height / canvas.width)), Image.LANCZOS) if w < canvas.width else canvas
        suffix = "" if w == widths[0] else "@2x"
        im.save(OUT / f"{name}{suffix}.webp", "WEBP", quality=82, method=6)
    print(f"{name}: {canvas.size}")


def main():
    cut, mac_cut, cap = SRC / "cutouts", SRC / "cutouts-mac", SRC / "captures"

    # Hero: viajar on the phone, its word card enlarged, the reading duck
    c = Image.new("RGBA", (1600, 1500), (0, 0, 0, 0))
    place(c, phone(cap / "01-word-viajar.png", 640), 560, 40, shadow=0.3)
    place(c, card(cut / "word-card-viajar.png", 1080), 300, 860, rotate=-2.5)
    place(c, duck("my-dictionary-duck", 380), 1180, 1020, rotate=6, shadow=0.16)
    save(c, "hero")

    # Capture: the word list, its rows enlarged, the walking duck
    c = Image.new("RGBA", (1500, 1500), (0, 0, 0, 0))
    place(c, phone(cap / "02-word-list.png", 620), 120, 40)
    place(c, card(cut / "word-list-rows.png", 760, 0.04), 640, 520, rotate=2)
    place(c, duck("walking-duck", 300), 1120, 1140, shadow=0.16)
    save(c, "capture")

    # Definitions: quedar and its meaning card
    c = Image.new("RGBA", (1500, 1500), (0, 0, 0, 0))
    place(c, phone(cap / "03-word-quedar.png", 620), 760, 40)
    place(c, card(cut / "meaning-quedar.png", 1040), 60, 820, rotate=-2)
    save(c, "definitions")

    # Games: Match Pairs with a matched pair floating
    c = Image.new("RGBA", (1500, 1500), (0, 0, 0, 0))
    place(c, phone(cap / "05-match-pairs.png", 620), 140, 40)
    green = (11, 138, 26, 255)
    place(c, card(cut / "match-tile-word.png", 520, 0.08, green), 600, 700, rotate=-4)
    place(c, card(cut / "match-tile-meaning.png", 520, 0.08, green), 900, 980, rotate=4)
    place(c, check_badge(170), 1000, 830, shadow=0.3)
    place(c, duck("headphones-duck", 300), 1140, 1170, rotate=-6, shadow=0.16)
    save(c, "games")

    # Progress: the practice hub with the streak card enlarged
    c = Image.new("RGBA", (1500, 1500), (0, 0, 0, 0))
    place(c, phone(cap / "05-quizzes-hub.png", 620), 800, 40)
    place(c, card(mac_cut / "streak-card.png", 1000, 0.04), 40, 860, rotate=-2)
    save(c, "progress")

    # Mac: MacBook with the dictionary, the MCP card and the celebrating duck
    c = Image.new("RGBA", (2000, 1500), (0, 0, 0, 0))
    place(c, macbook(SRC / "mac" / "dictionary-pato.png", 1700), 260, 40, shadow=0.24)
    place(c, card(mac_cut / "mcp-card.png", 820, 0.05), 40, 820, rotate=-2)
    place(c, duck("celebrating-duck", 380), 1560, 1020, shadow=0.16)
    save(c, "mac", widths=(960, 1920))

    # Small duck for the closing call to action
    d = duck("celebrating-duck", 320)
    d.save(OUT / "duck.webp", "WEBP", quality=85, method=6)

    # Social preview (1200 × 630): hero scene on cream
    og = Image.new("RGBA", (1200, 630), (248, 243, 232, 255))
    hero = Image.open(OUT / "hero@2x.webp").convert("RGBA")
    hero = hero.resize((round(600 * hero.width / hero.height), 600), Image.LANCZOS)
    og.alpha_composite(hero, (1200 - hero.width - 20, 20))
    og.convert("RGB").save(OUT / "og.jpg", quality=88)
    print("og.jpg")


if __name__ == "__main__":
    main()
