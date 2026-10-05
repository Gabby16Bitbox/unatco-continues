"""Ombre "cotte" della geometria fissa (BSP) di una mappa UE1 (Deus Ex, versione 68).

Il motore salva, per ogni superficie illuminata e per ogni luce che la tocca, una
maschera a 1 bit (1 = la luce arriva, 0 = ombra). Le ombre lasciate da oggetti tolti
dopo la ricostruzione delle luci restano li': questo strumento le mostra e le toglie
senza ricostruire le luci (che nell'editor SDK scurisce le mappe di Revision).

Uso:
  python lightbits.py <mappa.dx> list x1 y1 x2 y2 z1 z2
      superfici in quel riquadro (pavimenti e muri) con le luci e quanta ombra hanno
  python lightbits.py <mappa.dx> png <cartella> x1 y1 x2 y2 z1 z2
      un'immagine per superficie+luce (bianco = luce, nero = ombra)
  python lightbits.py <mappa.dx> clear x1 y1 x2 y2 z1 z2 [nz] [luce,...]
      mette a "luce" i punti delle superfici dentro il riquadro (solo quelle con
      normale z ~ nz se dato, solo le luci indicate se date). Modifica il file sul posto.
  python lightbits.py <mappa.dx> unshadow <mappa_vecchia.dx> x1 y1 x2 y2 z1 z2 [prova]
      il modo giusto per togliere le ombre di geometria tolta: per ogni punto delle
      superfici nel riquadro traccia il raggio verso ogni luce sia nella geometria
      vecchia (quella con cui furono calcolate le ombre) sia in quella attuale, e
      accende solo i punti in ombra prima e liberi adesso. Con "prova" non scrive.
"""
import math
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(__file__))
from ue1pkg import Pkg
from bspsurf import props_end


