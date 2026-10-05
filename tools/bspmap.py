"""Pianta precisa dall'alto di una mappa Deus Ex, dalla geometria BSP del livello.

Legge il Model piu' grande del pacchetto (il BSP del livello): punti, nodi e
vertici. Disegna i PAVIMENTI (normale verso l'alto) colorati per altezza e i MURI
come linee chiare. Opzionale: solo una fascia di altezze (es. la strada).

Uso: python bspmap.py <mappa.dx> <out.png> [zmin zmax] [--marks]
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(__file__))
from ue1pkg import Pkg
from mapplot import png, FONT


def read_model(p, idx):
    e = p.exports[idx - 1]
    d = p.d
    o = e['off']
    # proprieta' (fino a "None")
    while True:
        ni, o = p.ci(o)
        if p.names[ni] == 'None':
            break
        info = d[o]; o += 1
        t = info & 0x0F; si = (info >> 4) & 7; arr = info & 0x80
        if t == 10:
            _, o = p.ci(o)
        size = {0: 1, 1: 2, 2: 4, 3: 12, 4: 16}.get(si)
        if size is None:
            if si == 5: size = d[o]; o += 1
            elif si == 6: size = struct.unpack_from('<H', d, o)[0]; o += 2
            else: size = struct.unpack_from('<I', d, o)[0]; o += 4
        if arr and t != 3:
            b = d[o]
            o += 1 if b < 128 else (2 if (b & 0xC0) == 0x80 else 4)
        o += size
    # UPrimitive: BoundingBox (25) + BoundingSphere (16)
    o += 25 + 16
    # Vectors
    n, o = p.ci(o); o += 12 * n
    # Points
    n, o = p.ci(o)
    points = [struct.unpack_from('<fff', d, o + 12 * k) for k in range(n)]
    o += 12 * n
    # Nodes
    n, o = p.ci(o)
    nodes = []
    for _ in range(n):
        plane = struct.unpack_from('<ffff', d, o); o += 16
        o += 8          # ZoneMask
        o += 1          # NodeFlags
        ivp, o = p.ci(o)
        isurf, o = p.ci(o)
        for _k in range(5):   # iBack iFront iPlane iCollisionBound iRenderBound
            _, o = p.ci(o)
        o += 2          # iZone[2]
        nv = d[o]; o += 1
        o += 8          # iLeaf[2]
        nodes.append((plane, ivp, nv, isurf))
    # Surfs
    n, o = p.ci(o)
    surfs = []
    for _ in range(n):
        _, o = p.ci(o)                       # Texture
        flags = struct.unpack_from('<I', d, o)[0]; o += 4
        for _k in range(6):                  # pBase vNormal vTextureU vTextureV iLightMap iBrushPoly
            _, o = p.ci(o)
        o += 4                               # PanU PanV
        _, o = p.ci(o)                       # Actor
        surfs.append(flags)
    # Verts
    n, o = p.ci(o)
    verts = []
    for _ in range(n):
        pv, o = p.ci(o)
        _, o = p.ci(o)
        verts.append(pv)
    return points, nodes, surfs, verts


def main():
    mp, out = sys.argv[1], sys.argv[2]
    args = [a for a in sys.argv[3:] if not a.startswith('--')]
    zmin = float(args[0]) if args else -1e9
    zmax = float(args[1]) if len(args) > 1 else 1e9
    p = Pkg(mp)
    idx = max((e['size'], i + 1) for i, e in enumerate(p.exports) if p.classname(e) == 'Model')[1]
    points, nodes, surfs, verts = read_model(p, idx)
    polys = []
    for plane, ivp, nv, isurf in nodes:
        if nv < 3 or ivp + nv > len(verts):
            continue
        if isurf < len(surfs) and surfs[isurf] & 0x00000001:   # PF_Invisible
            continue
        pts = [points[verts[ivp + k]] for k in range(nv) if verts[ivp + k] < len(points)]
        if len(pts) < 3:
            continue
        zc = sum(q[2] for q in pts) / len(pts)
        if not (zmin <= zc <= zmax):
            continue
        polys.append((plane[2], pts, zc))
    xs = [q[0] for _, pts, _ in polys for q in pts]
    ys = [q[1] for _, pts, _ in polys for q in pts]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    grid = 500
    for arg in sys.argv[3:]:
        if arg.startswith('--bounds='):
            x0, x1, y0, y1 = (float(v) for v in arg[9:].split(','))
        if arg.startswith('--grid='):
            grid = int(arg[7:])
    W = 1600
    scale = W / max(x1 - x0, y1 - y0)
    H = W
    px = bytearray([10, 10, 14] * W * H)

    def tp(x, y):
        return (x - x0) * scale, (y1 - y) * scale

    floors = [(nz, pts, zc) for nz, pts, zc in polys if nz > 0.7]
    za = min((zc for _, _, zc in floors), default=0)
    zb = max((zc for _, _, zc in floors), default=1)
    # pavimenti: riempimento scanline, colore per altezza (blu basso -> arancio alto)
    for nz, pts, zc in sorted(floors, key=lambda f: f[2]):
        t = (zc - za) / max(1.0, zb - za)
        col = bytes((int(40 + 200 * t), int(90 + 60 * (1 - abs(t - 0.5) * 2)), int(200 - 170 * t)))
        sp = [tp(q[0], q[1]) for q in pts]
        ymin = max(0, int(min(q[1] for q in sp))); ymax = min(H - 1, int(max(q[1] for q in sp)))
        for yy in range(ymin, ymax + 1):
            xsx = []
            for k in range(len(sp)):
                (ax, ay), (bx, by) = sp[k], sp[(k + 1) % len(sp)]
                if (ay <= yy < by) or (by <= yy < ay):
                    xsx.append(ax + (yy - ay) * (bx - ax) / (by - ay))
            xsx.sort()
            for a, b in zip(xsx[0::2], xsx[1::2]):
                for xx in range(max(0, int(a)), min(W - 1, int(b)) + 1):
                    k = (yy * W + xx) * 3
                    px[k:k + 3] = col
    # muri: bordi dei poligoni verticali
    for nz, pts, zc in polys:
        if abs(nz) > 0.3:
            continue
        sp = [tp(q[0], q[1]) for q in pts]
        for k in range(len(sp)):
            (ax, ay), (bx, by) = sp[k], sp[(k + 1) % len(sp)]
            steps = int(max(abs(bx - ax), abs(by - ay))) + 1
            for s in range(steps + 1):
                X = int(ax + (bx - ax) * s / steps); Y = int(ay + (by - ay) * s / steps)
                if 0 <= X < W and 0 <= Y < H:
                    k2 = (Y * W + X) * 3
                    px[k2:k2 + 3] = b'\xe6\xe6\xe6'
    # griglia + etichette ogni 500
    def text(x, y, s, col):
        cx, cy = x, y
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
    for gx in range(int(x0 // grid) * grid, int(x1) + 1, grid):
        X = int((gx - x0) * scale)
        if 0 <= X < W:
            for yy in range(0, H, 3):
                k = (yy * W + X) * 3
                px[k:k + 3] = b'\x50\x50\x60'
            text(X + 3, 4, str(gx), (255, 255, 120))
    for gy in range(int(y0 // grid) * grid, int(y1) + 1, grid):
        Y = int((y1 - gy) * scale)
        if 0 <= Y < H:
            for xx in range(0, W, 3):
                k = (Y * W + xx) * 3
                px[k:k + 3] = b'\x50\x50\x60'
            text(4, Y + 3, str(gy), (255, 255, 120))
    # segni opzionali: x,y,colore passati come MARK=x,y
    for a in sys.argv[3:]:
        if a.startswith('--mark='):
            x, y = (float(v) for v in a[7:].split(','))
            X, Y = tp(x, y)
            for dy in range(-7, 8):
                for dx in range(-7, 8):
                    if abs(dx) == abs(dy) or dx == 0 or dy == 0:
                        XX, YY = int(X) + dx, int(Y) + dy
                        if 0 <= XX < W and 0 <= YY < H:
                            k = (YY * W + XX) * 3
                            px[k:k + 3] = b'\xff\x20\x20'
    png(out, W, H, px)
    print('ok', out, 'poligoni', len(polys), 'pavimenti', len(floors), 'x', int(x0), int(x1), 'y', int(y0), int(y1), 'z', int(za), int(zb))


if __name__ == '__main__':
    main()
