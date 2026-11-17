#!/usr/bin/env python3
"""Play Store graphics: 512 px icon and the 1024 x 500 feature graphic.

    python3 tools/make_store_assets.py   (after tools/prep_art.py)
"""
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'store')
ART = os.path.join(ROOT, 'assets', 'art')
FONT = os.path.join(ROOT, 'assets', 'fonts', 'Quicksand-Bold.ttf')


def main():
    os.makedirs(OUT, exist_ok=True)
    Image.open(os.path.join(ROOT, 'assets', 'icon', 'icon.png')).resize((512, 512), Image.LANCZOS).save(
        os.path.join(OUT, 'icon-512.png'))

    bg = Image.open(os.path.join(ART, 'bg_home.webp')).convert('RGBA')
    bg = bg.resize((1024, 1024), Image.LANCZOS).crop((0, 300, 1024, 800))
    shade = Image.new('RGBA', bg.size, (60, 30, 140, 0))
    grad = Image.linear_gradient('L').rotate(90).resize(bg.size)
    shade.putalpha(grad.point(lambda v: int(v * 0.75)))
    bg.alpha_composite(shade)

    def place(name, size, xy):
        im = Image.open(os.path.join(ART, f'room_{name}.webp')).convert('RGBA').resize((size, size), Image.LANCZOS)
        glow = im.getchannel('A').filter(ImageFilter.GaussianBlur(10))
        halo = Image.new('RGBA', im.size, (255, 255, 255, 0))
        halo.putalpha(glow.point(lambda a: int(a * 0.5)))
        bg.alpha_composite(halo, xy)
        bg.alpha_composite(im, xy)

    place('songs', 250, (40, 125))
    place('guitar', 150, (735, 40))
    place('drums', 150, (860, 170))
    place('xylophone', 160, (700, 300))
    place('karaoke', 130, (890, 330))

    d = ImageDraw.Draw(bg)
    for text, size, y in (('Tiny Tunes', 96, 130), ('Studio', 96, 230), ('Play · Beat · Sing!', 40, 345)):
        f = ImageFont.truetype(FONT, size)
        d.text((305, y + 4), text, font=f, fill=(40, 20, 90, 160))
        d.text((300, y), text, font=f, fill=(255, 255, 255, 255))
    bg.convert('RGB').save(os.path.join(OUT, 'feature-graphic.png'))
    print('store graphics in', os.path.abspath(OUT))


if __name__ == '__main__':
    main()
