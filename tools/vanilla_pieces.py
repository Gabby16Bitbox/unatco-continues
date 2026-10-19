"""The pieces a map script or the map editor copied from other maps (prefabs lib_/reg_/obj_, original_actor),
taken from the ORIGINAL Deus Ex's maps instead of Revision's (19 Oct 2026: the mod's maps for the original
game must not carry Revision's own work).

A block of a piece is kept when the original game's map of the same name has it: a brush of that name with
the same shape (world bounds within 2 units), an object of that name, class and place (within 4 units). It
is then the original game's block (its polygons, textures, properties). A block the original game has not
(Revision added or remade it) is left out, and listed in the report.

    import vanilla_pieces; vanilla_pieces.install()      # before the script's Scene builds
    vanilla_pieces.REPORT                                # what was taken from where, what was left out

The original maps are exported to T3D once (tools\\mapkit\\out\\vanilla_t3d) by the original game's editor engine.
"""
import copy
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / 'tools' / 'mapkit'
for p in (KIT, KIT / 'editor'):
    if str(p) not in sys.path:
        sys.path.insert(0, str(p))
import settings  # noqa: E402
import t3d  # noqa: E402

CACHE = KIT / 'out' / 'vanilla_t3d'
GAME_MAPS = settings.GAME / 'Maps'          # the original game's maps (not Revision\Maps)
REPORT = {}                                  # piece id -> dict(kept=[...], dropped=[...])
_maps = {}
_tex_pkg = None


def export(map_name):
    """The original game's map as T3D (cached)."""
    out = CACHE / (map_name + '.t3d')
    if out.exists():
        return out
    src = GAME_MAPS / (map_name + '.dx')
    if not src.exists():
        return None
    import convert
    CACHE.mkdir(parents=True, exist_ok=True)
    run = convert._run(settings.GAME, 'vanilla', 'export-' + map_name)
    try:
        shutil.copy2(src, run / 'Input' / src.name)
        convert._execute(run, ['MAP LOAD FILE="..\\Input\\%s"' % src.name,
                               'MAP EXPORT FILE="..\\Output\\%s.t3d"' % map_name], 'export.log')
        shutil.copy2(run / 'Output' / (map_name + '.t3d'), out)
    finally:
        convert._remove(run)
    return out


def actors(map_name):
    """name -> actor of the original game's map (None: the original game has no such map)."""
    if map_name not in _maps:
        f = export(map_name)
        _maps[map_name] = None if f is None else {a['name']: a for a in
                                                  t3d.actors(f.read_text(encoding='latin1', errors='replace'))}
    return _maps[map_name]


def _bounds(a):
    try:
        return t3d.bounds(a)
    except Exception:
        return None


def _polys(raw):
    return re.findall(r'Begin Polygon[^\n]*', raw)


def _texture(line):
    m = re.search(r'Texture=(\S+)', line)
    return m.group(1) if m else None


def _same_faces_hidden(rev_raw, van_raw):
    """The copy's faces nobody saw in the source map took its main texture (prefabs._hide_unseen_faces):
    the same faces take the original block's main texture."""
    rp, vp = _polys(rev_raw), _polys(van_raw)
    if len(rp) != len(vp) or not rp:
        return van_raw
    rt = [_texture(l) for l in rp]
    main = max(set(rt), key=rt.count)
    pairs = {}
    for a, b in zip(rt, (_texture(l) for l in vp)):
        if a == main and b:
            pairs[b] = pairs.get(b, 0) + 1
    if not pairs:
        return van_raw
    vmain = max(pairs, key=pairs.get)
    it = iter(rt)

    def fix(m):
        if next(it, None) == main and _texture(m.group(0)):
            return re.sub(r'Texture=\S+', 'Texture=' + vmain, m.group(0), count=1)
        return m.group(0)
    return re.sub(r'Begin Polygon[^\n]*', fix, van_raw)


def twin(map_name, block):
    """The original game's version of a block of a piece, or None."""
    van = actors(map_name)
    if not van:
        return None
    v = van.get(block['name'])
    mine = list(t3d.actors(block['raw']))[0]
    if block.get('brush'):
        a = _bounds(mine)
        b = _bounds(v) if v is not None else None
        if a and b and all(abs(a[k][i] - b[k][i]) <= 2 for k in range(2) for i in range(3)):
            return v
        return _moved_twin(van, mine, a) if a else None
    if v is None:
        return None
    if v['cls'].split('.')[-1] != mine['cls'].split('.')[-1]:
        return None
    la, lb = t3d.vec(mine['props'].get('Location')), t3d.vec(v['props'].get('Location'))
    if la is None or lb is None or any(abs(la[i] - lb[i]) > 4 for i in range(3)):
        return None
    return v


