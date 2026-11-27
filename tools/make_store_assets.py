#!/usr/bin/env python3
"""Play Store graphics: 512 px icon and the 1024 x 500 feature graphic.

    python3 tools/make_store_assets.py   (after tools/prep_art.py)

The feature graphic (v1.1.0) is the approved Z-Image animal band (seed B, 26 Nov 2026) on the
right with the app name on the left; the previous version used the home background and room icons.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'store')
FONT = os.path.join(ROOT, 'assets', 'fonts', 'Quicksand-Bold.ttf')
BAND = os.path.join(ROOT, 'assets', 'images', '20261126-1445-music-studio-image-02_raw.png')


def main():
    os.makedirs(OUT, exist_ok=True)
    Image.open(os.path.join(ROOT, 'assets', 'icon', 'icon.png')).resize((512, 512), Image.LANCZOS).save(
        os.path.join(OUT, 'icon-512.png'))

    # Scale the square picture so the band fills the right of the graphic, then widen it to the left by
    # stretching its plain left edge (sky and floor), so there is no seam behind the title.
    scaled = Image.open(BAND).convert('RGBA').resize((717, 717), Image.LANCZOS).crop((0, 190, 717, 690))
    bg = scaled.crop((0, 0, 6, 500)).resize((1024, 500))
    bg.alpha_composite(scaled, (1024 - 717, 0))

    d = ImageDraw.Draw(bg)
    for text, size, y in (('Tiny Tunes', 72, 130), ('Studio', 72, 210), ('Play · Beat · Sing!', 32, 305)):
        f = ImageFont.truetype(FONT, size)
        d.text((44, y + 4), text, font=f, fill=(60, 30, 120, 150))
        d.text((40, y), text, font=f, fill=(255, 255, 255, 255))
    bg.convert('RGB').save(os.path.join(OUT, 'feature-graphic.png'))
    print('store graphics in', os.path.abspath(OUT))


if __name__ == '__main__':
    main()
