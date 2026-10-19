"""Build the warehouse rear service access, preserving Revision's baked lighting.

Incremental CSG only: never MAP REBUILD or LIGHT APPLY. The caller chooses
the resulting workspace version for a reversible bridge trial before publication.
"""
import argparse
import json
import re
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE / 'editor_bridge'), str(HERE)]
import core
import editor
import geometry
import preserve_baked
from archive import objects


def box(name, low, high, texture="StanGrayCindr_B", sky_ceiling=False, unlit=False,
        warehouse=False, wall_phase=False, service_exit=False):
    x, y, z = low
    X, Y, Z = high
    faces = [
        ((-1, 0, 0), [(x,y,z),(x,y,Z),(x,Y,Z),(x,Y,z)]),
        ((1, 0, 0), [(X,y,z),(X,Y,z),(X,Y,Z),(X,y,Z)]),
        ((0,-1, 0), [(x,y,z),(X,y,z),(X,y,Z),(x,y,Z)]),
        ((0, 1, 0), [(x,Y,z),(x,Y,Z),(X,Y,Z),(X,Y,z)]),
        ((0, 0,-1), [(x,y,z),(x,Y,z),(X,Y,z),(X,y,z)]),
        ((0, 0, 1), [(x,y,Z),(X,y,Z),(X,Y,Z),(x,Y,Z)])]
    lines = ['Begin Brush Name=' + name, 'Begin PolyList']
    for normal, vertices in faces:
        # Origin is a point of this face, not the brush center.
        flags=(64 if unlit else 0) | (128 if sky_ceiling and normal==(0,0,1) else 0)
        u,v=((0,1,0),(0,0,-1)) if normal[0] else (((1,0,0),(0,0,-1)) if normal[1] else ((1,0,0),(0,-1,0)))
        face_texture=texture
        origin=vertices[0]
        if warehouse:
            if normal==(0,0,-1): face_texture='DamgGreyWood01'
            elif normal==(0,0,1): face_texture='DrtyWoodCrate_C'
            else: u=tuple(2*a for a in u); v=tuple(2*a for a in v)
        if wall_phase and normal[1]:
            # Match the original warehouse's front-wall mapping in world space.
            u=(-2,0,0); v=(0,0,-2)
            origin=(432,vertices[0][1],z)
        if service_exit and normal[0]:
            face_texture='SemiBackDoor_B'
            direction=1 if normal[0]<0 else -1
            origin=(vertices[0][0],y if direction>0 else Y,Z)
            u=(0,direction*256/(Y-y),0); v=(0,0,-256/(Z-z))
        lines += ['Begin Polygon Texture=' + face_texture + ' Flags=' + str(flags),
                  'Origin ' + ','.join(map(str, origin)),
                  'Normal ' + ','.join(map(str, normal)),
                  'TextureU ' + ','.join(map(str,u)), 'TextureV ' + ','.join(map(str,v))]
        lines += ['Vertex ' + ','.join(map(str, v)) for v in vertices]
        lines += ['End Polygon']
    return '\n'.join(lines + ['End PolyList', 'End Brush']) + '\n'


