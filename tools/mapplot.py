"""Pianta dall'alto di una mappa Deus Ex (PNG, senza dipendenze).

Disegna i punti di navigazione (PathNode ecc.) colorati per altezza, piu' gli
attori indicati. Serve per capire strade e passaggi prima di piazzare oggetti.

Uso: python mapplot.py <mappa.dx> <out.png> [zmin zmax]
"""
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(__file__))
from ue1pkg import Pkg

NAV = ('PathNode', 'PatrolPoint', 'HidePoint', 'AmbushPoint', 'HomeBase', 'InventorySpot', 'PlayerStart')
MARK = {'Teleporter': (255, 255, 0), 'DeusExMover': (255, 0, 255), 'RoadBlock': (255, 120, 0),
        'BlockPlayer': (255, 0, 0), 'BlockAll': (255, 0, 0), 'Hooker1': (0, 255, 255)}

# font 3x5 per le etichette (cifre e poche lettere)
FONT = {
    '0': ['111', '101', '101', '101', '111'], '1': ['010', '110', '010', '010', '111'],
    '2': ['111', '001', '111', '100', '111'], '3': ['111', '001', '111', '001', '111'],
    '4': ['101', '101', '111', '001', '001'], '5': ['111', '100', '111', '001', '111'],
    '6': ['111', '100', '111', '101', '111'], '7': ['111', '001', '001', '001', '001'],
    '8': ['111', '101', '111', '101', '111'], '9': ['111', '101', '111', '001', '111'],
    '-': ['000', '000', '111', '000', '000'], ',': ['000', '000', '000', '010', '100'],
}


def png(path, w, h, px):
    raw = b''.join(b'\x00' + bytes(px[y * w * 3:(y + 1) * w * 3]) for y in range(h))
    def chunk(t, d):
        c = struct.pack('>I', len(d)) + t + d
        return c + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    data = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) \
        + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    open(path, 'wb').write(data)


def main():
    mp, out = sys.argv[1], sys.argv[2]
    zmin = float(sys.argv[3]) if len(sys.argv) > 3 else -1e9
    zmax = float(sys.argv[4]) if len(sys.argv) > 4 else 1e9
    m = Pkg(mp)
    pts, marks = [], []
    for i, e in enumerate(m.exports):
        c = m.classname(e)
        if c not in NAV and c not in MARK:
            continue
        try:
            loc = m.get(i + 1, 'Location')
        except Exception:
            continue
        if not loc:
            continue
        if c in NAV:
            if zmin <= loc[2] <= zmax:
                pts.append(loc)
        else:
            marks.append((c, loc, e['name']))
    xs = [p[0] for p in pts] + [l[0] for _, l, _ in marks]
    ys = [p[1] for p in pts] + [l[1] for _, l, _ in marks]
    x0, x1, y0, y1 = min(xs) - 200, max(xs) + 200, min(ys) - 200, max(ys) + 200
    W = 1400
    scale = W / max(x1 - x0, y1 - y0)
    H = W
    px = bytearray([18, 18, 22] * W * H)

    def put(x, y, col, r=2):
        cx, cy = int((x - x0) * scale), int((y1 - y) * scale)
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                X, Y = cx + dx, cy + dy
                if 0 <= X < W and 0 <= Y < H:
                    k = (Y * W + X) * 3
                    px[k:k + 3] = bytes(col)

    def text(x, y, s, col):
        cx, cy = int((x - x0) * scale) + 6, int((y1 - y) * scale) - 6
        for ch in s:
            g = FONT.get(ch)
            if g:
                for gy, row in enumerate(g):
                    for gx, b in enumerate(row):
                        if b == '1':
                            for sy in range(2):
                                for sx in range(2):
                                    X, Y = cx + gx * 2 + sx, cy + gy * 2 + sy
                                    if 0 <= X < W and 0 <= Y < H:
                                        k = (Y * W + X) * 3
                                        px[k:k + 3] = bytes(col)
            cx += 8

    # griglia ogni 500 unita'
    for gx in range(int(x0 // 500) * 500, int(x1) + 1, 500):
        for yy in range(H):
            X = int((gx - x0) * scale)
            if 0 <= X < W:
                k = (yy * W + X) * 3
                px[k:k + 3] = bytes((40, 40, 48))
        text(gx, y1 - 40, str(gx), (110, 110, 120))
    for gy in range(int(y0 // 500) * 500, int(y1) + 1, 500):
        Y = int((y1 - gy) * scale)
        if 0 <= Y < H:
            for xx in range(W):
                k = (Y * W + xx) * 3
                px[k:k + 3] = bytes((40, 40, 48))
        text(x0 + 20, gy, str(gy), (110, 110, 120))

    zs = [p[2] for p in pts] or [0]
    za, zb = min(zs), max(zs)
    for p in pts:
        t = (p[2] - za) / max(1, zb - za)
        put(p[0], p[1], (int(60 + 195 * t), int(200 - 120 * t), int(255 - 200 * t)), 2)
    for c, l, n in marks:
        put(l[0], l[1], MARK[c], 5)
    png(out, W, H, px)
    print('ok', out, 'x', int(x0), int(x1), 'y', int(y0), int(y1), 'z', int(za), int(zb), 'nodi', len(pts))
    for c, l, n in marks:
        print(c, n, tuple(int(v) for v in l))


if __name__ == '__main__':
    main()
