"""Reviewable native mover recipes, staged outputs and exact workspace undo."""
from datetime import datetime
import difflib
import json
import math
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import uuid

import core
import editor
from archive import ancestry_index, objects
from fix_brush_surfs import read_polys

FIXER = core.PROJECT / 'tools/fix_brush_surfs.py'
LIGHT_FIELDS = ('lightmaps', 'lights', 'lightbits_sha256', 'lightbits_bytes')


def vector(value, label):
    if (not isinstance(value, (tuple, list)) or len(value) != 3
            or any(type(v) not in (int, float) or not math.isfinite(v) for v in value)):
        raise ValueError(label + ' requires three finite numbers')
    return list(value)


def close(left, right, epsilon=0.002):
    if isinstance(left, (list, tuple)) and isinstance(right, (list, tuple)):
        return len(left) == len(right) and all(close(a, b, epsilon) for a, b in zip(left, right))
    if type(left) in (int, float) and type(right) in (int, float):
        return abs(left - right) <= epsilon
    return left == right


def is_mover(class_name, ancestry):
    seen = set()
    while class_name.lower() not in seen:
        name = class_name.lower()
        if name == 'mover':
            return True
        seen.add(name)
        class_name = ancestry.get(name, '')
    return False


def mover_data(path, package, rows, actor):
    row = next((r for r in rows if r['name'].lower() == actor.lower()), None)
    if not row or not is_mover(row['class_name'], ancestry_index()):
        raise ValueError('Only an existing Mover subclass is supported: ' + actor)
    name = row['properties'].get('Brush')
    if not name or not re.fullmatch(r'[A-Za-z0-9_]+', name):
        raise ValueError('Mover has no supported brush model')
    model = editor.load_model(path, package, name)
    details = editor.native_model_details(package, model)
    polys_ref = package.find_export(details['polys'], 'Polys')
    if not polys_ref:
        raise ValueError('Brush has no editable polygons')
    try:
        polys = read_polys(package, polys_ref)
    except SystemExit as error:
        raise ValueError('Unsupported polygon serialization: ' + str(error)) from error
    vertices = [v for poly in polys for v in poly['verts']]
    if not vertices:
        raise ValueError('Brush is empty')
    bounds = [[min(v[i] for v in vertices) for i in range(3)],
              [max(v[i] for v in vertices) for i in range(3)]]
    convex = len(polys) >= 4
    planar = True
    edges = {}
    for poly in polys:
        normal = poly['normal']
        if not close(math.dist(normal, [0, 0, 0]), 1, 0.001) or len(poly['verts']) < 3:
            planar = convex = False
            continue
        if any(abs(sum(v[i] * normal[i] for i in range(3)) - poly['w']) > 0.01 for v in poly['verts']):
            planar = False
        if any(sum(v[i] * normal[i] for i in range(3)) - poly['w'] > 0.01 for v in vertices):
            convex = False
        for a, b in zip(poly['verts'], poly['verts'][1:] + poly['verts'][:1]):
            edge = tuple(sorted((tuple(round(x, 3) for x in a), tuple(round(x, 3) for x in b))))
            edges[edge] = edges.get(edge, 0) + 1
    closed = bool(edges) and all(count == 2 for count in edges.values())
    lighting_empty = not (model.bits_len or model.lights
        or any(s['iLightMap'] >= 0 for s in model.surfs))
    shared = sorted(r['name'] for r in rows if r['properties'].get('Brush') == name and r['name'] != row['name'])
    dynamic = row['properties'].get('bDynamicLightMover') is True
    summary = dict(actor=row['name'], class_name=row['class_name'], model=name,
        location=row['location'], base_pos=row['properties'].get('BasePos'),
        pre_pivot=row['properties'].get('PrePivot', [0, 0, 0]), local_bounds=bounds,
        polygons=len(polys), nodes=len(model.nodes), convex=convex, closed=closed,
        planar=planar, origins_on_planes=not any(p['moved'] for p in polys),
        dynamic_lighting=dynamic, baked_lighting_empty=lighting_empty,
        unused_lightmaps=len(model.lightmaps) if lighting_empty else 0,
        shared_model_actors=shared, translate_supported=row['location'] is not None,
        scale_supported=convex and closed and planar and dynamic and lighting_empty and not shared)
    return row, model, polys, summary


def inspect(identity, actor):
    _, _, current = core.workspace(identity)
    package, rows = objects(current)
    return dict(sha256=core.sha(current), **mover_data(current, package, rows, actor)[3],
        units='Unreal units; local_bounds are before actor rotation/MainScale/PostScale')


