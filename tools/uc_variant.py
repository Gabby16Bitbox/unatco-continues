"""One UnrealScript source for both games: the lines only one game can compile, between markers.

    //#if revision          (lines for Deus Ex: Revision only: its classes, properties, functions)
    ...
    //#else                 (optional: the original game's lines, commented out with a leading //)
    //  ...
    //#endif

    //#if vanilla           (lines for the original Deus Ex only, commented out with a leading //)
    //  ...
    //#endif

Revision's compiler reads the file as it is: the markers and the vanilla lines are comments. For the original
game (tools\\build_vanilla.ps1) this script writes the vanilla version: a revision block's lines dropped, its
else part and a vanilla block's lines uncommented (the leading // and one space or tab after it removed).
Lines keep their count (dropped lines become empty), so the compiler's line numbers still point at the source.

    python tools\\uc_variant.py vanilla <in.uc> <out.uc>      # exit 0; 2 when the markers do not pair
    python tools\\uc_variant.py check <folder of .uc>          # every file's markers pair
"""
import re
import sys
from pathlib import Path

MARK = re.compile(r'^\s*//#(if\s+(revision|vanilla)|else|endif)\b', re.I)


def variant(text, name='?'):
    """The original game's version of a source."""
    out, stack = [], []          # stack: [block ('revision' | 'vanilla'), in its else part]
    for n, line in enumerate(text.split('\n'), 1):
        cr = '\r' if line.endswith('\r') else ''
        m = MARK.match(line)
        if m:
            word = m.group(1).lower()
            if word.startswith('if'):
                if stack:
                    raise ValueError('%s(%d): nested //#if' % (name, n))
                stack.append([m.group(2).lower(), False])
            elif word == 'else':
                if not stack or stack[-1][1] or stack[-1][0] != 'revision':
                    raise ValueError('%s(%d): //#else only once, in a //#if revision block' % (name, n))
                stack[-1][1] = True
            else:
                if not stack:
                    raise ValueError('%s(%d): //#endif without //#if' % (name, n))
                stack.pop()
            out.append(cr)
            continue
        if not stack:
            out.append(line)
        elif stack[-1][0] == 'revision' and not stack[-1][1]:
            out.append(cr)
        else:
            out.append(re.sub(r'^(\s*)//[ \t]?', r'\1', line, count=1))
    if stack:
        raise ValueError('%s: //#if without //#endif' % name)
    return '\n'.join(out)


def main(argv):
    if argv[:1] == ['vanilla'] and len(argv) == 3:
        src = Path(argv[1])
        try:
            text = variant(src.read_text(encoding='latin1'), src.name)
        except ValueError as e:
            print(e)
            return 2
        Path(argv[2]).write_text(text, encoding='latin1', newline='')
        return 0
    if argv[:1] == ['check'] and len(argv) == 2:
        bad = 0
        for f in sorted(Path(argv[1]).glob('*.uc')):
            try:
                variant(f.read_text(encoding='latin1'), f.name)
            except ValueError as e:
                print(e)
                bad += 1
        return 2 if bad else 0
    print(__doc__)
    return 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
