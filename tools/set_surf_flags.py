"""Cambia i PolyFlags delle superfici della geometria fissa (BSP) create da un brush.

Uso: python set_surf_flags.py <mappa.dx> <NomeBrush> <flag esadecimali> [nz]
     nz (facoltativo): solo le superfici con quella componente Z della normale (es. -1)

Modifica sul posto (4 byte per superficie, nessuno spostamento nel file): utile per
esempio per rendere "Unlit" (sempre luminosa, 0x00400000) una superficie, senza
ricalcolare le luci. Vale per tutte le partite (e' geometria della mappa).
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ue1pkg import Pkg            # noqa: E402
from bspsurf import props_end     # noqa: E402


def main():
    path, brush, flags = sys.argv[1], sys.argv[2], int(sys.argv[3], 16)
    nz = float(sys.argv[4]) if len(sys.argv) > 4 else None
    p = Pkg(path)
    d = bytearray(p.d)
    models = sorted(((e['size'], i + 1) for i, e in enumerate(p.exports) if p.classname(e) == 'Model'), reverse=True)
    idx = models[0][1]
    o = props_end(p, idx) + 25 + 16
    n, o = p.ci(o)
    vectors = [struct.unpack_from('<fff', d, o + 12 * i) for i in range(n)]
    o += 12 * n
    n, o = p.ci(o)
    o += 12 * n
    n, o = p.ci(o)
    for _ in range(n):
        o += 16 + 8 + 1
        for _k in range(7):
            _, o = p.ci(o)
        o += 1 + 1 + 1 + 8
    n, o = p.ci(o)
    changed = 0
    for _ in range(n):
        _tex, o = p.ci(o)
        flag_off = o
        old = struct.unpack_from('<I', d, o)[0]
        o += 4
        vals = []
        for _k in range(6):
            v, o = p.ci(o)
            vals.append(v)
        o += 4
        actor, o = p.ci(o)
        if p.refname(actor).lower() != brush.lower():
            continue
        if nz is not None and not (0 <= vals[1] < len(vectors) and abs(vectors[vals[1]][2] - nz) < 0.01):
            continue
        struct.pack_into('<I', d, flag_off, flags)
        print('%s: superficie %08x -> %08x' % (brush, old, flags))
        changed += 1
    if not changed:
        raise SystemExit('nessuna superficie di %s trovata' % brush)
    open(path, 'wb').write(d)


if __name__ == '__main__':
    main()
