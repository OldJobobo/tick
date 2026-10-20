#!/usr/bin/env python3
"""Add captions outside genuine QML captures; no interface pixels are redrawn."""
from pathlib import Path
import json
import re
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
FRAMES = ROOT / 'frames'
OUT = ROOT / 'published'
OUT.mkdir(exist_ok=True)
FONT = ImageFont.truetype('DejaVuSans.ttf', 16)
SMALL = ImageFont.truetype('DejaVuSans.ttf', 12)
BG = '#141719'
INK = '#ecebe5'
MUTED = '#b4bd9b'

def card(variant, frame, title, crop=None):
    image = Image.open(FRAMES / f'{variant}-{frame}.png').convert('RGB')
    assert image.size == (840, 560)
    if crop:
        image = image.crop(crop)
    result = Image.new('RGB', (840, image.height + 68), BG)
    draw = ImageDraw.Draw(result)
    draw.text((14, 7), 'BEFORE: upstream main' if variant == 'before' else 'AFTER: PR #338', font=SMALL, fill=MUTED)
    draw.text((14, 26), title, font=FONT, fill=INK)
    result.paste(image, (0, 50))
    draw.text((14, image.height + 54), 'Actual QML capture | synthetic files | report.pdf remains unchanged', font=SMALL, fill=INK)
    return result

def stack(*images):
    result = Image.new('RGB', (840, sum(i.height for i in images) + 12 * (len(images) - 1)), '#33383a')
    y = 0
    for image in images:
        result.paste(image, (0, y))
        y += image.height + 12
    return result

sequence = [
    ('before', '01-path-click', 'Click the destination path: nothing opens', 1800),
    ('after', '01-path-click', 'Click the destination path: selected input opens', 2400),
    ('before', '02-hidden-files', 'No visible control for showing dotfiles', 1600),
    ('after', '02-hidden-files', 'Click the eye: .env.example and .draft-notes.txt appear', 2600),
    ('before', '06-grid-huge', 'Three Ctrl+wheel-up notches: icons stay Medium', 1800),
    ('after', '03-grid-medium', 'Start in Grid at Medium', 1200),
    ('after', '04-grid-wheel-up', 'Ctrl+wheel up: Large', 1200),
    ('after', '05-grid-wheel-up-again', 'Ctrl+wheel up again: Extra large', 1200),
    ('after', '06-grid-huge', 'Ctrl+wheel up again: Huge', 2200),
    ('after', '07-grid-wheel-down', 'Ctrl+wheel down: back to Extra large', 1800),
]
images = [card(v, f, title) for v, f, title, _ in sequence]
images[0].save(OUT / 'picker-before-after.gif', save_all=True, append_images=images[1:],
               duration=[delay for *_, delay in sequence], loop=0, disposal=2, optimize=True)
stack(card('before', '01-path-click', 'Path click does not open an input', (0, 0, 840, 100)),
      card('after', '01-path-click', 'The same click opens the selected path input', (0, 0, 840, 100))).save(OUT / '01-path-click.png')
stack(card('before', '02-hidden-files', 'No eye control; dotfiles remain excluded'),
      card('after', '02-hidden-files', 'Eye control reveals both dotfiles')).save(OUT / '02-hidden-files.png')
stack(card('before', '06-grid-huge', 'After three Ctrl+wheel-up notches: still Medium'),
      card('after', '06-grid-huge', 'The same input reaches Huge')).save(OUT / '03-grid-zoom.png')

records = []
for variant in ('before', 'after'):
    text = (FRAMES / f'{variant}.log').read_text()
    records += [json.loads(line.split('VISUAL FRAME ', 1)[1]) for line in text.splitlines() if 'VISUAL FRAME ' in line]
assert len(records) == 16
assert all(r['filename'] == 'report.pdf' and not r['answered'] for r in records)
(OUT / 'capture-state.json').write_text(json.dumps(records, indent=2) + '\n')
for path in sorted(OUT.iterdir()):
    print(path.name, path.stat().st_size)
