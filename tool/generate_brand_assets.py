from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BLUE = (0, 90, 171)
WHITE = (255, 255, 255)

TITLE_TEXT = "TOP-KARTA"
SUBTITLE_TEXT = "Навигатор кампуса"


def _font_dir_windows() -> Path:
    return Path(os.environ.get("WINDIR", r"C:\Windows")) / "Fonts"


def load_title_font(size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        _font_dir_windows() / "segoeuib.ttf",
        _font_dir_windows() / "calibrib.ttf",
        _font_dir_windows() / "arialbd.ttf",
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
        Path("/System/Library/Fonts/Supplemental/Arial Bold.ttf"),
    ]
    for path in candidates:
        if path.is_file():
            try:
                return ImageFont.truetype(str(path), size)
            except OSError:
                continue
    return ImageFont.load_default()


def load_subtitle_font(size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        _font_dir_windows() / "seguisb.ttf",
        _font_dir_windows() / "segoeui.ttf",
        _font_dir_windows() / "calibri.ttf",
        _font_dir_windows() / "arial.ttf",
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
        Path("/System/Library/Fonts/Supplemental/Arial.ttf"),
    ]
    for path in candidates:
        if path.is_file():
            try:
                return ImageFont.truetype(str(path), size)
            except OSError:
                continue
    return ImageFont.load_default()


def draw_arrow_mask(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = size // 2
    tip_y = int(size * 0.14)
    wing_y = int(size * 0.52)
    tail_top_y = int(size * 0.48)
    tail_bot_y = int(size * 0.86)
    half_w_top = int(size * 0.38)
    half_w_mid = int(size * 0.16)
    pts = [
        (cx, tip_y),
        (cx + half_w_top, wing_y),
        (cx + half_w_mid, tail_top_y),
        (cx + half_w_mid, tail_bot_y),
        (cx - half_w_mid, tail_bot_y),
        (cx - half_w_mid, tail_top_y),
        (cx - half_w_top, wing_y),
    ]
    draw.polygon(pts, fill=BLUE + (255,))
    return img


def composite_on_white(arrow: Image.Image) -> Image.Image:
    base = Image.new("RGB", arrow.size, WHITE)
    base.paste(arrow, mask=arrow.split()[3])
    return base


def make_app_icon(out: Path, size: int = 1024) -> None:
    arrow = draw_arrow_mask(size)
    composite_on_white(arrow).save(out, format="PNG", optimize=True)


def make_foreground(out: Path, size: int = 1024) -> None:
    draw_arrow_mask(size).save(out, format="PNG", optimize=True)


def make_splash_native_centered(out: Path, w: int = 1152, h: int = 900) -> None:
    img = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    aw = int(min(w, h) * 0.42)
    arrow = draw_arrow_mask(aw)
    ax = (w - aw) // 2
    ay = int(h * 0.12)
    img.paste(arrow, (ax, ay), arrow)
    title = TITLE_TEXT
    subtitle = SUBTITLE_TEXT
    title_font = load_title_font(int(w * 0.072))
    sub_font = load_subtitle_font(int(w * 0.042))
    tb = draw.textbbox((0, 0), title, font=title_font)
    tw, th = tb[2] - tb[0], tb[3] - tb[1]
    sb = draw.textbbox((0, 0), subtitle, font=sub_font)
    sw = sb[2] - sb[0]
    ty = ay + aw + int(h * 0.06)
    draw.text((w // 2 - tw // 2, ty), title, fill=BLUE + (255,), font=title_font)
    sy = ty + th + int(h * 0.03)
    draw.text((w // 2 - sw // 2, sy), subtitle, fill=(60, 60, 60, 255), font=sub_font)
    img.save(out, format="PNG", optimize=True)


def make_splash(out: Path, w: int = 1152, h: int = 2436) -> None:
    img = Image.new("RGB", (w, h), WHITE)
    draw = ImageDraw.Draw(img)
    aw = min(w, h) // 3
    arrow = draw_arrow_mask(aw)
    ax = (w - aw) // 2
    ay = int(h * 0.32)
    img.paste(arrow, (ax, ay), arrow)
    title = TITLE_TEXT
    subtitle = SUBTITLE_TEXT
    title_font = load_title_font(int(w * 0.065))
    sub_font = load_subtitle_font(int(w * 0.038))
    tw, th = draw.textbbox((0, 0), title, font=title_font)[2:]
    sw, _ = draw.textbbox((0, 0), subtitle, font=sub_font)[2:]
    ty = ay + aw + int(h * 0.04)
    draw.text((w // 2 - tw // 2, ty), title, fill=BLUE, font=title_font)
    sy = ty + th + int(h * 0.02)
    draw.text((w // 2 - sw // 2, sy), subtitle, fill=(60, 60, 60), font=sub_font)
    img.save(out, format="PNG", optimize=True)


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    assets = root / "assets"
    assets.mkdir(parents=True, exist_ok=True)
    make_app_icon(assets / "topkarta_app_icon.png")
    make_foreground(assets / "topkarta_app_icon_foreground.png")
    make_splash(assets / "splash_logo.png")
    make_splash_native_centered(assets / "topkarta_splash_native.png")
    print("Wrote:", assets / "topkarta_app_icon.png")
    print("Wrote:", assets / "topkarta_app_icon_foreground.png")
    print("Wrote:", assets / "splash_logo.png")
    print("Wrote:", assets / "topkarta_splash_native.png")


if __name__ == "__main__":
    main()
