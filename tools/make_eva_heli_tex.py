"""Eva's helicopter skin: the game's BlackHelicopterTex1 recoloured dark police blue, with the cockpit
section left black (Gabby, 15 Oct 2026: "blu poliziesco ma scuro", then "il cockpit nero, il resto un
blu un po' piu' scuro"). Her helicopter from Battery Park on.

    python tools\\make_eva_heli_tex.py

Reads, as the map editor exported them from YOUR game (tools\\mapkit\\editor\\cache\\_palette: open any
map with a helicopter in the editor once if they are missing):
  tex\\DeusExDeco.Skins.BlackHelicopterTex1.png   the texture
  meshes.json (BlackHelicopter)                  the model's triangles and texture coordinates
and writes src\\UnatcoContinues\\Textures\\UCEvaHeliTex.pcx (256 colours), which UCTextures imports.
The cockpit is the body around the canopy glass (is_cockpit): its pixels keep the original black. Made from the game's own
texture, so it stays out of the repository (.gitignore), like UCSignElevators.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / 'tools' / 'mapkit' / 'editor' / 'cache' / '_palette'
SRC = CACHE / 'tex' / 'DeusExDeco.Skins.BlackHelicopterTex1.png'
MESHES = CACHE / 'meshes.json'
OUT = ROOT / 'src' / 'UnatcoContinues' / 'Textures' / 'UCEvaHeliTex.pcx'

# Photos of 15 Oct: a greyish navy read as olive green under Battery Park's orange street lamps, a
# saturated blue looked like a toy on the Hong Kong roof. Dark navy with almost no green.
DARK = (3, 6, 40)         # the body: dark police blue instead of black
LIGHT = (70, 90, 160)     # highlights and markings: muted blue
# The cockpit = the canopy: the body faces under the glass (the glass, slot 2, spans model x 58..188
# and z -18..34; the nose is +x). They all take their texture from one block, top right of the
# texture (u > 0.75, v < 0.40): those faces stay black. Not the nose, not the side panels next to
# the cabin (one with a ring marking) nor the rear pillar (Gabby, 15 Oct: "solo cockpit", then
# "piccoli sprazzi ... andrebbero blu").
def is_cockpit(cx, cz, u, v):
    return 55 < cx < 195 and cz > -22 and u > 0.75 and v < 0.40


# The nose tip: its faces take the light grey nose cone of the texture, which came out as a pale
# triangle on the blue (Gabby, 15 Oct): there the shading is kept but the highlights are damped.
def is_tip(cx, cz, u, v):
    return cx > 210


def recolour(px, strength=1.0):
    r, g, b = px[:3]
    lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    t = strength * lum ** 0.85
    return tuple(int(DARK[i] + (LIGHT[i] - DARK[i]) * t) for i in range(3))


def cockpit_mask(size, test=None):
    """White where the texture is used by the body faces (slot 0) that pass test (the cockpit)."""
    test = test or is_cockpit
    mask = Image.new('L', size, 0)
    if not MESHES.is_file():
        return mask
    mesh = json.loads(MESHES.read_text(encoding='utf-8')).get('BlackHelicopter')
    if not mesh:
        return mask
    part = next((p for p in mesh['parts'] if p.get('slot') == 0), None)
    if not part or 'uv' not in part:
        return mask
    pos, uv = part['pos'], part['uv']
    draw = ImageDraw.Draw(mask)
    w, h = size
    for i in range(len(pos) // 9):
        x = sum(pos[i * 9 + k * 3] for k in range(3)) / 3
        z = sum(pos[i * 9 + k * 3 + 2] for k in range(3)) / 3
        u = sum(uv[i * 6 + k * 2] for k in range(3)) / 3
        v = sum(uv[i * 6 + k * 2 + 1] for k in range(3)) / 3
        if test(x, z, u, v):
            draw.polygon([(uv[i * 6 + k * 2] * w, uv[i * 6 + k * 2 + 1] * h) for k in range(3)], fill=255)
    return mask.filter(ImageFilter.MaxFilter(3))      # one pixel more: no blue seam at the edges


def main():
    if not SRC.is_file():
        sys.exit('missing %s: open a map with a helicopter in the map editor once (it exports the game texture)' % SRC)
    im = Image.open(SRC).convert('RGB')
    blue = Image.new('RGB', im.size)
    blue.putdata([recolour(p) for p in im.getdata()])
    dim = Image.new('RGB', im.size)
    dim.putdata([recolour(p, 0.25) for p in im.getdata()])
    blue = Image.composite(dim, blue, cockpit_mask(im.size, is_tip))   # the nose tip without the pale cone
    mask = cockpit_mask(im.size)
    out = Image.composite(im, blue, mask)              # original black in the cockpit, blue elsewhere
    out = out.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT)
    print('written', OUT, out.size, 'cockpit pixels kept:', sum(1 for v in mask.getdata() if v))


if __name__ == '__main__':
    main()
