"""Isolated SDK runs and compatibility checks; no generic console is exposed."""
import hashlib
import json
import re
import shutil
import subprocess
import uuid
import types
import struct

import core
import engine
from archive import objects
from lightbits import Model
from bspsurf import props_end

LAB = core.HERE / 'editor_lab'
HOST = LAB / 'UCEditorHost.exe'


def load_model(path, package, name):
    constructor = types.FunctionType(Model.__init__.__code__,
        {**Model.__init__.__globals__, 'Pkg': lambda _: package})
    model = Model.__new__(Model)
    try:
        constructor(model, str(path), name)
    except SystemExit as error:
        raise ValueError('Unsupported model ' + name + ': ' + str(error)) from error
    return model


def native_model_details(package, model):
    """Fields omitted by the lightbits view, including collision and render bounds."""
    p, d = package, package.d
    o = props_end(p, model.idx)
    bounding = d[o:o + 41].hex()
    o = model.sec['start']
    n, o = p.ci(o)
    nodes = []
    for _ in range(n):
        prefix = d[o:o + 25].hex()
        o += 25
        indices = []
        for _ in range(7):
            value, o = p.ci(o)
            indices.append(value)
        nodes.append([prefix, indices, d[o:o + 11].hex()])
        o += 11
    o = model.sec['surfs'][1]
    n, o = p.ci(o)
    vertices = []
    for _ in range(n):
        point, o = p.ci(o)
        side, o = p.ci(o)
        vertices.append([point, side])
    shared_sides, zones_count = struct.unpack_from('<ii', d, o)
    o += 8
    zones = []
    for _ in range(zones_count):
        actor, o = p.ci(o)
        zones.append([p.refname(actor), d[o:o + 16].hex()])
        o += 16
    polys, o = p.ci(o)
    if o != model.sec['lightmap'][0]:
        raise ValueError('Model zone/polygon alignment failed')
    o = model.sec['lightbits'][1]
    bounds_count, o = p.ci(o)
    bounds = d[o:o + bounds_count * 25].hex()
    o += bounds_count * 25
    hull_count, o = p.ci(o)
    hulls = d[o:o + hull_count * 4].hex()
    o += hull_count * 4
    n, o = p.ci(o)
    leaves = []
    for _ in range(n):
        indices = []
        for _ in range(3):
            value, o = p.ci(o)
            indices.append(value)
        leaves.append([indices, d[o:o + 8].hex()])
        o += 8
    if o != model.sec['lights'][0]:
        raise ValueError('Model collision/leaf alignment failed')
    return dict(bounding=bounding, full_nodes=nodes, full_vertices=vertices,
        shared_sides=shared_sides, zones=zones, polys=p.refname(polys),
        bounds=bounds, leaf_hulls=hulls, leaves=leaves,
        root_linked=d[model.sec['end'] - 8:model.sec['end']].hex())


def model_snapshot(path, package):
    # Reuse the package parser without changing the existing lightbits module.
    result = {}
    for export in package.exports:
        if package.classname(export) != 'Model':
            continue
        model = load_model(path, package, export['name'])
        surfaces = [{k: v for k, v in surf.items() if k not in ('tex_ref', 'actor_ref')}
                    for surf in model.surfs]
        result[export['name']] = dict(vectors=model.vectors, points=model.points,
            nodes=model.nodes, node_polys=model.node_polys, surfaces=surfaces,
            vertices=model.verts, lightmaps=model.lightmaps,
            lights=[package.refname(reference) for reference in model.lights],
            lightbits_sha256=hashlib.sha256(package.d[model.bits_at:model.bits_at + model.bits_len]).hexdigest(),
            lightbits_bytes=model.bits_len, native_details=native_model_details(package, model))
    return result


