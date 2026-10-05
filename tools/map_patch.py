"""Map patches: publish the mod's map changes without publishing the maps.

The mod changes a few of the game's maps. Those files belong to the game, so the
repository holds only the DIFFERENCE between the original map (which you own) and the
modified one, as a small patch file in maps/patches/. This tool makes and applies them.

  python tools/map_patch.py apply-all [--game "C:\\...\\Deus Ex"]
        rebuild maps\\*.dx from your own Revision maps and the patches (checked by SHA-256)
  python tools/map_patch.py make-all [--game ...]
        after editing a map in maps\\, write its patch again
  python tools/map_patch.py make  <original> <modified> <patch>
  python tools/map_patch.py apply <original> <patch> <output>

A patch is a JSON header line followed by zlib-compressed operations: "copy this run of
bytes from the original" or "insert these new bytes". No dependencies.
"""
import glob
import hashlib
import json
import os
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = r'C:\Program Files (x86)\Steam\steamapps\common\Deus Ex'
BLOCK = 32
MAGIC = 'UCMAPPATCH1'


def sha(b):
    return hashlib.sha256(b).hexdigest()


def make(orig, new):
    """Returns (ops, copied, inserted). ops = list of ('C', offset, length) / ('D', bytes)."""
    index = {}
    for off in range(0, len(orig) - BLOCK + 1, BLOCK):
        index.setdefault(orig[off:off + BLOCK], off)
    ops = []
    lit = bytearray()
    i = 0
    n = len(new)
    copied = 0
    while i < n:
        off = index.get(new[i:i + BLOCK]) if i + BLOCK <= n else None
        if off is None:
            lit.append(new[i])
            i += 1
            continue
        # extend the match backwards into the pending literal, then forwards
        back = 0
        while back < len(lit) and off - back > 0 and orig[off - back - 1] == lit[len(lit) - back - 1]:
            back += 1
        if back:
            del lit[len(lit) - back:]
        start = off - back
        length = back + BLOCK
        j = i + BLOCK
        k = off + BLOCK
        # compare in big steps, then byte by byte
        while j + 4096 <= n and k + 4096 <= len(orig) and new[j:j + 4096] == orig[k:k + 4096]:
            j += 4096
            k += 4096
        while j < n and k < len(orig) and new[j] == orig[k]:
            j += 1
            k += 1
        length = k - start
        if lit:
            ops.append(('D', bytes(lit)))
            lit = bytearray()
        ops.append(('C', start, length))
        copied += length
        i = j
    if lit:
        ops.append(('D', bytes(lit)))
    inserted = sum(len(o[1]) for o in ops if o[0] == 'D')
    return ops, copied, inserted


def write_patch(path, name, orig, new):
    ops, copied, inserted = make(orig, new)
    body = bytearray()
    for o in ops:
        if o[0] == 'C':
            body += b'C' + struct.pack('<II', o[1], o[2])
        else:
            body += b'D' + struct.pack('<I', len(o[1])) + o[1]
    head = {'format': MAGIC, 'map': name, 'original_size': len(orig), 'original_sha256': sha(orig),
            'result_size': len(new), 'result_sha256': sha(new), 'new_bytes': inserted}
    with open(path, 'wb') as f:
        f.write((json.dumps(head) + '\n').encode('utf-8'))
        f.write(zlib.compress(bytes(body), 9))
    return head, os.path.getsize(path)


def read_patch(path):
    data = open(path, 'rb').read()
    nl = data.index(b'\n')
    head = json.loads(data[:nl].decode('utf-8'))
    if head.get('format') != MAGIC:
        sys.exit('not a map patch: ' + path)
    return head, zlib.decompress(data[nl + 1:])


def apply(orig, path):
    head, body = read_patch(path)
    if sha(orig) != head['original_sha256']:
        sys.exit('%s: your original map is not the version this patch was made from '
                 '(different Revision version?). Nothing written.' % head['map'])
    out = bytearray()
    i = 0
    while i < len(body):
        op = body[i:i + 1]
        if op == b'C':
            off, length = struct.unpack_from('<II', body, i + 1)
            out += orig[off:off + length]
            i += 9
        else:
            (length,) = struct.unpack_from('<I', body, i + 1)
            out += body[i + 5:i + 5 + length]
            i += 5 + length
    if sha(bytes(out)) != head['result_sha256']:
        sys.exit('%s: the rebuilt map does not match. Nothing written.' % head['map'])
    return head, bytes(out)


def game_map(game, name):
    return os.path.join(game, 'Revision', 'Maps', name)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--game')]
    game = GAME
    for i, a in enumerate(sys.argv):
        if a.startswith('--game='):
            game = a[7:]
        elif a == '--game' and i + 1 < len(sys.argv):
            game = sys.argv[i + 1]
            args = [x for x in args if x != game]
    cmd = args[0] if args else ''
    patches = os.path.join(ROOT, 'maps', 'patches')
    if cmd == 'make' and len(args) == 4:
        head, size = write_patch(args[3], os.path.basename(args[2]), open(args[1], 'rb').read(), open(args[2], 'rb').read())
        print('ok', args[3], size, 'bytes;', head['new_bytes'], 'new bytes in the map')
    elif cmd == 'apply' and len(args) == 4:
        head, out = apply(open(args[1], 'rb').read(), args[2])
        open(args[3], 'wb').write(out)
        print('ok', args[3])
    elif cmd == 'make-all':
        os.makedirs(patches, exist_ok=True)
        for f in sorted(glob.glob(os.path.join(ROOT, 'maps', '*.dx'))):
            name = os.path.basename(f)
            base = game_map(game, name)
            if not os.path.exists(base):
                print('skipped (no original in the game):', name)
                continue
            if open(base, 'rb').read() == open(f, 'rb').read():
                print('%-32s identical to the original: no patch needed' % name)
                continue
            head, size = write_patch(os.path.join(patches, name + '.ucpatch'), name,
                                     open(base, 'rb').read(), open(f, 'rb').read())
            print('%-32s patch %8d bytes, %8d new bytes of %d' % (name, size, head['new_bytes'], head['result_size']))
    elif cmd == 'apply-all':
        found = sorted(glob.glob(os.path.join(patches, '*.ucpatch')))
        if not found:
            sys.exit('no patches in ' + patches)
        for p in found:
            head, _ = read_patch(p)
            base = game_map(game, head['map'])
            if not os.path.exists(base):
                sys.exit('original map not found: %s (use --game "<Deus Ex folder>")' % base)
            head, out = apply(open(base, 'rb').read(), p)
            dst = os.path.join(ROOT, 'maps', head['map'])
            if os.path.exists(dst) and sha(open(dst, 'rb').read()) == head['result_sha256']:
                print('already up to date:', head['map'])
                continue
            if os.path.exists(dst):
                sys.exit('%s exists and is different from the patched map (your own edits?). '
                         'Move it away first.' % dst)
            open(dst, 'wb').write(out)
            print('written', dst)
    else:
        print(__doc__)


if __name__ == '__main__':
    main()
