"""Scrive una proprieta' float (es. DrawScale) in una texture di un pacchetto UE1 gia' compilato.

Serve perche' "#exec TEXTURE IMPORT" del nostro ucc non ha l'opzione DrawScale, e in
UnrealScript DrawScale e' const (non si puo' cambiare nemmeno con SetPropertyText).
Revision usa DrawScale per le sue texture HD (es. 1024x1024 con 0.125 = mappata come 128).

Uso: python set_texture_prop.py <pacchetto.u> <NomeTexture> <Proprieta'> <valore>

Come funziona: i dati della texture vengono riscritti in fondo al file con la nuova
proprieta' in testa alla lista; gli offset assoluti delle mip (lazy array) vengono
ricalcolati; la tabella degli export (e dei nomi, se serve un nome nuovo) viene riscritta
in fondo e l'intestazione punta alle nuove tabelle. I vecchi dati restano nel file, inutilizzati.
"""
import struct
import sys


def read_ci(d, o):
    b = d[o]
    o += 1
    neg = b & 0x80
    v = b & 0x3F
    if b & 0x40:
        sh = 6
        while True:
            b = d[o]
            o += 1
            v |= (b & 0x7F) << sh
            sh += 7
            if not (b & 0x80):
                break
    return (-v if neg else v), o


def write_ci(v):
    out = bytearray()
    neg = v < 0
    v = abs(v)
    b0 = (0x80 if neg else 0) | (v & 0x3F)
    v >>= 6
    if v:
        b0 |= 0x40
    out.append(b0)
    while v:
        b = v & 0x7F
        v >>= 7
        if v:
            b |= 0x80
        out.append(b)
    return bytes(out)


def main():
    path, tex_name, prop_name, value = sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4])
    d = bytearray(open(path, 'rb').read())
    tag, ver, flags, name_count, name_off, exp_count, exp_off, imp_count, imp_off = struct.unpack_from('<9I', d, 0)
    if tag != 0x9E2A83C1:
        raise SystemExit('non e\' un pacchetto Unreal')
    ver &= 0xFFFF
    gen_pos = None
    if ver >= 68:
        gen_count = struct.unpack_from('<I', d, 36 + 16)[0]
        gen_pos = 36 + 16 + 4 + (gen_count - 1) * 8   # ultima generazione (ExportCount, NameCount)

    # nomi
    names, name_entries = [], []
    o = name_off
    for _ in range(name_count):
        start = o
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
        name_entries.append(bytes(d[start:o]))

    def name_index(n):
        for i, s in enumerate(names):
            if s.lower() == n.lower():
                return i
        return -1

    # export
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

    imports = []
    o = imp_off
    for _ in range(imp_count):
        cp, o = read_ci(d, o)
        cn, o = read_ci(d, o)
        pk = struct.unpack_from('<i', d, o)[0]
        o += 4
        on, o = read_ci(d, o)
        imports.append((names[cp], names[cn], pk, names[on]))

    def classname(e):
        r = e[0]
        if r > 0:
            return names[exports[r - 1][3]]
        if r < 0:
            return imports[-r - 1][3]
        return 'Class'

    idx = None
    for i, e in enumerate(exports):
        if names[e[3]].lower() == tex_name.lower() and classname(e) == 'Texture':
            idx = i
    if idx is None:
        raise SystemExit('texture %s non trovata' % tex_name)
    e = exports[idx]
    start, size = e[6], e[5]
    data = bytes(d[start:start + size])

    # nome della proprieta' (aggiunto se manca)
    new_names = False
    pi = name_index(prop_name)
    if pi < 0:
        pi = len(names)
        names.append(prop_name)
        enc = prop_name.encode('latin1') + b'\0'
        name_entries.append(write_ci(len(enc)) + enc + struct.pack('<I', 0x00070010))
        new_names = True

    # proprieta' esistenti: si salta fino a "None" (e si toglie la proprieta' se c'era gia')
    o = 0
    props = bytearray()
    while True:
        ps = o
        ni, o = read_ci(data, o)
        if names[ni] == 'None':
            break
        info = data[o]
        o += 1
        t = info & 0x0F
        si = (info >> 4) & 7
        arr = info & 0x80
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
        o += sz
        if ni != pi:
            props += data[ps:o]
    none_end = o
    rest = data[none_end:]
    none_tag = data[none_end - len(write_ci(name_index('None'))):none_end]

    new_prop = write_ci(pi) + bytes([0x24]) + struct.pack('<f', value)   # float, 4 byte
    head = bytes(new_prop) + bytes(props) + none_tag
    new_start = len(d)

    # mip: gli offset assoluti di fine dati vanno ricalcolati per la nuova posizione
    rest = bytearray(rest)
    ro = 0
    for _mipset in range(1):
        n, ro = read_ci(rest, ro)
        for _ in range(n):
            pos = ro
            ro += 4
            cnt, ro = read_ci(rest, ro)
            ro += cnt
            struct.pack_into('<i', rest, pos, new_start + len(head) + ro)
            ro += 10
    new_data = head + bytes(rest)

    d += new_data
    e[5], e[6] = len(new_data), new_start

    # nomi nuovi: tabella riscritta in fondo
    if new_names:
        name_off = len(d)
        for ent in name_entries:
            d += ent
        name_count = len(name_entries)
        if gen_pos is not None:
            struct.pack_into('<I', d, gen_pos + 4, name_count)

    exp_off = len(d)
    for (cls, sup, pkg, on, fl, size, off) in exports:
        d += write_ci(cls) + write_ci(sup) + struct.pack('<i', pkg) + write_ci(on) + struct.pack('<I', fl) + write_ci(size)
        if size > 0:
            d += write_ci(off)
    struct.pack_into('<9I', d, 0, tag, struct.unpack_from('<I', d, 4)[0], flags, name_count, name_off, exp_count, exp_off, imp_count, imp_off)
    open(path, 'wb').write(d)
    print('%s: %s.%s = %g' % (path, tex_name, prop_name, value))


if __name__ == '__main__':
    main()