def _baked(raw):
    """A brush block with its transform (PrePivot, MainScale, Rotation, PostScale) baked into its polygons, as the
    map editor's own copies are: its Location at the brush's centre, nothing else. A piece's blocks are then
    turned and moved as wholes; with the original map's PostScale (applied in the world's axes, after the
    rotation) left on, a turned piece came out bent (the canal's pipes on the roof stood off, 19 Oct 2026)."""
    a = list(t3d.actors(raw))[0]
    p = a['props']
    if a['cls'] != 'Brush' or not any(p.get(k) for k in ('Rotation', 'MainScale', 'PostScale', 'PrePivot')):
        return raw
    loc = t3d.vec(p.get('Location')) or (0.0, 0.0, 0.0)
    pre = t3d.vec(p.get('PrePivot')) or (0.0, 0.0, 0.0)
    main, post = t3d._scale(p, 'MainScale'), t3d._scale(p, 'PostScale')
    r = t3d.rot(p.get('Rotation'))

    def lin(q):                                  # the linear part, as t3d.world_verts
        q = tuple(q[i] * main[i] for i in range(3))
        q = t3d._rotate(q, r)
        return tuple(q[i] * post[i] for i in range(3))

    def point(q):
        q = lin(tuple(q[i] - pre[i] for i in range(3)))
        return tuple(q[i] + loc[i] for i in range(3))

    cols = [lin(e) for e in ((1.0, 0, 0), (0, 1.0, 0), (0, 0, 1.0))]      # M's columns
    m = [[cols[j][i] for j in range(3)] for i in range(3)]
    det = (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
           + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))
    if abs(det) < 1e-9:
        return raw
    inv = [[(m[(j + 1) % 3][(i + 1) % 3] * m[(j + 2) % 3][(i + 2) % 3] -
             m[(j + 1) % 3][(i + 2) % 3] * m[(j + 2) % 3][(i + 1) % 3]) / det for j in range(3)] for i in range(3)]

    def cov(v):                                  # texture axes and normals: M^-T
        return tuple(sum(inv[k][i] * v[k] for k in range(3)) for i in range(3))

    verts = [point(tuple(float(x) for x in v.split(','))) for v in re.findall(r'Vertex\s+([-+0-9.eE,]+)', a['body'])]
    if not verts:
        return raw
    c = tuple(round((min(v[i] for v in verts) + max(v[i] for v in verts)) / 2, 3) for i in range(2)) + \
        (round(min(v[2] for v in verts), 3),)

    def fmt(v):
        return ','.join('%+013.6f' % x for x in v)

    def line(mm):
        key, nums = mm.group(2), tuple(float(x) for x in mm.group(3).split(','))
        if key == 'Vertex' or key == 'Origin':
            q = point(nums)
            q = tuple(q[i] - c[i] for i in range(3))
        elif key == 'Normal':
            q = cov(nums)
            ln = sum(x * x for x in q) ** 0.5 or 1.0
            q = tuple(x / ln for x in q)
            if det < 0:
                q = tuple(-x for x in q)
        else:                                    # TextureU, TextureV
            q = cov(nums)
        return '%s%-8s %s' % (mm.group(1), key, fmt(q))
    out = re.sub(r'(?m)^(\s*)(Vertex|Origin|Normal|TextureU|TextureV)\s+([-+0-9.eE,]+)\s*$', line, raw)
    out = re.sub(r'(?m)^\s*(Rotation|MainScale|PostScale|PrePivot|TempScale)=[^\r\n]*\r?\n', '', out)
    loc_line = '    Location=(X=%.6f,Y=%.6f,Z=%.6f)' % c
    if re.search(r'(?m)^\s*Location=', out):
        out = re.sub(r'(?m)^\s*Location=[^\r\n]*', lambda mm: loc_line, out, count=1)
    else:
        head, rest = out.split('\n', 1)
        out = head + '\n' + loc_line + '\n' + rest
    if det < 0:                                  # a mirror: the polygons' winding turns
        def flip(pm):
            body = pm.group(0)
            vs = re.findall(r'(?m)^\s*Vertex[^\r\n]*', body)
            if len(vs) < 3:
                return body
            it = iter(reversed(vs))
            return re.sub(r'(?m)^\s*Vertex[^\r\n]*', lambda _m: next(it), body)
        out = re.sub(r'(?s)Begin Polygon.*?End Polygon', flip, out)
    return out


