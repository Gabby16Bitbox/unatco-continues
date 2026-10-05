"""Imposta proprieta' bool/float di un attore in una mappa UE1 (.dx) gia' salvata, senza editor.

Uso: python set_actor_props.py <mappa.dx> <NomeAttore> Prop=Valore [Prop=Valore ...]
     (Valore: True/False per i bool, un numero per i float, (x,y,z) per i vettori)

Gli attori (es. i mover) sono salvati come sola lista di proprieta': i dati dell'attore
vengono riscritti in fondo al file con le nuove proprieta' (quelle con lo stesso nome
vengono tolte), la tabella degli export riscritta in fondo e l'intestazione aggiornata.
I nomi delle proprieta' devono gia' esistere nella tabella dei nomi (in una mappa ci sono).
Stessa tecnica di set_texture_prop.py (che in piu' sistema le mip delle texture).
"""
import struct
import sys

sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
from set_texture_prop import read_ci, write_ci   # noqa: E402


def main():
    path, actor = sys.argv[1], sys.argv[2]
    wanted = []
    for arg in sys.argv[3:]:
        k, v = arg.split('=', 1)
        if v.lower() in ('true', 'false'):
            wanted.append((k, 'bool', v.lower() == 'true'))
        elif v.startswith('('):
            wanted.append((k, 'vector', tuple(float(x) for x in v.strip('()').split(','))))
        else:
            wanted.append((k, 'float', float(v)))
    d = bytearray(open(path, 'rb').read())
    tag, ver, flags, name_count, name_off, exp_count, exp_off, imp_count, imp_off = struct.unpack_from('<9I', d, 0)
    ver &= 0xFFFF
    names = []
    o = name_off
    for _ in range(name_count):
        if ver >= 64:
            n, o = read_ci(d, o)
            s = bytes(d[o:o + n])
            o += n
        else:
            e = d.index(b'\0', o)
            s = bytes(d[o:e + 1])
            o = e + 1
        o += 4
        names.append(s.split(b'\0')[0].decode('latin1'))
    low = [n.lower() for n in names]
    exports = []
    o = exp_off
    for _ in range(exp_count):
        cls, o = read_ci(d, o)
        sup, o = read_ci(d, o)
        pkg = struct.unpack_from('<i', d, o)[0]
        o += 4
        on, o = read_ci(d, o)
        fl = struct.unpack_from('<I', d, o)[0]
        o += 4
        size, o = read_ci(d, o)
        off = 0
        if size > 0:
            off, o = read_ci(d, o)
        exports.append([cls, sup, pkg, on, fl, size, off])
    idx = [i for i, e in enumerate(exports) if names[e[3]].lower() == actor.lower()]
    if len(idx) != 1:
        raise SystemExit('attore %s: trovati %d' % (actor, len(idx)))
    e = exports[idx[0]]
    data = bytes(d[e[6]:e[6] + e[5]])
    # attori con stato salvato (RF_HasStack, es. i mover): Node, StateNode, ProbeMask,
    # LatentAction e (se Node) Offset prima delle proprieta': si copiano come sono
    o = 0
    if e[4] & 0x02000000:
        node, o = read_ci(data, o)
        _, o = read_ci(data, o)
        o += 8 + 4
        if node != 0:
            _, o = read_ci(data, o)
    prefix = data[:o]
    drop = set()
    for k, _t, _v in wanted:
        if k.lower() not in low:
            raise SystemExit('nome %s non presente nella mappa' % k)
        drop.add(low.index(k.lower()))
    keep = bytearray()
    while True:
        ps = o
        ni, o = read_ci(data, o)
        if names[ni] == 'None':
            none_tag = data[ps:o]
            break
        info = data[o]
        o += 1
        t, si, arr = info & 0x0F, (info >> 4) & 7, info & 0x80
        if t == 10:
            _, o = read_ci(data, o)
        sz = {0: 1, 1: 2, 2: 4, 3: 12, 4: 16}.get(si)
        if si == 5:
            sz = data[o]; o += 1
        elif si == 6:
            sz = struct.unpack_from('<H', data, o)[0]; o += 2
        elif si == 7:
            sz = struct.unpack_from('<I', data, o)[0]; o += 4
        if arr and t != 3:
            b = data[o]
            o += 1 if b < 128 else (2 if (b & 0xC0) == 0x80 else 4)
        if t == 3:
            sz = 0
        o += sz
        if ni not in drop:
            keep += data[ps:o]
    if o != len(data):
        raise SystemExit('dati dopo le proprieta' + "'" + ' (%d byte): non gestito' % (len(data) - o))
    new = bytearray()
    for k, t, v in wanted:
        ni = low.index(k.lower())
        if t == 'vector':
            # struct Vector, 12 byte: tag tipo 10 (struct), dimensione codice 3, nome della struct
            new += write_ci(ni) + bytes([0x3A]) + write_ci(low.index('vector')) + struct.pack('<fff', *v)
        elif t == 'bool':
            # come li scrive l'editor: tipo bool, dimensione "1 byte che segue" = 0, valore nel bit alto
            new += write_ci(ni) + bytes([0x53 | (0x80 if v else 0), 0x00])
        else:
            new += write_ci(ni) + bytes([0x24]) + struct.pack('<f', v)
    new_data = bytes(prefix) + bytes(new) + bytes(keep) + none_tag
    e[5], e[6] = len(new_data), len(d)
    d += new_data
    exp_off = len(d)
    for (cls, sup, pkg, on, fl, size, off) in exports:
        d += write_ci(cls) + write_ci(sup) + struct.pack('<i', pkg) + write_ci(on) + struct.pack('<I', fl) + write_ci(size)
        if size > 0:
            d += write_ci(off)
    struct.pack_into('<9I', d, 0, tag, struct.unpack_from('<I', d, 4)[0], flags, name_count, name_off, exp_count, exp_off, imp_count, imp_off)
    open(path, 'wb').write(d)
    print('%s: %s %s' % (path, actor, ' '.join(sys.argv[3:])))


if __name__ == '__main__':
    main()
