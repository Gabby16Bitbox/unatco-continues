"""Temporary in-game trials, with a durable journal and guarded restoration."""
from datetime import datetime, timezone
from functools import wraps
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import uuid
import msvcrt

import core
from engine import read_ini

TRIALS = core.HERE / 'trials'
LOCK = core.HERE / 'game-trial.lock'
CONFIGS = ('RevisionUser.ini', 'UCShots.ini', 'RevisionUCShots.ini')
PHOTOS = {'cam', 'view', 'player', 'follow'}


def serialized(function):
    @wraps(function)
    def operation(*args, **kwargs):
        # The OS releases this guard on process death. The durable journal marker remains.
        with (core.HERE / 'active-game-trial.guard').open('a+b') as guard:
            if guard.tell() == 0:
                guard.write(b'0')
                guard.flush()
            guard.seek(0)
            try:
                msvcrt.locking(guard.fileno(), msvcrt.LK_NBLCK, 1)
            except OSError:
                raise ValueError('An in-game trial/recovery is already executing')
            try:
                return function(*args, **kwargs)
            finally:
                guard.seek(0)
                msvcrt.locking(guard.fileno(), msvcrt.LK_UNLCK, 1)
    return operation


def powershell(script, arguments=(), timeout=20):
    return subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive',
                           '-ExecutionPolicy', 'Bypass', '-File', str(script), *map(str, arguments)],
                          capture_output=True, timeout=timeout,
                          creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))


def game_state():
    result = powershell(core.HERE / 'game_state.ps1')
    if result.returncode:
        raise ValueError('Cannot check the game state: ' + result.stderr.decode(errors='replace'))
    state = json.loads(result.stdout.decode('utf-8-sig'))
    if (Path(state['revision']).resolve() != core.REVISION.resolve()
            or Path(state['project']).resolve() != core.PROJECT.resolve()):
        raise ValueError('shots.ps1 configuration differs from bridge paths; align config.ps1 first')
    return state


def require_closed():
    games = game_state()['games']
    if games:
        raise ValueError('Close Deus Ex/Revision before trying or restoring: ' +
                         ', '.join(str(g['name']) + ' PID ' + str(g['pid']) for g in games))


def resolve_game_map(map_name):
    """Follow Revision's ordered map search paths, including UnatcoMaps overrides."""
    if not re.fullmatch(r'[A-Za-z0-9_-]+', map_name):
        raise ValueError('Invalid map name')
    system = core.REVISION / 'System'
    config = system / 'Revision.ini'
    section = ''
    for line in read_ini(config).splitlines():
        line = line.strip()
        if line.startswith('[') and line.endswith(']'):
            section = line[1:-1].lower()
        if section != 'core.system':
            continue
        match = re.match(r'(?i)^Paths\s*=\s*(.+)$', line)
        if not match:
            continue
        value = Path(match[1].strip('"').replace('\\', '/'))
        if value.suffix.lower() != '.dx':
            continue
        pattern = (value if value.is_absolute() else system / value).resolve()
        candidate = pattern.parent / (map_name + '.dx')
        if not candidate.exists():
            continue
        if not candidate.is_relative_to(core.REVISION.parent.resolve()) or candidate.is_symlink():
            raise ValueError('Active map is outside the game installation or is a symlink: ' + str(candidate))
        return candidate
    raise ValueError('Installed map not found through Revision.ini search paths')


def validate_shots(shots):
    if not isinstance(shots, list) or not 1 <= len(shots) <= 40:
        raise ValueError('Supply 1..40 photographer actions')
    counts = {'cam': 8, 'view': 2, 'player': 7, 'wait': 3,
              'console': 3, 'torch': 3, 'follow': 3, 'where': 3,
              'talk': 3, 'flag': 3, 'hud': 3, 'next': 2, 'hand': 2,
              'waitmap': 4, 'waitflag': 4}
    for shot in shots:
        if not isinstance(shot, str) or not shot or any(c in shot for c in '\r\n\0'):
            raise ValueError('Each action must be one nonempty line')
        fields = shot.split(';')
        if len(fields) < 2 or not fields[0] or fields[1] not in counts or len(fields) != counts[fields[1]]:
            raise ValueError('Invalid photographer action: ' + shot)
        kind = fields[1]
        if kind in ('cam', 'player', 'wait', 'waitmap', 'waitflag'):
            try:
                numbers = list(map(float, fields[3:] if kind in ('waitmap', 'waitflag') else fields[2:]))
            except ValueError:
                raise ValueError('Invalid coordinates/time in action: ' + shot)
            if not all(math.isfinite(n) for n in numbers) or (kind in ('wait', 'waitmap', 'waitflag') and numbers[0] < 0):
                raise ValueError('Coordinates/time must be finite; waiting time must be nonnegative')
        elif kind in ('torch', 'hud') and fields[2] not in ('0', '1'):
            raise ValueError('torch/hud requires 0 or 1')
        if kind in ('follow', 'where', 'talk', 'flag', 'waitflag') and not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]{0,62}', fields[2]):
            raise ValueError('Invalid actor Tag, map or flag name')
        elif kind == 'waitmap' and not re.fullmatch(r'[A-Za-z0-9_][A-Za-z0-9_]{0,62}', fields[2]):
            raise ValueError('Invalid map name')
        elif kind == 'console' and not fields[2].strip():
            raise ValueError('Empty console command')
    return sum(s.split(';')[1] in PHOTOS for s in shots)


