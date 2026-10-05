"""Genera ucadd.t3d: mover per la porta blindata dell'eliporto (06_HongKong_Helibase).
 - UCWallSoffitto, UCWallSud: coperture "solo UNATCO" (nella mappa invisibili, senza collisione;
   UCMod.RaiseRouteWalls le rende muri veri sulla route UNATCO);
 - UCVanillaLamiere, UCVanillaMacerie: copie identiche dei brush rotti Brush234/Brush236 (che si
   cancellano dalla geometria): esistono solo nel gioco normale (UCMod.HideVanillaOnly).
"""
import os
import re
import sys

# cartella con l'esportazione T3D della mappa (helibase.t3d, da UnrealEd: File > Export)
S = os.environ.get('UC_T3D_DIR', os.path.join(os.path.expanduser('~'), 'uc_t3d'))
t3d = open(S + r'\helibase.t3d', encoding='latin-1').read()
actors = {n: b for c, n, b in re.findall(r'Begin Actor Class=(\w+) Name=(\w+)\r?\n(.*?)\r?\nEnd Actor', t3d, re.S)}


def f(v):
    return '%+013.6f' % v


def vec(v):
    return ','.join(f(c) for c in v)


def sub(a, b):
    return tuple(a[i] - b[i] for i in range(3))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def poly(tex, verts, normal, u, v, origin):
    # ordine dei vertici: normale = (v1-v0) x (v2-v0), come nei brush esportati
    c = cross(sub(verts[1], verts[0]), sub(verts[2], verts[0]))
    dot = sum(c[i] * normal[i] for i in range(3))
    if dot < 0:
        verts = list(reversed(verts))
    # l'origine deve stare SUL piano della faccia: l'editor la usa anche come punto del
    # piano (fuori dal piano = BSP del mover sbagliato, facce scure, torcia che non illumina).
    # Spostarla lungo la normale non cambia le coordinate della texture.
    k = sum((origin[i] - verts[0][i]) * normal[i] for i in range(3))
    origin = tuple(origin[i] - k * normal[i] for i in range(3))
    lines = ['          Begin Polygon Texture=%s' % tex,
             '             Origin   ' + vec(origin),
             '             Normal   ' + vec(normal),
             '             TextureU ' + vec(u),
             '             TextureV ' + vec(v)]
    lines += ['             Vertex   ' + vec(p) for p in verts]
    lines.append('          End Polygon')
    return '\n'.join(lines)


def box(loc, mn, mx, faces):
    """faces: per ogni lato (+x,-x,+y,-y,+z,-z) -> lista di (tex, u, v, origin_mondo, [zmin,zmax] opzionale)."""
    out = []
    L = lambda p: sub(p, loc)
    x0, y0, z0 = mn
    x1, y1, z1 = mx
    quads = {
        '+x': ((1, 0, 0), [(x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)]),
        '-x': ((-1, 0, 0), [(x0, y0, z0), (x0, y1, z0), (x0, y1, z1), (x0, y0, z1)]),
        '+y': ((0, 1, 0), [(x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)]),
        '-y': ((0, -1, 0), [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)]),
        '+z': ((0, 0, 1), [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]),
        '-z': ((0, 0, -1), [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]),
    }
    for side, (normal, q) in quads.items():
        for spec in faces[side]:
            tex, u, v, orig = spec[:4]
            verts = q
            if len(spec) > 4:      # faccia divisa in altezza
                za, zb = spec[4]
                verts = [(p[0], p[1], za if p[2] == z0 else zb) for p in q]
            out.append(poly(tex, [L(p) for p in verts], normal, u, v, L(orig)))
    return '\n'.join(out)


def mover(name, tag, loc, polys, prepivot=None, wall=True):
    model = 'UCMdl' + name
    props = ['    bDynamicLightMover=True']
    if wall:
        props += ['    bHidden=True', '    bCollideActors=False', '    bBlockActors=False', '    bBlockPlayers=False']
    props += ['    BasePos=(X=%f,Y=%f,Z=%f)' % loc,
              '    Tag=%s' % tag,
              '    Location=(X=%f,Y=%f,Z=%f)' % loc]
    if prepivot:
        props.append('    PrePivot=(X=%f,Y=%f,Z=%f)' % prepivot)
    return '\n'.join(['Begin Actor Class=Mover Name=%s' % name] + props + [
        '    Begin Brush Name=%s' % model,
        '       Begin PolyList',
        polys,
        '       End PolyList',
        '    End Brush',
        '    Brush=Model\'MyLevel.%s\'' % model,
        '    Name=%s' % name,
        'End Actor'])


