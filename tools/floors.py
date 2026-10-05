"""Altezze dei pavimenti (BSP) in alcuni punti di una mappa: python floors.py <mappa.dx> x,y [x,y ...]"""
import sys
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
from ue1pkg import Pkg
from bspmap import read_model


def inside(px, py, pts):
    c = False
    n = len(pts)
    for k in range(n):
        ax, ay = pts[k][0], pts[k][1]
        bx, by = pts[(k + 1) % n][0], pts[(k + 1) % n][1]
        if (ay > py) != (by > py):
            if ax + (py - ay) * (bx - ax) / (by - ay) > px:
                c = not c
    return c


p = Pkg(sys.argv[1])
idx = max((e['size'], i + 1) for i, e in enumerate(p.exports) if p.classname(e) == 'Model')[1]
points, nodes, surfs, verts = read_model(p, idx)
for a in sys.argv[2:]:
    x, y = (float(v) for v in a.split(','))
    zs = set()
    for plane, ivp, nv, isurf in nodes:
        if nv < 3 or plane[2] < 0.7:
            continue
        pts = [points[verts[ivp + k]] for k in range(nv)]
        if inside(x, y, pts):
            zs.add(round(sum(q[2] for q in pts) / len(pts)))
    print(a, sorted(zs))