def directory_hashes(folder):
    if not folder.exists():
        return None
    result = {}
    for path in [folder, *folder.rglob('*')]:
        if path.is_symlink() or path.is_junction():
            raise ValueError('Save/Current must not contain symlinks or junctions')
        if path.is_file():
            result[path.relative_to(folder).as_posix()] = core.sha(path)
    return result


def replace_file(source, destination, expected, source_expected=None):
    """Same-directory staging and hash guard immediately before the atomic replace."""
    temporary = destination.with_name(destination.name + '.bridge-' + uuid.uuid4().hex + '.tmp')
    try:
        shutil.copy2(source, temporary)
        if core.sha(temporary) != core.sha(source) or (source_expected and core.sha(temporary) != source_expected):
            raise ValueError('Staged copy does not match its backup')
        current = core.sha(destination) if destination.exists() else None
        if current != expected:
            raise ValueError('Concurrent change detected: ' + str(destination))
        temporary.replace(destination)
    finally:
        if temporary.exists():
            temporary.unlink()


def trial_folder(identity):
    if not re.fullmatch(r'[0-9a-f]{32}', identity):
        raise ValueError('Invalid trial ID')
    folder = (TRIALS / identity).resolve()
    if not folder.is_relative_to(TRIALS.resolve()):
        raise ValueError('Trial must stay inside the bridge')
    return folder


def restore(folder, report):
    require_closed()
    if not re.fullmatch(r'[A-Za-z0-9_-]+', report['map_name']):
        raise ValueError('Invalid trial map name')
    relative = report.get('game_relative_map', 'Revision/Maps/' + report['map_name'] + '.dx')
    target = (core.REVISION.parent / relative).resolve()
    if not target.is_relative_to(core.REVISION.parent.resolve()) or target.name != report['map_name'] + '.dx':
        raise ValueError('Invalid game map path')
    backup = folder / 'map-original.dx'
    if core.sha(backup) != report['original_sha256']:
        raise ValueError('Original map backup changed; restoration refused')
    current_hash = core.sha(target) if target.exists() else None
    if current_hash != report['original_sha256']:
        if current_hash != report['trial_sha256']:
            raise ValueError('Installed map changed during the trial; preserved it and the original backup: ' + str(backup))
        replace_file(backup, target, report['trial_sha256'], report['original_sha256'])
    report['map_restored'] = True
    core.save(folder / 'report.json', report)
    for config in report['configs']:
        if config['name'] not in CONFIGS:
            raise ValueError('Invalid configuration filename')
        destination = core.REVISION / 'System' / config['name']
        actual = core.sha(destination) if destination.exists() else None
        if actual == config['original_sha256']:
            continue
        expected = config.get('after_sha256', actual)
        if actual != expected:
            raise ValueError('Configuration changed after photography: ' + str(destination))
        if config['original_sha256'] is not None:
            source = folder / config['name']
            if core.sha(source) != config['original_sha256']:
                raise ValueError('Configuration backup hash changed')
            replace_file(source, destination, expected, config['original_sha256'])
        elif destination.exists():
            # Preserve generated settings as an artifact instead of deleting them.
            destination.rename(folder / ('generated-' + config['name']))
    report['configs_restored'] = True
    core.save(folder / 'report.json', report)
    current = (core.REVISION / 'Save/Current').resolve()
    if current.parent != (core.REVISION / 'Save').resolve():
        raise ValueError('Save/Current resolves outside the game save folder')
    saved = folder / 'SavedCurrent'
    if saved.exists():
        if directory_hashes(saved) != report['save_original']:
            raise ValueError('Original temporary save backup changed')
        if current.exists():
            # Both exact, resolved targets were checked; no recursive deletion is used.
            current.rename(folder / ('generated-Current-' + uuid.uuid4().hex))
        saved.rename(current)
    elif report['save_original'] is not None:
        if directory_hashes(current) != report['save_original']:
            raise ValueError('Missing original temporary save backup')
    elif report.get('launched') and current.exists():
        current.rename(folder / ('generated-Current-' + uuid.uuid4().hex))
    if directory_hashes(current) != report['save_original']:
        raise ValueError('Temporary save restoration failed')
    report['save_restored'] = True
    report['restored'] = True
    core.save(folder / 'report.json', report)


