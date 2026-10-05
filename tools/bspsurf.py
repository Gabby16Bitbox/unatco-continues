"""Superfici della geometria fissa (BSP) di una mappa UE1 (Deus Ex, versione 68).

Uso: python bspsurf.py <mappa.dx> [testo]
Elenca, per ogni superficie del modello principale, texture, flag e il brush che l'ha
creata (FBspSurf.Actor); con [testo] solo le righe che lo contengono. Serve per sapere
se un brush cancellato ha lasciato pezzi nella geometria (mappa non ricostruita).
"""
import os
import struct
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(__file__))
from ue1pkg import Pkg


def props_end(p, idx):
    e = p.exports[idx - 1]
    d = p.d
    o = e['off']
    if e['flags'] & 0x02000000:
        node, o = p.ci(o)
        _, o = p.ci(o)
        o += 12
        if node != 0:
            _, o = p.ci(o)
    while True:
        ni, o = p.ci(o)
        if p.names[ni] == 'None':
            return o
        info = d[o]
        o += 1
        t, si, arr = info & 0x0F, (info >> 4) & 7, info & 0x80
        if t == 10:
            _, o = p.ci(o)
        size = {0: 1, 1: 2, 2: 4, 3: 12, 4: 16}.get(si)
        if si == 5:
            size = d[o]; o += 1
        elif si == 6:
            size = struct.unpack_from('<H', d, o)[0]; o += 2
        elif si == 7:
            size = struct.unpack_from('<I', d, o)[0]; o += 4
        if arr and t != 3:
            b = d[o]
            o += 1 if b < 128 else (2 if (b & 0xC0) == 0x80 else 4)
        o += size


def read_model(p, idx):
    d = p.d
    o = props_end(p, idx)
    o += 25 + 16                      # BoundingBox, BoundingSphere
    n, o = p.ci(o)                    # Vectors
    vectors = [struct.unpack_from('<fff', d, o + 12 * i) for i in range(n)]
    o += 12 * n
    n, o = p.ci(o)                    # Points
    points = [struct.unpack_from('<fff', d, o + 12 * i) for i in range(n)]
    o += 12 * n
    n, o = p.ci(o)                    # Nodes
    for _ in range(n):
        o += 16 + 8 + 1
        for _k in range(7):
            _, o = p.ci(o)
        o += 1 + 1 + 1 + 8
    n, o = p.ci(o)                    # Surfs
    surfs = []
    for _ in range(n):
        tex, o = p.ci(o)
        flags = struct.unpack_from('<I', d, o)[0]
        o += 4
        vals = []
        for _k in range(6):
            v, o = p.ci(o)
            vals.append(v)
        panu, panv = struct.unpack_from('<hh', d, o)
        o += 4
        actor, o = p.ci(o)
        surfs.append({'tex': p.refname(tex), 'flags': flags, 'base': points[vals[0]] if 0 <= vals[0] < len(points) else None,
                      'normal': vectors[vals[1]] if 0 <= vals[1] < len(vectors) else None, 'actor': p.refname(actor)})
    return surfs


def main():
    path = sys.argv[1]
    flt = sys.argv[2].lower() if len(sys.argv) > 2 else None
    p = Pkg(path)
    models = [(e['size'], i + 1) for i, e in enumerate(p.exports) if p.classname(e) == 'Model']
    models.sort(reverse=True)
    surfs = read_model(p, models[0][1])
    print('modello', p.exports[models[0][1] - 1]['name'], 'superfici', len(surfs))
    per_actor = Counter(s['actor'] for s in surfs)
    for s in surfs:
        line = '%-22s %-10s flags=%08x base=%s normal=%s' % (s['tex'], s['actor'], s['flags'],
                                                            tuple(round(x) for x in s['base']) if s['base'] else None,
                                                            tuple(round(x, 2) for x in s['normal']) if s['normal'] else None)
        if flt is None or flt in line.lower():
            print(line)
    if flt is None:
        print(per_actor.most_common(20))


if __name__ == '__main__':
    main()
