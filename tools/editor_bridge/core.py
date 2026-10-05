"""Shared CLI/MCP operations. All map writes stay in private workspaces."""
from datetime import datetime
from functools import wraps
import hashlib
import json
import math
from pathlib import Path
import re
import uuid

from archive import PROJECT, objects, patch_bytes, tags, equal

HERE = Path(__file__).resolve().parent
WORKSPACES = HERE / 'workspaces'
REVISION = Path('C:/Program Files (x86)/Steam/steamapps/common/Deus Ex/Revision')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path, value):
    temporary = path.with_name(path.name + '.' + uuid.uuid4().hex + '.tmp')
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temporary.replace(path)


def locked(function):
    @wraps(function)
    def operation(identity, *args, **kwargs):
        workspace(identity)
        lock = WORKSPACES / identity / 'mutation.lock'
        try:
            with lock.open('x') as stream:
                stream.write(function.__name__)
        except FileExistsError:
            raise ValueError('Another operation is changing this workspace; retry after it finishes')
        try:
            return function(identity, *args, **kwargs)
        finally:
            lock.unlink()
    return operation


def catalog():
    maps = {}
    for folder, origin in ((REVISION / 'Maps', 'revision'), (PROJECT / 'maps', 'project')):
        for path in folder.glob('*.dx'):
            maps[path.stem.lower()] = dict(name=path.stem, origin=origin, path=str(path),
                                           bytes=path.stat().st_size)
    return sorted(maps.values(), key=lambda r: r['name'].lower())


def create_workspace(map_name):
    if not re.fullmatch(r'[A-Za-z0-9_-]+', map_name):
        raise ValueError('Supply a map name without a path or extension')
    entry = next((m for m in catalog() if m['name'].lower() == map_name.lower()), None)
    if not entry:
        raise ValueError('Map not found in project or Revision')
    source = Path(entry['path'])
    content = source.read_bytes()
    digest = hashlib.sha256(content).hexdigest()
    if sha(source) != digest:
        raise ValueError('Source changed while copying; retry')
    identity = uuid.uuid4().hex
    folder = WORKSPACES / identity
    folder.mkdir(parents=True)
    (folder / 'versions').mkdir()
    (folder / 'plans').mkdir()
    first = folder / 'versions' / 'original.dx'
    first.write_bytes(content)
    manifest = dict(workspace=identity, map_name=entry['name'], source=str(source),
                    source_sha256=digest, created_at=datetime.now().isoformat(timespec='seconds'),
                    current=0, versions=[dict(file='versions/original.dx', sha256=digest,
                                             parent=None, changes=[], action='checkout')])
    save(folder / 'manifest.json', manifest)
    return status(identity)


def workspace(identity):
    if not re.fullmatch(r'[0-9a-f]{32}', identity):
        raise ValueError('Invalid workspace ID')
    folder = WORKSPACES / identity
    if not folder.resolve().is_relative_to(WORKSPACES.resolve()):
        raise ValueError('Workspace must stay inside the bridge folder')
    manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
    version = manifest['versions'][manifest['current']]
    current = (folder / version['file']).resolve()
    if not current.is_relative_to(folder.resolve()) or current.suffix != '.dx':
        raise ValueError('Invalid workspace path')
    if sha(current) != version['sha256']:
        raise ValueError('Workspace map was edited outside the bridge')
    return folder, manifest, current


def status(identity):
    folder, manifest, current = workspace(identity)
    source = Path(manifest['source'])
    return dict(workspace=identity, map_name=manifest['map_name'], current_file=str(current),
                sha256=sha(current), current_version=manifest['current'],
                versions=len(manifest['versions']), source=str(source),
                source_changed=not source.exists() or sha(source) != manifest['source_sha256'],
                writes='private copies only; project maps and game installation are not overwritten')


def list_objects(identity, query='', class_name='', z_min=None, z_max=None, offset=0, limit=60, near=None):
    if near is not None:
        if (not isinstance(near, (list, tuple)) or len(near) != 4
                or any(type(v) not in (int, float) or not math.isfinite(v) for v in near)
                or near[3] < 0):
            raise ValueError('near requires four finite numbers: X Y Z RADIUS (radius >= 0)')
    _, _, current = workspace(identity)
    _, records = objects(current)
    if offset < 0 or limit < 1 or limit > 200:
        raise ValueError('offset must be nonnegative, limit between 1 and 200')
    rows = []
    for record in records:
        if class_name and record['class_name'].lower() != class_name.lower():
            continue
        if query and query.lower() not in json.dumps(record).lower():
            continue
        position = record['location']
        distance = None
        if near is not None:
            if position is None:
                continue
            distance = math.dist(position, near[:3])
            if distance > near[3]:
                continue
        if z_min is not None or z_max is not None:
            if position is None or (z_min is not None and position[2] < z_min) or (z_max is not None and position[2] > z_max):
                continue
        row = {k: record[k] for k in ('name', 'class_name', 'location', 'rotation', 'tag', 'event', 'hidden')}
        if near is not None:
            row['distance'] = distance
        rows.append(row)
    if near is not None:
        rows.sort(key=lambda row: (row['distance'], row['name']))
    return dict(sha256=sha(current), total=len(rows), offset=offset, objects=rows[offset:offset + limit],
                values='serialized overrides; null means inherited or unset')


