"""Wan Chai Street of the original Deus Ex with the mod's butcher's shop (tools\\mapkit\\maps\\butcher_shop.py):
the original game's map, untouched but for the shop built into the shell block south of Queen's Tower, its
doors and the arrival point of the dock's service stair. Built by the original game's editor engine in a
private run, then checked like the converted maps (gamecheck: the original game can load it).

    python tools\\build_vanilla_street.py        # -> maps\\vanilla\\06_HongKong_WanChai_Street.dx
"""
import json
import re
import shutil
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools' / 'mapkit'))
sys.path.insert(0, str(ROOT / 'tools' / 'mapkit' / 'editor'))
sys.path.insert(0, str(ROOT / 'tools' / 'mapkit' / 'maps'))
import settings  # noqa: E402
import convert  # noqa: E402
import gamecheck  # noqa: E402
import t3d  # noqa: E402
from scene import Scene, BRUSH_MODEL, UNLINK  # noqa: E402
import butcher_shop  # noqa: E402

NAME = '06_HongKong_WanChai_Street'
NAV = ('PathNode', 'Teleporter')


def scene():
    s = Scene(NAME, packages=butcher_shop.PACKAGES)
    butcher_shop.build(s)
    return s


def blocks(s):
    """The shop's brushes (named so they cannot meet the map's own Brush<n>) and its actors."""
    out = []
    for b in s.brush_blocks():
        b = re.sub(r'Name=Brush(\d+)', r'Name=UCShopBrush\1', b, count=1)
        out.append(b.replace(BRUSH_MODEL, BRUSH_MODEL + 'Shop'))
    return out + s.actors


def main():
    runtime = ROOT / 'dist' / 'vanilla' / 'UnatcoContinues.u'
    src = settings.GAME / 'Maps' / (NAME + '.dx')            # the original game's map
    s = scene()
    folder = convert._run(settings.GAME, 'vanilla', 'street-shop', packages=[runtime])
    try:
        shutil.copy2(src, folder / 'Input' / src.name)
        (folder / 'T3D' / 'shop.t3d').write_text(t3d.import_text(blocks(s)), encoding='latin1')
        nav = [re.match(r'Begin Actor Class=\S+ Name=(\S+)', a).group(1) for a in s.actors
               if re.match(r'Begin Actor Class=(%s) ' % '|'.join(NAV), a)]
        cmds = [r'MAP LOAD FILE="..\Input\%s"' % src.name, 'UC_KEEPPATHS save']
        cmds += ['OBJ LOAD FILE="%s.utx"' % p for p in butcher_shop.PACKAGES]
        cmds += [r'MAP IMPORTADD FILE="..\T3D\shop.t3d"', UNLINK]
        cmds += ['UC_MOVER prep %s 1 1 1' % m for m in s.movers]
        cmds += ['MAP REBUILD', 'BSP REBUILD OPTIMAL BALANCE=15', 'UC_WORLD finish']
        cmds += ['UC_NAVDROP ' + ' '.join(nav), 'UC_NAVDROP temp', 'PATHS DEFINE', 'UC_NAVLIFT', 'UC_KEEPPATHS restore']
        cmds += ['LIGHT APPLY', 'UC_CAMERAS clear', r'MAP SAVE FILE="..\Output\%s.dx"' % NAME,
                 r'MAP EXPORT FILE="..\Output\%s.t3d"' % NAME]
        t0 = time.time()
        text = convert._execute(folder, cmds, 'build.log')
        out = ROOT / 'maps' / 'vanilla' / (NAME + '.dx')
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(folder / 'Output' / (NAME + '.dx'), out)
        shutil.copy2(folder / 'Output' / (NAME + '.t3d'), out.with_suffix('.t3d'))
        check = gamecheck.check(out, 'vanilla', own=[runtime.stem])
        report = dict(built=time.strftime('%Y-%m-%d %H:%M:%S'), seconds=round(time.time() - t0, 1), check=check,
                      world=re.findall(r'UCMapKit\|world\|.*', text)[-3:],
                      warnings=[l for l in text.splitlines() if re.search(r'missing|Warning|failed', l, re.I)][:40])
        out.with_suffix('.build.json').write_text(json.dumps(report, indent=1, default=str), encoding='utf-8')
        print('wrote', out, 'loads in the original game:', check['loads'], 'in %.0fs' % report['seconds'])
        for w in report['world'] + report['warnings'][:15]:
            print(' ', w)
    finally:
        convert._remove(folder)


if __name__ == '__main__':
    main()
