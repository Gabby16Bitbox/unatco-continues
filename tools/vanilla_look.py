"""Photos of a map of the mod in the ORIGINAL Deus Ex: launch it (tools\\play_vanilla.py), put JC at each spot,
grab the game window, quit cleanly (console exit), one contact sheet.

    python tools\\vanilla_look.py <map> <name> "player;x;y;z;yaw;pitch" ...    -> shots\\vanilla\\<name>.jpg

The original game's own screenshot comes out magenta: the window is grabbed instead.
"""
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
sys.path.insert(0, str(ROOT / 'video' / 'game'))
import play_vanilla as pv  # noqa: E402
import shoot  # noqa: E402
from PIL import ImageGrab, Image  # noqa: E402

OUT = ROOT / 'shots' / 'vanilla'


def main(map_name, name, steps):
    OUT.mkdir(parents=True, exist_ok=True)
    print('first:', pv.start(map_name))
    shots = []
    try:
        time.sleep(8)               # the map settles (an early step was once never answered)
        pv.live.do('hud;0', timeout=90)
        try:
            pv.live.do('console;ghost', timeout=20)
        except TimeoutError:        # now and then its answer never comes; the steps after it are answered
            print('(ghost: no answer, going on)')
        for i, s in enumerate(steps):
            print(s, '->', pv.live.do(s, timeout=60)[0])
            time.sleep(1.2)
            x, y, w, h = shoot.client_rect()
            f = OUT / ('%s_%d.png' % (name, i))
            ImageGrab.grab(bbox=(x, y, x + w, y + h), all_screens=True).save(f)
            shots.append(f)
        lines = [l for l in pv.log_tail(800) if any(k in l for k in ('Accessed None', 'Critical', 'UnatcoContinues:'))]
        print('\n'.join(lines[-20:]))
    finally:
        try:
            pv.live.do('console;exit', timeout=8)
        except Exception:
            pass
        time.sleep(6)
        print(pv.stop())
    if shots:
        ims = [Image.open(f).convert('RGB').resize((640, 480)) for f in shots]
        sheet = Image.new('RGB', (1280, 480 * ((len(ims) + 1) // 2)))
        for i, im in enumerate(ims):
            sheet.paste(im, ((i % 2) * 640, (i // 2) * 480))
        sheet.save(OUT / ('%s.jpg' % name))
        print('sheet', OUT / ('%s.jpg' % name))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3:])
