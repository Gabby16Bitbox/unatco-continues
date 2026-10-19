"""Apply the native service-door material to the existing INF gate only.

Preserves every actor, polygon vertex, BSP node, collision hull and baked light.
Writes a private bridge version; publication requires a restored game trial.
"""
import argparse
import json
from pathlib import Path
import struct
import sys
import uuid

HERE=Path(__file__).resolve().parent
sys.path[:0]=[str(HERE/'editor_bridge'),str(HERE)]
import core
import editor
import geometry
from archive import objects
from bspsurf import props_end
from set_texture_prop import write_ci

ACTOR='UCServiceBoundary0'
TEXTURE='SemiBackDoor_B'


def name_entries(p):
    offset=struct.unpack_from('<I',p.d,16)[0]
    entries=[]
    for _ in p.names:
        start=offset
        length,offset=p.ci(offset)
        if length<=0: raise ValueError('Expected UE1 ANSI names')
        offset+=length+4
        entries.append(p.d[start:offset])
    return entries


def export_table(p,changed):
    out=bytearray()
    for index,entry in enumerate(p.exports,1):
        size,offset=changed.get(index,(entry['size'],entry['off']))
        out+=write_ci(entry['class'])+write_ci(entry['super'])
        out+=struct.pack('<i',entry['pkg'])+write_ci(p.names.index(entry['name']))
        out+=struct.pack('<I',entry['flags'])+write_ci(size)
        if size: out+=write_ci(offset)
    return out


def edits(blob,start,replacements):
    result=bytearray(blob)
    for at,length,value in sorted(replacements,reverse=True):
        result[at-start:at-start+length]=value
    return bytes(result)


def verify_style(source,output):
    """Recheck the material-only change against the previously tested map."""
    before,old_rows=objects(source); after,new_rows=objects(output)
    if old_rows!=new_rows: raise ValueError('Actor properties changed')
    _,old,old_polys,details=geometry.mover_data(source,before,old_rows,ACTOR)
    _,new,new_polys,_=geometry.mover_data(output,after,new_rows,ACTOR)
    changed={old.idx,before.find_export(editor.native_model_details(before,old)['polys'],'Polys')}
    if len(before.exports)!=len(after.exports): raise ValueError('Export count changed')
    for i,(a,b) in enumerate(zip(before.exports,after.exports),1):
        if any(a[k]!=b[k] for k in ('class','super','pkg','name','flags')):
            raise ValueError('Export identity changed')
        if i not in changed and before.d[a['off']:a['off']+a['size']]!=after.d[b['off']:b['off']+b['size']]:
            raise ValueError('Unrelated export changed: '+a['name'])
    if after.names[:len(before.names)]!=before.names or after.imports[:len(before.imports)]!=before.imports:
        raise ValueError('Existing name/import identity changed')
    added=after.imports[len(before.imports):]
    original=next(i for i in before.imports if i[3]=='ClenGrayMetal_A')
    if added!=[(original[0],original[1],original[2],TEXTURE)]:
        raise ValueError('Unexpected added import')
    if after.names[len(before.names):]!=[TEXTURE]: raise ValueError('Unexpected added name')
    if editor.native_model_details(before,old)!=editor.native_model_details(after,new):
        raise ValueError('Gate collision or bounds changed')
    if old.nodes!=new.nodes or old.verts!=new.verts:
        raise ValueError('Gate BSP geometry changed')
    if new.vectors[:len(old.vectors)]!=old.vectors or new.points[:len(old.points)]!=old.points:
        raise ValueError('Existing model vectors or points changed')
    if len(old_polys)!=len(new_polys) or len(old.surfs)!=len(new.surfs):
        raise ValueError('Gate face count changed')
    for a,b in zip(old_polys,new_polys):
        for key in ('normal','verts','flags','w','pan'):
            if a[key]!=b[key]: raise ValueError('Polygon geometry changed')
        if abs(a['normal'][0])>.9:
            direction=1 if a['normal'][0]<0 else -1
            expected=((a['verts'][0][0],-96 if direction>0 else 96,88),
                      (0,direction*256/192,0),(0,0,-256/176))
            if after.refname(b['tex'])!=TEXTURE or not all(geometry.close(b[k],v) for k,v in zip(('base','u','v'),expected)):
                raise ValueError('Wrong service-door material mapping')
        elif any(a[k]!=b[k] for k in ('base','u','v','tex')):
            raise ValueError('Gate side trim changed')
    for a,b in zip(old.surfs,new.surfs):
        if abs(old.vectors[a['vNormal']][0])>.9:
            if b['tex']!=TEXTURE: raise ValueError('Wrong surface material')
            keys=('flags','vNormal','iLightMap','iBrushPoly','pan_uv','actor')
        else: keys=tuple(k for k in a if k not in ('tex_ref','actor_ref'))
        if any(a[k]!=b[k] for k in keys): raise ValueError('Surface geometry changed')
    return dict(actors_identical=True,unrelated_exports_identical=True,
                geometry_identical=True,collision_identical=True,baked_lighting_identical=True)


