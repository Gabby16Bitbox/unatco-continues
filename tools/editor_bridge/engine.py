"""Validate and inspect private map copies in the original Deus Ex engine."""
from datetime import datetime
import json
from functools import wraps
from pathlib import Path
import re
import shutil
import socket
import subprocess
import uuid

from archive import PROJECT, objects
from core import HERE, workspace, sha, save

LAB = HERE / 'engine_lab'


def lab_locked(function):
    @wraps(function)
    def operation(*args, **kwargs):
        LAB.mkdir(parents=True, exist_ok=True)
        lock = LAB / 'preparation.lock'
        try:
            with lock.open('x') as stream:
                stream.write('private compiler')
        except FileExistsError:
            raise ValueError('Private engine setup is already running; retry after it finishes')
        try:
            return function(*args, **kwargs)
        finally:
            lock.unlink()
    return operation


def read_ini(path):
    raw = path.read_bytes()
    if raw.startswith((b'\xff\xfe', b'\xfe\xff')):
        return raw.decode('utf-16')
    if raw.startswith(b'\xef\xbb\xbf'):
        return raw.decode('utf-8-sig')
    return raw.decode('latin1')


def run(command, directory, log, timeout=55):
    with log.open('wb') as output:
        process = subprocess.run(command, cwd=directory, stdout=output,
                                 stderr=subprocess.STDOUT, timeout=timeout)
    text = log.read_text(encoding='utf-8', errors='replace')
    if process.returncode or re.search(r'(?im)^.*(?:Critical:|Failed to load|Error,|Failed import:)', text):
        raise ValueError('Engine operation failed; see ' + str(log) + '\n' + '\n'.join(text.splitlines()[-12:]))
    return text


@lab_locked
def prepare_lab():
    system = LAB / 'System'
    snapshot_source = HERE / 'engine_src/UCMapBridge/Classes/UCBridgeSnapshot.uc'
    package = system / 'UCMapBridge.u'
    build_file = LAB / 'build.json'
    if package.exists() and build_file.exists():
        build = json.loads(build_file.read_text(encoding='utf-8'))
        if build['source_sha256'] == sha(snapshot_source) and build['package_sha256'] == sha(package):
            return system
    if package.exists():
        package.unlink()
    system.mkdir(parents=True, exist_ok=True)
    original = PROJECT / 'DevInstall/System'
    for path in original.glob('*.ini'):
        shutil.copy2(path, system / path.name)
    for path in original.iterdir():
        if path.is_file() and path.suffix.lower() in ('.exe', '.dll', '.u', '.int'):
            target = system / path.name
            if path.name in ('UnatcoContinues.u', 'UnatcoVoices.u'):
                continue
            if not target.exists():
                # These dependency files are only loaded, never rewritten by the bridge.
                target.hardlink_to(path)
    for name in ('UnatcoContinues.u', 'UnatcoVoices.u'):
        compiled_source = PROJECT / 'dist' / name
        before = sha(compiled_source)
        shutil.copy2(compiled_source, system / name)
        if before != sha(compiled_source) or before != sha(system / name):
            raise ValueError('Compiled mod changed while copying; retry')
    classes = LAB / 'UCMapBridge/Classes'
    classes.mkdir(parents=True, exist_ok=True)
    shutil.copy2(snapshot_source, classes / snapshot_source.name)
    original_ini = read_ini(original / 'DeusEx.ini')
    lines = []
    for line in original_ini.splitlines():
        if line.startswith(('ServerActors=', 'EditPackages=', 'Suppress=ScriptWarning')):
            continue
        if line.startswith('Paths='):
            value = line[6:]
            resolved = (original / value).resolve() if not Path(value).is_absolute() else Path(value)
            if resolved.suffix.lower() == '.dx':
                continue
            line = 'Paths=' + str(resolved)
        if line == '[Core.System]':
            lines.append(line)
            lines.append('Paths=' + str(system / '*.u'))
            continue
        if line == '[Editor.EditorEngine]':
            lines.append(line)
            lines += ['EditPackages=' + p for p in ('Core', 'Engine', 'Editor', 'Extension',
                       'DeusExUI', 'ConSys', 'DeusEx', 'Revision', 'UnatcoContinues', 'UCMapBridge')]
            continue
        lines.append(line)
    for name in ('DeusEx.ini', 'Default.ini', 'Revision.ini', 'ucc.ini'):
        (system / name).write_text('\n'.join(lines) + '\n', encoding='latin1')
    run([str(system / 'ucc.exe'), 'Editor.MakeCommandlet'], system, LAB / 'compile.log')
    if not (system / 'UCMapBridge.u').exists():
        raise ValueError('Private bridge package was not created')
    save(LAB / 'build.json', dict(created=datetime.now().isoformat(),
         source_sha256=sha(snapshot_source), package_sha256=sha(system / 'UCMapBridge.u')))
    return system


