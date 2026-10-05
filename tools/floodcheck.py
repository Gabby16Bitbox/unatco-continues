"""Verifica dei posti di blocco: dove puo' camminare il giocatore?

Rasterizza i pavimenti BSP in una fascia di altezze (griglia di CELL unita'),
taglia la griglia lungo i segmenti barriera e fa un flood fill dal punto di
partenza. Stampa quali uscite (teleporter/mete) sono raggiungibili e salva un PNG:
grigio = pavimento, verde = raggiungibile, rosso = barriere, giallo = uscite.

Uso: python floodcheck.py <mappa.dx> <out.png> <zmin> <zmax> <startx,starty>
        --bar=x1,y1,x2,y2 (ripetibile)  --exit=nome,x,y (ripetibile)  [--bounds=x0,x1,y0,y1]
"""
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(__file__))
from ue1pkg import Pkg
from bspmap import read_model
from mapplot import png

CELL = 16


def main():
    mp, out, zmin, zmax, start = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4]), sys.argv[5]
    sx, sy = (float(v) for v in start.split(','))
    bars, exits, bounds, walls = [], [], None, None
    for a in sys.argv[6:]:
        if a.startswith('--walls='):
            walls = tuple(float(v) for v in a[8:].split(','))
        if a.startswith('--bar='):
            bars.append(tuple(float(v) for v in a[6:].split(',')))
        elif a.startswith('--exit='):
            n, x, y = a[7:].split(',')
            exits.append((n, float(x), float(y)))
        elif a.startswith('--bounds='):
            bounds = tuple(float(v) for v in a[9:].split(','))
    p = Pkg(mp)
    idx = max((e['size'], i + 1) for i, e in enumerate(p.exports) if p.classname(e) == 'Model')[1]
    points, nodes, surfs, verts = read_model(p, idx)
    floors, wallpolys = [], []
    for plane, ivp, nv, isurf in nodes:
        if nv < 3:
            continue
        flags = surfs[isurf] if isurf < len(surfs) else 0
        if walls and abs(plane[2]) < 0.3 and not (flags & 0x8):      # muro solido (non PF_NotSolid)
            pts = [points[verts[ivp + k]] for k in range(nv)]
            za_, zb_ = min(q[2] for q in pts), max(q[2] for q in pts)
            if za_ < walls[1] and zb_ > walls[0]:
                wallpolys.append(pts)
            continue
        if plane[2] < 0.7:
            continue
        pts = [points[verts[ivp + k]] for k in range(nv)]
        zc = sum(q[2] for q in pts) / len(pts)
        if zmin <= zc <= zmax:
            floors.append(pts)
    xs = [q[0] for f in floors for q in f]
    ys = [q[1] for f in floors for q in f]
    x0, x1, y0, y1 = bounds if bounds else (min(xs), max(xs), min(ys), max(ys))
    W, H = int((x1 - x0) / CELL) + 1, int((y1 - y0) / CELL) + 1
    grid = bytearray(W * H)   # 0 vuoto, 1 pavimento, 2 barriera
    for f in floors:
        sp = [((q[0] - x0) / CELL, (y1 - q[1]) / CELL) for q in f]
        ya = max(0, int(min(q[1] for q in sp))); yb = min(H - 1, int(max(q[1] for q in sp)))
        for yy in range(ya, yb + 1):
            yc = yy + 0.5
            xsx = []
            for k in range(len(sp)):
                (ax, ay), (bx, by) = sp[k], sp[(k + 1) % len(sp)]
                if (ay <= yc < by) or (by <= yc < ay):
                    xsx.append(ax + (yc - ay) * (bx - ax) / (by - ay))
            xsx.sort()
            for a, b in zip(xsx[0::2], xsx[1::2]):
                for xx in range(max(0, int(a)), min(W - 1, int(b)) + 1):
                    grid[yy * W + xx] = 1
    # muri veri della mappa (alti come una persona)
    for wp in wallpolys:
        for k in range(len(wp)):
            (ax, ay), (bx, by) = ((wp[k][0] - x0) / CELL, (y1 - wp[k][1]) / CELL), ((wp[(k + 1) % len(wp)][0] - x0) / CELL, (y1 - wp[(k + 1) % len(wp)][1]) / CELL)
            n = int(max(abs(bx - ax), abs(by - ay)) * 2) + 1
            for s_ in range(n + 1):
                XX, YY = int(ax + (bx - ax) * s_ / n), int(ay + (by - ay) * s_ / n)
                if 0 <= XX < W and 0 <= YY < H and grid[YY * W + XX] == 1:
                    grid[YY * W + XX] = 3
    # barriere (spesse 2 celle)
    for bx1, by1, bx2, by2 in bars:
        ax, ay = (bx1 - x0) / CELL, (y1 - by1) / CELL
        bx, by = (bx2 - x0) / CELL, (y1 - by2) / CELL
        n = int(max(abs(bx - ax), abs(by - ay)) * 2) + 1
        for s in range(n + 1):
            X = ax + (bx - ax) * s / n; Y = ay + (by - ay) * s / n
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    XX, YY = int(X) + dx, int(Y) + dy
                    if 0 <= XX < W and 0 <= YY < H:
                        grid[YY * W + XX] = 2
    # flood fill
    seen = bytearray(W * H)
    parent = {}
    q = deque()
    SX, SY = int((sx - x0) / CELL), int((y1 - sy) / CELL)
    # parte dal pavimento piu' vicino al punto di partenza
    best = None
    for r in range(0, 12):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                X, Y = SX + dx, SY + dy
                if 0 <= X < W and 0 <= Y < H and grid[Y * W + X] == 1:
                    best = (X, Y); break
            if best: break
        if best: break
    if not best:
        sys.exit('punto di partenza fuori dal pavimento')
    q.append(best); seen[best[1] * W + best[0]] = 1
    while q:
        X, Y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            XX, YY = X + dx, Y + dy
            if 0 <= XX < W and 0 <= YY < H:
                k = YY * W + XX
                if not seen[k] and grid[k] == 1:
                    seen[k] = 1
                    parent[k] = Y * W + X
                    q.append((XX, YY))
    # uscite raggiungibili (entro 3 celle da una cella raggiunta)
    for n, ex, ey in exits:
        X, Y = int((ex - x0) / CELL), int((ey - y0) / CELL)
        Y = int((y1 - ey) / CELL)
        hit = any(0 <= X + dx < W and 0 <= Y + dy < H and seen[(Y + dy) * W + X + dx]
                  for dx in range(-6, 7) for dy in range(-6, 7))
        print('%-12s %s' % (n, 'RAGGIUNGIBILE' if hit else 'chiusa'))
        if hit and ('--path=' + n) in sys.argv:
            # cella raggiunta piu' vicina all'uscita, poi risale i genitori fino alla partenza
            best_k = min((((Y + dy) * W + X + dx) for dx in range(-6, 7) for dy in range(-6, 7)
                          if 0 <= X + dx < W and 0 <= Y + dy < H and seen[(Y + dy) * W + X + dx]),
                         key=lambda kk: abs(kk % W - X) + abs(kk // W - Y))
            path = [best_k]
            while path[-1] in parent:
                path.append(parent[path[-1]])
            path.reverse()
            print('   percorso (ogni 25 celle):', ' '.join('(%d,%d)' % (x0 + (kk % W) * CELL, y1 - (kk // W) * CELL) for kk in path[::25]))
    # immagine (fattore 2)
    S = 2
    px = bytearray([10, 10, 14] * (W * S) * (H * S))
    for Y in range(H):
        for X in range(W):
            k = Y * W + X
            col = None
            if grid[k] == 2: col = b'\xff\x30\x30'
            elif seen[k]: col = b'\x40\xd0\x60'
            elif grid[k] == 1: col = b'\x55\x58\x60'
            if col:
                for dy in range(S):
                    base = ((Y * S + dy) * W * S + X * S) * 3
                    px[base:base + 3 * S] = col * S
    for n, ex, ey in exits:
        X, Y = int((ex - x0) / CELL) * S, int((y1 - ey) / CELL) * S
        for dy in range(-5, 6):
            for dx in range(-5, 6):
                XX, YY = X + dx, Y + dy
                if 0 <= XX < W * S and 0 <= YY < H * S:
                    k = (YY * W * S + XX) * 3
                    px[k:k + 3] = b'\xff\xff\x00'
    png(out, W * S, H * S, px)
    print('ok', out, W * S, 'x', H * S)


if __name__ == '__main__':
    main()