MOVER_KEYS = ('bLocked', 'bPickable', 'bBreakable', 'KeyIDNeeded', 'InitialState', 'bFrobbable', 'bHighlight',
              'MoveTime', 'StayOpenTime', 'doorStrength', 'bIsDoor')


def _mover_as(copied, raw):
    """The original map's mover with the copied one's behaviour (MOVER_KEYS: set as there, or the class default
    where the copy has none)."""
    for key in MOVER_KEYS:
        m = re.search(r'(?m)^\s*' + key + r'=([^\r\n]*)', copied)
        raw = re.sub(r'(?m)^\s*' + key + r'=[^\r\n]*\r?\n', '', raw)
        if m:
            raw = raw.replace('End Actor', '    %s=%s\nEnd Actor' % (key, m.group(1).strip()), 1)
    return raw


def _sig(raw):
    """A brush's look: its textures and polygon count."""
    return set(re.findall(r'Texture=(\S+)', raw)), len(_polys(raw))


def _moved_twin(van, mine, a):
    """The same brush under another name (Revision renumbered the map's brushes): the same size, polygons
    and textures (the copy's unseen faces took its main texture: its set may be smaller). Its block is moved
    to where the piece's was."""
    size = [a[1][i] - a[0][i] for i in range(3)]
    tex, polys = _sig(mine['raw'])
    best = None
    for c in van.values():
        if c['cls'] != 'Brush':
            continue
        ct, cp = _sig(c['raw'])
        if cp != polys or not tex <= ct:
            continue
        b = _bounds(c)
        if b and all(abs((b[1][i] - b[0][i]) - size[i]) <= 2 for i in range(3)):
            d = sum(abs(b[0][i] - a[0][i]) for i in range(3))
            if best is None or d < best[0]:
                best = (d, c, b)
    if best is None:
        return None
    _, c, b = best
    loc = t3d.vec(c['props'].get('Location')) or (0.0, 0.0, 0.0)
    new = tuple(loc[i] + a[0][i] - b[0][i] for i in range(3))
    text = 'Location=(X=%.6f,Y=%.6f,Z=%.6f)' % new
    raw = c['raw']
    if re.search(r'(?m)^\s*Location=', raw):
        raw = re.sub(r'(?m)^(\s*)Location=\([^)]*\)', lambda m: m.group(1) + text, raw, count=1)
    else:
        head, rest = raw.split('\n', 1)
        raw = head + '\n    ' + text + '\n' + rest
    return dict(c, raw=raw, moved_from=c['name'])


# invisible, masked, translucent, not solid, semisolid, modulated, two-sided, no smooth, special lit, unlit,
# high shadow: what a face may keep (not the editor's selection and the like)
KEEP_FLAGS = 1 | 2 | 4 | 8 | 32 | 64 | 256 | 2048 | 0x100000 | 0x400000 | 0x800000
SIGNISH = re.compile(r'sign|light|lght|neon|panel|logo|kanji|poster|danger|cmptr|exit', re.I)
_n_own = [0]


def _vanilla_class(block):
    """An object of a class the original game's maps use (decorations, crates: not Revision's own)."""
    cls = list(t3d.actors(block['raw']))[0]['cls'].split('.')[-1]
    known = set()
    for m in _maps.values():
        if m:
            known |= {a['cls'].split('.')[-1] for a in m.values()}
    return cls in known and cls not in ('Brush',) and not cls.startswith('Rev')


