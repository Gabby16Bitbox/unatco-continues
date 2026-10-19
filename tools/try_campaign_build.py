"""Trial a checked private package build and bridge map, restoring both afterward."""
import argparse
import json
import re
from pathlib import Path
import shutil
import sys
import uuid

HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE / 'editor_bridge'), str(HERE)]
import core
import trial


def run(build, workspace, shots, timeout):
    build = build.resolve(strict=True)
    if (not build.is_relative_to((core.PROJECT / 'DevInstall').resolve())
            or build.name != 'System' or not build.parent.name.startswith('Build-')):
        raise ValueError('Use a managed private build')
    verified = json.loads((build / 'voice-build.json').read_text())
    if any(value[1] for value in verified['native_checks'].values()):
        raise ValueError('Private native checks did not pass')
    trial.require_closed()
    folder = trial.TRIALS / ('packages-' + uuid.uuid4().hex)
    folder.mkdir(parents=True)
    game = core.REVISION / 'System'
    _, map_manifest, _ = core.workspace(workspace)
    steam_map = core.REVISION / 'Maps' / (map_manifest['map_name'] + '.dx')
    journal = {'restored': False, 'build': str(build), 'packages': {},
               'steam_original_map_sha256': core.sha(steam_map)}
    for name in ('UnatcoContinues.u', 'UnatcoVoices.u'):
        if core.sha(build / name) != verified['packages'][name]:
            raise ValueError('Checked package changed before staging')
        shutil.copy2(game / name, folder / name)
        journal['packages'][name] = {'original': core.sha(game / name),
                                     'trial': core.sha(build / name)}
    core.save(folder / 'journal.json', journal)
    written = []
    try:
        for name, entry in journal['packages'].items():
            if core.sha(game / name) != entry['original']:
                raise ValueError('Game package changed before trial')
            shutil.copy2(build / name, game / name)
            written.append(name)
        result = trial.try_game(workspace, shots, setup='UCDbgTongLab', timeout=timeout)
        journal['map_trial'] = result
        log = game / 'Revision.log'
        if log.exists():
            shutil.copy2(log, folder / 'Revision.log')
            contents = log.read_bytes().decode('latin-1')
            checks = re.search(r'UCRWPlayCheck:\s*(\d+) checked,\s*(\d+) failed', contents)
            if any('summon UnatcoContinues.UCRW' in shot for shot in shots):
                if not checks:
                    raise ValueError('Gameplay probe did not finish; inspect ' + str(folder / 'Revision.log'))
                journal['gameplay_checks'] = [int(checks[1]), int(checks[2])]
                result['gameplay_checks'] = journal['gameplay_checks']
                core.save(Path(result['report_file']),result)
                if int(checks[2]):
                    raise ValueError('Gameplay probe failed; inspect ' + str(folder / 'Revision.log'))
        return result
    finally:
        trial.require_closed()
        for name in written:
            if core.sha(game / name) != journal['packages'][name]['trial']:
                raise ValueError('Another process changed the trial package; backup retained at ' + str(folder))
            shutil.copy2(folder / name, game / name)
            if core.sha(game / name) != journal['packages'][name]['original']:
                raise ValueError('Package restoration hash failed')
        journal['restored'] = True
        core.save(folder / 'journal.json', journal)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-system', type=Path, required=True)
    parser.add_argument('--workspace', required=True)
    parser.add_argument('--shots-file', type=Path, required=True)
    parser.add_argument('--timeout', type=int, default=360)
    args = parser.parse_args()
    print(json.dumps(run(args.build_system, args.workspace,
                         json.loads(args.shots_file.read_text()), args.timeout), indent=2))
