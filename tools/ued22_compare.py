"""A map before and after a round trip through UnrealEd 2.2: package version, objects and saved
properties compared, then both loaded in the Deus Ex engine (our host) and their actors counted."""
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(r'C:\Users\gab4y\Desktop\Deus Ex\UnatcoContinues')
sys.path.insert(0, str(ROOT / 'tools' / 'editor_bridge'))
sys.path.insert(0, str(ROOT / 'tools' / 'mapkit'))
from inspect_map import inspect  # noqa: E402
import kit  # noqa: E402

a_path, b_path = Path(sys.argv[1]), Path(sys.argv[2])
A, B = inspect(a_path), inspect(b_path)
print('package version', A['package_version'], '->', B['package_version'],
      '| exports', A['export_count'], '->', B['export_count'], '| parse errors', len(A['parse_errors']), len(B['parse_errors']))
oa = {o['name']: o for o in A['objects']}
ob = {o['name']: o for o in B['objects']}
print('objects only before:', len(set(oa) - set(ob)), sorted(set(oa) - set(ob))[:15])
print('objects only after: ', len(set(ob) - set(oa)), sorted(set(ob) - set(oa))[:15])
lost, added, changed = Counter(), Counter(), Counter()
examples = {}


def key(p):
    return (p['name'], p['array_index'])


def same(x, y):
    if isinstance(x, float) and isinstance(y, float):
        return abs(x - y) < 1e-3
    if isinstance(x, (list, tuple)) and isinstance(y, (list, tuple)) and len(x) == len(y):
        return all(same(i, j) for i, j in zip(x, y))
    if isinstance(x, dict) and isinstance(y, dict):
        return x.keys() == y.keys() and all(same(x[k], y[k]) for k in x)
    return x == y


for n in set(oa) & set(ob):
    pa = {key(p): p['value'] for p in oa[n]['properties']}
    pb = {key(p): p['value'] for p in ob[n]['properties']}
    cls = oa[n]['class_name']
    for k in pa.keys() - pb.keys():
        lost[k[0]] += 1
        examples.setdefault(('lost', k[0]), (n, cls, pa[k]))
    for k in pb.keys() - pa.keys():
        added[k[0]] += 1
        examples.setdefault(('added', k[0]), (n, cls, pb[k]))
    for k in pa.keys() & pb.keys():
        if not same(pa[k], pb[k]):
            changed[k[0]] += 1
            examples.setdefault(('changed', k[0]), (n, cls, pa[k], pb[k]))
for label, c in (('lost', lost), ('added', added), ('changed', changed)):
    print('\nproperties %s:' % label, sum(c.values()))
    for name, count in c.most_common(25):
        print('  %-28s %5d   e.g. %s' % (name, count, json.dumps(examples[(label, name)], default=str)[:150]))

if '--engine' in sys.argv:
    s = kit.Session([a_path, b_path], 'ued22-check')
    for p in (a_path, b_path):
        text = s.cmd('MAP LOAD FILE="..\\Input\\%s"' % p.name)
        bad = [l for l in text.splitlines() if 'Failed' in l or 'version' in l.lower() or 'Critical' in l]
        actors = [l for l in text.splitlines() if l.startswith('UCMapKit|actors|')]
        print('Deus Ex engine loads %-28s %s %s' % (p.name, actors[-1] if actors else '?', bad[:5]))
    s.close()
