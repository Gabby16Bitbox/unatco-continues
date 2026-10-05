"""Estrae TUTTI i dialoghi della mod dal codice (src\\UnatcoContinues\\Classes\\*.uc) e scrive
docs\\NARRATIVE_DESIGN.md: il documento di narrative design, con ogni conversazione, le sue
condizioni e le sue varianti, nell'ordine della storia.

Il codice e' la fonte: le conversazioni sono costruite con UCCon (c.Begin / c.Line / ...),
gli InfoLink con Say("Chi", "testo"). Questo script legge quelle chiamate; l'ordine, i
titoli e le note di regia stanno in tools\\narrative_manifest.py; l'introduzione scritta a
mano in docs\\narrative\\intro.md.

Uso:  python tools\\export_dialogues.py            (scrive docs\\NARRATIVE_DESIGN.md)
      python tools\\export_dialogues.py --list     (elenco grezzo: cosa c'e' nel codice)
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLASSES = os.path.join(ROOT, 'src', 'UnatcoContinues', 'Classes')
OUT = os.path.join(ROOT, 'docs', 'NARRATIVE_DESIGN.md')
INTRO = os.path.join(ROOT, 'docs', 'narrative', 'intro.md')
SKIP = ('UCCon.uc', 'UCDialogueCheckCommandlet.uc', 'UCVoiceCheckCommandlet.uc', 'UCRouteCheckCommandlet.uc',
        'UCVoiceIdentityCheck.uc', 'UCShotRunner.uc', 'UCTour.uc', 'UCHKCheck.uc', 'UCWalkOffCheck.uc')

STR = r'"((?:[^"\\]|\\.)*)"'
NAME = r"'([A-Za-z0-9_]+)'"


def unesc(s):
    return s.replace('\\"', '"').replace('\\\\', '\\')


class Conv:
    def __init__(self, name, owner, first_person, src, func, code_conds):
        self.name = name
        self.owner = owner
        self.first_person = first_person
        self.src = src
        self.func = func
        self.code_conds = code_conds      # condizioni del codice attorno a tutta la conversazione
        self.events = []                  # (tipo, dati, condizioni locali)
        self.once = False
        self.radius = None
        self.passive = False
        self.nofrob = False
        self.requires = []


def logical_lines(text):
    """Righe del sorgente senza commenti, con le istruzioni spezzate su piu' righe riunite."""
    out = []
    buf = ''
    indent = 0
    for raw in text.split('\n'):
        line = raw.rstrip()
        # via i commenti di fine riga (non dentro le stringhe)
        res = ''
        in_str = False
        i = 0
        while i < len(line):
            ch = line[i]
            if ch == '"' and (i == 0 or line[i - 1] != '\\'):
                in_str = not in_str
            if not in_str and line[i:i + 2] == '//':
                break
            res += ch
            i += 1
        line = res.rstrip()
        if not line.strip():
            continue
        if not buf:
            indent = len(line) - len(line.lstrip('\t'))
            buf = line.strip()
        else:
            buf += ' ' + line.strip()
        # istruzione completa: parentesi bilanciate
        depth = 0
        in_str = False
        for j, ch in enumerate(buf):
            if ch == '"' and (j == 0 or buf[j - 1] != '\\'):
                in_str = not in_str
            elif not in_str:
                depth += (ch == '(') - (ch == ')')
        if depth <= 0:
            out.append((indent, buf))
            buf = ''
    return out