def t3d_actors(path):
    text = path.read_text(encoding='latin1')
    blocks = {}
    for match in re.finditer(r'^Begin Actor Class=\w+ Name=(\w+)\r?\n.*?^End Actor\s*$', text, re.M | re.S):
        name = match.group(1)
        if name in blocks:
            raise ValueError('Duplicate native T3D actor')
        blocks[name] = match.group(0)
    if not blocks:
        raise ValueError('Native editor produced no actor export')
    return text, blocks


def canonical_poly(package, poly):
    return dict(base=struct.unpack_from('<fff', package.d, poly['base_at']),
        normal=poly['normal'], u=poly['u'], v=poly['v'], verts=poly['verts'],
        flags=poly['flags'], texture=package.refname(poly['tex']), pan=poly['pan'])


def verify_output(source, output, folder, operations):
    before_package, before_rows = objects(source)
    after_package, after_rows = objects(output)
    before_text, before = t3d_actors(folder / 'before.t3d')
    after_text, after = t3d_actors(folder / 'after.t3d')
    targets = {operation['actor'] for operation in operations}
    if before.keys() != after.keys():
        raise ValueError('Native editor added or removed game actors')
    for name in targets:
        before_text = before_text.replace(before[name], 'UC_TARGET:' + name)
        after_text = after_text.replace(after[name], 'UC_TARGET:' + name)
    if before_text != after_text:
        raise ValueError('Native recipe changed unrelated actor/world text')
    translations = {o['actor']: o for o in operations if o['operation'] == 'translate'}
    scales = {o['actor']: o for o in operations if o['operation'] == 'scale'}
    checks = []
    scaled_models = set()
    for name in targets:
        old_row, old_model, old_polys, old = mover_data(source, before_package, before_rows, name)
        new_row, new_model, new_polys, new = mover_data(output, after_package, after_rows, name)
        old_block, new_block = before[name], after[name]
        if name in scales:
            scaled_models.add(old['model'])
            pattern = r'^    Begin Brush.*?^    End Brush\s*$'
            old_block = re.sub(pattern, '    UC_BRUSH', old_block, flags=re.M | re.S)
            new_block = re.sub(pattern, '    UC_BRUSH', new_block, flags=re.M | re.S)
        if name in translations:
            pattern = r'^    (?:Location|BasePos)=.*\n?'
            old_block = re.sub(pattern, '', old_block, flags=re.M)
            new_block = re.sub(pattern, '', new_block, flags=re.M)
            delta = translations[name]['delta']
            for field, default in (('Location', [0, 0, 0]), ('BasePos', [0, 0, 0])):
                wanted = [v + d for v, d in zip(old_row['properties'].get(field, default), delta)]
                if not close(new_row['properties'].get(field, default), wanted):
                    raise ValueError('Mover absolute position verification failed: ' + field)
        if old_block != new_block:
            raise ValueError('Mover properties/keyframes changed outside recipe: ' + name)
        if len(old_polys) != len(new_polys):
            raise ValueError('Mover polygon count changed')
        for old_poly, new_poly in zip(old_polys, new_polys):
            a, b = canonical_poly(before_package, old_poly), canonical_poly(after_package, new_poly)
            if name in scales:
                scale = scales[name]['factors']
                pivot = old['pre_pivot']
                for key in ('verts', 'base'):
                    values = a[key] if key == 'verts' else [a[key]]
                    scaled = [[(v[i] - pivot[i]) * scale[i] + pivot[i] for i in range(3)] for v in values]
                    a[key] = scaled if key == 'verts' else scaled[0]
                a['normal'] = [a['normal'][i] / scale[i] for i in range(3)]
                length = math.dist(a['normal'], [0, 0, 0])
                a['normal'] = [v / length for v in a['normal']]
                for key in ('u', 'v'):
                    a[key] = [a[key][i] / scale[i] for i in range(3)]
                # Origins may be projected onto their face after reconstruction.
                distance = sum((a['base'][i] - a['verts'][0][i]) * a['normal'][i] for i in range(3))
                a['base'] = [a['base'][i] - distance * a['normal'][i] for i in range(3)]
            if any(not close(a[key], b[key]) for key in a):
                raise ValueError('Unexpected mover polygon/texture change: ' + name)
        if name in scales and not all(new[k] for k in ('convex', 'closed', 'planar', 'origins_on_planes')):
            raise ValueError('Rebuilt mover failed geometry validation')
        checks.append(dict(actor=name, before=old, after=new, keyframes_preserved=True,
                           polygon_transform_verified=True))
    old_models = editor.model_snapshot(source, before_package)
    new_models = editor.model_snapshot(output, after_package)
    if old_models.keys() != new_models.keys():
        raise ValueError('Model set changed')
    changed_models = sorted(name for name in old_models if old_models[name] != new_models[name])
    if any(name not in scaled_models for name in changed_models):
        raise ValueError('Unrelated model changed: ' + ', '.join(changed_models))
    if any(any(old_models[name][key] != new_models[name][key] for key in LIGHT_FIELDS) for name in old_models):
        raise ValueError('Baked lighting changed')
    old_actors = {r['name']: r['class_name'] for r in before_rows}
    new_actors = {r['name']: r['class_name'] for r in after_rows}
    removed = old_actors.keys() - new_actors.keys()
    if (new_actors.keys() - old_actors.keys() or any(old_actors[n] != 'Camera' for n in removed)
            or any(old_actors[n] != new_actors[n] for n in new_actors)):
        raise ValueError('Saved game actor set changed')
    diff = ''.join(difflib.unified_diff((folder / 'before.t3d').read_text(encoding='latin1').splitlines(True),
        (folder / 'after.t3d').read_text(encoding='latin1').splitlines(True), fromfile='before.t3d', tofile='after.t3d'))
    (folder / 'changes.diff').write_text(diff, encoding='utf-8')
    return dict(actors=checks, changed_models=changed_models, lighting_preserved=True,
        unrelated_native_text_preserved=True, game_actors_preserved=True,
        removed_editor_cameras=sorted(removed), models_checked=len(old_models),
        native_diff=str(folder / 'changes.diff'))