def prepare_run(current, map_name):
    if not HOST.exists():
        raise ValueError('Build the private SDK host first; see EDITOR_BACKEND.md')
    build = json.loads((LAB / 'host-build.json').read_text(encoding='utf-8-sig'))
    if build['host_sha256'] != core.sha(HOST) or build['source_sha256'] != core.sha(core.HERE / 'editor_src/UCEditorSdkHost.cpp'):
        raise ValueError('Native host/source changed; rebuild the host')
    for name, digest in build['dll_sha256'].items():
        if core.sha(core.PROJECT / 'DevInstall/System' / name) != digest:
            raise ValueError('SDK DLL changed; rebuild the host against the current DLLs')
    base = engine.prepare_lab()
    folder = LAB / 'runs' / uuid.uuid4().hex
    system = folder / 'System'
    system.mkdir(parents=True)
    for path in base.iterdir():
        if path.is_file() and path.suffix.lower() == '.ini':
            shutil.copy2(path, system / path.name)
        elif path.is_file() and path.suffix.lower() in ('.exe', '.dll', '.u', '.int'):
            if path.name not in ('UnatcoContinues.u', 'UnatcoVoices.u'):
                (system / path.name).hardlink_to(path)
    for name, digest in build['dll_sha256'].items():
        if core.sha(system / name) != digest:
            raise ValueError('Private runtime SDK differs from host build; refresh the laboratory')
    dependencies = {}
    for name in ('UnatcoContinues.u', 'UnatcoVoices.u'):
        source = core.PROJECT / 'dist' / name
        digest = core.sha(source)
        shutil.copy2(source, system / name)
        if core.sha(source) != digest or core.sha(system / name) != digest:
            raise ValueError('Compiled mod changed during copying; retry')
        dependencies[name] = digest
    shutil.copy2(HOST, system / HOST.name)
    lines = []
    for line in engine.read_ini(base / 'DeusEx.ini').splitlines():
        if line.startswith(('EditPackages=', 'AutoSave=')):
            continue
        if line == '[Editor.EditorEngine]':
            lines.extend([line, 'AutoSave=False', *('EditPackages=' + name for name in
                ('Core', 'Engine', 'Editor', 'Extension', 'DeusExUI', 'ConSys', 'DeusEx', 'Revision'))])
            continue
        if line == '[Core.System]':
            lines.extend([line, 'Paths=' + str(system / '*.u')])
            continue
        lines.append(line)
    for name in ('Default.ini', 'DeusEx.ini', 'Revision.ini', 'ucc.ini', 'Editor.ini', 'UnrealEd.ini'):
        (system / name).write_text('\n'.join(lines) + '\n', encoding='latin1')
    (folder / 'Input').mkdir()
    (folder / 'Output').mkdir()
    source = folder / 'Input' / (map_name + '.dx')
    shutil.copy2(current, source)
    if core.sha(source) != core.sha(current):
        raise ValueError('Workspace changed during copying')
    return folder, dependencies


def execute(folder, commands, log_name='editor.log'):
    """Run a bridge-generated recipe in its own native editor process."""
    command_file = folder / ('commands-' + uuid.uuid4().hex + '.txt')
    command_file.write_text('\n'.join(commands) + '\n', encoding='ascii')
    log = folder / log_name
    with log.open('wb') as stream:
        process = subprocess.run([str(folder / 'System' / HOST.name), str(command_file)],
            cwd=folder / 'System', stdin=subprocess.DEVNULL, stdout=stream, stderr=subprocess.STDOUT,
            timeout=90, creationflags=subprocess.CREATE_NO_WINDOW)
    text = log.read_text(encoding='utf-8', errors='replace')
    if (process.returncode or 'UCEditorHost|done' not in text
            or text.count('UCEditorHost|complete') != len(commands)
            or re.search(r'(?im)^.*(?:Failed to load|Failed loading|Failed import|Critical:|Unrecognized editor|appRequestExit\(1\))', text)):
        raise ValueError('Native editor failed; see ' + str(log))
    return text


