"""Build and check voices against a private campaign snapshot.

Never changes the live editor's SDK files. Publication refuses concurrent
source/package changes. --install also backs up the closed game's packages.
"""
import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid

import make_voices as m
import natural_voices as n

ROOT = Path(m.ROOT)
PACKAGES = ('UnatcoVoices.u', 'UnatcoContinues.u')


def signature(paths):
    return {str(path): n.sha(path) for path in paths if path.is_file()}


def source_files(plan):
    files = [p for p in (ROOT / 'src/UnatcoContinues').rglob('*') if p.is_file()]
    files += list((ROOT / 'src/UnatcoVoices/Classes').glob('*.uc'))
    files += [Path(m.OUT_SOUNDS) / (key + '.wav') for key in plan['lines']]
    return files


def run(args, cwd, log):
    with log.open('wb') as output:
        completed = subprocess.run([str(arg) for arg in args], cwd=cwd,
                                   stdin=subprocess.DEVNULL, stdout=output,
                                   stderr=subprocess.STDOUT, timeout=180)
    if completed.returncode:
        raise ValueError('Failed command; inspect ' + str(log))


def read_log(path):
    raw = path.read_bytes()
    # Windows PowerShell writes redirected logs as UTF-16; pwsh uses UTF-8.
    encoding = 'utf-16' if raw.startswith((b'\xff\xfe', b'\xfe\xff')) else 'utf-8-sig'
    return raw.decode(encoding, errors='replace')


