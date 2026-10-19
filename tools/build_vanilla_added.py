"""A map of the original Deus Ex with what the mod added to Revision's copy of it: the objects (and brushes) the
mod's map (maps\<map>.dx) has and Revision's has not, taken as they are (the two games' maps are the same there:
check it first) and imported into the original game's map in a private run of its editor engine; rebuilt and lit
again only when brushes or lights came (otherwise the original lighting stays as it is); checked (gamecheck).

    python tools\build_vanilla_added.py 04_NYC_BatteryPark      # -> maps\vanilla\04_NYC_BatteryPark.dx
    python tools\build_vanilla_added.py 06_HongKong_TongBase    # the warehouse's rear service access (later)
"""
import json
import math
import re
import shutil
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools' / 'mapkit'))
sys.path.insert(0, str(ROOT / 'tools' / 'mapkit' / 'editor'))
import settings  # noqa: E402
import convert  # noqa: E402
import gamecheck  # noqa: E402
import prefabs  # noqa: E402
import t3d  # noqa: E402

NAME = sys.argv[1] if len(sys.argv) > 1 else '04_NYC_BatteryPark'
VAN_EXPORTS = ROOT / 'tools' / 'mapkit' / 'out' / 'vanilla_t3d'
SKIP = ('Camera',)                      # the editor's viewpoints
# Revision's maps the original game has not: where the same place is there (Gordon Quick's compound is part of
# the market in the original game; Tong's lab teleports to its #compound)
URLS = {'06_HongKong_WanChai_Compound#compound': '06_HongKong_WanChai_Market#compound'}


def export(src, target, out):
    """A map as T3D, exported by `target`'s editor engine (cached by the source's size and date)."""
    stamp = '%d-%d' % (src.stat().st_size, int(src.stat().st_mtime))
    marker = out.with_suffix('.stamp')
    if out.exists() and marker.exists() and marker.read_text() == stamp:
        return out
    run = convert._run(settings.GAME, target, 'export-' + out.stem)
    try:
        shutil.copy2(src, run / 'Input' / src.name)
        convert._execute(run, ['MAP LOAD FILE="..\\Input\\%s"' % src.name,
                               'MAP EXPORT FILE="..\\Output\\%s.t3d"' % NAME], 'export.log')
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(run / 'Output' / (NAME + '.t3d'), out)
        marker.write_text(stamp)
    finally:
        convert._remove(run)
    return out


def actors(path):
    return list(t3d.actors(path.read_text(encoding='latin1', errors='replace')))


