"""Private one-time site survey for the Wan Chai rooftop arrival."""
import json
import sys
from pathlib import Path
sys.path[:0] = [str(Path(__file__).parent), str(Path(__file__).parent.parent)]
import core
import editor
from archive import objects

site = core.create_workspace('06_HongKong_WanChai_Market')
folder, manifest, current = core.workspace(site['workspace'])
run, deps = editor.prepare_run(current, manifest['map_name'])
editor.execute(run, ['MAP LOAD FILE="..\\Input\\06_HongKong_WanChai_Market.dx"',
    'MAP EXPORT FILE="..\\market.t3d"', 'MAP NEW',
    'MAP SAVE FILE="..\\Output\\blank.dx"', 'MAP EXPORT FILE="..\\blank.t3d"'])
p, rows = objects(current)
core.save(folder/'site-survey.json', dict(site=site, run=str(run),
    landmarks=[r for r in rows if r['class_name'] in
        ('Teleporter','DeusExLevelInfo','LevelInfo','SkyZoneInfo','Jock','BlackHelicopter')
        or r['class_name'].startswith('Truck')], dependencies=deps))
print(json.dumps(dict(workspace=site['workspace'], run=str(run),
    landmarks=[{k:r[k] for k in ('name','class_name','location','tag')} for r in rows
        if r['class_name'] in ('Teleporter','DeusExLevelInfo','LevelInfo','SkyZoneInfo')]),indent=2))
