"""A screenshot of the game (Shot0000.bmp...) as a PNG, read the way the game writes it.

The engine writes its BMP rows without the padding the format asks for (each row a multiple of 4 bytes): when
the window's width is not a multiple of 4 (18 Oct 2026: 2350 wide) every row is a few bytes short, the file is
short by height x that, and an ordinary reader shears the picture and scrambles its colours. Here the stride is
the one the file really has.
    python tools\\shot_bmp.py <Shot.bmp> <out.png> [width]
"""
import struct
import sys
from PIL import Image


def read(path):
    data = open(path, 'rb').read()
    offset = struct.unpack_from('<I', data, 10)[0]
    width, height = struct.unpack_from('<ii', data, 18)
    depth = struct.unpack_from('<H', data, 28)[0] // 8
    rows = abs(height)
    padded = (width * depth + 3) // 4 * 4
    stride = padded if len(data) - offset >= padded * rows else width * depth
    raw = data[offset:offset + stride * rows]
    mode = {3: 'BGR', 4: 'BGRX'}[depth]
    return Image.frombuffer('RGB', (width, rows), raw, 'raw', mode, stride, -1 if height > 0 else 1)


def main():
    src, dst = sys.argv[1], sys.argv[2]
    im = read(src)
    if len(sys.argv) > 3:
        w = int(sys.argv[3])
        im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    im.save(dst)


if __name__ == '__main__':
    main()