def _brush_raw(name, brush, csg='CSG_Add', polyflags=None):
    """A Brush actor block for a geom brush made in world (source) coordinates: its Location at the brush's
    centre (lowest Z) and its polygons around it, as the maps' own brushes are. A Location at the origin made the
    map editor's structure pivots (the centre of the pieces' Locations) wrong: a scaled group went astray."""
    import geom
    pts = [p for f in brush.faces for p in f.verts]
    c = tuple(round((min(p[i] for p in pts) + max(p[i] for p in pts)) / 2, 3) for i in range(2)) + \
        (round(min(p[2] for p in pts), 3),)
    local = brush.transformed(geom.XForm((0, 0, 0), offset=tuple(-v for v in c)))
    local.name = name + 'M'
    return ('Begin Actor Class=Brush Name=%s\n    CsgOper=%s\n%s    Location=(X=%.6f,Y=%.6f,Z=%.6f)\n%s'
            "    Brush=Model'MyLevel.%sM'\nEnd Actor\n" % (name, csg, '    PolyFlags=%s\n' % polyflags if polyflags else '',
                                                      c[0], c[1], c[2], local.t3d(), name))


def _world_mapping(actor, poly_raw):
    """A polygon's TextureU, TextureV and Origin in world space (the brush's PrePivot, Rotation, Location; its
    scales taken as 1), or None."""
    def vec3(key):
        m = re.search(r'(?m)^\s*' + key + r'\s+([-+0-9.eE]+),([-+0-9.eE]+),([-+0-9.eE]+)', poly_raw)
        return tuple(float(m.group(i)) for i in (1, 2, 3)) if m else None
    u, v, o = vec3('TextureU'), vec3('TextureV'), vec3('Origin')
    if not (u and v and o):
        return None
    p = actor['props']
    loc = t3d.vec(p.get('Location')) or (0.0, 0.0, 0.0)
    pre = t3d.vec(p.get('PrePivot')) or (0.0, 0.0, 0.0)
    r = t3d.rot(p.get('Rotation'))
    turn = lambda q: t3d._rotate(q, r)
    origin = turn(tuple(o[i] - pre[i] for i in range(3)))
    return turn(u), turn(v), tuple(origin[i] + loc[i] for i in range(3))


