"""Stage two arrival maps + checked packages, photograph, then restore exactly."""
from pathlib import Path
import argparse
import json
import shutil
import sys
import uuid
HERE=Path(__file__).resolve().parent
sys.path[:0]=[str(HERE/'editor_bridge'),str(HERE)]
import core,trial

SHOTS=[
 'roof;cam;1280;-580;320;448;-96;100',
 'stairs;player;416;-860;56;16384;0',
 'utilities;player;420;-1250;56;40000;0',
 'checkpoint;player;540;-768;56;0;0',
 'proof;console;summon UnatcoContinues.UCRooftopPlayCheck',
 'down;waitmap;06_HongKong_WanChai_Market;100',
 'cabin;view',
 'raid;waitflag;UCHongKongRaidStarted;70',
 'label;waitflag;HongKongShipmentInspected;45',
 'cargo;view',
 'done;waitflag;UC_RooftopProofComplete;150',
 'return;view',
 'pad;cam;1220;540;440;448;-96;80',
 'stairs-detail;cam;416;-1100;176;416;-620;80',
 'services-detail;cam;600;-1120;260;314;-1510;110',
 'rooftop-wide;cam;1350;510;600;540;-580;60',
 'maintenance;cam;510;-920;150;40;-1140;100',
 'lift-detail;cam;1216;-1180;140;1216;-1480;100',
 'access-detail;cam;440;-1030;150;708;-768;110',
 'shaft;where;UCRoofCabin',
]

def run(build,report,shots,baseline=None):
    trial.require_closed()
    verified=json.loads((build/'voice-build.json').read_text())
    if any(v[1] for v in verified['native_checks'].values()): raise ValueError('Native package checks failed')
    f=trial.TRIALS/('rooftop-'+uuid.uuid4().hex); f.mkdir()
    j=dict(restored=False,build=str(build),geometry=report,files={},original_maps={},publication_baseline={})
    # Snapshot every publication target, including existing map overrides.
    targets=[d/(name+'.dx') for name in report['maps'] for d in (core.PROJECT/'maps',core.REVISION/'UnatcoMaps')]
    targets += [d/name for name in verified['packages'] for d in (core.PROJECT/'dist',core.REVISION/'System')]
    for dst in targets:
        old=core.sha(dst) if dst.exists() else None
        if baseline is not None and (str(dst) not in baseline or old!=baseline[str(dst)]):
            raise ValueError('Concurrent edit since the start of this refinement: '+str(dst))
        j['publication_baseline'][str(dst)]=old
    files=[(build/n,core.REVISION/'System'/n,verified['packages'][n]) for n in ('UnatcoContinues.u','UnatcoVoices.u')]
    # Market's installed override shadows Revision/Maps; stage the tested copy too.
    files += [(Path(v['file']),core.REVISION/'UnatcoMaps'/(n+'.dx'),v['sha256']) for n,v in report['maps'].items()]
    for i,(src,dst,digest) in enumerate(files):
        if core.sha(src)!=digest: raise ValueError('Checked source changed: '+str(src))
        old=core.sha(dst) if dst.exists() else None
        backup=f/('original-'+str(i)+dst.suffix)
        if old is not None: shutil.copy2(dst,backup)
        j['files'][str(dst)]=dict(original=old,trial=digest,backup=str(backup),source=str(src))
    for n in ('06_HongKong_WanChai_Market','06_HongKong_Helibase'):
        j['original_maps'][n]=core.sha(core.REVISION/'Maps'/(n+'.dx'))
    core.save(f/'journal.json',j)
    written=[]
    try:
        for dstname,v in j['files'].items():
            dst=Path(dstname)
            if (core.sha(dst) if dst.exists() else None)!=v['original']: raise ValueError('Game changed before staging')
            dst.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(v['source'],dst); written.append(dst)
        result=trial.try_game(report['site'],shots,setup='UCDbgHongKong',timeout=360)
        j['map_trial']=result
        log=core.REVISION/'System/Revision.log'
        shutil.copy2(log,f/'Revision.log')
        import re
        m=re.search(r'UCRooftopPlayCheck:\s*(\d+) checked,\s*(\d+) failed',log.read_text(encoding='latin1'))
        j['gameplay_checks']=[int(m[1]),int(m[2])] if m else None
        if not m or int(m[2]): raise ValueError('Rooftop acceptance failed; see '+str(f/'Revision.log'))
        return j
    finally:
        trial.require_closed()
        for dst in written:
            v=j['files'][str(dst)]
            if core.sha(dst)!=v['trial']: raise ValueError('Another process changed '+str(dst)+'; backup retained')
            if v['original'] is None: dst.rename(f/('generated-'+dst.name))
            else:
                shutil.copy2(v['backup'],dst)
                if core.sha(dst)!=v['original']: raise ValueError('Restoration failed')
        for n,digest in j['original_maps'].items():
            if core.sha(core.REVISION/'Maps'/(n+'.dx'))!=digest: raise ValueError('Original Steam map was not restored')
        j['restored']=True
        core.save(f/'journal.json',j)
        print(json.dumps(dict(trial=str(f),restored=True,checks=j.get('gameplay_checks'),map_trial=j.get('map_trial')),indent=2))

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--build-system',type=Path,required=True)
    p.add_argument('--report',type=Path,default=HERE/'editor_bridge/rooftop-build.json')
    p.add_argument('--shots-file',type=Path)
    p.add_argument('--baseline',type=Path)
    a=p.parse_args()
    shots=json.loads(a.shots_file.read_text()) if a.shots_file else SHOTS
    run(a.build_system,json.loads(a.report.read_text()),shots,json.loads(a.baseline.read_text()) if a.baseline else None)
