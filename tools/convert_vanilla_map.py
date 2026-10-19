"""A map of the mod for the original Deus Ex (GOTY 1112fm): the Revision one converted by the map editor's
converter (tools\\mapkit\\editor\\convert.py: T3D round trip, the original game's classes, textures, mission
script and conversations, rebuilt by the original game's engine, checked with gamecheck and loaded again).
The mod's own objects stay the mod's (dist\\vanilla\\UnatcoContinues.u, tools\\build_vanilla.ps1, first).

    python tools\\convert_vanilla_map.py 06_HongKong_WanChai_Rooftop      # maps\\<name>.dx -> maps\\vanilla\\<name>.dx

The rooftop with the original game's pieces (no Revision content): build it first with UC_VANILLA=1, then
    python tools\\convert_vanilla_map.py 06_HongKong_WanChai_Rooftop --from tools\\mapkit\\out\\vanilla\\06_HongKong_WanChai_Rooftop.dx

Writes the report next to the map (<name>.convert.json).
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools' / 'mapkit'))
sys.path.insert(0, str(ROOT / 'tools' / 'mapkit' / 'editor'))
import convert  # noqa: E402

# Revision's neon signs and posters (RevTexHK) and the original game's signs that take their place: same
# shape (the tall neons stay tall) and as near a colour as the original HK_Signs have, chosen by eye
# (18 Oct 2026); the converter's own guess put an Area 51 lamp and a concrete wall there
TEXTURES = {
    'RevTexHK.Glass.AptRent_Kanji_Lime': 'HK_Signs.HK_Sign_18',
    'RevTexHK.Glass.AptRent_Kanji_Orange': 'HK_Signs.ClenReddSign_B',
    'RevTexHK.Glass.Hotel_Kanji_Azure': 'HK_Signs.ClenBlueSign_A',
    'RevTexHK.Glass.Hotel_Kanji_Blue': 'HK_Signs.ClenBlueSign_A',
    'RevTexHK.Glass.Hotel_Kanji_Red': 'HK_Signs.ClenReddSign_C',
    'RevTexHK.Glass.Hotel_Kanji_Vermillion': 'HK_Signs.ClenReddSign_V',
    'RevTexHK.Glass.Laundry-DryCleaning_Kanji_Azure': 'HK_Signs.HK_Sign_13',
    'RevTexHK.Glass.Restaraunt_Kanji_Blue': 'HK_Signs.HK_Sign_23',
    'RevTexHK.Glass.Restaraunt_Kanji_Vermillion': 'HK_Signs.ClenReddSign_E',
    'RevTexHK.Glass.neonbooze': 'HK_Signs.HK_Sign_15',
    'RevTexHK.Glass.neondimsum': 'HK_Signs.HK_Sign_05',
    'RevTexHK.Glass.neontea': 'HK_Signs.HK_Sign_10',
    'RevTexHK.Metal.Queens_Tower2': 'HK_Signs.Metal.HK_Sign_QTLS',
    'RevTexHK.Metal.Versalife_alt1': 'HK_VersaLife.logo1c',
    'RevTexHK.Metal.Versalife_alt2': 'HK_VersaLife.logo1c',
    'RevTexHK.Plastic.China_Sun1': 'HK_Signs.HK_Sign_14',
    'RevTexHK.Plastic.Chinese_NewYear2B': 'HK_Signs.HK_Sign_07',
    'RevTexHK.Plastic.ForichiNewYearParty': 'HK_Signs.HK_Sign_Kiosk1',
    'RevTexHK.Plastic.SmokingGeisha1': 'HK_Signs.HK_Sign_Kiosk1',
    'RevTexHK.Plastic.SmokingGeisha2': 'HK_Signs.HK_Sign_06',
    'RevTexHK.Plastic.Underground_Mall_blue': 'HK_Signs.HK_Sign_LM',
    'RevTexHK.Plastic.lemon-black': 'HK_Signs.HK_Sign_24',
}


def main(name, src=None):
    src = Path(src) if src else ROOT / 'maps' / (name + '.dx')
    runtime = ROOT / 'dist' / 'vanilla' / 'UnatcoContinues.u'
    if not runtime.is_file():
        raise SystemExit('Build the mod for the original game first: tools\\build_vanilla.ps1')
    data, report = convert.revision_to_vanilla(src, name, runtime=[runtime], textures=TEXTURES)
    out = ROOT / 'maps' / 'vanilla' / (name + '.dx')
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(data)
    out.with_suffix('.convert.json').write_text(json.dumps(report, indent=1, default=str), encoding='utf-8')
    print('wrote', out, len(data), 'bytes; ok:', report.get('ok'))


if __name__ == '__main__':
    # --from <file.dx>: another build of the map (the rooftop built with UC_VANILLA=1: outanilla\<name>.dx)
    args = sys.argv[1:]
    src = None
    if '--from' in args:
        i = args.index('--from')
        src = args[i + 1]
        del args[i:i + 2]
    main(args[0] if args else '06_HongKong_WanChai_Rooftop', src)
