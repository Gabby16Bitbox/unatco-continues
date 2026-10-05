"""Lettore minimo di pacchetti Unreal Engine 1 (Deus Ex, versione 68).

Serve per leggere offline conversazioni (.u) e attori delle mappe (.dx)
senza aprire il gioco o UnrealEd.

Uso:
  python ue1pkg.py <file> find <testo>          # export il cui nome contiene <testo>
  python ue1pkg.py <file> dump <NomeExport>     # proprieta' di un export
  python ue1pkg.py <file> conv <NomeConversazione>   # conversazione leggibile
  python ue1pkg.py <file> class <NomeClasse>    # tutti gli export di quella classe (riassunto)
"""
import struct
import sys

PROP_TYPES = {1: 'byte', 2: 'int', 3: 'bool', 4: 'float', 5: 'object', 6: 'name',
              7: 'string', 8: 'class', 9: 'array', 10: 'struct', 11: 'vector',
              12: 'rotator', 13: 'str', 14: 'map', 15: 'fixedarray'}


class Pkg:
    def __init__(self, path):
        self.d = open(path, 'rb').read()
        d = self.d
        (self.tag, ver, self.flags, nn, no, ne, eo, ni, io) = struct.unpack_from('<IIIIIIIII', d, 0)
        self.ver = ver & 0xFFFF
        self.names = []
        o = no
        for _ in range(nn):
            if self.ver >= 64:
                n, o = self.ci(o)
                s = d[o:o + n]
                o += n
            else:
                e = d.index(b'\0', o)
                s = d[o:e + 1]
                o = e + 1
            o += 4
            self.names.append(s.split(b'\0')[0].decode('latin1'))
        self.imports = []
        o = io
        for _ in range(ni):
            cp, o = self.ci(o)
            cn, o = self.ci(o)
            pkg = struct.unpack_from('<i', d, o)[0]
            o += 4
            on, o = self.ci(o)
            self.imports.append((self.names[cp], self.names[cn], pkg, self.names[on]))
        self.exports = []
        o = eo
        for _ in range(ne):
            cls, o = self.ci(o)
            sup, o = self.ci(o)
            pkg = struct.unpack_from('<i', d, o)[0]
            o += 4
            on, o = self.ci(o)
            fl = struct.unpack_from('<I', d, o)[0]
            o += 4
            size, o = self.ci(o)
            off = 0
            if size > 0:
                off, o = self.ci(o)
            self.exports.append({'class': cls, 'super': sup, 'pkg': pkg, 'name': self.names[on],
                                 'flags': fl, 'size': size, 'off': off})

    def ci(self, o):
        d = self.d
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

    def refname(self, r):
        if r > 0:
            return self.exports[r - 1]['name']
        if r < 0:
            return self.imports[-r - 1][3]
        return 'None'

    def classname(self, e):
        return self.refname(e['class']) if e['class'] else 'Class'

    def find_export(self, name, cls=None):
        for i, e in enumerate(self.exports):
            if e['name'] == name and (cls is None or self.classname(e) == cls):
                return i + 1
        return None

    def props(self, idx):
        """Ritorna lista di (nome, tipo, indice_array, valore)."""
        e = self.exports[idx - 1]
        d = self.d
        o = e['off']
        end = o + e['size']
        if e['flags'] & 0x02000000:  # RF_HasStack
            node, o = self.ci(o)
            _, o = self.ci(o)
            o += 8 + 4
            if node != 0:
                _, o = self.ci(o)
        out = []
        while o < end:
            ni, o = self.ci(o)
            name = self.names[ni]
            if name == 'None':
                break
            info = d[o]
            o += 1
            t = info & 0x0F
            si = (info >> 4) & 7
            arr = info & 0x80
            sname = None
            if t == 10:
                sn, o = self.ci(o)
                sname = self.names[sn]
            if si == 0: size = 1
            elif si == 1: size = 2
            elif si == 2: size = 4
            elif si == 3: size = 12
            elif si == 4: size = 16
            elif si == 5:
                size = d[o]; o += 1
            elif si == 6:
                size = struct.unpack_from('<H', d, o)[0]; o += 2
            else:
                size = struct.unpack_from('<I', d, o)[0]; o += 4
            aidx = 0
            if arr and t != 3:
                b = d[o]
                if b < 128:
                    aidx = b; o += 1
                elif (b & 0xC0) == 0x80:
                    aidx = struct.unpack_from('>H', d, o)[0] & 0x3FFF; o += 2
                else:
                    aidx = struct.unpack_from('>I', d, o)[0] & 0x3FFFFFFF; o += 4
            raw = d[o:o + size]
            o += size
            if t == 3:
                val = bool(arr)
            elif t == 1:
                val = raw[0] if raw else 0
            elif t == 2:
                val = struct.unpack('<i', raw)[0]
            elif t == 4:
                val = round(struct.unpack('<f', raw)[0], 3)
            elif t in (5, 8):
                r, _ = self.ci_bytes(raw)
                val = ('ref', r)
            elif t == 6:
                r, _ = self.ci_bytes(raw)
                val = self.names[r]
            elif t == 13:
                n, p = self.ci_bytes(raw)
                val = raw[p:p + n].split(b'\0')[0].decode('latin1')
            elif t == 10 and sname == 'Vector':
                val = tuple(round(x, 1) for x in struct.unpack('<fff', raw[:12]))
            elif t == 10 and sname == 'Rotator':
                val = struct.unpack('<iii', raw[:12])
            else:
                val = raw.hex()
            out.append((name, PROP_TYPES.get(t, t) if t != 10 else 'struct:' + str(sname), aidx, val))
        return out

    def ci_bytes(self, raw):
        save = self.d
        self.d = raw
        try:
            return self.ci(0)
        finally:
            self.d = save

    def pval(self, v):
        if isinstance(v, tuple) and len(v) == 2 and v[0] == 'ref':
            return self.refname(v[1])
        return v

    def get(self, idx, prop, default=None):
        prop = prop.lower()
        for (n, t, a, v) in self.props(idx):
            if n.lower() == prop:
                return v
        return default