def snapshot(identity, mode='plain'):
    if mode not in ('plain', 'hk_setup'):
        raise ValueError('mode must be plain or hk_setup')
    folder, manifest, current = workspace(identity)
    if mode == 'hk_setup' and not manifest['map_name'].startswith('06_'):
        raise ValueError('hk_setup is only supported on Hong Kong maps')
    base = prepare_lab()
    run_folder = LAB / 'runs' / uuid.uuid4().hex
    system = run_folder / 'System'
    maps = run_folder / 'Maps'
    system.mkdir(parents=True)
    maps.mkdir()
    for path in base.iterdir():
        if path.is_file() and path.suffix.lower() == '.ini':
            shutil.copy2(path, system / path.name)
        if path.is_file() and path.suffix.lower() in ('.exe', '.dll', '.u', '.int'):
            target = system / path.name
            if path.name in ('UnatcoContinues.u', 'UnatcoVoices.u'):
                continue
            target.hardlink_to(path)
    compiled = {}
    for name in ('UnatcoContinues.u', 'UnatcoVoices.u'):
        source = PROJECT / 'dist' / name
        before = sha(source)
        shutil.copy2(source, system / name)
        if sha(system / name) != before or sha(source) != before:
            raise ValueError('Compiled mod changed while copying; retry')
        compiled[name] = before
    shutil.copy2(current, maps / 'DX.dx')
    lines = []
    for line in (base / 'DeusEx.ini').read_text(encoding='latin1').splitlines():
        if line.startswith('ServerActors='):
            continue
        if line == '[Core.System]':
            lines.extend([line, 'Paths=' + str(maps / '*.dx'), 'Paths=' + str(system / '*.u')])
            continue
        if line == '[DeusEx.DeusExGameEngine]':
            lines.extend([line, 'ServerActors=UCMapBridge.UCBridgeSnapshot'])
            continue
        if line.startswith('DefaultServerGame='):
            line = 'DefaultServerGame=Revision.RevGameInfo'
        lines.append(line)
    lines += ['', '[UCMapBridge]', 'Mode=' + mode]
    for name in ('DeusEx.ini', 'Default.ini', 'Revision.ini', 'ucc.ini'):
        (system / name).write_text('\n'.join(lines) + '\n', encoding='latin1')
    # Choose a free localhost port, independent of Claude's test servers.
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        port = sock.getsockname()[1]
    text = run([str(system / 'ucc.exe'), 'Engine.ServerCommandlet',
                'DX.dx?game=Revision.RevGameInfo', '-multihome=127.0.0.1',
                '-port=' + str(port), '-nosound'], system, run_folder / 'engine.log')
    match = re.search(r'UCBridgeMap\|([^|\r\n]+)\|([^\r\n]+)', text)
    done = re.search(r'UCBridgeDone\|(\d+)', text)
    if not match or not done or match[1].lower() != manifest['map_name'].lower() or match[2] != mode:
        raise ValueError('Missing snapshot completion or wrong map/mode: ' + str(run_folder / 'engine.log'))
    _, saved = objects(current)
    saved_by_name = {r['name']: r for r in saved}
    actors = []
    for line in text.splitlines():
        if not line.startswith('UCBridgeActor|'):
            continue
        row = line.split('|')
        if len(row) != 17:
            raise ValueError('Unexpected actor snapshot row')
        _, name, cls, tag, event, x, y, z, pitch, yaw, roll, hidden, collide, block, block_player, familiar, bark = row
        previous = saved_by_name.get(name)
        actors.append(dict(name=name, class_name=cls.rsplit('.', 1)[-1], tag=tag, event=event,
                           location=[float(x), float(y), float(z)], rotation=[int(pitch), int(yaw), int(roll)],
                           hidden=hidden.lower() == 'true', collide_actors=collide.lower() == 'true',
                           block_actors=block.lower() == 'true', block_players=block_player.lower() == 'true',
                           familiar_name=familiar, bark_bind_name=bark,
                           origin='saved_actor' if previous else 'runtime_spawned',
                           saved_location=previous['location'] if previous else None))
    if len(actors) != int(done[1]):
        raise ValueError('Incomplete actor snapshot')
    result = dict(workspace=identity, map_name=manifest['map_name'], mode=mode,
                  map_sha256=sha(current), compiled_packages=compiled,
                  scope='headless fresh map; hk_setup calls only explicit HK setup routines, not a full player playthrough',
                  count=len(actors), spawned=sum(a['origin'] == 'runtime_spawned' for a in actors),
                  log=str(run_folder / 'engine.log'), actors=actors)
    destination = folder / 'runtime-snapshot.json'
    save(destination, result)
    return dict(file=str(destination), count=result['count'], spawned=result['spawned'],
                mode=mode, log=result['log'], map_sha256=result['map_sha256'], scope=result['scope'])
