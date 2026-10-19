"""Patches of the mod's maps: what the mod changes in a map of Revision, without Revision's map itself.

The repository must not carry Revision's maps (theirs). A patch keeps only our differences: the player's own
copy of the original map (Revision\\Maps\\<name>.dx) plus the patch gives back our map, byte for byte, and
install.ps1 writes it to Revision\\UnatcoMaps. A map of ours made from pieces of several originals (the
rooftop) can take its unchanged bytes from all of them.

    python tools\\mappatch.py make <our map.dx> <out.ucpatch> <original.dx> [<original.dx> ...]
    python tools\\mappatch.py apply <in.ucpatch> <maps folder of the game> <out.dx>
    python tools\\mappatch.py all            the patches of maps\\patches.json into maps\\patches\\
    python tools\\mappatch.py check          every patch applied in memory and compared with our maps
    python tools\\mappatch.py all vanilla    the same for the original Deus Ex: maps\\vanilla\\patches.json, our maps in
                                           maps\\vanilla\\, the originals in <Deus Ex>\\Maps, into maps\\vanilla\\patches\\

Format (little endian): 'UCPATCH1', then raw deflate (zlib wbits -15) of:
  u32 number of sources; per source: u16 length + name (latin1), u64 size, 32 bytes sha256
  u64 size of the result, 32 bytes sha256 of the result
  operations until the end: 0x01 copy  = u8 source, u64 offset, u32 length
                            0x02 bytes = u32 length + the bytes (ours)
Applied by install.ps1 (Expand-MapPatch) with the same format.
"""
import hashlib
import json
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAGIC = b'UCPATCH1'
BLOCK = 32                      # unchanged runs shorter than this stay in the patch as bytes


def _sha(b):
    return hashlib.sha256(b).digest()


def make(target, sources):
    """target: bytes; sources: [(name, bytes)] -> patch bytes"""
    index = {}
    for si, (_, data) in enumerate(sources):
        for j in range(0, len(data) - BLOCK + 1, BLOCK):
            index.setdefault(data[j:j + BLOCK], (si, j))
    ops = []
    lit = bytearray()
    i, n = 0, len(target)

    def flush():
        if lit:
            ops.append((2, bytes(lit)))
            lit.clear()

    while i < n:
        hit = index.get(target[i:i + BLOCK]) if i + BLOCK <= n else None
        if hit is None:
            lit.append(target[i])
            i += 1
            continue
        si, j = hit
        src = sources[si][1]
        # back over the bytes just written as ours, while they match too
        back = 0
        while back < len(lit) and j - back > 0 and src[j - back - 1] == lit[-1 - back]:
            back += 1
        if back:
            del lit[len(lit) - back:]
        start_t, start_s = i - back, j - back
        # forward, in big steps then byte by byte
        k = BLOCK
        step = 4096
        while step:
            while i + k + step <= n and j + k + step <= len(src) and target[i + k:i + k + step] == src[j + k:j + k + step]:
                k += step
            step //= 8
        while i + k < n and j + k < len(src) and target[i + k] == src[j + k]:
            k += 1
        flush()
        ops.append((1, si, start_s, k + back))
        i = start_t + k + back
    flush()
    body = bytearray(struct.pack('<I', len(sources)))
    for name, data in sources:
        nb = name.encode('latin1')
        body += struct.pack('<H', len(nb)) + nb + struct.pack('<Q', len(data)) + _sha(data)
    body += struct.pack('<Q', len(target)) + _sha(target)
    for op in ops:
        if op[0] == 1:
            body += struct.pack('<BBQI', 1, op[1], op[2], op[3])
        else:
            body += struct.pack('<BI', 2, len(op[1])) + op[1]
    c = zlib.compressobj(9, zlib.DEFLATED, -15)
    return MAGIC + c.compress(bytes(body)) + c.flush()


def parse(patch):
    if patch[:8] != MAGIC:
        raise ValueError('not a map patch')
    body = zlib.decompress(patch[8:], -15)
    p = 0
    (ns,) = struct.unpack_from('<I', body, p)
    p += 4
    sources = []
    for _ in range(ns):
        (ln,) = struct.unpack_from('<H', body, p)
        p += 2
        name = body[p:p + ln].decode('latin1')
        p += ln
        (size,) = struct.unpack_from('<Q', body, p)
        p += 8
        sources.append((name, size, body[p:p + 32]))
        p += 32
    (size,) = struct.unpack_from('<Q', body, p)
    p += 8
    sha = body[p:p + 32]
    p += 32
    return sources, (size, sha), body, p


