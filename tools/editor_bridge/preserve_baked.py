"""Restore original baked bindings after native zone/collision finalization.

TestVisibility keeps shadow masks but invalidates surface light indexes and
replaces the shared light array. Preserve the original baked prefix; append
and rebase the new leaf illumination so both layouts remain valid.
"""
import struct

import editor
import geometry
from archive import objects
from fix_brush_surfs import export_name_indices
from set_texture_prop import write_ci


def restore(source, output):
    original, _ = objects(source)
    current, _ = objects(output)
    old_idx = max((i+1 for i,e in enumerate(original.exports) if original.classname(e)=='Model'),
                  key=lambda i: original.exports[i-1]['size'])
    name = original.exports[old_idx-1]['name']
    old = editor.load_model(source, original, name)
    new = editor.load_model(output, current, name)
    if old.lightmaps != new.lightmaps or original.d[old.bits_at:old.bits_at+old.bits_len] != current.d[new.bits_at:new.bits_at+new.bits_len]:
        raise ValueError('Native finalization changed the baked lightmaps/masks')
    if len(new.surfs)<len(old.surfs):
        raise ValueError('Native finalization removed original surface indexes')
    surfaces = bytearray(write_ci(len(new.surfs)))
    for i,s in enumerate(new.surfs):
        light = s['iLightMap']
        if i<len(old.surfs):
            fields = ('tex','flags','iBrushPoly','pan_uv','actor')
            if any(old.surfs[i][k]!=s[k] for k in fields):
                raise ValueError('Original surface identity changed before restoring lighting: ' + str(i))
            # bspRefresh compacts point/vector arrays without remapping surfaces.
            pairs = [(old.points[old.surfs[i]['pBase']], new.points[s['pBase']])]
            pairs += [(old.vectors[old.surfs[i][k]],new.vectors[s[k]]) for k in ('vNormal','vU','vV')]
            if any(not geometry.close(a,b) for a,b in pairs):
                raise ValueError('Original surface plane/texture mapping changed: '+str(i))
            light=old.surfs[i]['iLightMap']
        surfaces += write_ci(s['tex_ref']) + struct.pack('<I',s['flags'])
        surfaces += b''.join(write_ci(v) for v in (s['pBase'],s['vNormal'],s['vU'],s['vV'],light,s['iBrushPoly']))
        surfaces += struct.pack('<hh',*s['pan_uv']) + write_ci(s['actor_ref'])
    # Read the exact native bounds/hulls prefix, then rebase the leaf light offsets.
    d=current.d
    o=new.sec['lightbits'][1]
    n,o=current.ci(o); o+=n*25
    n,o=current.ci(o); o+=n*4
    leaf_start=o
    n,o=current.ci(o)
    leaves=bytearray(write_ci(n))
    for _ in range(n):
        zone,o=current.ci(o); permeating,o=current.ci(o); volumetric,o=current.ci(o)
        if permeating>=0: permeating+=len(old.lights)
        if volumetric>=0: volumetric+=len(old.lights)
        leaves+=b''.join(write_ci(v) for v in (zone,permeating,volumetric))+d[o:o+8]
        o+=8
    if o!=new.sec['lights'][0]: raise ValueError('Native leaf alignment failed')
    refs=[]
    for ref in old.lights:
        actor=original.refname(ref)
        mapped=0 if actor=='None' else current.find_export(actor)
        if actor!='None' and not mapped: raise ValueError('Missing original light actor: '+actor)
        refs.append(mapped)
    refs+=new.lights
    lights=write_ci(len(refs))+b''.join(write_ci(ref) for ref in refs)
    e=current.exports[new.idx-1]
    blob=(d[e['off']:new.sec['surfs'][0]]+surfaces+d[new.sec['surfs'][1]:leaf_start]
          +leaves+lights+d[new.sec['lights'][1]:new.sec['end']])
    data=bytearray(d); offset=len(data); data+=blob
    table=bytearray(); names=export_name_indices(current)
    for i,x in enumerate(current.exports):
        size,at=(len(blob),offset) if i==new.idx-1 else (x['size'],x['off'])
        table+=write_ci(x['class'])+write_ci(x['super'])+struct.pack('<i',x['pkg'])
        table+=write_ci(names[i])+struct.pack('<I',x['flags'])+write_ci(size)
        if size>0: table+=write_ci(at)
    struct.pack_into('<I',data,24,len(data)); data+=table
    output.write_bytes(data)
