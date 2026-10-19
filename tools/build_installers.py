"""The two installers of the mod (Inno Setup, installer\\UnatcoContinues.iss) -> build\\installer\\:
UNATCO-Continues-DeusEx-Setup-<v>.exe (the original Deus Ex) and UNATCO-Continues-Revision-Setup-<v>.exe.

    python tools\\build_installers.py [--version 0.1.0]

Each installs the version's packages (built: dist\\vanilla\\UnatcoContinues.u / dist\\UnatcoContinues.u, and
dist\\UCAnims.u, dist\\UCModels.u) and its map PATCHES (never a whole map: they are made from the player's own
copy at install), with the version's install/uninstall scripts. No voices (UnatcoVoices.u): see tools\\voices.
Inno Setup: UC_ISCC, else DeusEdix's build_tools\\InnoSetup6\\ISCC.exe, else Program Files.
"""
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'build' / 'installer' / 'stage'
ISCC = [os.environ.get('UC_ISCC', ''),
        str(Path.home() / 'Documents' / 'Unreal Projects' / 'DeusEdix' / 'build_tools' / 'InnoSetup6' / 'ISCC.exe'),
        r'C:\Program Files (x86)\Inno Setup 6\ISCC.exe', r'C:\Program Files\Inno Setup 6\ISCC.exe']

BEFORE = """UNATCO Continues is a work in progress: a new route through Deus Ex in which JC stays loyal to UNATCO.

What it installs: the mod's own packages and map patches. No file of the game is included: the maps are made
now from your own copy of {game} (the originals are not changed), and the mod needs the game to run. It is
free and not for sale.

There are no recorded voices in this download: the new lines show as subtitles. You can make the voices
yourself (see the project's page, tools/voices).

Made with DeusEdix, a map and story editor for Deus Ex (coming soon).
Discord: coming soon.  Source code: https://github.com/Gabby16Bitbox/unatco-continues

After installing: start the game, load or begin a game, press T, delete "Say" and type
{start}
"""

VERSIONS = {
    'vanilla': dict(game='Deus Ex (Game of the Year Edition)', start='    exec unatcostart.txt', files={
        'config.ps1': 'config.ps1', 'install-vanilla.ps1': 'install-vanilla.ps1',
        'uninstall-vanilla.ps1': 'uninstall-vanilla.ps1', 'tools/Expand-MapPatch.ps1': 'tools/Expand-MapPatch.ps1',
        'release/vanilla/UnatcoContinues.u': 'dist/vanilla/UnatcoContinues.u',
        'dist/UCAnims.u': 'dist/UCAnims.u', 'dist/UCModels.u': 'dist/UCModels.u'},
        patches='maps/vanilla/patches'),
    'revision': dict(game='Deus Ex: Revision', start='    unatcostart', files={
        'config.ps1': 'config.ps1', 'install.ps1': 'install.ps1', 'uninstall.ps1': 'uninstall.ps1',
'tools/Expand-MapPatch.ps1': 'tools/Expand-MapPatch.ps1',
        'tools/tour-keys.ps1': 'tools/tour-keys.ps1',
        'release/UnatcoContinues.u': 'dist/UnatcoContinues.u',
        'dist/UCAnims.u': 'dist/UCAnims.u', 'dist/UCModels.u': 'dist/UCModels.u'},
        patches='maps/patches'),
}


def stage(target):
    v = VERSIONS[target]
    out = STAGE / target
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    for dest, src in v['files'].items():
        s = ROOT / src
        if not s.exists():
            if src.endswith('.ps1') and dest == 'make-ini.ps1':
                continue
            raise SystemExit('missing %s (build the mod first)' % src)
        (out / dest).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(s, out / dest)
    pdir = out / v['patches']
    pdir.mkdir(parents=True)
    for p in (ROOT / v['patches']).glob('*.ucpatch'):
        if target == 'vanilla' and p.stem == '06_HongKong_TongBase':
            continue                    # not ready for the original game yet
        shutil.copy2(p, pdir / p.name)
    for name in ('LICENSE', 'NOTICE.md'):
        if (ROOT / name).exists():
            shutil.copy2(ROOT / name, out / name)
    (out / 'BEFORE.txt').write_text(BEFORE.format(game=v['game'], start=v['start']), encoding='utf-8')
    return out


def main():
    a = argparse.ArgumentParser()
    a.add_argument('--version', default='0.1.0')
    args = a.parse_args()
    iscc = next((p for p in ISCC if p and Path(p).exists()), None)
    if not iscc:
        raise SystemExit('Inno Setup (ISCC.exe) not found: set UC_ISCC')
    for target in ('vanilla', 'revision'):
        st = stage(target)
        r = subprocess.run([iscc, '/Q', '/DTarget=' + target, '/DAppVersion=' + args.version, '/DStage=' + str(st),
                            str(ROOT / 'installer' / 'UnatcoContinues.iss')], capture_output=True, text=True)
        if r.returncode:
            print(r.stdout[-3000:], r.stderr[-3000:])
            raise SystemExit('ISCC failed for ' + target)
    for f in sorted((ROOT / 'build' / 'installer').glob('*.exe')):
        print(f, f.stat().st_size)


if __name__ == '__main__':
    main()