def source_hits(query):
    if not isinstance(query, str) or len(query) < 3:
        return []
    hits = []
    for path in (PROJECT / 'src/UnatcoContinues/Classes').glob('*.uc'):
        for line_number, line in enumerate(path.read_text(encoding='latin1').splitlines(), 1):
            if query.lower() in line.lower():
                hits.append(dict(file=str(path), line=line_number, text=line.strip()[:220]))
                if len(hits) >= 24:
                    return hits
    return hits


def get_object(identity, actor):
    _, _, current = workspace(identity)
    _, records = objects(current)
    match = next((r for r in records if r['name'].lower() == actor.lower()), None)
    if not match:
        raise ValueError('Actor not found')
    return dict(sha256=sha(current), actor=match,
                source_hits=source_hits(match['tag'] or match['name']),
                values='serialized overrides; inherited defaults are not resolved')


def links(identity, actor):
    detail = get_object(identity, actor)
    selected = detail['actor']
    _, _, current = workspace(identity)
    _, records = objects(current)
    targets = []
    incoming = []
    for r in records:
        if selected['event'] and r['tag'] and selected['event'].lower() == r['tag'].lower():
            targets.append(r['name'])
        if selected['tag'] and r['event'] and selected['tag'].lower() == r['event'].lower():
            incoming.append(r['name'])
    return dict(actor=actor, tag=selected['tag'], event=selected['event'],
                event_targets=targets, triggered_by=incoming,
                scope='saved Tag/Event relationships; scripted or inherited links may be additional')


def plan_patch(identity, expected_sha256, operations):
    folder, _, current = workspace(identity)
    if sha(current) != expected_sha256:
        raise ValueError('Map SHA256 changed; refresh objects before planning')
    data, changes, _ = patch_bytes(current, operations)
    token = uuid.uuid4().hex
    plan = dict(plan=token, workspace=identity, base_sha256=expected_sha256,
                output_sha256=hashlib.sha256(data).hexdigest(), operations=operations, changes=changes,
                created_at=datetime.now().isoformat(timespec='seconds'))
    save(folder / 'plans' / (token + '.json'), plan)
    return plan


@locked
def apply_plan(identity, token):
    if not re.fullmatch(r'[0-9a-f]{32}', token):
        raise ValueError('Invalid plan ID')
    folder, manifest, current = workspace(identity)
    plan = json.loads((folder / 'plans' / (token + '.json')).read_text(encoding='utf-8'))
    if sha(current) != plan['base_sha256']:
        raise ValueError('Stale plan: current map changed')
    data, changes, changed_indices = patch_bytes(current, plan['operations'])
    if hashlib.sha256(data).hexdigest() != plan['output_sha256']:
        raise ValueError('Plan output changed; create a fresh plan')
    filename = 'versions/' + uuid.uuid4().hex + '.dx'
    target = folder / filename
    target.write_bytes(data)
    # Assert structural integrity and preservation of every unrelated export.
    previous, _ = objects(current)
    updated, rows = objects(target)
    if len(previous.exports) != len(updated.exports) or previous.imports != updated.imports:
        raise ValueError('Unexpected export/import table change')
    for index, (old, new) in enumerate(zip(previous.exports, updated.exports)):
        if any(old[k] != new[k] for k in ('name', 'class', 'super', 'pkg', 'flags')):
            raise ValueError('Unexpected export identity change')
        if index not in changed_indices:
            if previous.d[old['off']:old['off'] + old['size']] != updated.d[new['off']:new['off'] + new['size']]:
                raise ValueError('Unrelated export changed: ' + old['name'])
    for change in changes:
        row = next(r for r in rows if r['name'] == change['actor'])
        if not equal(row['properties'][change['property']], change['after']):
            raise ValueError('Property verification failed')
    manifest['versions'].append(dict(file=filename, sha256=sha(target), parent=manifest['current'],
                                     changes=changes, action='patch', plan=token))
    manifest['current'] = len(manifest['versions']) - 1
    save(folder / 'manifest.json', manifest)
    return dict(**status(identity), changes=changes, preserved_exports=len(previous.exports) - len(changed_indices))


@locked
def undo(identity, expected_sha256):
    folder, manifest, current = workspace(identity)
    if sha(current) != expected_sha256:
        raise ValueError('Map SHA256 changed; refresh before undo')
    parent = manifest['versions'][manifest['current']]['parent']
    if parent is None:
        raise ValueError('Already at the original copy')
    manifest['current'] = parent
    save(folder / 'manifest.json', manifest)
    return status(identity)


def create_preview(identity, runtime_file=None):
    from viewer import write_preview
    folder, manifest, current = workspace(identity)
    destination = folder / 'preview.html'
    write_preview(current, destination, manifest['map_name'], runtime_file)
    return dict(file=str(destination), sha256=sha(current), workspace=identity)
