"""Gera os PWA icons do Hook Finance no estilo BloomLogo.

Saida: app/web/icons/Icon-{192,512,maskable-192,maskable-512}.png e app/web/favicon.png.

Design: gradiente conico (violet, sky, mint, pink, violet) num quadrado arredondado;
quadrado branco interno arredondado; letra "h" centralizada (Segoe UI Bold como
fallback p/ Bricolage Grotesque).
"""
from __future__ import annotations

import math
import os
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ICONS_DIR = ROOT / "web" / "icons"
FAVICON = ROOT / "web" / "favicon.png"

VIOLET = (110, 92, 231)
SKY = (93, 167, 242)
MINT = (63, 183, 147)
PINK = (238, 123, 184)
INK = (19, 18, 58)
INNER_BG = (251, 247, 255)

GRADIENT_STOPS = [
    (0.00, VIOLET),
    (0.25, SKY),
    (0.50, MINT),
    (0.75, PINK),
    (1.00, VIOLET),
]
START_DEGREES = 220


def _interp(c1, c2, t):
    return tuple(int(round(c1[i] + (c2[i] - c1[i]) * t)) for i in range(3))


def _color_at(theta_norm: np.ndarray) -> np.ndarray:
    out = np.zeros((*theta_norm.shape, 3), dtype=np.uint8)
    for (s1, c1), (s2, c2) in zip(GRADIENT_STOPS[:-1], GRADIENT_STOPS[1:]):
        mask = (theta_norm >= s1) & (theta_norm <= s2)
        if not mask.any():
            continue
        local_t = (theta_norm[mask] - s1) / (s2 - s1)
        for ch in range(3):
            out[..., ch][mask] = (
                c1[ch] + (c2[ch] - c1[ch]) * local_t
            ).astype(np.uint8)
    return out


def _conic_gradient(size: int) -> Image.Image:
    yy, xx = np.mgrid[0:size, 0:size]
    cx = cy = (size - 1) / 2.0
    dy = yy - cy
    dx = xx - cx
    theta = np.arctan2(dy, dx)
    start_rad = math.radians(START_DEGREES) - math.pi / 2.0
    theta = (theta - start_rad) % (2.0 * math.pi)
    theta_norm = theta / (2.0 * math.pi)
    rgb = _color_at(theta_norm)
    return Image.fromarray(rgb, mode="RGB")


def _rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=radius, fill=255
    )
    return mask


def _font_for(size_px: int) -> ImageFont.FreeTypeFont:
    for name in ("seguisb.ttf", "segoeuib.ttf", "arialbd.ttf"):
        try:
            return ImageFont.truetype(name, size_px)
        except OSError:
            continue
    return ImageFont.load_default()


def _draw_h(canvas: Image.Image, color: tuple[int, int, int]) -> None:
    w, h = canvas.size
    target_h = int(round(h * 0.5))
    font = _font_for(target_h)
    draw = ImageDraw.Draw(canvas)
    bbox = draw.textbbox((0, 0), "h", font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (w - tw) / 2.0 - bbox[0]
    y = (h - th) / 2.0 - bbox[1]
    draw.text((x, y), "h", fill=color, font=font)


def _make_icon(size: int, *, maskable: bool = False) -> Image.Image:
    if maskable:
        # Maskable: o icon "real" ocupa ~80% (margem 10% em cada lado), o resto e' a cor de fundo violeta solida
        # para evitar bordas transparentes.
        margin = int(round(size * 0.10))
        inner_size = size - 2 * margin
        canvas = Image.new("RGBA", (size, size), (*VIOLET, 255))
        inner = _make_icon(inner_size, maskable=False)
        canvas.paste(inner, (margin, margin), inner)
        return canvas

    # Conic gradient com mascara arredondada (radius = 32% do tamanho).
    outer_radius = int(round(size * 0.32))
    inner_inset = int(round(size * 0.13))
    inner_size = size - 2 * inner_inset
    inner_radius = int(round(size * 0.20))

    grad = _conic_gradient(size).convert("RGBA")
    outer_mask = _rounded_mask(size, outer_radius)
    grad.putalpha(outer_mask)

    # Quadrado branco interno arredondado.
    inner = Image.new("RGBA", (inner_size, inner_size), (0, 0, 0, 0))
    inner_mask = _rounded_mask(inner_size, inner_radius)
    fill = Image.new("RGBA", (inner_size, inner_size), (*INNER_BG, 255))
    fill.putalpha(inner_mask)
    inner.paste(fill, (0, 0), fill)
    _draw_h(inner, INK)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(grad)
    canvas.alpha_composite(inner, (inner_inset, inner_inset))
    return canvas


def main() -> None:
    ICONS_DIR.mkdir(parents=True, exist_ok=True)

    targets = [
        (ICONS_DIR / "Icon-192.png", 192, False),
        (ICONS_DIR / "Icon-512.png", 512, False),
        (ICONS_DIR / "Icon-maskable-192.png", 192, True),
        (ICONS_DIR / "Icon-maskable-512.png", 512, True),
        (FAVICON, 64, False),
    ]
    for path, size, maskable in targets:
        img = _make_icon(size, maskable=maskable)
        img.save(path, format="PNG", optimize=True)
        print(f"wrote {path.relative_to(ROOT)} ({size}x{size}{' maskable' if maskable else ''})")


if __name__ == "__main__":
    main()