@core.locked
def plan(identity, expected_sha256, operations):
    workspace_folder, manifest, current = core.workspace(identity)
    if core.sha(current) != expected_sha256:
        raise ValueError('Workspace SHA256 changed; refresh before geometry plan')
    if not re.fullmatch(r'[A-Za-z0-9_-]+', manifest['map_name']):
        raise ValueError('Invalid map name')
    if not isinstance(operations, list) or not 1 <= len(operations) <= 16:
        raise ValueError('Provide 1 to 16 mover operations')
    package, rows = objects(current)
    recipe, seen = [], set()
    for item in operations:
        if not isinstance(item, dict) or not re.fullmatch(r'[A-Za-z0-9_]+', str(item.get('actor', ''))):
            raise ValueError('Invalid mover operation/actor name')
        operation = item.get('operation')
        fields = {'actor', 'operation', 'expected_location', 'delta'} if operation == 'translate' else {
            'actor', 'operation', 'expected_bounds', 'factors'}
        if operation not in ('translate', 'scale') or set(item) != fields:
            raise ValueError('Supported recipes: translate (expected_location, delta), scale (expected_bounds, factors)')
        _, _, _, detail = mover_data(current, package, rows, item['actor'])
        name = detail['actor']
        if (name, operation) in seen:
            raise ValueError('Duplicate operation for mover')
        seen.add((name, operation))
        item = dict(item, actor=name)
        if operation == 'translate':
            previous = vector(item['expected_location'], 'expected_location')
            delta = vector(item['delta'], 'delta')
            if not close(previous, detail['location']):
                raise ValueError('Mover location changed')
            if not any(delta) or any(abs(v) > 32768 for v in delta):
                raise ValueError('Translation must be nonzero and within 32768 units per axis')
        else:
            scale = vector(item['factors'], 'factors')
            bounds = item['expected_bounds']
            if not isinstance(bounds, list) or len(bounds) != 2:
                raise ValueError('expected_bounds requires [minXYZ, maxXYZ]')
            vector(bounds[0], 'minimum bounds'); vector(bounds[1], 'maximum bounds')
            if not close(bounds, detail['local_bounds']):
                raise ValueError('Mover bounds changed')
            if not detail['scale_supported']:
                raise ValueError('Scale requires a closed convex brush, an unshared model and explicit dynamic lighting without baked lightmaps')
            if any(v < 0.1 or v > 10 for v in scale) or close(scale, [1, 1, 1], 0):
                raise ValueError('Scale factors must be 0.1 to 10 and change at least one axis')
        recipe.append(item)
    folder, dependencies = editor.prepare_run(current, manifest['map_name'])
    source = folder / 'Input' / (manifest['map_name'] + '.dx')
    output = folder / 'Output' / source.name
    report = dict(workspace=identity, operation='native mover recipe', operations=recipe,
        input_sha256=expected_sha256, output=str(output), passed=False,
        lighting_rebuild=False, compiled_packages=dependencies, host_sha256=core.sha(editor.HOST),
        fixer_sha256=core.sha(FIXER), report_file=str(folder / 'report.json'))
    report['sdk_dll_sha256'] = json.loads((editor.LAB / 'host-build.json').read_text(encoding='utf-8-sig'))['dll_sha256']
    core.save(folder / 'report.json', report)
    commands = ['MAP LOAD FILE="..\\Input\\' + source.name + '"', 'MAP EXPORT FILE="..\\before.t3d"']
    for item in recipe:
        values = item['delta'] if item['operation'] == 'translate' else item['factors']
        commands.append('UC_MOVER ' + item['operation'] + ' ' + item['actor'] + ' ' + ' '.join(format(v, '.9g') for v in values))
    commands.append('MAP SAVE FILE="..\\Output\\' + source.name + '"')
    try:
        editor.execute(folder, commands)
        fixer_logs = []
        for item in recipe:
            if item['operation'] != 'scale':
                continue
            name = mover_data(current, package, rows, item['actor'])[3]['model']
            log = folder / ('fix-' + name + '.log')
            # The established fixer validates the rebuilt node/surface correspondence
            # and convex BSP, then repairs only this model on the staged copy.
            with log.open('wb') as stream:
                process = subprocess.run([sys.executable, str(FIXER), str(output), name],
                    stdin=subprocess.DEVNULL, stdout=stream, stderr=subprocess.STDOUT, timeout=45,
                    creationflags=subprocess.CREATE_NO_WINDOW)
            if process.returncode:
                raise ValueError('Mover surface correction failed: ' + str(log))
            fixer_logs.append(str(log))
        editor.execute(folder, ['MAP LOAD FILE="..\\Output\\' + source.name + '"',
            'MAP EXPORT FILE="..\\after.t3d"'], 'reload.log')
        report.update(verify_output(source, output, folder, recipe))
        if core.sha(current) != expected_sha256 or core.sha(source) != expected_sha256:
            raise ValueError('Input changed during native recipe')
        report.update(passed=True, output_sha256=core.sha(output), surface_fixer_logs=fixer_logs)
        token = uuid.uuid4().hex
        result = dict(plan=token, kind='native_movers', workspace=identity,
            base_sha256=expected_sha256, output_sha256=report['output_sha256'],
            created_at=datetime.now().isoformat(timespec='seconds'), operations=recipe,
            staged_file=str(output), report_file=report['report_file'],
            host_sha256=report['host_sha256'], fixer_sha256=report['fixer_sha256'],
            sdk_dll_sha256=report['sdk_dll_sha256'],
            compiled_packages=dependencies, validation=report,
            writes='staged private output; apply-movers selects it, undo restores exact previous bytes')
        core.save(workspace_folder / 'plans' / (token + '.json'), result)
        return result
    except (Exception, KeyboardInterrupt) as error:
        report['error'] = str(error)
        raise ValueError(str(error) + '\nReport: ' + report['report_file']) from error
    finally:
        core.save(folder / 'report.json', report)