def additions():
    brush = box('UCMdlNorthAccess', (-64,-8,-56), (64,8,56), wall_phase=True)
    outer = box('UCMdlServiceBoundary', (-8,-96,-88), (8,96,88), 'ClenGrayMetal_A', service_exit=True)
    return ('Begin Map\nBegin Actor Class=DeusExMover Name=UCNorthDoor0\n'
            'Tag=UCNorthAccess\nLocation=(X=128,Y=-1152,Z=56)\n'
            'BasePos=(X=128,Y=-1152,Z=56)\n'
            'KeyPos(1)=(Z=-120)\nNumKeys=2\nMoveTime=2.0\nStayOpenTime=3600\n'
            'InitialState=TriggerOpenTimed\nbDynamicLightMover=True\n'
            'bIsDoor=True\nbFrobbable=False\nbPickable=False\nbBreakable=False\nbLocked=True\n'
            'bCollideActors=True\nbBlockActors=True\nbBlockPlayers=True\n'
            'MoverEncroachType=ME_IgnoreWhenEncroach\n'
            "OpeningSound=Sound'MoverSFX.door.MachineDoor3'\n"
            "ClosingSound=Sound'MoverSFX.door.MachineDoor3'\n"
            "MoveAmbientSound=Sound'MoverSFX.Other.ManholeMove'\n" + brush +
            "Brush=Model'MyLevel.UCMdlNorthAccess'\nEnd Actor\n"
            'Begin Actor Class=DeusExMover Name=UCServiceBoundary0\n'
            'Tag=UCServiceBoundary\nLocation=(X=944,Y=-1488,Z=248)\n'
            'BasePos=(X=944,Y=-1488,Z=248)\nNumKeys=1\n'
            'InitialState=TriggerOpenTimed\nbDynamicLightMover=True\n'
            'bIsDoor=True\nbFrobbable=True\nbPickable=False\nbBreakable=False\nbLocked=True\n'
            'bCollideActors=True\nbBlockActors=True\nbBlockPlayers=True\n'
            'KeyIDNeeded=UCOffMapServiceGate\nmsgKeyLocked="Service road access restricted."\n' + outer +
            "Brush=Model'MyLevel.UCMdlServiceBoundary'\nEnd Actor\n"
            'Begin Actor Class=ComputerSecurity Name=UCNorthConsole0\n'
            'Tag=UCNorthConsole\nLocation=(X=280,Y=-1128,Z=80)\n'
            'Rotation=(Yaw=16384)\nPhysics=PHYS_None\nComputerNode=CN_HKNet\n'
            'ItemName="Laboratory service control"\ntitleString="REAR SERVICE ACCESS"\n'
            'End Actor\n'
            'Begin Actor Class=Light Name=UCNorthLight0\n'
            'Tag=UCServiceLight\nLocation=(X=128,Y=-1240,Z=108)\n'
            'bStatic=False\nbMovable=True\nLightBrightness=65\nLightRadius=7\nEnd Actor\n'
            'Begin Actor Class=Light Name=UCServiceCourtLight0\n'
            'Location=(X=128,Y=-1488,Z=132)\n'
            'bStatic=False\nbMovable=True\nLightBrightness=65\nLightRadius=8\nLightHue=32\nLightSaturation=60\nEnd Actor\n'
            'Begin Actor Class=Light Name=UCServiceLaneLight0\n'
            'Location=(X=688,Y=-1488,Z=292)\n'
            'bStatic=False\nbMovable=True\nLightBrightness=85\nLightRadius=8\nEnd Actor\n'
            'Begin Actor Class=Light Name=UCServiceConsoleLight0\n'
            'Location=(X=200,Y=-1056,Z=148)\n'
            'bStatic=False\nbMovable=True\nLightBrightness=70\nLightRadius=6\nEnd Actor\n'
            'Begin Actor Class=CrateUnbreakableMed Name=UCServiceCrate0\n'
            'Location=(X=-64,Y=-1528,Z=32)\nEnd Actor\n'
            'Begin Actor Class=CrateUnbreakableMed Name=UCServiceCrate1\n'
            'Location=(X=-64,Y=-1456,Z=32)\nEnd Actor\n'
            'Begin Actor Class=CrateUnbreakableMed Name=UCServiceFrontCrate0\n'
            'Tag=UCServiceCargo\nLocation=(X=-40,Y=-1096,Z=32)\nEnd Actor\n'
            'Begin Actor Class=CrateUnbreakableMed Name=UCServiceFrontCrate1\n'
            'Tag=UCServiceCargo\nLocation=(X=-40,Y=-1024,Z=32)\nEnd Actor\n'
            'Begin Actor Class=CrateUnbreakableMed Name=UCServiceFrontCrate2\n'
            'Tag=UCServiceCargo\nLocation=(X=-40,Y=-1096,Z=96)\nEnd Actor\n'
            'Begin Actor Class=Cart Name=UCServiceCart0\n'
            'Location=(X=336,Y=-1304,Z=27)\nRotation=(Yaw=16384)\nEnd Actor\n'
            'Begin Actor Class=BoxSmall Name=UCServiceCartBox0\n'
            'Location=(X=336,Y=-1304,Z=64)\nEnd Actor\n'
            'Begin Actor Class=Barrel1 Name=UCServiceBarrel0\n'
            'Location=(X=-64,Y=-1328,Z=29)\nbExplosive=False\nEnd Actor\n'
            'Begin Actor Class=BoxMedium Name=UCServiceBox0\n'
            'Location=(X=40,Y=-1532,Z=30)\nEnd Actor\n'
            'Begin Actor Class=CrateUnbreakableSmall Name=UCServiceShelfCargo0\n'
            'Location=(X=136,Y=-1564,Z=68)\nEnd Actor\n'
            'Begin Actor Class=CrateUnbreakableSmall Name=UCServiceShelfCargo1\n'
            'Location=(X=208,Y=-1564,Z=120)\nEnd Actor\n'
            'Begin Actor Class=BoxSmall Name=UCServiceShelfBox0\n'
            'Location=(X=280,Y=-1564,Z=111)\nEnd Actor\n'
            'Begin Actor Class=BoxSmall Name=UCServiceShelfBox1\n'
            'Location=(X=128,Y=-1564,Z=7)\nEnd Actor\n'
            'Begin Actor Class=Teleporter Name=UCServiceExit0\n'
            'Tag=UCServiceExit\nURL="06_HongKong_WanChai_Compound#compound"\n'
            'Location=(X=1004,Y=-1488,Z=212)\nCollisionRadius=24\nCollisionHeight=50\n'
            'bEnabled=True\nEnd Actor\nEnd Map\n')


