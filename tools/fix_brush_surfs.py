"""Ricostruisce le superfici (Surfs) del brush di un mover partendo dai suoi poligoni.

Uso: python fix_brush_surfs.py <mappa.dx> <NomeModello> [prova]
     (es. UCMdlUCWallSud0: il nome del Brush del mover)

Perche': importando un mover da T3D l'editor dell'SDK ha costruito il BSP del brush
mescolando le superfici (facce opposte con la stessa superficie, texture perse): la
faccia visibile prende la normale della faccia nascosta, quindi la luce la tratta come
girata dall'altra parte (scura, la torcia non la illumina) e le texture sbagliano.
I poligoni originali (UPolys del brush) sono giusti: qui ogni nodo del BSP riceve la
superficie del poligono a cui appartiene (stessa texture, normale, assi e pan).
Il modello viene riscritto in fondo al file (tabella export aggiornata).
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ue1pkg import Pkg                              # noqa: E402
from bspsurf import props_end                       # noqa: E402
from set_texture_prop import write_ci                # noqa: E402


def read_polys(p, idx):
    d = p.d
    e = p.exports[idx - 1]
    o = props_end(p, idx)
    num, _mx = struct.unpack_from('<ii', d, o)
    o += 8
    polys = []
    for _ in range(num):
        nv, o = p.ci(o)
        base_at = o
        base, nrm, tu, tv = [struct.unpack_from('<fff', d, o + 12 * i) for i in range(4)]
        o += 48
        verts = [struct.unpack_from('<fff', d, o + 12 * i) for i in range(nv)]
        o += 12 * nv
        flags = struct.unpack_from('<I', d, o)[0]
        o += 4
        actor, o = p.ci(o)
        tex, o = p.ci(o)
        _item, o = p.ci(o)
        _link, o = p.ci(o)
        _bpoly, o = p.ci(o)
        pan = struct.unpack_from('<hh', d, o)
        o += 4
        # il motore usa Base anche come punto del piano: se l'origine della texture e' fuori
        # dal piano, il piano del nodo viene sbagliato. Spostarla lungo la normale non
        # cambia le coordinate della texture (U e V stanno nel piano)
        w = sum(verts[0][i] * nrm[i] for i in range(3))
        k = sum(base[i] * nrm[i] for i in range(3)) - w
        on_plane = tuple(base[i] - k * nrm[i] for i in range(3))
        polys.append({'base': on_plane, 'base_at': base_at, 'moved': abs(k) > 0.01, 'normal': nrm, 'w': w,
                      'u': tu, 'v': tv, 'verts': verts, 'flags': flags, 'tex': tex, 'pan': pan})
    if o != e['off'] + e['size']:
        raise SystemExit('lettura dei poligoni non allineata')
    return polys


def close(a, b, eps=0.01):
    return all(abs(a[i] - b[i]) < eps for i in range(len(a)))


def main():
    path, name = sys.argv[1], sys.argv[2]
    dry = len(sys.argv) > 3 and sys.argv[3] == 'prova'
    p = Pkg(path)
    d = p.d
    idx = p.find_export(name, 'Model')
    if not idx:
        raise SystemExit('modello %s non trovato' % name)
    e = p.exports[idx - 1]
    end = e['off'] + e['size']
    head = props_end(p, idx) + 25 + 16              # proprieta', BoundingBox, BoundingSphere
    o = head
    n, o = p.ci(o)
    vectors = [struct.unpack_from('<fff', d, o + 12 * i) for i in range(n)]
    o += 12 * n
    n, o = p.ci(o)
    points = [struct.unpack_from('<fff', d, o + 12 * i) for i in range(n)]
    o += 12 * n
    n, o = p.ci(o)
    nodes = []
    for _ in range(n):
        raw_a = d[o:o + 25]                         # Plane, ZoneMask, NodeFlags
        o += 25
        f = []
        for _k in range(7):                         # iVertPool iSurf iBack iFront iPlane iCollisionBound iRenderBound
            v, o = p.ci(o)
            f.append(v)
        raw_b = d[o:o + 11]                         # iZone[2], NumVertices, iLeaf[2]
        o += 11
        nodes.append({'plane': struct.unpack_from('<ffff', raw_a, 0), 'a': raw_a, 'f': f, 'b': raw_b, 'nv': raw_b[2]})
    n, o = p.ci(o)
    surfs = []
    for _ in range(n):
        tex, o = p.ci(o)
        flags = struct.unpack_from('<I', d, o)[0]
        o += 4
        vals = []
        for _k in range(6):
            v, o = p.ci(o)
            vals.append(v)
        pan = struct.unpack_from('<hh', d, o)
        o += 4
        actor, o = p.ci(o)
        surfs.append({'tex': tex, 'flags': flags, 'vals': vals, 'pan': pan, 'actor': actor})
    rest = o
    # Verts (per i vertici dei nodi) e riferimento ai poligoni
    n, o = p.ci(o)
    verts = []
    for _ in range(n):
        pv, o = p.ci(o)
        _, o = p.ci(o)
        verts.append(pv)
    o += 4
    nz = struct.unpack_from('<i', d, o)[0]
    o += 4
    for _ in range(nz):
        _, o = p.ci(o)
        o += 16
    polys_ref, o = p.ci(o)
    polys = read_polys(p, polys_ref)

    actor_ref = surfs[0]['actor'] if surfs else 0

    def vec_index(v):
        for i, w in enumerate(vectors):
            if close(v, w, 1e-4):
                return i
        vectors.append(tuple(v))
        return len(vectors) - 1

    def point_index(v):
        for i, w in enumerate(points):
            if close(v, w, 1e-3):
                return i
        points.append(tuple(v))
        return len(points) - 1

    new_surfs = []
    for k, pl in enumerate(polys):
        new_surfs.append({'tex': pl['tex'], 'flags': pl['flags'],
                          'vals': [point_index(pl['base']), vec_index(pl['normal']), vec_index(pl['u']),
                                   vec_index(pl['v']), -1, -1],
                          'pan': pl['pan'], 'actor': actor_ref})
    for ni, nd in enumerate(nodes):
        pv = [points[verts[nd['f'][0] + k]] for k in range(nd['nv'])]
        # verso vero della faccia: dall'ordine dei vertici (il piano salvato puo' essere sbagliato)
        a = [pv[1][i] - pv[0][i] for i in range(3)]
        b = [pv[2][i] - pv[0][i] for i in range(3)]
        c = (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
        ln = sum(x * x for x in c) ** 0.5 or 1.0
        facing = tuple(x / ln for x in c)
        best = None
        for k, pl in enumerate(polys):
            if sum(facing[i] * pl['normal'][i] for i in range(3)) < 0.99:
                continue
            if any(abs(sum(q[i] * pl['normal'][i] for i in range(3)) - pl['w']) > 0.1 for q in pv):
                continue
            lo = [min(v[i] for v in pl['verts']) - 0.1 for i in range(3)]
            hi = [max(v[i] for v in pl['verts']) + 0.1 for i in range(3)]
            if all(lo[i] <= q[i] <= hi[i] for q in pv for i in range(3)):
                best = k
                break
        if best is None:
            raise SystemExit('nodo %d: nessun poligono corrispondente' % ni)
        old = surfs[nd['f'][1]]
        pl = polys[best]
        plane = tuple(pl['normal']) + (pl['w'],)
        print('nodo %d: superficie %d (%s, normale %s) -> poligono %d (%s, normale %s)%s' % (
            ni, nd['f'][1], p.refname(old['tex']), tuple(round(x, 2) for x in vectors[old['vals'][1]]),
            best, p.refname(pl['tex']), tuple(round(x, 2) for x in pl['normal']),
            '' if close(plane, nd['plane']) else ', piano %s -> %s' % (
                tuple(round(x, 2) for x in nd['plane']), tuple(round(x, 2) for x in plane))))
        nd['f'][1] = best
        nd['a'] = struct.pack('<ffff', *plane) + nd['a'][16:]
    # albero BSP rifatto per un solido convesso (il vecchio era costruito sui piani sbagliati):
    # catena sul lato "dietro" (dentro il solido), davanti = fuori; le facce sullo stesso
    # piano stanno nella lista dei complanari del primo nodo. Senza limiti di collisione
    # (gli indici vecchi puntano a scafi calcolati sui piani sbagliati).
    def plane_of(ni):
        return struct.unpack_from('<ffff', nodes[ni]['a'], 0)
    for nd in nodes:
        nd['f'][2:7] = [-1, -1, -1, -1, -1]          # iBack iFront iPlane iCollisionBound iRenderBound
    primaries = []
    for ni in range(len(nodes)):
        same = [pi for pi in primaries if close(plane_of(ni), plane_of(pi))]
        if same:
            last = same[0]
            while nodes[last]['f'][4] >= 0:
                last = nodes[last]['f'][4]
            nodes[last]['f'][4] = ni
        else:
            primaries.append(ni)
    for a, b in zip(primaries, primaries[1:]):
        nodes[a]['f'][2] = b
    # convesso: tutti i vertici dietro (o sopra) ogni piano
    for pi in primaries:
        pl = plane_of(pi)
        if any(sum(points[v][i] * pl[i] for i in range(3)) - pl[3] > 0.1 for v in verts):
            raise SystemExit('il brush non e' + "'" + ' convesso: albero non ricostruibile con questo strumento')
    for ni, nd in enumerate(nodes):
        print('  nodo %d: dietro %d, davanti %d, complanare %d' % (ni, nd['f'][2], nd['f'][3], nd['f'][4]))
    if dry:
        print('prova: file non toccato')
        return

    out = bytearray(d[e['off']:head])
    out += write_ci(len(vectors)) + b''.join(struct.pack('<fff', *v) for v in vectors)
    out += write_ci(len(points)) + b''.join(struct.pack('<fff', *v) for v in points)
    out += write_ci(len(nodes))
    for nd in nodes:
        out += nd['a'] + b''.join(write_ci(v) for v in nd['f']) + nd['b']
    out += write_ci(len(new_surfs))
    for s in new_surfs:
        out += write_ci(s['tex']) + struct.pack('<I', s['flags']) + b''.join(write_ci(v) for v in s['vals'])
        out += struct.pack('<hh', *s['pan']) + write_ci(s['actor'])
    out += d[rest:end]

    # export riscritto in fondo, poi la tabella degli export (come set_actor_props.py)
    data = bytearray(d)
    for pl in polys:
        if pl['moved']:
            struct.pack_into('<fff', data, pl['base_at'], *pl['base'])
    tag, ver, flags, name_count, name_off, exp_count, exp_off, imp_count, imp_off = struct.unpack_from('<9I', data, 0)
    new_off = len(data)
    data += out
    table = bytearray()
    name_idx = export_name_indices(p)
    for i, x in enumerate(p.exports):
        size, off = (len(out), new_off) if i == idx - 1 else (x['size'], x['off'])
        table += write_ci(x['class']) + write_ci(x['super']) + struct.pack('<i', x['pkg'])
        table += write_ci(name_idx[i]) + struct.pack('<I', x['flags'])
        table += write_ci(size)
        if size > 0:
            table += write_ci(off)
    exp_off = len(data)
    data += table
    struct.pack_into('<9I', data, 0, tag, ver, flags, name_count, name_off, exp_count, exp_off, imp_count, imp_off)
    open(path, 'wb').write(bytes(data))
    print('%s: %s riscritto (%d superfici, %d vettori, %d punti)' % (path, name, len(new_surfs), len(vectors), len(points)))


def export_name_indices(p):
    """Indice nella tabella dei nomi del nome di ogni export (Pkg tiene solo il testo)."""
    d = p.d
    o = struct.unpack_from('<I', d, 24)[0]           # ExportOffset
    out = []
    for _ in p.exports:
        _, o = p.ci(o)
        _, o = p.ci(o)
        o += 4
        on, o = p.ci(o)
        o += 4
        size, o = p.ci(o)
        if size > 0:
            _, o = p.ci(o)
        out.append(on)
    return out


if __name__ == '__main__':
    main()