def run_photographer(folder, request):
    core.save(folder / 'request.json', request)
    result = powershell(core.HERE / 'run_shots.ps1',
                        ['-RequestFile', folder / 'request.json', '-ReportFile', folder / 'photographer.json'],
                        timeout=request['timeout'] + 240)
    (folder / 'photographer.log').write_bytes(result.stdout + result.stderr)
    destination = folder / 'photographer.json'
    data = json.loads(destination.read_text(encoding='utf-8-sig')) if destination.exists() else {}
    if result.returncode or not data.get('success'):
        raise ValueError('Photographer failed: ' + str(data.get('error') or folder / 'photographer.log'))
    return data


@serialized
def try_game(identity, shots, setup='', start_map='01_NYC_UNATCOIsland', delay=6,
             timeout=300, width=1600, expected_sha256=None, expected_game_sha256=None):
    expected_photos = validate_shots(shots)
    if setup and not re.fullmatch(r'UCDbg\w+', setup):
        raise ValueError('Setup must be a UCDbg class name')
    if not re.fullmatch(r'[A-Za-z0-9_-]+', start_map):
        raise ValueError('Invalid start map')
    if not math.isfinite(delay) or delay < 0 or not 1 <= timeout <= 600 or not 320 <= width <= 3840:
        raise ValueError('delay >= 0, timeout 1..600 seconds, width 320..3840')
    folder_workspace, manifest, selected = core.workspace(identity)
    if core.status(identity)['source_changed']:
        raise ValueError('Workspace source changed; checkout the updated map before trying it')
    selected_sha = core.sha(selected)
    if expected_sha256 and selected_sha != expected_sha256:
        raise ValueError('Workspace SHA256 changed')
    require_closed()
    trial_id = uuid.uuid4().hex
    try:
        with LOCK.open('x') as stream:
            stream.write(trial_id)
    except FileExistsError:
        raise ValueError('Another trial is running or needs recovery: ' + LOCK.read_text())
    folder = trial_folder(trial_id)
    folder.mkdir(parents=True)
    report = None
    try:
        target = resolve_game_map(manifest['map_name'])
        game_config_sha = core.sha(core.REVISION / 'System/Revision.ini')
        original_sha = core.sha(target)
        if target.is_symlink():
            raise ValueError('Installed map must be a regular file, not a symlink')
        if expected_game_sha256 and original_sha != expected_game_sha256:
            raise ValueError('Installed game map SHA256 changed')
        backup = folder / 'map-original.dx'
        shutil.copy2(target, backup)
        if core.sha(backup) != original_sha or core.sha(target) != original_sha:
            raise ValueError('Game map changed while backing it up')
        current = core.REVISION / 'Save/Current'
        if current.resolve().parent != (core.REVISION / 'Save').resolve():
            raise ValueError('Invalid Save/Current path')
        if current.exists() and current.resolve().drive.lower() != folder.drive.lower():
            raise ValueError('Temporary save staging currently requires game and bridge on the same drive')
        configs = []
        for name in CONFIGS:
            path = core.REVISION / 'System' / name
            if path.is_symlink():
                raise ValueError('Game settings must not be symlinks')
            digest = core.sha(path) if path.exists() else None
            if digest is not None:
                shutil.copy2(path, folder / name)
                if core.sha(folder / name) != digest or core.sha(path) != digest:
                    raise ValueError('Configuration changed while backing it up')
            configs.append(dict(name=name, original_sha256=digest))
        report = dict(trial=trial_id, workspace=identity, map_name=manifest['map_name'],
                      game_relative_map=target.relative_to(core.REVISION.parent.resolve()).as_posix(),
                      game_config_sha256=game_config_sha,
                      original_sha256=original_sha, trial_sha256=selected_sha, configs=configs,
                      save_original=directory_hashes(current), restored=False, launched=False,
                      expected_photos=expected_photos, status='prepared', photos=[],
                      started=datetime.now().isoformat(), report_file=str(folder / 'report.json'))
        core.save(folder / 'report.json', report)
        require_closed()
        if current.exists():
            current.rename(folder / 'SavedCurrent')
        replace_file(selected, target, original_sha, selected_sha)
        if core.sha(target) != selected_sha:
            raise ValueError('Trial map copy verification failed')
        require_closed()
        if resolve_game_map(manifest['map_name']) != target or core.sha(core.REVISION / 'System/Revision.ini') != game_config_sha:
            raise ValueError('Revision map search configuration changed before launch')
        report['launched'] = True
        report['status'] = 'photographing'
        core.save(folder / 'report.json', report)
        script_hash = core.sha(core.PROJECT / 'tools/shots.ps1')
        log = core.REVISION / 'System/Revision.log'
        log_stamp = log.stat().st_mtime_ns if log.exists() else None
        request = dict(map=manifest['map_name'], start_map=start_map, setup=setup, delay=delay,
                       launched_at=datetime.now(timezone.utc).isoformat(),
                       shots=shots, name='bridge-' + trial_id[:10], timeout=timeout, width=width)
        data = run_photographer(folder, request)
        require_closed()
        if core.sha(core.PROJECT / 'tools/shots.ps1') != script_hash:
            raise ValueError('shots.ps1 changed during the trial; results need review')
        if core.sha(core.REVISION / 'System/Revision.ini') != game_config_sha:
            raise ValueError('Revision.ini changed during the trial; results need review')
        photos = []
        for line in data['output']:
            path = Path(line)
            if path.suffix.lower() == '.png' and path.is_file() and path.resolve().is_relative_to((core.PROJECT / 'shots').resolve()):
                photos.append(str(path.resolve()))
        report['photos'] = photos
        if not log.exists() or log.stat().st_mtime_ns == log_stamp:
            raise ValueError('Photographer did not write a new game log')
        shutil.copy2(log, folder / 'Revision.log')
        text = log.read_text(encoding='latin1')
        report['actor_positions'] = re.findall(r'(?m)^.*UCShot segui .*$', text)
        tracking = [s.split(';')[2] for s in shots if s.split(';')[1] in ('where', 'follow')]
        report['tracking_missing'] = [tag for tag in sorted(set(tracking)) if
            len(re.findall(r'(?im)^.*UCShot segui ' + re.escape(tag) + r' a .+$', text)) < tracking.count(tag)]
        report['map_seen_in_log'] = bool(re.search(r'(?im)^.*(?:LoadMap|Bringing.*Level).*' + re.escape(manifest['map_name']), text))
        if not report['map_seen_in_log'] or 'UCShot fine' not in text or len(photos) != expected_photos:
            raise ValueError('Incomplete photography: require the requested map, UCShot fine and all expected images')
        if report['tracking_missing']:
            raise ValueError('Requested actors were not found by the photographer: ' + ', '.join(report['tracking_missing']))
        report['status'] = 'passed'
    except BaseException as exc:
        if report:
            report['status'] = 'failed'
            report['error'] = str(exc)
            if isinstance(exc, Exception):
                raise ValueError(str(exc) + '\nReport: ' + str(folder / 'report.json')) from exc
        raise
    finally:
        if report:
            request_path = folder / 'request.json'
            if report.get('launched') and request_path.exists():
                try:
                    cleanup = powershell(core.HERE / 'close_trial_game.ps1',
                                         ['-RequestFile', request_path], timeout=40)
                    report['game_cleanup'] = cleanup.stdout.decode('utf-8-sig', errors='replace').strip()
                except (OSError, subprocess.TimeoutExpired) as exc:
                    report['game_cleanup_error'] = str(exc)
            for config in report['configs']:
                path = core.REVISION / 'System' / config['name']
                config['after_sha256'] = core.sha(path) if path.exists() else None
            core.save(folder / 'report.json', report)
            try:
                restore(folder, report)
            except (ValueError, OSError, subprocess.TimeoutExpired) as exc:
                report['restore_error'] = str(exc)
                report['status'] = 'recovery_required'
                core.save(folder / 'report.json', report)
                raise ValueError('Trial needs recovery; backups preserved. ' + str(exc) + '\nReport: ' + str(folder / 'report.json'))
        if not report or report.get('restored'):
            LOCK.unlink()
    return report


@serialized
def recover(identity):
    folder = trial_folder(identity)
    report = json.loads((folder / 'report.json').read_text(encoding='utf-8'))
    if report['trial'] != identity:
        raise ValueError('Trial ID mismatch')
    if LOCK.exists() and LOCK.read_text() != identity:
        raise ValueError('A different trial owns the game lock')
    restore(folder, report)
    report['status'] = 'recovered'
    core.save(folder / 'report.json', report)
    if LOCK.exists():
        LOCK.unlink()
    return report
