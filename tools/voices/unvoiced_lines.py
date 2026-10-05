"""Battute della mod che non hanno ancora una voce registrata.

Confronta le battute nel codice (c.Line / Say / battute dei soldati) con quelle che il
controllo delle voci conosce (UCVoiceCheckCommandlet.uc: una riga Check(...) per ogni
battuta doppiata) e stampa quelle senza voce: personaggio, file, testo.

Uso: python tools\\voices\\unvoiced_lines.py [file_di_uscita.tsv]
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CLASSES = os.path.join(ROOT, 'src', 'UnatcoContinues', 'Classes')
STR = r'"((?:[^"\\]|\\.)*)"'


def main():
    vc = open(os.path.join(CLASSES, 'UCVoiceCheckCommandlet.uc'), encoding='latin-1').read()
    voiced = {m.group(2) for m in re.finditer(r'Check\(\d+,\s*' + STR + r',\s*' + STR, vc)}
    rows = []
    for f in sorted(glob.glob(os.path.join(CLASSES, '*.uc'))):
        name = os.path.basename(f)
        if name in ('UCVoiceCheckCommandlet.uc', 'UCDialogueCheckCommandlet.uc', 'UCVoiceIdentityCheck.uc'):
            continue
        t = open(f, encoding='latin-1').read()
        for m in re.finditer(r'\.Line\(\s*' + STR + r',\s*(?:"[^"]*"|\w+),\s*' + STR + r'\)', t):
            rows.append((name, m.group(1), m.group(2)))
        for m in re.finditer(r'Say\(\s*' + STR + r',\s*' + STR + r'\)', t):
            rows.append((name, m.group(1), m.group(2)))
        if name == 'UCMod.uc':
            body = t[t.index('function string BarkLine'):t.index('function BarkTick')]
            for m in re.finditer(r'return ' + STR + ';', body):
                if m.group(1):
                    rows.append((name, 'UNATCOTroop', m.group(1)))
    seen = set()
    missing = []
    for name, speaker, text in rows:
        if (speaker, text) in seen:
            continue
        seen.add((speaker, text))
        if text not in voiced:
            missing.append((speaker, name, text))
    out = sys.argv[1] if len(sys.argv) > 1 else None
    lines = ['%s\t%s\t%s' % m for m in sorted(missing)]
    if out:
        open(out, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    else:
        print('\n'.join(lines))
    print('battute nel codice: %d, con voce: %d, senza voce: %d' % (len(seen), len(seen) - len(missing), len(missing)), file=sys.stderr)


if __name__ == '__main__':
    main()