@core.locked
def apply(identity, token):
    if not re.fullmatch(r'[0-9a-f]{32}', token):
        raise ValueError('Invalid plan ID')
    folder, manifest, current = core.workspace(identity)
    plan = json.loads((folder / 'plans' / (token + '.json')).read_text(encoding='utf-8'))
    if plan.get('kind') != 'native_movers' or plan.get('workspace') != identity:
        raise ValueError('Not a native mover plan for this workspace')
    if core.sha(current) != plan['base_sha256']:
        raise ValueError('Stale plan: current map changed')
    staged = Path(plan['staged_file']).resolve()
    if not staged.is_relative_to((editor.LAB / 'runs').resolve()) or staged.suffix != '.dx':
        raise ValueError('Staged output must stay inside the private SDK laboratory')
    if core.sha(staged) != plan['output_sha256'] or not plan['validation']['passed']:
        raise ValueError('Validated staged output changed; make a fresh plan')
    if core.sha(editor.HOST) != plan['host_sha256'] or core.sha(FIXER) != plan['fixer_sha256']:
        raise ValueError('Native backend changed; make a fresh plan')
    for name, digest in plan['sdk_dll_sha256'].items():
        if core.sha(core.PROJECT / 'DevInstall/System' / name) != digest:
            raise ValueError('SDK dependency changed; make a fresh plan')
    for name, digest in plan['compiled_packages'].items():
        if core.sha(core.PROJECT / 'dist' / name) != digest:
            raise ValueError('Compiled mod changed since planning; make a fresh plan')
    filename = 'versions/' + uuid.uuid4().hex + '.dx'
    target = folder / filename
    shutil.copy2(staged, target)
    if core.sha(target) != plan['output_sha256']:
        raise ValueError('Staged output changed during copying')
    if core.sha(current) != plan['base_sha256']:
        raise ValueError('Workspace changed during copying')
    for name, digest in plan['compiled_packages'].items():
        if core.sha(core.PROJECT / 'dist' / name) != digest:
            raise ValueError('Compiled mod changed during applying; make a fresh plan')
    manifest['versions'].append(dict(file=filename, sha256=plan['output_sha256'],
        parent=manifest['current'], changes=plan['operations'], action='native_movers', plan=token))
    manifest['current'] = len(manifest['versions']) - 1
    core.save(folder / 'manifest.json', manifest)
    return dict(**core.status(identity), operations=plan['operations'], validation=plan['validation'])
