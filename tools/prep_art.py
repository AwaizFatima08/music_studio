#!/usr/bin/env python3
"""Turns approved homidev art (assets/images, assets/icons) into what the app uses.

    python3 tools/prep_art.py

- Room icons: cutouts trimmed to their content, 512 px WebP -> assets/art/room_<id>.webp
- Backgrounds: 1024 px WebP -> assets/art/bg_<name>.webp
- Launcher icon (Homi, 17 Nov 2026: the smiling music note on solid purple, not the
  generated headphones icon): assets/icon/icon.png (full square) and
  assets/icon/icon_foreground.png (adaptive-icon foreground with safe-zone padding)
"""
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
ICONS = os.path.join(ROOT, 'assets', 'icons')
IMAGES = os.path.join(ROOT, 'assets', 'images')
ART = os.path.join(ROOT, 'assets', 'art')
LAUNCHER = os.path.join(ROOT, 'assets', 'icon')
PURPLE = (124, 77, 255, 255)

ROOMS = {
    'piano': '20261117-1358-music-studio-icon-01',
    'xylophone': '20261117-1358-music-studio-icon-02',
    'guitar': '20261117-1358-music-studio-icon-03',
    'drums': '20261117-1358-music-studio-icon-04',
    'flute': '20261117-1359-music-studio-icon-01',
    'silly': '20261117-1359-music-studio-icon-02',
    'beats': '20261117-1359-music-studio-icon-03',
    'songs': '20261117-1410-music-studio-icon-01',
    'karaoke': '20261117-1411-music-studio-icon-01',
}
BACKGROUNDS = {
    'home': '20261117-1357-music-studio-image-01',
    'stage': '20261117-1357-music-studio-image-02',
}


def trimmed(job):
    im = Image.open(os.path.join(ICONS, f'{job}_cutout.png')).convert('RGBA')
    box = im.getchannel('A').point(lambda a: 255 if a > 8 else 0).getbbox()
    return im.crop(box)


def fit(im, size, fill):
    """Scales [im] to fit a [size] square at [fill] of its side, centred, transparent around."""
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    scale = size * fill / max(im.size)
    im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    out.alpha_composite(im, ((size - im.width) // 2, (size - im.height) // 2))
    return out


def main():
    os.makedirs(ART, exist_ok=True)
    os.makedirs(LAUNCHER, exist_ok=True)
    for room, job in ROOMS.items():
        fit(trimmed(job), 512, 0.96).save(os.path.join(ART, f'room_{room}.webp'), quality=88, method=6)
    for name, job in BACKGROUNDS.items():
        Image.open(os.path.join(IMAGES, f'{job}_raw.png')).convert('RGB').save(
            os.path.join(ART, f'bg_{name}.webp'), quality=82, method=6)
    note = trimmed(ROOMS['songs'])
    full = Image.new('RGBA', (1024, 1024), PURPLE)
    full.alpha_composite(fit(note, 1024, 0.72))
    full.convert('RGB').save(os.path.join(LAUNCHER, 'icon.png'))
    # Adaptive icons crop to the inner ~61 %; keep the note inside it.
    fit(note, 1024, 0.5).save(os.path.join(LAUNCHER, 'icon_foreground.png'))
    print('art written to', os.path.abspath(ART), 'and', os.path.abspath(LAUNCHER))


if __name__ == '__main__':
    main()