@core.locked
def refine(identity,expected):
    workspace,manifest,current=core.workspace(identity)
    if core.sha(current)!=expected: raise ValueError('Workspace changed')
    p,rows=objects(current)
    row,model,polys,details=geometry.mover_data(current,p,rows,ACTOR)
    props=row['properties']
    if not (row['class_name']=='DeusExMover' and props.get('bLocked') and props.get('bFrobbable',True) and
            props.get('bPickable') is False and props.get('bBreakable',False) is False and
            props.get('NumKeys')==1 and details['closed'] and details['convex']):
        raise ValueError('Expected the existing closed INF gate')
    if details['local_bounds']!=[[-8.0,-96.0,-88.0],[8.0,96.0,88.0]]:
        raise ValueError('Unexpected service-gate geometry')
    if not details['baked_lighting_empty']: raise ValueError('Gate has baked light')

    names=list(p.names); entries=name_entries(p)
    if TEXTURE not in names:
        names.append(TEXTURE)
        raw=TEXTURE.encode('ascii')+b'\0'
        entries.append(write_ci(len(raw))+raw+struct.pack('<I',0x00070010))
    imports=list(p.imports)
    original=next(i for i in imports if i[3]=='ClenGrayMetal_A')
    candidates=[-i-1 for i,value in enumerate(imports)
                if value[1]=='Texture' and value[2]==original[2] and value[3]==TEXTURE]
    if candidates: reference=candidates[0]
    else:
        imports.append((original[0],original[1],original[2],TEXTURE))
        reference=-len(imports)

    # Both faces get one complete native texture; the sides keep their metal trim.
    fronts={i for i,poly in enumerate(polys) if abs(poly['normal'][0])>.9}
    if len(fronts)!=2: raise ValueError('Expected exactly two gate faces')
    poly_ref=editor.native_model_details(p,model)['polys']
    poly_index=p.find_export(poly_ref,'Polys')
    pe=p.exports[poly_index-1]
    offset=props_end(p,poly_index)+8
    replacements=[]
    mappings={}
    for i,poly in enumerate(polys):
        count,offset=p.ci(offset)
        base_at=offset
        offset+=48+count*12+4
        _,offset=p.ci(offset)
        tex_at=offset; _,offset=p.ci(offset); tex_end=offset
        for _ in range(3): _,offset=p.ci(offset)
        offset+=4
        if i not in fronts: continue
        direction=1 if poly['normal'][0]<0 else -1
        base=(poly['verts'][0][0],-96.0 if direction>0 else 96.0,88.0)
        u=(0.0,direction*256.0/192.0,0.0); v=(0.0,0.0,-256.0/176.0)
        mappings[i]=(base,u,v)
        replacements.extend([(base_at,12,struct.pack('<fff',*base)),
                             (base_at+24,12,struct.pack('<fff',*u)),
                             (base_at+36,12,struct.pack('<fff',*v)),
                             (tex_at,tex_end-tex_at,write_ci(reference))])
    if offset!=pe['off']+pe['size']: raise ValueError('Polygon alignment failed')
    polygon_data=edits(p.d[pe['off']:pe['off']+pe['size']],pe['off'],replacements)

    me=p.exports[model.idx-1]
    head=props_end(p,model.idx)+41
    vectors=list(model.vectors); points=list(model.points)
    surfaces=[]
    for surface in model.surfs:
        s=dict(surface)
        normal=model.vectors[s['vNormal']]
        if abs(normal[0])>.9:
            i=next(i for i in fronts if geometry.close(normal,polys[i]['normal']))
            base,u,v=mappings[i]
            s['pBase']=len(points); points.append(base)
            s['vU']=len(vectors); vectors.append(u)
            s['vV']=len(vectors); vectors.append(v)
            s['tex_ref']=reference
        surfaces.append(s)
    data=bytearray(p.d[me['off']:head])
    data+=write_ci(len(vectors))+b''.join(struct.pack('<fff',*v) for v in vectors)
    data+=write_ci(len(points))+b''.join(struct.pack('<fff',*v) for v in points)
    data+=p.d[model.sec['start']:model.sec['surfs'][0]]
    data+=write_ci(len(surfaces))
    for s in surfaces:
        data+=write_ci(s['tex_ref'])+struct.pack('<I',s['flags'])
        data+=b''.join(write_ci(s[k]) for k in ('pBase','vNormal','vU','vV','iLightMap','iBrushPoly'))
        data+=struct.pack('<hh',*s['pan_uv'])+write_ci(s['actor_ref'])
    data+=p.d[model.sec['surfs'][1]:me['off']+me['size']]

    output_data=bytearray(p.d); changed={}
    for index,blob in ((poly_index,polygon_data),(model.idx,data)):
        changed[index]=(len(blob),len(output_data)); output_data+=blob
    name_off=len(output_data); output_data+=b''.join(entries)
    import_off=len(output_data)
    for cp,cn,outer,name in imports:
        output_data+=write_ci(names.index(cp))+write_ci(names.index(cn))
        output_data+=struct.pack('<i',outer)+write_ci(names.index(name))
    export_off=len(output_data); output_data+=export_table(p,changed)
    struct.pack_into('<IIIIII',output_data,12,len(names),name_off,len(p.exports),export_off,len(imports),import_off)
    generations=struct.unpack_from('<I',output_data,52)[0]
    if generations: struct.pack_into('<I',output_data,56+(generations-1)*8+4,len(names))
    run=uuid.uuid4().hex
    output=workspace/'versions'/('service-door-'+run+'.dx')
    output.write_bytes(output_data)

    after,after_rows=objects(output)
    if rows!=after_rows: raise ValueError('Actor properties changed')
    for index,entry in enumerate(p.exports,1):
        if index in changed: continue
        other=after.exports[index-1]
        if p.d[entry['off']:entry['off']+entry['size']]!=after.d[other['off']:other['off']+other['size']]:
            raise ValueError('Unrelated export changed: '+entry['name'])
    _,after_model,after_polys,after_details=geometry.mover_data(output,after,after_rows,ACTOR)
    if editor.native_model_details(p,model)!=editor.native_model_details(after,after_model):
        raise ValueError('Gate collision or bounds changed')
    if model.nodes!=after_model.nodes or model.verts!=after_model.verts:
        raise ValueError('Gate BSP geometry changed')
    for old,new in zip(polys,after_polys):
        for key in ('normal','verts','flags','w'):
            if old[key]!=new[key]: raise ValueError('Polygon geometry changed')
    for i in fronts:
        if after.refname(after_polys[i]['tex'])!=TEXTURE: raise ValueError('Wrong door texture')
    report=dict(input_sha256=expected,output_sha256=core.sha(output),actor=ACTOR,
        texture='CoreTexMetal.Metal.'+TEXTURE,changed_exports=[p.exports[i-1]['name'] for i in changed],
        actors_identical=True,unrelated_exports_identical=True,collision_identical=True,
        geometry_identical=True,baked_lighting_identical=True,closed_inf_gate=True,
        native_verification_pending=True)
    report.update(verify_style(current,output))
    report_path=workspace/('service-door-'+run+'.json');core.save(report_path,report)
    if core.sha(current)!=expected: raise ValueError('Workspace changed during styling')
    manifest['versions'].append(dict(file=str(output.relative_to(workspace)),sha256=core.sha(output),
        parent=manifest['current'],changes=[dict(operation='service_exit_material',actor=ACTOR,texture=TEXTURE)],
        action='service_exit_material',report=str(report_path)))
    manifest['current']=len(manifest['versions'])-1
    core.save(workspace/'manifest.json',manifest)
    return dict(workspace=identity,sha256=core.sha(output),current_file=str(output),report=str(report_path))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('workspace');parser.add_argument('--expected-sha256',required=True)
    args=parser.parse_args()
    print(json.dumps(refine(args.workspace,args.expected_sha256),indent=2))