def own_block(block, textures=None):
    """Our own stand-in for a brush only Revision has: a box (a cylinder when it is round and many-sided) of
    the same place and size, each side with the texture and flags of the original's faces that look that way
    (Revision's own textures as `textures` says); a sign's face shows the whole sign. A sheet (no thickness: a
    railing, a neon) stays one polygon, seen from both sides."""
    import geom
    a = list(t3d.actors(block['raw']))[0]
    wv = t3d.world_verts(a)
    if not wv:
        return None
    lo = [min(v[i] for _, vs in wv for v in vs) for i in range(3)]
    hi = [max(v[i] for _, vs in wv for v in vs) for i in range(3)]
    thin = [i for i in range(3) if hi[i] - lo[i] < 0.5]
    for i in range(3):
        if i not in thin and hi[i] - lo[i] < 1:
            lo[i], hi[i] = (lo[i] + hi[i]) / 2 - 0.5, (lo[i] + hi[i]) / 2 + 0.5
    faces = []
    for poly, vs in wv:
        if len(vs) < 3 or not poly['texture']:
            continue
        n = geom.norm(geom.cross(geom.sub(vs[1], vs[0]), geom.sub(vs[2], vs[0])))
        faces.append((n, poly['texture'], poly['flags'], _world_mapping(a, poly['raw'])))
    if not faces:
        return None
    tex_count = {}
    for _, tx, _f, _m in faces:
        tex_count[tx] = tex_count.get(tx, 0) + 1
    common = max(tex_count, key=tex_count.get)

    def bare(tx):
        b = tx.split("'")[-2] if "'" in tx else tx
        b = b.split('.')[-1]
        for k, v in (textures or {}).items():
            if k.split('.')[-1].lower() == b.lower():
                return v.split('.')[-1]
        return b

    def pick(d):
        """The faces that look that way (either winding): a sign among them first, else the most of them."""
        near = [f for f in faces if abs(geom.dot(f[0], d)) > 0.5]
        if not near:
            return bare(common), 0, None
        signs = [f for f in near if SIGNISH.search(bare(f[1]))]
        if signs:
            best = signs[0]
        else:
            count = {}
            for f in near:
                count[f[1]] = count.get(f[1], 0) + 1
            top = max(count, key=count.get)
            best = next(f for f in near if f[1] == top)
        # its texture mapping too, when that face lies the same way (the stand-in shows the texture as it did)
        return bare(best[1]), best[2] & KEEP_FLAGS, best[3] if abs(geom.dot(best[0], d)) > 0.9 else None

    mats, mapping = {}, {}
    size = [hi[i] - lo[i] for i in range(3)]
    corner = (lo[0], lo[1], hi[2])          # a sign starts at a corner of its face: the whole sign shows
    for key, d, (wi, hi_ax) in (('-x', (-1, 0, 0), (1, 2)), ('+x', (1, 0, 0), (1, 2)), ('-y', (0, -1, 0), (0, 2)),
                                ('+y', (0, 1, 0), (0, 2)), ('-z', (0, 0, -1), (0, 1)), ('+z', (0, 0, 1), (0, 1))):
        tx, fl, mapping[key] = pick(d)
        if SIGNISH.search(tx):
            mats[key] = geom.Mat(tx, tile=(max(size[wi], 1), max(size[hi_ax], 1)), flags=fl, align=corner)
        else:
            mats[key] = geom.Mat(tx, flags=fl)
    # what makes the original not solid or semisolid (most of its faces): all of the stand-in's
    shared = 0
    for bit in (8, 32):
        if sum(1 for f in faces if f[2] & bit) * 2 > len(faces):
            shared |= bit
    for m in mats.values():
        m.flags |= shared
    _n_own[0] += 1
    name = 'UCOwn%d' % _n_own[0]
    round_ = abs(size[0] - size[1]) < 4 and len(faces) >= 14 and size[0] > 8
    if thin:
        i = thin[0]
        c = (lo[i] + hi[i]) / 2
        d = tuple(1 if k == i else 0 for k in range(3))
        u, v = [k for k in range(3) if k != i]
        verts = []
        for cu, cv in ((lo[u], lo[v]), (hi[u], lo[v]), (hi[u], hi[v]), (lo[u], hi[v])):
            pnt = [0.0, 0.0, 0.0]
            pnt[i], pnt[u], pnt[v] = c, cu, cv
            verts.append(tuple(pnt))
        n = geom.norm(geom.cross(geom.sub(verts[1], verts[0]), geom.sub(verts[2], verts[0])))
        if geom.dot(n, d) < 0:
            verts.reverse()
        m = mats['+' + 'xyz'[i]]
        b = geom.Brush([geom.Face(verts, m.with_(flags=m.flags | 256))], name + 'M')       # two-sided
    elif round_:
        b = geom.prism(((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2), size[0] / 2, lo[2], hi[2],
                       {'sides': mats['+x'], 'top': mats['+z'], 'bottom': mats['-z']}, sides=12, name=name + 'M')
    else:
        b = geom.box(tuple(lo), tuple(hi), mats, name=name + 'M')
    for f in b.faces:
        k = max(range(3), key=lambda j: abs(f.normal[j]))
        m = mapping.get(('+' if f.normal[k] > 0 else '-') + 'xyz'[k]) or (mapping.get('+' + 'xyz'[k]) if thin else None)
        if m and abs(f.normal[k]) > 0.9:
            f.u, f.v, f.origin = m
    pf = re.search(r'(?m)^\s*PolyFlags=(\d+)', block['raw'])
    csg = re.search(r'(?m)^\s*CsgOper=(\w+)', block['raw'])
    return dict(block, raw=_brush_raw(name, b, csg.group(1) if csg else 'CSG_Add', pf.group(1) if pf else None),
                own=True)


def _packages(raws):
    """The texture packages of these blocks (the catalog: catalog\\<package>.txt)."""
    global _tex_pkg
    if _tex_pkg is None:
        _tex_pkg = {}
        for f in (KIT / 'catalog').glob('*.txt'):
            for line in f.read_text(encoding='utf-8', errors='replace').splitlines():
                m = re.match(r'\s*\d+\s+\S*?\.?([^.\s]+)\s+\d+x\d+', line)
                if m:
                    _tex_pkg.setdefault(m.group(1).lower(), f.stem)
    out = set()
    for raw in raws:
        for t in re.findall(r'Texture=(\S+)', raw):
            name = t.split("'")[-2] if "'" in t else t
            pkg = name.split('.')[0] if '.' in name else _tex_pkg.get(name.lower())
            if pkg:
                out.add(pkg)
    return sorted(out)


TEXTURES = {}       # Revision's textures -> the original game's, for our stand-ins (convert_vanilla_map.TEXTURES)
# pieces made by hand instead: [(match(prefab) -> bool, make(prefab) -> blocks)]. The paste stays where it is in the
# script (the map editor's edits name pastes by their number: S16, S25_c1...), only what it holds changes
OVERRIDES = []


def brush_block(name, brush, polyflags=None, csg='CSG_Add'):
    """A block of a piece from a geom brush in the piece's source coordinates (around its pivot)."""
    return dict(name=name, cls='Brush', brush=True, raw=_brush_raw(name, brush, csg, polyflags), own=True)


def vanillize(pf):
    """The original game's version of prefab pf (a copy): its blocks the original map has, as there."""
    import prefabs
    src = pf.get('source')
    out = copy.deepcopy(pf)
    rep = REPORT.setdefault(pf.get('id', '?'), dict(source=src, label=pf.get('label'), kept=[], dropped=[]))
    for match, make in OVERRIDES:              # our own piece in its place (made by hand, same pivot)
        if match(pf):
            out['blocks'] = make(pf)
            out['packages'] = _packages(b['raw'] for b in out['blocks'])
            rep['own'] = ['(made by hand: %d blocks)' % len(out['blocks'])]
            return out
    if not src or actors(src) is None:         # a map only Revision has: our own stand-ins of its brushes
        out['blocks'] = [o for o in (own_block(b, TEXTURES) for b in pf['blocks'] if b.get('brush') and not b.get('mover'))
                         if o is not None]
        rep['own'] = [b['name'] for b in pf['blocks'] if b.get('brush')]
        rep['dropped'] = ['(the original game has no %s)' % src] + [b['name'] for b in pf['blocks'] if not b.get('brush')]
        out['packages'] = _packages(b['raw'] for b in out['blocks'])
        return out
    blocks = []
    for b in pf['blocks']:
        v = twin(src, b)
        if v is None and b.get('brush') and not b.get('mover'):
            nb = own_block(b, TEXTURES)         # what only Revision has: our own stand-in
            if nb is not None:
                blocks.append(nb)
                rep.setdefault('own', []).append(b['name'])
                continue
        if v is None and not b.get('brush') and not b.get('mover') and _vanilla_class(b):
            blocks.append(dict(b, raw=prefabs._clean_block(b['raw'])))     # a crate, a barrel: placed as it was
            rep.setdefault('placed', []).append(b['name'])
            continue
        if v is None:
            if b['name'] not in rep['dropped']:
                rep['dropped'].append(b['name'])
            continue
        nb = dict(b)
        raw = prefabs._clean_block(v['raw'])
        if b.get('brush'):
            raw = _baked(raw)
        nb['raw'] = _same_faces_hidden(b['raw'], raw) if b.get('hidden_faces') else raw
        if b.get('mover'):
            # a door works as the piece did (its lock, times, use): the original map's may be locked where the
            # copied one was open (the Silo's door on the roof, Gabby 19 Oct 2026)
            nb['raw'] = _mover_as(b['raw'], nb['raw'])
        blocks.append(nb)
        name = b['name'] + ('<-' + v['moved_from'] if v.get('moved_from') else '')
        if name not in rep['kept']:
            rep['kept'].append(name)
    out['blocks'] = blocks
    out['packages'] = sorted(set(p for p in pf.get('packages', []) if p.startswith('sound:'))
                             | set(_packages(b['raw'] for b in blocks)))
    return out


def install():
    """Every prefab and original object the build loads comes from the original game's maps."""
    import prefabs
    if getattr(prefabs, '_vanilla_installed', False):
        return
    load, _original = prefabs.load, prefabs._original

    def load_vanilla(pid):
        return vanillize(load(pid))

    def original_vanilla(map_name, name, log=print):
        a = (actors(map_name) or {}).get(name)
        if a is None:
            raise KeyError('the original game\'s %s has no %s' % (map_name, name))
        return a
    prefabs.load = load_vanilla
    prefabs._original = original_vanilla
    prefabs._vanilla_installed = True
    prefabs._revision_load = load


def summary():
    lines = []
    for pid, r in sorted(REPORT.items()):
        lines.append('%-56s kept %3d  own %3d  left out %3d  %s' % (pid[:56], len(r['kept']), len(r.get('own', [])),
                                                                   len(r['dropped']), ', '.join(r['dropped'][:6])))
    return lines