out = ['Begin Map']

# 1. soffitto: lastra 2 unita' sotto il soffitto (640), sopra tutto lo squarcio di Brush233
loc = (-1288.0, -128.0, 642.0)
mn, mx = (-1380.0, -256.0, 638.0), (-1196.0, 0.0, 646.0)
ceil_o = (-1328.0, -256.0, 638.0)
side_m = ('Metal_A', (0, 1, 0), (0, 0, -1), ceil_o)
faces = {'-z': [('Metal_A', (0, 1, 0), (-1, 0, 0), ceil_o)], '+z': [side_m],
         '+x': [('Metal_A', (0, 1, 0), (0, 0, -1), ceil_o)], '-x': [('Metal_A', (0, 1, 0), (0, 0, -1), ceil_o)],
         '+y': [('Metal_A', (1, 0, 0), (0, 0, -1), ceil_o)], '-y': [('Metal_A', (1, 0, 0), (0, 0, -1), ceil_o)]}
out.append(mover('UCWallSoffitto0', 'UCWallSoffitto', loc, box(loc, mn, mx, faces)))

# 2. muro sud: pannello 2 unita' davanti al muro (y=-256), sopra la rientranza di Brush235
loc = (-1264.0, -258.0, 512.0)
mn, mx = (-1328.0, -262.0, 384.0), (-1200.0, -254.0, 640.0)
low_o, up_o = (-1200.0, -254.0, 384.0), (-1200.0, -254.0, 512.0)
U, V = (-1, 0, 0), (0, 0, -1)
faces = {'+y': [('HelibaseWall_E', U, V, low_o, (384.0, 512.0)), ('DrtyBrwnWall_A', U, V, up_o, (512.0, 640.0))],
         '-y': [('DrtyBrwnWall_A', (1, 0, 0), V, up_o)],
         '+x': [('DrtyBrwnWall_A', (0, 1, 0), V, up_o)], '-x': [('DrtyBrwnWall_A', (0, 1, 0), V, up_o)],
         '+z': [('Metal_A', (0, 1, 0), (-1, 0, 0), up_o)], '-z': [('ClenMetlPanel_A', (0, 1, 0), (-1, 0, 0), low_o)]}
out.append(mover('UCWallSud0', 'UCWallSud', loc, box(loc, mn, mx, faces)))

# 3-4. copie identiche delle lamiere strappate e delle macerie (solo gioco normale)
for brush, name, tag in (('Brush234', 'UCVanillaLamiere0', 'UCVanillaLamiere'), ('Brush236', 'UCVanillaMacerie0', 'UCVanillaMacerie')):
    body = actors[brush]
    m = re.search(r'Location=\(([^)]*)\)', body).group(1)
    lv = dict(re.findall(r'(X|Y|Z)=([-\d.]+)', m))
    loc = tuple(float(lv.get(k, 0)) for k in 'XYZ')
    pm = dict(re.findall(r'(X|Y|Z)=([-\d.]+)', re.search(r'PrePivot=\(([^)]*)\)', body).group(1)))
    pp = tuple(float(pm.get(k, 0)) for k in 'XYZ')
    polys = re.search(r'Begin PolyList\r?\n(.*?)\r?\n\s*End PolyList', body, re.S).group(1)
    polys = re.sub(r' Item=\w+', '', polys)
    out.append(mover(name, tag, loc, polys.replace('\r', ''), prepivot=pp, wall=False))

out.append('End Map')
dst = os.path.join(os.path.expanduser('~'), 'ucadd.t3d')
open(dst, 'w', encoding='latin-1', newline='\r\n').write('\n'.join(out) + '\n')
print('ok', dst, sum(1 for l in out for _ in re.finditer('Begin Polygon', l)), 'poligoni')
