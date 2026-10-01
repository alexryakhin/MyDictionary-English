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
    k = width / frame.width
    to_image = lambda x, y: ((50 + x * 880 / 1320) * k, (44 + y * 1912 / 2868) * k)
    return body.resize((width, round(width * frame.height / frame.width)), Image.LANCZOS), to_image


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
    k = width / frame.width
    to_image = lambda x, y: ((sx + round(wx) + x * scale) * k, (sy + round(wy) + y * scale) * k)
    return canvas.resize((width, round(width * frame.height / frame.width)), Image.LANCZOS), to_image


def window(path, width):
    """A Mac window capture (transparent, with its shadow) scaled so the window itself is `width` wide."""
    win = load(path)
    box = win.getchannel("A").point(lambda v: 255 if v > 250 else 0).getbbox()
    f = width / (box[2] - box[0])
    to_image = lambda x, y: (x * f, y * f)
    return win.resize((round(win.width * f), round(win.height * f)), Image.LANCZOS), to_image


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


def pop(canvas, layer, center, rotate=0, shadow=0.26):
    """Place an enlarged card centred on the spot it was cut from."""
    w, h = layer.size
    if rotate:
        a = math.radians(abs(rotate))
        w, h = w * math.cos(a) + h * math.sin(a), w * math.sin(a) + h * math.cos(a)
    place(canvas, layer, round(center[0] - w / 2), round(center[1] - h / 2), rotate=rotate, shadow=shadow)


def at(origin, to_image, box):
    """Centre of a source box (capture pixels) in canvas pixels, for a device placed at origin."""
    x, y = to_image((box[0] + box[2]) / 2, (box[1] + box[3]) / 2)
    return origin[0] + x, origin[1] + y


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


# Where each card was cut from, in its capture's pixels (iPhone boxes match
# docs/ASO/screenshots/make_cutouts.py; Mac boxes are the cutouts in source/cutouts-mac).
BOX = {
    "word-card-viajar": (52, 974, 1268, 1508),
    "word-list-rows": (62, 772, 1258, 1672),
    "meaning-quedar": (52, 1106, 1268, 1590),
    "match-tile-word": (62, 1926, 644, 2188),
    "match-tile-meaning": (62, 1316, 644, 1574),
    "streak-card": (240, 283, 1899, 1031),
    "mcp-card": (584, 212, 1415, 690),
}


def main():
    cut, mac_cut, cap = SRC / "cutouts", SRC / "cutouts-mac", SRC / "captures"
    green = (11, 138, 26, 255)

    # Hero: viajar on the phone, its word card popping out, the reading duck
    c = Image.new("RGBA", (1500, 1500), (0, 0, 0, 0))
    ph, m = phone(cap / "01-word-viajar.png", 640); o = (430, 40)
    place(c, ph, *o, shadow=0.3)
    pop(c, card(cut / "word-card-viajar.png", 1060), at(o, m, BOX["word-card-viajar"]), rotate=-2.5)
    place(c, duck("my-dictionary-duck", 340), 1120, 900, rotate=6, shadow=0.16)
    save(c, "hero")

    # Capture: the word list with its rows popping out, the walking duck
    c = Image.new("RGBA", (1500, 1500), (0, 0, 0, 0))
    ph, m = phone(cap / "02-word-list.png", 640); o = (430, 40)
    place(c, ph, *o)
    pop(c, card(cut / "word-list-rows.png", 900, 0.04), at(o, m, BOX["word-list-rows"]), rotate=2)
    place(c, duck("walking-duck", 280), 1160, 1080, shadow=0.16)
    save(c, "capture")

    # Definitions: quedar and its first meaning popping out
    c = Image.new("RGBA", (1500, 1500), (0, 0, 0, 0))
    ph, m = phone(cap / "03-word-quedar.png", 640); o = (430, 40)
    place(c, ph, *o)
    pop(c, card(cut / "meaning-quedar.png", 1060), at(o, m, BOX["meaning-quedar"]), rotate=-2)
    save(c, "definitions")

    # Games: Match Pairs, the matched word and meaning popping out of their tiles
    c = Image.new("RGBA", (1500, 1500), (0, 0, 0, 0))
    ph, m = phone(cap / "05-match-pairs.png", 640); o = (500, 40)
    place(c, ph, *o)
    meaning = at(o, m, BOX["match-tile-meaning"])
    word = at(o, m, BOX["match-tile-word"])
    pop(c, card(cut / "match-tile-meaning.png", 470, 0.08, green), meaning, rotate=-3)
    pop(c, card(cut / "match-tile-word.png", 470, 0.08, green), word, rotate=3)
    place(c, check_badge(150), round(meaning[0] + 160), round((meaning[1] + word[1]) / 2 - 75), shadow=0.3)
    place(c, duck("headphones-duck", 280), 1170, 1150, rotate=-6, shadow=0.16)
    save(c, "games")

    # Progress: the Mac Progress window with its streak card popping out
    c = Image.new("RGBA", (1500, 1500), (0, 0, 0, 0))
    win, m = window(SRC / "mac" / "progress.png", 760); o = (400, 0)
    place(c, win, *o, shadow=0)
    pop(c, card(mac_cut / "streak-card.png", 1180, 0.04), at(o, m, BOX["streak-card"]), rotate=-2)
    save(c, "progress")

    # Mac: MacBook with the MCP Server settings, its card popping out, the celebrating duck
    c = Image.new("RGBA", (2000, 1500), (0, 0, 0, 0))
    mb, m = macbook(SRC / "mac" / "mcp.png", 1700); o = (150, 40)
    place(c, mb, *o, shadow=0.24)
    pop(c, card(mac_cut / "mcp-card.png", 900, 0.05), at(o, m, BOX["mcp-card"]), rotate=-2)
    place(c, duck("celebrating-duck", 380), 1580, 1020, shadow=0.16)
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