def require_closed_game():
    command = "if(Get-Process -Name Revision,DeusEx -ErrorAction SilentlyContinue){exit 1}"
    if subprocess.run(['powershell.exe', '-NoProfile', '-Command', command],
                      stdin=subprocess.DEVNULL, capture_output=True).returncode:
        raise ValueError('Close Deus Ex / Revision before installing voices.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--publish', action='store_true')
    parser.add_argument('--install', action='store_true')
    parser.add_argument('--resume', type=Path, help='Publish an already checked private System snapshot.')
    parser.add_argument('--game-system', type=Path, default=Path(
        'C:/Program Files (x86)/Steam/steamapps/common/Deus Ex/Revision/System'))
    args = parser.parse_args()
    plan = json.loads(n.PLAN.read_text(encoding='utf-8'))
    if set(plan['lines']) != {line['key'] for line in m.extract()}:
        raise ValueError('Refresh changed dialogue before building.')
    for key in plan['lines']:
        if n.sha(Path(m.OUT_SOUNDS) / (key + '.wav')) != n.sha(n.OUT / (key + '.wav')):
            raise ValueError('Apply verified audio before building: ' + key)
    expected = signature(source_files(plan))
    package_paths = [ROOT / 'dist' / name for name in PACKAGES]
    game_paths = [args.game_system / name for name in PACKAGES]
    previous_dist, previous_game = signature(package_paths), signature(game_paths)
    if args.resume:
        system = args.resume.resolve(strict=True)
        allowed = (ROOT / 'DevInstall').resolve()
        if (not system.is_relative_to(allowed) or system.name != 'System'
                or not re.fullmatch(r'Build-[0-9a-f]{32}', system.parent.name)):
            raise ValueError('Resume requires a managed private Build-*/System.')
        inputs = system / 'voice-build-inputs.json'
        if inputs.exists():
            saved_inputs = json.loads(inputs.read_text(encoding='utf-8'))
            expected = saved_inputs['sources']
            previous_dist, previous_game = saved_inputs['dist'], saved_inputs['game']
        else:
            # Recover earlier checked snapshots by comparing the actual private
            # source files with today's originals; never infer from timestamps.
            copied = [p for p in (system.parent / 'UnatcoContinues').rglob('*') if p.is_file()]
            copied += list((system.parent / 'UnatcoVoices/Classes').glob('*.uc'))
            copied += [system.parent / 'UnatcoVoices/Sounds' / (key + '.wav') for key in plan['lines']]
            expected = {str(ROOT / 'src' / p.relative_to(system.parent)): n.sha(p) for p in copied}
    else:
        build = ROOT / 'DevInstall' / ('Build-' + uuid.uuid4().hex)
        system = build / 'System'
        system.mkdir(parents=True)
        dev = ROOT / 'DevInstall'
        for dependency in (dev / 'System').iterdir():
            if not dependency.is_file() or dependency.name in PACKAGES:
                continue
            target = system / dependency.name
            if dependency.suffix.lower() in ('.exe', '.dll', '.u'):
                os.link(dependency, target)
            elif dependency.suffix.lower() in ('.ini', '.int'):
                shutil.copy2(dependency, target)
        for name in ('UnatcoContinues', 'UnatcoVoices'):
            (build / name / 'Classes').mkdir(parents=True)
        # Native DXOgg opens ../Music directly rather than Core.System Paths.
        # Preserve the game's directory layout using passive asset junctions.
        for name in ('Music', 'Sounds', 'Textures', 'HDTP', 'NewVision'):
            source = dev / name
            if source.is_dir():
                target = build / name
                command = "New-Item -ItemType Junction -Path '%s' -Target '%s' | Out-Null" % (
                    str(target).replace("'", "''"), str(source).replace("'", "''"))
                subprocess.run(['powershell.exe', '-NoProfile', '-Command', command],
                               stdin=subprocess.DEVNULL, check=True, capture_output=True)
        for path in source_files(plan):
            target = build / path.relative_to(ROOT / 'src')
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
        if signature(source_files(plan)) != expected:
            raise ValueError('Sources changed during snapshot; retry against current sources.')
        # Keep package resolution local; route other relative asset paths to the
        # existing SDK assets, without junctions or edits to its configuration.
        for ini in system.glob('*.ini'):
            text = ini.read_text(encoding='latin-1')
            text = re.sub(r'(?mi)^Paths=\.\.\\(?!System\\)(.+)$',
                          lambda match: 'Paths=' + str(dev / match[1]), text)
            ini.write_text(text, encoding='latin-1')
        original_src = m.SRC
        try:
            m.SRC = str(build / 'UnatcoContinues/Classes')
            import prepare_voice_check
            prepare_voice_check.SRC = m.SRC
            prepare_voice_check.main()
        finally:
            m.SRC = original_src
        run([system / 'ucc.exe', 'editor.make'], system, system / 'build.log')
        run([sys.executable, ROOT / 'tools/set_texture_prop.py', 'UnatcoContinues.u',
             'UCSignElevators', 'DrawScale', '0.125'], system, system / 'texture.log')
        n.save(system / 'voice-build-inputs.json', {'sources': expected, 'dist': previous_dist, 'game': previous_game})
    checks = {}
    for commandlet, prefix in (('UCVoiceCheckCommandlet', 'UCVoiceCheck'),
                              ('UCDialogueCheckCommandlet', 'UCDialogueCheck'),
                              ('UCRouteCheckCommandlet', 'UCRouteCheck')):
        log = system / (commandlet + '.log')
        if not args.resume:
            run([system / 'ucc.exe', 'UnatcoContinues.' + commandlet], system, log)
        match = re.search(prefix + r':\s*(\d+) checked,\s*(\d+) failed',
                          read_log(log))
        if not match or int(match[2]):
            raise ValueError('Native check failed; inspect ' + str(log))
        checks[prefix] = [int(match[1]), int(match[2])]
    if not args.resume:
        run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
             ROOT / 'tools/check-voice-identity.ps1', '-BuildSystem', system],
            ROOT, system / 'identity-run.log')
    identity = read_log(system / 'VoiceIdentity.log')
    match = re.search(r'UCVoiceIdentityCheck:\s*(\d+) checked,\s*(\d+) failed', identity)
    if not match or int(match[2]):
        raise ValueError('Native voice identity check failed: ' + str(system))
    checks['UCVoiceIdentityCheck'] = [int(match[1]), int(match[2])]
    if signature(source_files(plan)) != expected:
        raise ValueError('Campaign changed while building; snapshot retained, publication refused.')
    compiled = {name: n.sha(system / name) for name in PACKAGES}
    report = {'build_system': str(system), 'sources': expected, 'packages': compiled,
              'native_checks': checks, 'published': False, 'installed': False}
    n.save(system / 'voice-build.json', report)
    if args.publish or args.install:
        if signature(package_paths) != previous_dist:
            raise ValueError('Another build updated dist; private packages retained.')
        if args.install:
            require_closed_game()
            if signature(game_paths) != previous_game:
                raise ValueError('Another build updated the game; private packages retained.')
        backup = ROOT / 'dist/backup' / ('voice-snapshot-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
        backup.mkdir(parents=True, exist_ok=False)
        for paths, label in ((package_paths, 'dist'), (game_paths, 'game')):
            (backup / label).mkdir()
            for path in paths:
                if path.exists():
                    shutil.copy2(path, backup / label / path.name)
        for path in package_paths:
            staged = path.with_suffix('.u.new')
            shutil.copy2(system / path.name, staged)
            os.replace(staged, path)
            if n.sha(path) != compiled[path.name]:
                raise ValueError('Published package hash mismatch: ' + str(path))
        report.update(published=True, backup=str(backup))
        if args.install:
            written = []
            try:
                require_closed_game()
                if signature(game_paths) != previous_game:
                    raise ValueError('Game packages changed before installation.')
                for path in game_paths:
                    staged = path.with_name(path.name + '.voice-' + uuid.uuid4().hex)
                    shutil.copy2(system / path.name, staged)
                    if n.sha(staged) != compiled[path.name]:
                        raise ValueError('Staged package hash mismatch: ' + str(staged))
                    os.replace(staged, path)
                    written.append(path)
                    if n.sha(path) != compiled[path.name]:
                        raise ValueError('Installed package hash mismatch: ' + str(path))
            except Exception:
                # Restore only files this transaction actually wrote.
                for path in written:
                    saved = backup / 'game' / path.name
                    if saved.exists() and path.exists() and n.sha(path) == compiled[path.name]:
                        shutil.copy2(saved, path)
                raise
            report['installed'] = True
    n.save(system / 'voice-build.json', report)
    n.save(n.OUT / 'latest-voice-build.json', report)
    print(json.dumps({key: report[key] for key in ('build_system', 'native_checks', 'published', 'installed')}, indent=2))


if __name__ == '__main__':
    main()