class Model:
    def __init__(self, path, name=None):
        self.path = path
        p = self.p = Pkg(path)
        d = p.d
        if name:
            idx = p.find_export(name, 'Model')
        else:
            # il modello piu' grande e' la geometria fissa della mappa
            models = sorted([(e['size'], i + 1) for i, e in enumerate(p.exports) if p.classname(e) == 'Model'], reverse=True)
            idx = models[0][1]
        self.idx = idx
        e = p.exports[idx - 1]
        o = props_end(p, idx)
        o += 25 + 16                      # BoundingBox, BoundingSphere
        n, o = p.ci(o)
        self.vectors = [struct.unpack_from('<fff', d, o + 12 * i) for i in range(n)]
        o += 12 * n
        n, o = p.ci(o)
        self.points = [struct.unpack_from('<fff', d, o + 12 * i) for i in range(n)]
        o += 12 * n
        self.sec = {}                     # sezioni del modello: nome -> (inizio, fine) nel file
        self.sec['start'] = o
        n, o = p.ci(o)                    # Nodes: piano, figli (dietro, davanti)
        self.nodes = []
        self.node_polys = []              # (iVertPool, iSurf, NumVertices)
        for _ in range(n):
            plane = struct.unpack_from('<ffff', d, o)
            o += 16 + 8 + 1
            ch = []
            for _k in range(7):
                v, o = p.ci(o)
                ch.append(v)
            nv = d[o + 2]
            o += 1 + 1 + 1 + 8
            self.nodes.append((plane, ch[2], ch[3]))
            self.node_polys.append((ch[0], ch[1], nv))
        s0 = o
        n, o = p.ci(o)                    # Surfs
        self.surfs = []
        for _ in range(n):
            tex, o = p.ci(o)
            flags = struct.unpack_from('<I', d, o)[0]
            o += 4
            vals = []
            for _k in range(6):
                v, o = p.ci(o)
                vals.append(v)
            pan_uv = struct.unpack_from('<hh', d, o)
            o += 4
            actor, o = p.ci(o)
            self.surfs.append({'tex': p.refname(tex), 'tex_ref': tex, 'flags': flags, 'pBase': vals[0], 'vNormal': vals[1],
                               'vU': vals[2], 'vV': vals[3], 'iLightMap': vals[4], 'iBrushPoly': vals[5],
                               'pan_uv': pan_uv, 'actor': p.refname(actor), 'actor_ref': actor})
        self.sec['surfs'] = (s0, o)
        n, o = p.ci(o)                    # Verts
        self.verts = []
        for _ in range(n):
            pv, o = p.ci(o)
            _, o = p.ci(o)
            self.verts.append(pv)
        o += 4                            # NumSharedSides
        nz = struct.unpack_from('<i', d, o)[0]
        o += 4
        for _ in range(nz):               # Zones: ZoneActor, Connectivity, Visibility
            _, o = p.ci(o)
            o += 16
        _, o = p.ci(o)                    # Polys
        l0 = o
        n, o = p.ci(o)                    # LightMap
        self.lightmaps = []
        for _ in range(n):
            off = struct.unpack_from('<i', d, o)[0]
            pan = struct.unpack_from('<fff', d, o + 4)
            o += 16
            uc, o = p.ci(o)
            vc, o = p.ci(o)
            us, vs, il = struct.unpack_from('<ffi', d, o)
            o += 12
            self.lightmaps.append({'off': off, 'pan': pan, 'uc': uc, 'vc': vc, 'us': us, 'vs': vs, 'il': il})
        self.sec['lightmap'] = (l0, o)
        b0 = o
        n, o = p.ci(o)                    # LightBits
        self.bits_at = o
        self.bits_len = n
        o += n
        self.sec['lightbits'] = (b0, o)
        n, o = p.ci(o)                    # Bounds
        o += 25 * n
        n, o = p.ci(o)                    # LeafHulls
        o += 4 * n
        n, o = p.ci(o)                    # Leaves
        for _ in range(n):
            for _k in range(3):
                _, o = p.ci(o)
            o += 8
        g0 = o
        n, o = p.ci(o)                    # Lights
        self.lights = []
        for _ in range(n):
            r, o = p.ci(o)
            self.lights.append(r)
        self.sec['lights'] = (g0, o)
        o += 8                            # RootOutside, Linked
        self.sec['end'] = o
        if o != e['off'] + e['size']:
            raise SystemExit('lettura del modello non allineata (%d invece di %d)' % (o, e['off'] + e['size']))

    def empty(self, P):
        """Vero se il punto e' nello spazio vuoto (non dentro la geometria fissa)."""
        i = 0
        front = True
        while i >= 0 and i < len(self.nodes):
            (x, y, z, w), back, frnt = self.nodes[i]
            front = x * P[0] + y * P[1] + z * P[2] - w > 0
            i = frnt if front else back
        return front

    def sees(self, a, b, step=2.0):
        """Vero se il segmento a-b non attraversa la geometria fissa."""
        dx, dy, dz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
        n = max(1, int(math.sqrt(dx * dx + dy * dy + dz * dz) / step))
        for k in range(1, n):
            t = k / n
            if not self.empty((a[0] + dx * t, a[1] + dy * t, a[2] + dz * t)):
                return False
        return True

    def against_wall(self, s, lm, u, v):
        """Vero per i punti sul bordo della maschera che toccano un muro: il motore li
        lascia sempre in ombra (li calcola a filo del muro), quindi non vanno accesi."""
        nrm = self.vectors[s['vNormal']]
        outs = []
        if u == 0:
            outs.append((-1, v))
        if u == lm['uc'] - 1:
            outs.append((lm['uc'], v))
        if v == 0:
            outs.append((u, -1))
        if v == lm['vc'] - 1:
            outs.append((u, lm['vc']))
        for (ou, ov) in outs:
            w = self.lumel_world(s, lm, ou, ov)
            if w and not self.empty(tuple(w[k] + nrm[k] for k in range(3))):
                return True
        return False

    def surf_lights(self, lm):
        """Luci (nome) della superficie, nell'ordine delle maschere."""
        out = []
        i = lm['il']
        while 0 <= i < len(self.lights) and self.lights[i] != 0:
            out.append(self.p.refname(self.lights[i]))
            i += 1
        return out

    def lumel_world(self, s, lm, u, v):
        """Punto del mondo al centro del punto (u,v) della maschera."""
        base = self.points[s['pBase']]
        tu = self.vectors[s['vU']]
        tv = self.vectors[s['vV']]
        nrm = self.vectors[s['vNormal']]
        U = lm['pan'][0] + (u + 0.5) * lm['us']
        V = lm['pan'][1] + (v + 0.5) * lm['vs']
        # P = base + a*tu' + b*tv' risolvendo (P-base).tu = U, (P-base).tv = V, (P-base).n = 0
        m = [tu, tv, nrm]
        rhs = [U, V, 0.0]
        det = (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
               + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))
        if abs(det) < 1e-9:
            return None
        res = []
        for c in range(3):
            mc = [list(r) for r in m]
            for r in range(3):
                mc[r][c] = rhs[r]
            dc = (mc[0][0] * (mc[1][1] * mc[2][2] - mc[1][2] * mc[2][1]) - mc[0][1] * (mc[1][0] * mc[2][2] - mc[1][2] * mc[2][0])
                  + mc[0][2] * (mc[1][0] * mc[2][1] - mc[1][1] * mc[2][0]))
            res.append(dc / det)
        return tuple(base[k] + res[k] for k in range(3))

    def surfaces_in(self, box, nz=None):
        x1, y1, x2, y2, z1, z2 = box
        seen = set()
        for si, s in enumerate(self.surfs):
            li = s['iLightMap']
            if li < 0 or li >= len(self.lightmaps) or li in seen:
                continue
            if nz is not None and abs(self.vectors[s['vNormal']][2] - nz) > 0.05:
                continue
            lm = self.lightmaps[li]
            inside = False
            for (u, v) in ((0, 0), (lm['uc'] - 1, 0), (0, lm['vc'] - 1), (lm['uc'] - 1, lm['vc'] - 1), (lm['uc'] // 2, lm['vc'] // 2)):
                w = self.lumel_world(s, lm, u, v)
                if w and x1 <= w[0] <= x2 and y1 <= w[1] <= y2 and z1 <= w[2] <= z2:
                    inside = True
            if inside:
                seen.add(li)
                yield si, s, lm

    def masks(self, lm):
        """(nome luce, offset nel file, byte per riga) per ogni maschera della superficie."""
        row = (lm['uc'] + 7) >> 3
        size = row * lm['vc']
        out = []
        for k, name in enumerate(self.surf_lights(lm)):
            out.append((name, self.bits_at + lm['off'] + k * size, row))
        return out


def write_png(path, px, scale):
    """PNG in scala di grigi (senza librerie esterne), ingrandito di 'scale'."""
    import zlib
    h, w = len(px) * scale, len(px[0]) * scale
    raw = b''.join(b'\0' + bytes(px[y // scale][x // scale] for x in range(w)) for y in range(h))

    def chunk(t, data):
        return struct.pack('>I', len(data)) + t + data + struct.pack('>I', zlib.crc32(t + data) & 0xFFFFFFFF)
    png = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 0, 0, 0, 0))
           + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))
    open(path, 'wb').write(png)


def box_args(a):
    return tuple(float(x) for x in a[:6])


def main():
    path, cmd = sys.argv[1], sys.argv[2]
    m = Model(path)
    d = m.p.d
    if cmd == 'list':
        box = box_args(sys.argv[3:9])
        for si, s, lm in m.surfaces_in(box):
            nrm = m.vectors[s['vNormal']]
            c = m.lumel_world(s, lm, lm['uc'] // 2, lm['vc'] // 2)
            print('surf %d %s %s n=%s centro=%s %dx%d' % (si, s['tex'], s['actor'], tuple(round(x, 2) for x in nrm),
                                                       tuple(round(x) for x in c), lm['uc'], lm['vc']))
            for name, off, row in m.masks(lm):
                tot = lm['uc'] * lm['vc']
                lit = sum(1 for v in range(lm['vc']) for u in range(lm['uc']) if d[off + v * row + (u >> 3)] >> (u & 7) & 1)
                print('    %-16s ombra %3d%%' % (name, round(100 * (tot - lit) / tot)))
    elif cmd == 'png':
        out = sys.argv[3]
        os.makedirs(out, exist_ok=True)
        box = box_args(sys.argv[4:10])
        for si, s, lm in m.surfaces_in(box):
            for name, off, row in m.masks(lm):
                px = [[255 if d[off + v * row + (u >> 3)] >> (u & 7) & 1 else 0 for u in range(lm['uc'])]
                      for v in range(lm['vc'])]
                write_png(os.path.join(out, 'surf%d_%s.png' % (si, name)), px, 8)
    elif cmd == 'clear':
        box = box_args(sys.argv[3:9])
        nz = float(sys.argv[9]) if len(sys.argv) > 9 and sys.argv[9] != '-' else None
        only = set(sys.argv[10].split(',')) if len(sys.argv) > 10 else None
        data = bytearray(d)
        x1, y1, x2, y2, z1, z2 = box
        changed = 0
        for si, s, lm in m.surfaces_in(box, nz):
            for name, off, row in m.masks(lm):
                if only and name not in only:
                    continue
                for v in range(lm['vc']):
                    for u in range(lm['uc']):
                        w = m.lumel_world(s, lm, u, v)
                        if w and x1 <= w[0] <= x2 and y1 <= w[1] <= y2 and z1 <= w[2] <= z2:
                            b = off + v * row + (u >> 3)
                            if not data[b] >> (u & 7) & 1:
                                data[b] |= 1 << (u & 7)
                                changed += 1
        open(path, 'wb').write(bytes(data))
        print('punti schiariti:', changed)
    elif cmd == 'unshadow':
        old = Model(sys.argv[3])
        box = box_args(sys.argv[4:10])
        dry = len(sys.argv) > 10 and sys.argv[10] == 'prova'
        data = bytearray(d)
        where = {}
        changed = 0
        for si, s, lm in m.surfaces_in(box):
            nrm = m.vectors[s['vNormal']]
            for name, off, row in m.masks(lm):
                if name not in where:
                    li = m.p.find_export(name)
                    where[name] = m.p.get(li, 'Location') if li else None
                L = where[name]
                if not L:
                    continue
                # bordi che il motore tiene scuri anche dove la luce arriva (punti calcolati
                # a filo di qualcosa): li' non si accende niente
                def stored(u, v):
                    return data[off + v * row + (u >> 3)] >> (u & 7) & 1

                def free(u, v):
                    w = m.lumel_world(s, lm, u, v)
                    a = tuple(w[k] + nrm[k] for k in range(3))
                    return m.sees(a, L) and old.sees(a, L)
                dark_edges = set()
                for edge, pts in (('u0', [(0, v) for v in range(lm['vc'])]),
                                  ('u1', [(lm['uc'] - 1, v) for v in range(lm['vc'])]),
                                  ('v0', [(u, 0) for u in range(lm['uc'])]),
                                  ('v1', [(u, lm['vc'] - 1) for u in range(lm['uc'])])):
                    if not any(stored(u, v) for u, v in pts) and any(free(u, v) for u, v in pts):
                        dark_edges.add(edge)
                grid = []
                n = 0
                for v in range(lm['vc']):
                    line = ''
                    for u in range(lm['uc']):
                        b = off + v * row + (u >> 3)
                        lit = data[b] >> (u & 7) & 1
                        mark = '.' if lit else '#'
                        edges = {e for e, c in (('u0', u == 0), ('u1', u == lm['uc'] - 1),
                                                ('v0', v == 0), ('v1', v == lm['vc'] - 1)) if c}
                        if not lit and not (edges & dark_edges) and not m.against_wall(s, lm, u, v):
                            w = m.lumel_world(s, lm, u, v)
                            a = tuple(w[k] + nrm[k] for k in range(3))
                            if m.sees(a, L) and not old.sees(a, L):
                                data[b] |= 1 << (u & 7)
                                mark = '+'
                                n += 1
                        line += mark
                    grid.append(line)
                if n:
                    changed += n
                    print('superficie %d %s, luce %s: %d punti accesi (+)' % (si, s['tex'], name, n))
                    for line in grid:
                        print('    ' + line)
        if not dry:
            open(path, 'wb').write(bytes(data))
        print('punti accesi:', changed, '(prova, file non toccato)' if dry else '')


if __name__ == '__main__':
    main()
