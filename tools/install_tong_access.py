"""Publish only the checked Tong access map after a restored real-game trial."""
import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import shutil
import sys
import uuid

HERE=Path(__file__).resolve().parent
sys.path[:0]=[str(HERE/'editor_bridge')]
import core
import trial


def publish(package_trial,appearance_base_trial=None):
    if not package_trial.startswith('packages-') or len(package_trial)!=41:
        raise ValueError('Use the package trial identity from try_campaign_build')
    folder=(trial.TRIALS/package_trial).resolve(strict=True)
    if folder.parent!=trial.TRIALS.resolve():
        raise ValueError('Trial outside managed folder')
    journal=json.loads((folder/'journal.json').read_text())
    proof=journal.get('map_trial',{})
    checks=journal.get('gameplay_checks',[0,1])
    if not journal['restored'] or not proof.get('restored') or proof.get('status')!='passed':
        raise ValueError('A restored, passing game trial is required')
    workspace,manifest,source=core.workspace(proof['workspace'])
    appearance_check=None
    if appearance_base_trial:
        # A material-only update reuses the campaign proof for its unchanged input.
        # The focused trial still has to load the exact output and test the gate.
        if not appearance_base_trial.startswith('packages-') or len(appearance_base_trial)!=41:
            raise ValueError('Invalid base trial')
        base_folder=(trial.TRIALS/appearance_base_trial).resolve(strict=True)
        if base_folder.parent!=trial.TRIALS.resolve(): raise ValueError('Base trial outside managed folder')
        base=json.loads((base_folder/'journal.json').read_text())
        base_checks=base.get('gameplay_checks',[0,1])
        original_copy=workspace/manifest['versions'][0]['file']
        if (not base.get('restored') or not base.get('map_trial',{}).get('restored') or
                base['map_trial']['status']!='passed' or base_checks[0]<28 or base_checks[1] or
                core.sha(original_copy)!=base['map_trial']['trial_sha256'] or
                any(base['packages'][name]['trial']!=entry['trial'] for name,entry in journal['packages'].items())):
            raise ValueError('The appearance input needs a fully passing campaign trial with identical packages')
        if not any('UCServiceBoundary' in line and 'posizione 0' in line for line in proof.get('actor_positions',[])):
            raise ValueError('Focused gate trial must record the closed gate after interaction')
        from refine_service_exit import verify_style
        appearance_check=verify_style(original_copy,source)
    elif checks[0]<28 or checks[1]:
        raise ValueError('A fully passing gameplay trial is required')
    expected=proof['trial_sha256']
    if manifest['map_name']!='06_HongKong_TongBase' or core.sha(source)!=expected:
        raise ValueError('The tested Tong map changed')
    for name,entry in journal['packages'].items():
        if core.sha(core.REVISION/'System'/name)!=entry['trial']:
            raise ValueError('Install the exact tested packages before the map: '+name)
    original=core.REVISION/'Maps/06_HongKong_TongBase.dx'
    steam_sha=journal.get('steam_original_map_sha256',proof['original_sha256'])
    if core.sha(original)!=steam_sha:
        raise ValueError('Original Revision map changed after the trial')
    active=(core.REVISION.parent/proof['game_relative_map']).resolve()
    allowed=[(core.REVISION/'Maps/06_HongKong_TongBase.dx').resolve(),
             (core.REVISION/'UnatcoMaps/06_HongKong_TongBase.dx').resolve()]
    if active not in allowed or core.sha(active)!=proof['original_sha256']:
        raise ValueError('Previously installed map changed after the trial')
    ini=(core.REVISION/'System/Revision.ini').read_text(encoding='latin-1')
    if 'Paths=..\\UnatcoMaps\\*.dx' not in ini:
        raise ValueError('Revision is not configured to load the custom map folder')
    trial.require_closed()
    backup=core.PROJECT/'dist/backup'/('tong-access-'+datetime.now().strftime('%Y%m%d-%H%M%S'))
    backup.mkdir(parents=True,exist_ok=False)
    targets=[core.PROJECT/'maps/06_HongKong_TongBase.dx',
             core.REVISION/'UnatcoMaps/06_HongKong_TongBase.dx']
    previous={str(path):core.sha(path) if path.exists() else None for path in targets}
    helipad=[core.PROJECT/'maps/06_HongKong_Helibase.dx',
             core.REVISION/'UnatcoMaps/06_HongKong_Helibase.dx']
    helipad_hashes={str(path):core.sha(path) for path in helipad if path.exists()}
    audit={'trial':package_trial,'map_sha256':expected,'original_sha256':core.sha(original),
           'previous':previous,'helipad':helipad_hashes,'installed':False}
    if appearance_check:
        audit.update(appearance_base_trial=appearance_base_trial,appearance_check=appearance_check)
    core.save(backup/'installation.json',audit)
    for i,path in enumerate(targets):
        if path.exists(): shutil.copy2(path,backup/(str(i)+'-original.dx'))
    written=[]
    try:
        for path in targets:
            trial.require_closed()
            if (core.sha(path) if path.exists() else None)!=previous[str(path)]:
                raise ValueError('Map changed before publication: '+str(path))
            path.parent.mkdir(parents=True,exist_ok=True)
            staged=path.with_name(path.name+'.'+uuid.uuid4().hex)
            shutil.copy2(source,staged)
            if core.sha(staged)!=expected: raise ValueError('Staged map hash mismatch')
            os.replace(staged,path)
            written.append(path)
            if core.sha(path)!=expected: raise ValueError('Installed map hash mismatch')
        if core.sha(original)!=steam_sha:
            raise ValueError('Original map changed during publication')
        if any(core.sha(Path(path))!=sha for path,sha in helipad_hashes.items()):
            raise ValueError('Helipad changed during publication')
    except Exception:
        for i,path in enumerate(targets):
            if path in written and core.sha(path)==expected:
                path.rename(backup/(str(i)+'-interrupted.dx'))
                saved=backup/(str(i)+'-original.dx')
                if saved.exists(): shutil.copy2(saved,path)
        raise
    audit['installed']=True
    core.save(backup/'installation.json',audit)
    print(json.dumps({'installed':True,'backup':str(backup),'map_sha256':expected},indent=2))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--package-trial',required=True)
    parser.add_argument('--appearance-base-trial',help='Passing campaign proof for the unchanged input to a verified gate-material-only patch.')
    args=parser.parse_args()
    publish(args.package_trial,args.appearance_base_trial)
