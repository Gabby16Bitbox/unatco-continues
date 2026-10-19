"""The mod in the ORIGINAL Deus Ex (GOTY 1112fm), for tests: the live link of tools\\mapkit\\live.py (the mod's
UCShotRunner in live mode: steps, photos) pointed at the original game.

Nothing of the player's game changes: the mod's files go to a folder of their own in the game
(Deus Ex\\UnatcoVanilla: dist\\vanilla\\UnatcoContinues.u, maps\\vanilla\\*.dx, its saves in Save), and the game
is started through Steam with copies of its DeusEx.ini and User.ini made for the launch (UnatcoVanilla\\Play:
those folders first in Paths, a window, the saves there). The live channel's System\\UCLive.txt goes when the
game is stopped.

    import play_vanilla as pv
    pv.start('06_HongKong_WanChai_Rooftop')          # stage + launch (~30 s), first answer
    pv.live.do('player;0;-320;48;16384;0')            # the same steps as live.py
    pv.stop()
"""
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools' / 'mapkit'))
import settings  # noqa: E402
import live  # noqa: E402

GAME = settings.GAME                    # the Deus Ex folder (Revision is inside it)
SYS = GAME / 'System'
MOD = GAME / 'UnatcoVanilla'
PLAY = MOD / 'Play'
REL = '..\\UnatcoVanilla\\'

# live.py's channel, on the original game
live.REV, live.SYS = GAME, SYS
live.EXE = SYS / 'DeusEx.exe'
live.INI = PLAY / 'User.ini'
live.PLAY_INI = PLAY / 'DeusEx.ini'
live.CMD = SYS / 'UCLive.txt'
live.CONSOLE_CMD = SYS / 'UCConsole.txt'
live._SESSION = None


def stage(maps=None):
    """The mod's files for the original game in UnatcoVanilla (copies: the game reads them while it runs)."""
    MOD.mkdir(exist_ok=True)
    (MOD / 'Save').mkdir(exist_ok=True)
    shutil.copy2(ROOT / 'dist' / 'vanilla' / 'UnatcoContinues.u', MOD / 'UnatcoContinues.u')
    for dx in (ROOT / 'maps' / 'vanilla').glob('*.dx'):
        if maps is None or dx.stem in maps:
            shutil.copy2(dx, MOD / dx.name)


def inis():
    """The launch's DeusEx.ini and User.ini: the player's own, read now, with UnatcoVanilla first in Paths,
    its Save folder, in a window."""
    PLAY.mkdir(parents=True, exist_ok=True)
    text = (SYS / 'DeusEx.ini').read_text(encoding='latin1')
    first = re.search(r'(?m)^Paths=', text)
    if not first:
        raise RuntimeError('DeusEx.ini has no Paths')
    ours = 'Paths=%s*.u\r\nPaths=%s*.dx\r\n' % (REL, REL)
    text = text[:first.start()] + ours + text[first.start():]
    text = re.sub(r'(?im)^SavePath=.*$', lambda m: 'SavePath=%sSave' % REL, text)
    text = re.sub(r'(?im)^StartupFullscreen=.*$', 'StartupFullscreen=False', text)
    (PLAY / 'DeusEx.ini').write_text(text, encoding='latin1', newline='')
    shutil.copy2(SYS / 'User.ini', PLAY / 'User.ini')


def start(map_name='06_HongKong_WanChai_Rooftop', delay=6, timeout=240):
    """Stage the mod, launch the original game on map_name in live mode; its first answer."""
    stage()

    def prepare():
        inis()
        live._set_section([live.RUNNER, 'bActive=True', 'bLive=True', 'LiveSeq=0', 'LiveDone=-1', 'LiveCmd=',
                           'LiveResult=', 'Setup=', 'SetupFlags=', 'StartDelay=%s' % delay])
        live.STATE.update(seq=0, command_written=False, maps=set())
        live._write_cmd([])
        (MOD / 'Save' / 'Current' / (map_name + '.dxs')).unlink(missing_ok=True)

    def dispatch(token):
        url = map_name + live.MUTATOR + '?DeusEdixSession=' + token     # the session claims the game by it
        # Steam quotes every word; a comma ends each ini value (live.py, 15 Oct 2026)
        argv, cwd = settings.game_command([url, 'INI=%sPlay\\DeusEx.ini,' % REL, 'USERINI=%sPlay\\User.ini,' % REL],
                                          target='vanilla', folder=GAME)
        import subprocess
        subprocess.Popen(argv, cwd=cwd)

    def cleanup():
        if live.running():
            raise RuntimeError('The original game is still running.')
        live.CMD.unlink(missing_ok=True)
        live.CMD.with_suffix('.tmp').unlink(missing_ok=True)

    live._session().start(prepare, dispatch, cleanup)
    folder = live.SHOTS / (__import__('time').strftime('%Y%m%d-%H%M%S') + '-vanilla')
    folder.mkdir(parents=True, exist_ok=True)
    live.STATE['folder'] = folder
    return live._wait_done(0, timeout).get('LiveResult', '')


def stop():
    return live.stop()


def log_tail(n=60):
    """The last lines of the original game's DeusEx.log."""
    path = SYS / 'DeusEx.log'
    return path.read_text(encoding='latin1', errors='replace').splitlines()[-n:] if path.exists() else []