def flagrefs(p, ref):
    out = []
    while isinstance(ref, tuple) and ref[1] > 0:
        idx = ref[1]
        name = p.get(idx, 'flagName', '?')
        val = p.get(idx, 'value', False)
        out.append('%s=%s' % (name, val))
        ref = p.get(idx, 'nextFlagRef', ('ref', 0))
    return out


def conv(p, name):
    idx = p.find_export(name, 'Conversation')
    if not idx:
        print('conversazione non trovata:', name)
        return
    print('=== Conversation', name)
    for (n, t, a, v) in p.props(idx):
        if n not in ('eventList', 'flagRefList'):
            print('  %s = %s' % (n, p.pval(v)))
    print('  REQUISITI:', flagrefs(p, p.get(idx, 'flagRefList', ('ref', 0))))
    ev = p.get(idx, 'eventList', ('ref', 0))
    i = 0
    while isinstance(ev, tuple) and ev[1] > 0 and i < 400:
        e = ev[1]
        cls = p.classname(p.exports[e - 1])
        pr = {n.lower(): v for (n, t, a, v) in p.props(e)}
        label = pr.get('label', '')
        desc = ''
        if cls == 'ConEventSpeech':
            sp = pr.get('conspeech')
            text = ''
            if isinstance(sp, tuple) and sp[1] > 0:
                text = p.get(sp[1], 'speech', '')
            desc = '%s -> %s: %s' % (pr.get('speakername', '?'), pr.get('speakingtoname', '?'), text)
        elif cls == 'ConEventSetFlag':
            desc = 'SET ' + ', '.join(flagrefs(p, pr.get('flagref', ('ref', 0))))
        elif cls == 'ConEventCheckFlag':
            desc = 'CHECK ' + ', '.join(flagrefs(p, pr.get('flagref', ('ref', 0)))) + ' -> ' + str(pr.get('setlabel', ''))
        elif cls == 'ConEventTrigger':
            desc = 'TRIGGER ' + str(pr.get('triggertag'))
        elif cls == 'ConEventJump':
            desc = 'JUMP %s %s' % (p.pval(pr.get('jumpcon', ('ref', 0))), pr.get('jumplabel', ''))
        elif cls == 'ConEventAddGoal':
            desc = 'GOAL %s %s %s' % (pr.get('goalname'), 'COMPLETED' if pr.get('bgoalcompleted') else '', pr.get('goaltext', ''))
        elif cls == 'ConEventChoice':
            ch = pr.get('choicelist', ('ref', 0))
            parts = []
            while isinstance(ch, tuple) and ch[1] > 0:
                cpr = {n.lower(): v for (n, t, a, v) in p.props(ch[1])}
                parts.append('[%s -> %s %s]' % (cpr.get('choicetext', ''), cpr.get('choicelabel', ''),
                                                 flagrefs(p, cpr.get('flagref', ('ref', 0)))))
                ch = cpr.get('nextchoice', ('ref', 0))
            desc = 'CHOICE ' + ' '.join(parts)
        else:
            desc = ', '.join('%s=%s' % (n, p.pval(v)) for n, v in pr.items()
                             if n not in ('nextevent', 'conversation', 'eventtype', 'label'))
        line = '  %-14s %-20s %s' % ('[' + label + ']' if label else '', cls.replace('ConEvent', ''), desc)
        print(line.encode('ascii', 'replace').decode())
        ev = pr.get('nextevent', ('ref', 0))
        i += 1


def main():
    path, cmd, arg = sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else ''
    p = Pkg(path)
    if cmd == 'find':
        for i, e in enumerate(p.exports):
            if arg.lower() in e['name'].lower():
                print(i + 1, p.classname(e), e['name'])
    elif cmd == 'dump':
        idx = p.find_export(arg)
        for (n, t, a, v) in p.props(idx):
            print('%s[%d] (%s) = %s' % (n, a, t, p.pval(v)))
    elif cmd == 'conv':
        conv(p, arg)
    elif cmd == 'class':
        keys = sys.argv[4].split(',') if len(sys.argv) > 4 else ['Tag', 'Event', 'Location', 'bHidden', 'BindName', 'Orders', 'OrderTag']
        for i, e in enumerate(p.exports):
            if p.classname(e) == arg:
                pr = p.props(i + 1)
                vals = {n: p.pval(v) for (n, t, a, v) in pr}
                print(i + 1, e['name'], {k: vals.get(k) for k in keys if k in vals})


if __name__ == '__main__':
    main()
