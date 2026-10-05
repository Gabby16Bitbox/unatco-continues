"""Genera ucluci.t3d: le due strisce di luce rovinate nel soffitto dell'atrio degli ascensori
(06_HongKong_Helibase), solo nella variante UNATCO.

Il riquadro di luci (texture HelibaseLght_A "dipinta" sul soffitto a z=640) ha 4 lati:
 - Brush1686 (lato lontano) e Brush1689 (lato sud): superficie Unlit (sempre accesa);
 - Brush1688 (lato nord): SpecialLit, illuminata solo dalle luci che tremolano -> fioca;
 - Brush1678 (lato verso il passaggio): illuminazione normale -> spenta, al buio.
Qui due lastre sottili (mover 'UCWallLuce...') 1 unita' sotto il soffitto, con la stessa
texture, la stessa mappatura e lo stesso flag Unlit dei lati accesi. Nella mappa sono nascoste;
UCMod.RaiseRouteWalls le mostra sulla route UNATCO. Essendo Unlit non serve ricalcolare le luci.
"""
import os
UNLIT = 0x00C00000      # PF_Unlit | PF_HighShadowDetail, come Brush1686/Brush1689


def f(v):
    return '%+013.6f' % v


def vec(v):
    return ','.join(f(c) for c in v)


def sub(a, b):
    return tuple(a[i] - b[i] for i in range(3))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def poly(tex, verts, normal, u, v, origin, flags):
    c = cross(sub(verts[1], verts[0]), sub(verts[2], verts[0]))
    if sum(c[i] * normal[i] for i in range(3)) < 0:
        verts = list(reversed(verts))
    lines = ['          Begin Polygon Texture=%s Flags=%d' % (tex, flags),
             '             Origin   ' + vec(origin),
             '             Normal   ' + vec(normal),
             '             TextureU ' + vec(u),
             '             TextureV ' + vec(v)]
    lines += ['             Vertex   ' + vec(p) for p in verts]
    lines.append('          End Polygon')
    return '\n'.join(lines)


def plate(name, tag, mn, mx, u, v, origin):
    """Lastra (scatola sottile) con tutte le facce HelibaseLght_A Unlit; la faccia sotto
    ha la mappatura del lato di luce originale (origin in coordinate del mondo)."""
    loc = tuple((mn[i] + mx[i]) / 2.0 for i in range(3))
    L = lambda p: sub(p, loc)
    x0, y0, z0 = mn
    x1, y1, z1 = mx
    quads = [
        ((0, 0, -1), [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]),
        ((0, 0, 1), [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]),
        ((1, 0, 0), [(x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)]),
        ((-1, 0, 0), [(x0, y0, z0), (x0, y1, z0), (x0, y1, z1), (x0, y0, z1)]),
        ((0, 1, 0), [(x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)]),
        ((0, -1, 0), [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)]),
    ]
    polys = '\n'.join(poly('HelibaseLght_A', [L(p) for p in q], n, u, v, L(origin), UNLIT) for n, q in quads)
    model = 'UCMdl' + name
    return '\n'.join([
        'Begin Actor Class=Mover Name=%s' % name,
        '    bHidden=True',
        '    bCollideActors=False',
        '    bBlockActors=False',
        '    bBlockPlayers=False',
        '    BasePos=(X=%f,Y=%f,Z=%f)' % loc,
        '    Tag=%s' % tag,
        '    Location=(X=%f,Y=%f,Z=%f)' % loc,
        '    Begin Brush Name=%s' % model,
        '       Begin PolyList',
        polys,
        '       End PolyList',
        '    End Brush',
        '    Brush=Model\'MyLevel.%s\'' % model,
        '    Name=%s' % name,
        'End Actor'])


out = ['Begin Map']
# lato nord (Brush1688): faccia sotto U=(0,-1,0) V=(-1,0,0), origine (-1680,0,640)
out.append(plate('UCWallLuceNord0', 'UCWallLuceNord', (-1680.0, -32.0, 639.0), (-1424.0, 0.0, 639.5),
                 (0, -1, 0), (-1, 0, 0), (-1680.0, 0.0, 640.0)))
# lato verso il passaggio (Brush1678): U=(1,0,0) V=(0,-1,0), origine (-1424,0,640)
out.append(plate('UCWallLuceVicina0', 'UCWallLuceVicina', (-1424.0, -256.0, 639.0), (-1392.0, 0.0, 639.5),
                 (1, 0, 0), (0, -1, 0), (-1424.0, 0.0, 640.0)))
out.append('End Map')
dst = os.path.join(os.path.expanduser('~'), 'ucluci.t3d')
open(dst, 'w', encoding='latin-1', newline='\r\n').write('\n'.join(out) + '\n')
print('ok', dst)
