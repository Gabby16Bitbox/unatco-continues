"""The cigarette of the smoker in Harbourline Tower (17 Oct 2026, Gabby: "no cigarette in the game? then
a very small flare, retextured"). The game has only the pack (DeusExItems.Cigarettes), so the cigarette is
the flare's model (DeusExItems.Flare) very small, with this texture painted for its UVs:

  - along the stick (Y -6.16 .. +6.16) V goes 0 .. 1; round it U goes 0 .. 1;
  - both end caps use the same corner, U 0.07-0.43, V 0.88-0.98 (an ember-orange that also reads as
    the orange cork of the filter).

    V 0.00-0.03  the burning tip (orange)      V 0.03-0.07  ash (grey)
    V 0.07-0.72  white paper                   V 0.72-1.00  the filter (cork orange, speckled)

Nothing of the game is in it: painted here. Writes src\\UnatcoContinues\\Textures\\UCCigaretteTex.pcx
(256 colours), which UCTextures imports.

    python tools\\make_cigarette_tex.py
"""
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'src' / 'UnatcoContinues' / 'Textures' / 'UCCigaretteTex.pcx'
W, H = 32, 128


def colour(u, v, rnd):
    if 0.07 <= u <= 0.43 and 0.88 <= v <= 0.98:          # the end caps
        return (214, 112, 38) if rnd.random() < 0.7 else (150, 62, 22)
    if v < 0.03:                                          # the burning tip
        return (255, 120 + rnd.randint(0, 50), 30)
    if v < 0.07:                                          # ash
        g = rnd.randint(90, 140)
        return (g, g, g - 6)
    if v < 0.72:                                          # paper, a faint seam
        base = 236 if abs(u - 0.62) > 0.02 else 222
        return (base, base - 3, base - 12)
    if v < 0.735:                                         # the gold line round the filter
        return (200, 160, 70)
    if rnd.random() < 0.18:                               # cork speckles
        return (168, 96, 40)
    return (208, 138, 66)


def main():
    rnd = random.Random(7)
    im = Image.new('RGB', (W, H))
    for y in range(H):
        for x in range(W):
            im.putpixel((x, y), colour((x + 0.5) / W, (y + 0.5) / H, rnd))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    im.quantize(colors=256, method=Image.MEDIANCUT).save(OUT)
    print('wrote', OUT)


if __name__ == '__main__':
    main()