def parse_file(path, known=None):
    """known: i frammenti (funzioni che ricevono un UCCon gia' aperto) trovati in una prima passata,
    cosi' si possono incollare anche se nel file sono definiti piu' in basso di chi li usa."""
    name = os.path.basename(path)
    text = open(path, encoding='latin-1').read()
    convs, says, helpers = [], [], {}
    stack = []            # (indent, testo della condizione)
    last_if = {}          # indent -> ultima condizione if a quell'indent (per gli else)
    func = ''
    cur = None
    base = 0
    helper = None         # funzione che riceve un UCCon gia' aperto: frammento da incollare
    case = None

    def local():
        return [c for (_, c) in stack[base:]] if len(stack) >= base else []

    for indent, line in logical_lines(text):
        if line in ('{', '}'):
            continue
        m = re.match(r'(?:static\s+)?(?:final\s+)?function\s+(?:[A-Za-z_<>]+\s+)?([A-Za-z0-9_]+)\s*\((.*)\)', line)
        if m and indent == 0:
            func = m.group(1)
            stack = []
            last_if = {}
            cur = None
            case = None
            helper = None
            if re.search(r'\bUCCon\s+c\b', m.group(2)):
                helper = func
                helpers[helper] = []
            continue
        if re.match(r'(auto\s+)?state\b', line) and indent == 0:
            func = line
            stack = []
            continue
        while stack and stack[-1][0] >= indent:
            stack.pop()
        m = re.match(r'(else\s+)?if\s*\((.*)\)\s*(.*)$', line)
        if m:
            cond = m.group(2)
            rest = m.group(3)
            # "if (x) istruzione;" sulla stessa riga: la condizione vale solo per quella
            depth = 0
            for j, ch in enumerate(m.group(2) + ')'):
                depth += (ch == '(') - (ch == ')')
            if m.group(1):
                cond = 'else if ' + cond
            if rest and not rest.startswith('{'):
                stack.append((indent, cond))
                handle = rest
                same_line = True
            else:
                stack.append((indent, cond))
                last_if[indent] = cond
                continue
            last_if[indent] = cond
        elif line == 'else' or line.startswith('else '):
            prev = last_if.get(indent, '?')
            stack.append((indent, 'OTHERWISE (not: %s)' % prev))
            if line == 'else':
                continue
            handle = line[5:]
            same_line = True
        else:
            handle = line
            same_line = False

        m = re.match(r'case\s+(\d+)\s*:\s*(.*)$', handle)
        if m:
            case = int(m.group(1))
            handle = m.group(2)
        ev = None
        m = re.search(r"\.Begin\(" + NAME + r",\s*" + STR + r",\s*(True|False)\)", handle)
        m2 = re.search(r"AnnaOpening\(" + NAME + r",\s*(\d),\s*(True|False)\)", handle)
        if m:
            helper = None     # la funzione apre lei la conversazione: non e' un frammento
            cur = Conv(m.group(1), m.group(2), m.group(3) == 'True', name, func, [c for (_, c) in stack])
            base = len(stack)
            convs.append(cur)
        elif m2 and 'function' not in handle:
            cur = Conv(m2.group(1), 'AnnaNavarre', False, name, func, [c for (_, c) in stack])
            base = len(stack)
            cur.once = True
            cur.radius = 200
            leb = int(m2.group(2))
            cur.requires.append(('UC_AnnaMetroOpened', False))
            cur.requires.append(('UC_AnnaPaulReportReceived', m2.group(3) == 'True'))
            cur.requires.append(('PlayerKilledLebedev', leb == 1))
            if leb != 1:
                cur.requires.append(('AnnaKilledLebedev', leb == 2))
            convs.append(cur)
        else:
            target = helpers[helper] if helper else (cur.events if cur else None)
            for pat, kind in (
                (r"\.Line\(\s*" + STR + r",\s*" + STR + r",\s*" + STR + r"\)", 'line'),
                (r"\.Line\(\s*" + STR + r",\s*([A-Za-z_]+),\s*" + STR + r"\)", 'line'),
                (r"\.Line\(\s*([A-Za-z_.]+),\s*" + STR + r",\s*([A-Za-z_]+)\)", 'dynline'),
                (r"\.Choice\(\s*" + STR + r",\s*" + STR + r",\s*" + STR + r",\s*" + STR + r"\)", 'choice'),
                (r"\.Label\(\s*" + STR + r"\)", 'label'),
                (r"\.Jump\(\s*" + STR + r"\)", 'jump'),
                (r"\.IfFlag\(\s*" + NAME + r",\s*(True|False),\s*" + STR + r"\)", 'ifflag'),
                (r"\.EndHere\(\)", 'end'),
                (r"\.SetFlag\(\s*" + NAME + r",\s*(True|False)\)", 'setflag'),
                (r"\.Goal\(\s*" + NAME + r",\s*" + STR, 'goal'),
                (r"\.Trigger\(\s*" + NAME + r"\)", 'trigger'),
            ):
                m = re.search(r'\bc' + pat, handle)
                if m and target is not None:
                    ev = (kind, tuple(unesc(g) for g in m.groups()), local() if not helper else [])
                    target.append(ev)
                    break
            if ev is None and cur is not None and not helper:
                m = re.search(r"\bc\.Require\(\s*" + NAME + r",\s*(True|False)\)", handle)
                if m:
                    cur.requires.append((m.group(1), m.group(2) == 'True'))
                elif re.search(r'\bc\.Once\(\)', handle):
                    cur.once = True
                elif re.search(r'\bc\.Passive\(\)', handle):
                    cur.passive = True
                elif re.search(r'\bc\.NoFrob\(\)', handle):
                    cur.nofrob = True
                else:
                    m = re.search(r'\bc\.Radius\((\d+)\)', handle)
                    if m:
                        cur.radius = int(m.group(1))
                    else:
                        m = re.match(r'(?:[A-Za-z_.\']+\.)?([A-Za-z0-9_]+)\(c\);', handle)
                        if m and m.group(1) in (known or helpers):
                            for (k, d, _) in (known or helpers)[m.group(1)]:
                                cur.events.append((k, d, local()))
                        elif re.search(r'AnnaOpeningDone\(c', handle):
                            cur.events.append(('setflag', ('UC_AnnaMetroOpened', 'True'), local()))
            # InfoLink
            for m in re.finditer(r'\bSay\(\s*' + STR + r',\s*' + STR + r'\)', handle):
                says.append((name, func, case, m.group(1), unesc(m.group(2)), [c for (_, c) in stack]))
        if same_line:
            stack.pop()
    return convs, says, helpers


def load():
    convs, says = [], []
    for f in sorted(glob.glob(os.path.join(CLASSES, '*.uc'))):
        if os.path.basename(f) in SKIP or os.path.basename(f).startswith('UCDbg'):
            continue
        _, _, known = parse_file(f)
        c, s, _ = parse_file(f, known)
        convs += c
        says += s
    return convs, says


def main():
    convs, says = load()
    if '--list' in sys.argv:
        for c in convs:
            first = next((d for (k, d, _) in c.events if k == 'line'), ('', '', ''))
            print('%-22s %-20s %-18s %s%s | %s' % (c.name, c.src[:-3], c.owner, 'P' if c.passive else '-',
                                                 '1' if c.once else '-', first[2][:60]))
            if c.code_conds:
                print('      code:', ' && '.join(c.code_conds)[:150])
        print()
        for s in says:
            print('SAY %-24s %-12s %s %-14s %s | %s' % (s[0][:-3], s[1][:12], s[2], s[3], s[4][:50], ' && '.join(s[5])[:60]))
        print(len(convs), 'conversazioni,', len(says), 'battute InfoLink')
        return
    import narrative_manifest
    narrative_manifest.write(convs, says, INTRO, OUT)


if __name__ == '__main__':
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    main()