@core.locked
def check(identity, expected_sha256):
    workspace_folder, manifest, current = core.workspace(identity)
    if not re.fullmatch(r'[A-Za-z0-9_-]+', manifest['map_name']):
        raise ValueError('Invalid map name in workspace')
    if core.sha(current) != expected_sha256:
        raise ValueError('Workspace SHA256 changed; refresh before editor check')
    folder, dependencies = prepare_run(current, manifest['map_name'])
    source = folder / 'Input' / (manifest['map_name'] + '.dx')
    output = folder / 'Output' / source.name
    report = dict(workspace=identity, operation='native SDK load-save-reload', passed=False,
        input_sha256=expected_sha256, output=str(output), host_sha256=core.sha(HOST),
        compiled_packages=dependencies, folder=str(folder), lighting_rebuild=False,
        workspace_version_selected=False)
    core.save(folder / 'report.json', report)
    commands = [
        'MAP LOAD FILE="..\\Input\\' + source.name + '"',
        'MAP EXPORT FILE="..\\before.t3d"',
        'MAP SAVE FILE="..\\Output\\' + source.name + '"',
        'MAP LOAD FILE="..\\Output\\' + source.name + '"',
        'MAP EXPORT FILE="..\\after.t3d"']
    # SDK filename parsing truncates long absolute names: use short, private relative paths.
    try:
        text = execute(folder, commands)
        for name in ('before.t3d', 'after.t3d'):
            path = folder / name
            if not path.exists() or path.stat().st_size < 1000:
                raise ValueError('Incomplete map export from native editor')
        if not output.exists():
            raise ValueError('Native editor did not save the output map')
        before_package, before = objects(source)
        after_package, after = objects(output)
        before_by_name = {row['name']: row for row in before}
        after_by_name = {row['name']: row for row in after}
        report['actors_before'] = len(before)
        report['actors_after'] = len(after)
        report['actor_names_preserved'] = before_by_name.keys() == after_by_name.keys()
        removed = before_by_name.keys() - after_by_name.keys()
        report['removed_editor_cameras'] = sorted(name for name in removed if before_by_name[name]['class_name'] == 'Camera')
        report['game_actor_names_preserved'] = (not after_by_name.keys() - before_by_name.keys()
            and all(before_by_name[name]['class_name'] == 'Camera' for name in removed))
        report['serialized_actor_differences'] = sorted(name for name in before_by_name.keys() & after_by_name.keys()
            if before_by_name[name]['class_name'] != after_by_name[name]['class_name']
            or before_by_name[name]['properties'] != after_by_name[name]['properties'])
        report['native_text_preserved'] = (folder / 'before.t3d').read_bytes() == (folder / 'after.t3d').read_bytes()
        before_models, after_models = model_snapshot(source, before_package), model_snapshot(output, after_package)
        report['model_names_preserved'] = before_models.keys() == after_models.keys()
        report['changed_models'] = sorted(name for name in before_models.keys() & after_models.keys()
                                    if before_models[name] != after_models[name])
        report['lighting_preserved'] = all(
            name in after_models and all(before_models[name][key] == after_models[name][key]
                for key in ('lightmaps', 'lights', 'lightbits_sha256', 'lightbits_bytes'))
            for name in before_models)
        report['output_sha256'] = core.sha(output)
        report['t3d_before'] = str(folder / 'before.t3d')
        report['t3d_after'] = str(folder / 'after.t3d')
        report['native_actor_counts'] = re.findall(r'UCEditorHost\|actors\|(\d+)', text)
        if (not report['game_actor_names_preserved'] or not report['native_text_preserved']
                or not report['model_names_preserved'] or report['changed_models']
                or not report['lighting_preserved']):
            raise ValueError('SDK roundtrip changed map data; output preserved for review, not selected')
        if core.sha(current) != expected_sha256 or core.sha(source) != expected_sha256:
            raise ValueError('Input changed during editor check')
        report['passed'] = True
        report['report_file'] = str(folder / 'report.json')
        report['scope'] = ('Native editor text, model geometry and baked lighting verified. '
            'The SDK rewrites serialization and can store inherited defaults; output is diagnostic, '
            'never automatically selected as a workspace version.')
        return report
    except (Exception, KeyboardInterrupt) as error:
        report['error'] = str(error)
        raise ValueError(str(error) + '\nReport: ' + str(folder / 'report.json')) from error
    finally:
        core.save(folder / 'report.json', report)