@core.locked
def build(identity, expected):
    workspace, manifest, current = core.workspace(identity)
    if core.sha(current) != expected:
        raise ValueError('Workspace changed before north-access build')
    package, rows = objects(current)
    if any(r['tag'] == 'UCNorthAccess' for r in rows):
        raise ValueError('North access already exists; undo to the original before rebuilding')
    folder, dependencies = editor.prepare_run(current, manifest['map_name'])
    name = manifest['map_name'] + '.dx'
    output = folder / 'Output' / name
    (folder / 'neck.t3d').write_text(box('UCServiceNeck', (64,-1264,0), (192,-1104,128),warehouse=True), encoding='ascii')
    (folder / 'courtyard.t3d').write_text(box('UCServiceCourt', (-128,-1600,0), (448,-1232,160),warehouse=True), encoding='ascii')
    (folder / 'lane.t3d').write_text(box('UCServiceStairwell', (416,-1584,0), (1040,-1392,336),warehouse=True), encoding='ascii')
    for step in range(8):
        (folder / ('step'+str(step)+'.t3d')).write_text(
            box('UCServiceStep'+str(step), (448+32*step,-1584,0), (1040,-1392,20*(step+1)),
                'DamgGreyWood01'),encoding='ascii')
    rack=[('rack0',(96,-1592,48),(320,-1536,52)),('rack1',(96,-1592,100),(320,-1536,104)),
          ('rackleg0',(96,-1592,0),(100,-1588,132)),('rackleg1',(316,-1592,0),(320,-1588,132)),
          ('rackleg2',(96,-1540,0),(100,-1536,132)),('rackleg3',(316,-1540,0),(320,-1536,132))]
    for part,low,high in rack:
        (folder/(part+'.t3d')).write_text(box('UCService'+part,low,high,'ClenGrayMetal_A'),encoding='ascii')
    (folder / 'actors.t3d').write_text(additions(), encoding='ascii')
    commands = ['MAP LOAD FILE="..\\Input\\' + name + '"',
                'MAP EXPORT FILE="..\\before.t3d"']
    for brush in ('neck', 'courtyard', 'lane'):
        commands += ['BRUSH RESET', 'BRUSH IMPORT FILE="..\\' + brush + '.t3d"', 'BRUSH SUBTRACT']
    for step in range(8):
        commands += ['BRUSH RESET','BRUSH IMPORT FILE="..\\step'+str(step)+'.t3d"','BRUSH ADD']
    for part,_,_ in rack:
        commands += ['BRUSH RESET','BRUSH IMPORT FILE="..\\'+part+'.t3d"','BRUSH ADD']
    commands += ['MAP IMPORTADD FILE="..\\actors.t3d"',
                 'UC_MOVER scale UCNorthDoor0 1 1 1',
                 'UC_MOVER scale UCServiceBoundary0 1 1 1',
                 'UC_WORLD finish',
                 'MAP SAVE FILE="..\\Output\\' + name + '"']
    editor.execute(folder, commands)
    preserve_baked.restore(current, output)
    subprocess.run([sys.executable, str(HERE / 'fix_brush_surfs.py'), str(output), 'UCMdlNorthAccess'], check=True)
    subprocess.run([sys.executable, str(HERE / 'fix_brush_surfs.py'), str(output), 'UCMdlServiceBoundary'], check=True)
    editor.execute(folder, ['MAP LOAD FILE="..\\Output\\' + name + '"',
                           'UC_MOVER bounds UCNorthDoor0 1 1 1',
                           'UC_MOVER bounds UCServiceBoundary0 1 1 1',
                           'MAP SAVE FILE="..\\Output\\' + name + '"',
                           'MAP EXPORT FILE="..\\after.t3d"'], 'reload.log')
    preserve_baked.restore(current,output)
    after_package, after_rows = objects(output)
    before_models = editor.model_snapshot(current, package)
    after_models = editor.model_snapshot(output, after_package)
    world_models = [m for m in after_models.values() if len(m['surfaces']) > 1000]
    if len(world_models) != 1 or not world_models[0]['native_details']['zones']:
        raise ValueError('Incremental world has no valid zone/collision partition')
    for model in before_models:
        for field in geometry.LIGHT_FIELDS:
            old, new = before_models[model][field], after_models[model][field]
            if field == 'lights':
                same = new[:len(old)] == old  # New BSP leaves use a rebased suffix.
            else:
                same = old == new
            if not same:
                raise ValueError('Existing baked lighting changed: ' + model + '/' + field)
        old_surfs = before_models[model]['surfaces']
        new_surfs = after_models[model]['surfaces']
        if any(s['iLightMap'] != new_surfs[i]['iLightMap'] for i,s in enumerate(old_surfs)):
            raise ValueError('Existing baked surface lighting index changed: ' + model)
    _, before = geometry.t3d_actors(folder / 'before.t3d')
    _, after = geometry.t3d_actors(folder / 'after.t3d')
    def gameplay(block):
        # The SDK invalidates cached BSP regions after incremental CSG; the
        # engine computes these from the new BSP on load. Selection is editor UI.
        return re.sub(r'^    (?:Region|FootRegion|HeadRegion|bSelected)=.*\n?', '', block, flags=re.M)
    for actor in before:
        if actor == 'Brush110':  # Original editor builder, never world geometry.
            continue
        if gameplay(before[actor]) != gameplay(after.get(actor, '')):
            raise ValueError('An original game actor changed: ' + actor)
    mover = geometry.mover_data(output, after_package, after_rows, 'UCNorthDoor0')[3]
    if not mover['scale_supported'] or not mover['origins_on_planes']:
        raise ValueError('New gate failed native brush/collision checks')
    version = 'versions/north-access-' + folder.name + '.dx'
    shutil.copy2(output, workspace / version)
    digest = core.sha(output)
    manifest['versions'].append(dict(file=version, sha256=digest,
        parent=manifest['current'], changes=[dict(operation='rear_service_access', bounds='narrow descending wall + furnished compact store + eight right-hand stairs + restricted exterior loading')],
        action='north_access', native_run=str(folder)))
    manifest['current'] = len(manifest['versions']) - 1
    core.save(workspace / 'manifest.json', manifest)
    report = dict(workspace=identity, output_sha256=digest, native_run=str(folder),
        compiled_packages=dependencies, existing_lighting_identical=True,
        input_gameplay_properties_identical=True, input_sha256=expected,
        original_map_sha256=manifest['source_sha256'],
        excluded_derived_properties=['Region', 'FootRegion', 'HeadRegion', 'bSelected', 'editor builder Brush110'],
        mover=mover, installed=False)
    core.save(folder / 'north-access-report.json', report)
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('workspace')
    parser.add_argument('--expected-sha256', required=True)
    args = parser.parse_args()
    print(json.dumps(build(args.workspace, args.expected_sha256), indent=2))
