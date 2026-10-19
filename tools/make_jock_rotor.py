"""Jock's helicopter with its rotors stopped (Gabby, 15 Oct 2026: the game's rotor is a blurred disc, made
in motion): two dark crossed blades on the main hub and two small ones on the tail rotor, in the
helicopter's own coordinates (BlackHelicopter mesh: main disc 600 across at z 60; tail disc 60 across
at x -342, z -28, in the XZ plane). Imported into the mod's UCModels as UCM_JockRotor."""
import math
import sys
from pathlib import Path

KIT = Path(r'C:\Users\gab4y\Desktop\Deus Ex\UnatcoContinues\tools\mapkit')
sys.path[:0] = [str(KIT / 'editor'), str(KIT), str(KIT.parent)]

pos, idx = [], []


def box(center, size, yaw=0.0, plane='xy'):
    """A box: size = (length, width, thickness); in the 'xy' plane it lies flat (turned by yaw), in the
    'xz' plane it stands up (turned by yaw in that plane)."""
    L, W, T = size
    base = len(pos) // 3
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    for dx in (-L / 2, L / 2):
        for dy in (-W / 2, W / 2):
            for dz in (-T / 2, T / 2):
                if plane == 'xy':
                    x, y, z = dx * c - dy * s, dx * s + dy * c, dz
                else:                       # in the XZ plane, thickness along Y
                    x, z, y = dx * c - dy * s, dx * s + dy * c, dz
                pos.extend([center[0] + x, center[1] + y, center[2] + z])
    # corners: index = ix*4 + iy*2 + iz
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    for a, b, c2, d in faces:
        idx.extend([base + a, base + b, base + c2, base + a, base + c2, base + d])


HUB = (0.0, 0.0, 63.0)
box(HUB, (590, 16, 3), 45)            # main rotor: two blades across the hub
box(HUB, (590, 16, 3), 135)
box((0.0, 0.0, 58.0), (26, 26, 12))   # the hub
box((-342.0, 0.0, -28.0), (58, 6, 2), 45, 'xz')    # tail rotor
box((-342.0, 0.0, -28.0), (58, 6, 2), 135, 'xz')

body = dict(name='JockRotor', source='tools: make_rotor.py (Battery Park, Jock\'s helicopter at rest)',
            positions=pos, uvs=[0.5] * (len(idx) * 2), indices=idx, triMaterials=[0] * (len(idx) // 3),
            materials=[dict(name='blade', color=[0.07, 0.07, 0.08], twosided=False, png='')])
if __name__ == '__main__':
    import models
    ok, lines, mesh = models.import_model(body)
    print(ok, mesh)
    print('\n'.join(lines))
