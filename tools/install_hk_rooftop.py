"""Publish the exact maps and packages from a restored, passing arrival trial."""
import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import shutil
import sys
import uuid
HERE=Path(__file__).resolve().parent
sys.path[:0]=[str(HERE/'editor_bridge'),str(HERE/'voices'),str(HERE)]
import core,trial
from voices.build_voice_snapshot import source_files,signature
from voices import natural_voices as n

def run(journal):
    folder=journal.resolve(strict=True).parent
    if folder.parent!=trial.TRIALS.resolve() or not folder.name.startswith('rooftop-'):
        raise ValueError('Use a rooftop trial journal')
    j=json.loads(journal.read_text())
    if not j['restored'] or not j['map_trial']['restored'] or not j['gameplay_checks'] or j['gameplay_checks'][0]<20 or j['gameplay_checks'][1]:
        raise ValueError('A passing, restored real-game arrival trial is required')
    build=Path(j['build']); verified=json.loads((build/'voice-build.json').read_text())
    inputs=json.loads((build/'voice-build-inputs.json').read_text())
    if signature(source_files(json.loads(n.PLAN.read_text())))!=verified['sources']:
        raise ValueError('Campaign sources changed after the acceptance trial')
    trial.require_closed()
    g=j['geometry']
    for name,digest in j['original_maps'].items():
        if core.sha(core.REVISION/'Maps'/(name+'.dx'))!=digest: raise ValueError('Steam original changed')
    if core.sha(core.PROJECT/'maps/06_HongKong_Helibase.dx')!=g['old_helibase_sha256']:
        raise ValueError('Someone changed the original helibase')
    writes=[]
    for name,entry in g['maps'].items():
        src=Path(entry['file'])
        if core.sha(src)!=entry['sha256']: raise ValueError('Tested map changed')
        for dst in (core.PROJECT/'maps'/(name+'.dx'),core.REVISION/'UnatcoMaps'/(name+'.dx')):
            writes.append((src,dst,entry['sha256']))
    for name,digest in verified['packages'].items():
        src=build/name
        if core.sha(src)!=digest: raise ValueError('Tested package changed')
        for dst in (core.PROJECT/'dist'/name,core.REVISION/'System'/name): writes.append((src,dst,digest))
    backup=core.PROJECT/'dist/backup'/('hk-rooftop-'+datetime.now().strftime('%Y%m%d-%H%M%S'))
    backup.mkdir(parents=True)
    publication=dict(installed=False,trial=str(journal),gameplay_checks=j['gameplay_checks'],writes=[])
    for i,(src,dst,digest) in enumerate(writes):
        old=core.sha(dst) if dst.exists() else None
        if 'publication_baseline' in j:
            if str(dst) not in j['publication_baseline'] or old!=j['publication_baseline'][str(dst)]:
                raise ValueError('Publication target changed since the trial: '+str(dst))
        elif dst.parent==core.REVISION/'System':
            expected=j['files'][str(dst)]['original']
            if old!=expected: raise ValueError('Game package changed since the trial')
        elif dst.parent==core.PROJECT/'dist':
            if old!=inputs['dist'].get(str(dst)): raise ValueError('Another build updated dist')
        elif dst.name.endswith('.dx') and dst.exists():
            # These two project/override maps were absent at the site survey.
            raise ValueError('A map was created concurrently; preserve it: '+str(dst))
        saved=backup/('before-'+str(i)+dst.suffix)
        if old is not None: shutil.copy2(dst,saved)
        publication['writes'].append(dict(source=str(src),target=str(dst),before=old,after=digest,backup=str(saved)))
    core.save(backup/'installation.json',publication)
    completed=[]
    try:
        for entry in publication['writes']:
            dst=Path(entry['target'])
            if (core.sha(dst) if dst.exists() else None)!=entry['before']: raise ValueError('Concurrent edit: '+str(dst))
            temp=dst.with_name(dst.name+'.rooftop-'+uuid.uuid4().hex)
            shutil.copy2(entry['source'],temp)
            if core.sha(temp)!=entry['after']: raise ValueError('Staged hash mismatch')
            os.replace(temp,dst); completed.append(entry)
        publication['installed']=True
        core.save(backup/'installation.json',publication)
        verified.update(published=True,installed=True,backup=str(backup),installation=str(backup/'installation.json'))
        core.save(build/'voice-build.json',verified)
        core.save(n.OUT/'latest-voice-build.json',verified)
    except Exception:
        for entry in reversed(completed):
            dst=Path(entry['target'])
            if core.sha(dst)!=entry['after']: continue
            if entry['before'] is None: dst.rename(backup/('failed-'+dst.name))
            else: shutil.copy2(entry['backup'],dst)
        raise
    print(json.dumps(dict(installed=True,backup=str(backup),checks=j['gameplay_checks']),indent=2))

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__); p.add_argument('journal',type=Path)
    run(p.parse_args().journal)
