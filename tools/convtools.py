"""Ricerca nelle conversazioni di Revision (RevisionConversationsText.u).

Le esportazioni si chiamano ConversationNNN: il nome vero e' nella proprieta' conName.
  python convtools.py name <testo> [<testo>...]   conversazioni il cui conName contiene il testo
  python convtools.py dump <conName>              eventi/battute/flag di una conversazione (nome esatto)
  python convtools.py owner <BindName>            conversazioni di un personaggio (conOwnerName)
  python convtools.py text <testo>                battute che contengono il testo (con la conversazione)
Opzione --pkg=<file> per un altro pacchetto (default RevisionConversationsText.u del gioco).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ue1pkg import Pkg, conv  # noqa: E402

DEFAULT = r'C:\Program Files (x86)\Steam\steamapps\common\Deus Ex\Revision\System\RevisionConversationsText.u'


def conversations(p):
    for i, e in enumerate(p.exports):
        if p.classname(e) == 'Conversation':
            yield i + 1, e['name'], str(p.get(i + 1, 'conName', '')), str(p.get(i + 1, 'conOwnerName', ''))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--pkg=')]
    pkg = next((a[6:] for a in sys.argv[1:] if a.startswith('--pkg=')), DEFAULT)
    if len(args) < 2:
        print(__doc__)
        return
    cmd, what = args[0], args[1:]
    p = Pkg(pkg)
    if cmd == 'name':
        for idx, ex, cn, own in conversations(p):
            if any(w.lower() in cn.lower() for w in what):
                print(ex, cn, 'owner=' + own)
    elif cmd == 'dump':
        for idx, ex, cn, own in conversations(p):
            if cn.lower() == what[0].lower():
                conv(p, ex)
    elif cmd == 'owner':
        for idx, ex, cn, own in conversations(p):
            if own.lower() == what[0].lower():
                pr = {n: p.pval(v) for (n, t, a, v) in p.props(idx)}
                flags = {k: pr[k] for k in pr if k.startswith('b') or k == 'radiusDistance'}
                print(ex, cn, flags)
    elif cmd == 'text':
        needle = ' '.join(what).lower()
        for i, e in enumerate(p.exports):
            if p.classname(e) == 'ConSpeech':
                s = str(p.get(i + 1, 'speech', ''))
                if needle in s.lower():
                    print(e['name'], s[:200].encode('ascii', 'replace').decode())


if __name__ == '__main__':
    main()