def apply(patch, read_source):
    """read_source(name) -> bytes of the player's original; returns our map (bytes) or raises."""
    sources, (size, sha), body, p = parse(patch)
    data = []
    for name, ssize, ssha in sources:
        b = read_source(name)
        if b is None:
            raise FileNotFoundError(name)
        if len(b) != ssize or _sha(b) != ssha:
            raise ValueError('%s is not the version the patch was made from (another Revision version?)' % name)
        data.append(b)
    out = bytearray()
    while p < len(body):
        kind = body[p]
        if kind == 1:
            _, si, off, ln = struct.unpack_from('<BBQI', body, p)
            p += 14
            out += data[si][off:off + ln]
        elif kind == 2:
            (ln,) = struct.unpack_from('<I', body, p + 1)
            p += 5
            out += body[p:p + ln]
            p += ln
        else:
            raise ValueError('bad patch')
    if len(out) != size or _sha(bytes(out)) != sha:
        raise ValueError('the result is not our map')
    return bytes(out)


def _ours(vanilla=False):
    """Where our maps, their patches.json and their patches are: maps\\ (Revision) or maps\\vanilla\\."""
    return ROOT / 'maps' / 'vanilla' if vanilla else ROOT / 'maps'


def _cfg(vanilla=False):
    return json.loads((_ours(vanilla) / 'patches.json').read_text(encoding='utf-8'))


def _game_maps(vanilla=False):
    import re
    cfg = (ROOT / 'config.ps1').read_text(encoding='utf-8', errors='replace')
    if vanilla:                     # the original game's own maps
        m = re.search(r"\$GameRoot\s*=\s*['\"]([^'\"]+)['\"]", cfg)
        return Path(m.group(1)) / 'Maps' if m else Path(r'C:\Program Files (x86)\Steam\steamapps\common\Deus Ex\Maps')
    m = re.search(r"\$RevSrc\s*=\s*['\"]([^'\"]+)['\"]", cfg)
    return Path(m.group(1)) / 'Maps' if m else Path(r'C:\Program Files (x86)\Steam\steamapps\common\Deus Ex\Revision\Maps')


def main(argv):
    if argv[:1] == ['make']:
        target = Path(argv[1]).read_bytes()
        srcs = [(Path(s).name, Path(s).read_bytes()) for s in argv[3:]]
        patch = make(target, srcs)
        Path(argv[2]).write_bytes(patch)
        print('%s: %d bytes (our map %d)' % (argv[2], len(patch), len(target)))
    elif argv[:1] == ['apply']:
        folder = Path(argv[2])
        out = apply(Path(argv[1]).read_bytes(), lambda n: (folder / n).read_bytes() if (folder / n).exists() else None)
        Path(argv[3]).write_bytes(out)
        print('wrote', argv[3], len(out))
    elif argv[:1] in (['all'], ['check']):
        vanilla = argv[1:2] == ['vanilla']
        maps = _game_maps(vanilla)
        out_dir = _ours(vanilla) / 'patches'
        out_dir.mkdir(exist_ok=True)
        for name, srcs in _cfg(vanilla).items():
            ours = _ours(vanilla) / (name + '.dx')
            pf = out_dir / (name + '.ucpatch')
            if argv[0] == 'all':
                patch = make(ours.read_bytes(), [(s + '.dx', (maps / (s + '.dx')).read_bytes()) for s in srcs])
                pf.write_bytes(patch)
            res = apply(pf.read_bytes(), lambda n: (maps / n).read_bytes() if (maps / n).exists() else None)
            same = res == ours.read_bytes()
            lit = sum(len(op) for op in _literals(pf.read_bytes()))
            print('%-28s patch %8d bytes, ours %8d bytes, bytes of ours in it %8d, result identical: %s'
                  % (name, pf.stat().st_size, ours.stat().st_size, lit, same))
    else:
        print(__doc__)


def _literals(patch):
    _, _, body, p = parse(patch)
    while p < len(body):
        if body[p] == 1:
            p += 14
        else:
            (ln,) = struct.unpack_from('<I', body, p + 1)
            yield body[p + 5:p + 5 + ln]
            p += 5 + ln


if __name__ == '__main__':
    main(sys.argv[1:])
