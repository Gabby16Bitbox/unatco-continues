"""Crea src\\UnatcoContinues\\Textures\\UCFade.pcx: una sfumatura orizzontale di grigi, da 128
(colonna 0) a 0 (colonna 127), 128x8, 256 colori.

Serve alla targhetta delle scritte della presentazione (UCCaptionWindow) per comparire in
dissolvenza: disegnata in stile "modulato" (schermo x colore x 2) una colonna grigio 128
non cambia niente, una nera copre tutto; scegliendo la colonna si sceglie l'opacita'.

Uso: python tools\\make_fade_texture.py
"""
import os
import struct

W, H = 128, 8
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'src', 'UnatcoContinues', 'Textures', 'UCFade.pcx')


def rle(row):
    out = bytearray()
    i = 0
    while i < len(row):
        v = row[i]
        n = 1
        while i + n < len(row) and row[i + n] == v and n < 63:
            n += 1
        if n > 1 or v >= 0xC0:
            out += bytes((0xC0 | n, v))
        else:
            out.append(v)
        i += n
    return bytes(out)


def main():
    # indice di tavolozza = livello di grigio
    row = bytes(round(128 * (1 - c / (W - 1))) for c in range(W))
    header = struct.pack('<BBBBHHHHHH', 10, 5, 1, 8, 0, 0, W - 1, H - 1, 72, 72)
    header += bytes(48) + b'\0' + struct.pack('<BHHHH', 1, W, 1, 0, 0)
    header += bytes(128 - len(header))
    palette = bytes(v for g in range(256) for v in (g, g, g))
    with open(OUT, 'wb') as f:
        f.write(header)
        for _ in range(H):
            f.write(rle(row))
        f.write(b'\x0c' + palette)
    print('ok', OUT, os.path.getsize(OUT), 'byte')


if __name__ == '__main__':
    main()