def main():
    runtime = ROOT / 'dist' / 'vanilla' / 'UnatcoContinues.u'
    mod_src = ROOT / 'maps' / (NAME + '.dx')
    rev_src = settings.GAME / 'Revision' / 'Maps' / (NAME + '.dx')
    van_src = settings.GAME / 'Maps' / (NAME + '.dx')
    mine = actors(export(mod_src, 'revision', VAN_EXPORTS / ('mod_' + NAME + '.t3d')))
    rev = {a['name']: a for a in actors(export(rev_src, 'revision', VAN_EXPORTS / ('rev_' + NAME + '.t3d')))}
    van = {a['name']: a for a in actors(export(van_src, 'vanilla', VAN_EXPORTS / (NAME + '.t3d')))}
    added = [a for a in mine if a['name'] not in rev and a['cls'] not in SKIP]
    # objects the mod moved (in Revision's map): the original game's same object (by class, where Revision had it)
    moves = []
    for a in mine:
        r = rev.get(a['name'])
        if r is None or a['cls'] in SKIP or a['cls'] == 'Brush':
            continue
        la, lr = t3d.vec(a['props'].get('Location')), t3d.vec(r['props'].get('Location'))
        if la and lr and math.dist(la, lr) > 1:
            twin = min((v for v in van.values() if v['cls'] == a['cls'] and t3d.vec(v['props'].get('Location'))),
                       key=lambda v: math.dist(t3d.vec(v['props'].get('Location')), lr), default=None)
            if twin is not None and math.dist(t3d.vec(twin['props'].get('Location')), lr) < 16:
                moves.append((twin['name'], la, a['props'].get('Rotation')))
            else:
                print('  no original twin for moved', a['name'])
    # brushes first (their order: the CSG), then the rest; their names unique in the original map
    taken = set(van)
    blocks, movers, renamed = [], [], {}
    for a in sorted(added, key=lambda a: a['cls'] != 'Brush'):
        name = a['name']
        if name in taken:
            name = 'UCTong' + name
        taken.add(name)
        renamed[a['name']] = name
        raw = prefabs._clean_block(a['raw'])
        for old, new in URLS.items():
            raw = raw.replace('URL="%s"' % old, 'URL="%s"' % new)
        if a['cls'] == 'Light':
            # dynamic in Revision's map (so its baked lighting could stay); this map is lit again: baked here
            raw = re.sub(r'(?m)^[ \t]*(bStatic=False|bMovable=True)[ \t]*\r?\n', '', raw)
        raw = re.sub(r'^Begin Actor Class=(\S+)', r'Begin Actor Class=\1 Name=%s' % name, raw, count=1)
        model = re.search(r"Brush=Model'MyLevel\.(\w+)'", raw)
        if model:
            new_model = 'UCTongModel_' + name
            raw = raw.replace("Model'MyLevel.%s'" % model.group(1), "Model'MyLevel.%s'" % new_model)
            raw = re.sub(r'Begin Brush Name=\w+', 'Begin Brush Name=' + new_model, raw, count=1)
        blocks.append(raw)
        if 'Mover' in a['cls']:
            movers.append(name)
    print('adding %d objects (%d brushes), moving %d' % (len(blocks), sum(a['cls'] == 'Brush' for a in added), len(moves)))
    folder = convert._run(settings.GAME, 'vanilla', 'added-' + NAME, packages=[runtime])
    try:
        shutil.copy2(van_src, folder / 'Input' / van_src.name)
        (folder / 'T3D' / 'added.t3d').write_text(t3d.import_text(blocks), encoding='latin1')
        packages = sorted({p for b in blocks for p in re.findall(r"=\w+'(\w+)\.", b) if p not in ('MyLevel',)})
        nav = [renamed[a['name']] for a in added if a['cls'] in ('PathNode', 'Teleporter', 'PatrolPoint')]
        cmds = [r'MAP LOAD FILE="..\Input\%s"' % van_src.name, 'UC_KEEPPATHS save']
        cmds += ['OBJ LOAD FILE="%s.utx"' % p for p in ('CoreTexBrick', 'CoreTexWood', 'CoreTexMetal', 'Dockyard', 'HK_Interior')]
        if any(re.match(r'Begin Actor Class=(UC|UnatcoContinues\.)', b) for b in blocks):
            cmds.append('OBJ LOAD FILE="%s"' % runtime.name)     # the mod's classes, or the import skips them
        cmds += [r'MAP IMPORTADD FILE="..\T3D\added.t3d"']
        cmds += ['UC_MOVER prep %s 1 1 1' % m for m in movers]
        for name, loc, rot in moves:
            r = [int(x) for x in re.findall(r'-?\d+', rot or '')] if rot else []
            cmds.append('UC_SET %s %.3f %.3f %.3f %d %d %d' % ((name,) + tuple(loc) + tuple((r + [0, 0, 0])[:3])))
        geometry = any(a['cls'] == 'Brush' for a in added)
        if geometry:
            cmds += ['MAP REBUILD', 'BSP REBUILD OPTIMAL BALANCE=15', 'UC_WORLD finish']
        if geometry or nav:
            cmds += (['UC_NAVDROP ' + ' '.join(nav)] if nav else []) + ['UC_NAVDROP temp', 'PATHS DEFINE', 'UC_NAVLIFT',
                                                                         'UC_KEEPPATHS restore']
        if geometry or any(a['cls'] in ('Light', 'Spotlight') for a in added):
            cmds += ['LIGHT APPLY']
        cmds += ['UC_CAMERAS clear', r'MAP SAVE FILE="..\Output\%s.dx"' % NAME,
                 r'MAP EXPORT FILE="..\Output\%s.t3d"' % NAME]
        t0 = time.time()
        text = convert._execute(folder, cmds, 'build.log')
        out = ROOT / 'maps' / 'vanilla' / (NAME + '.dx')
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(folder / 'Output' / (NAME + '.dx'), out)
        check = gamecheck.check(out, 'vanilla', own=[runtime.stem])
        report = dict(built=time.strftime('%Y-%m-%d %H:%M:%S'), seconds=round(time.time() - t0, 1), check=check,
                      added=[renamed[a['name']] for a in added], moved=[m[0] for m in moves], packages_seen=packages,
                      world=re.findall(r'UCMapKit\|world\|.*', text)[-3:] + re.findall(r'\d+ Lights, .*', text)[-2:],
                      warnings=[l for l in text.splitlines() if re.search(r'missing|failed|inside', l, re.I)][:40])
        out.with_suffix('.build.json').write_text(json.dumps(report, indent=1, default=str), encoding='utf-8')
        print('wrote', out, 'loads in the original game:', check['loads'], check.get('missing'), 'in %.0fs' % report['seconds'])
        for w in report['world'] + report['warnings'][:15]:
            print(' ', w)
    finally:
        convert._remove(folder)


if __name__ == '__main__':
    main()
