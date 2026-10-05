# 1. Setup, build, install

Windows, PowerShell. Everything below was done on one machine; the paths are in
`config.ps1`, change them there if your game is installed somewhere else.

## What you need

| | Where |
|---|---|
| Deus Ex: Game of the Year Edition and Deus Ex: Revision | Steam, both installed |
| The Deus Ex SDK installer, `DeusExSDK1112f.exe` | see <https://dev.dxgalaxy.org/guides/installing/>; put the file in `tools\` |
| 7-Zip | installed in `C:\Program Files\7-Zip` (the setup script uses it to unpack the SDK) |
| Python 3 | on the PATH |
| git | to clone this repository |

Only if you want to open maps in UnrealEd: the Visual Basic 5 runtime (`msvbvm50.exe`,
from Microsoft) in `tools\`. The Italian notes in `docs/NOTE_DI_SVILUPPO.md` list
everything that was needed to make the 2000-era editor run next to Revision.

## 1. The development copy

The game folder is treated as **read-only**. This creates `DevInstall\`: a copy of
Revision's `System` folder, links to the game's assets, the SDK compiler, and the
configuration files the compiler looks for.

```powershell
.\setup.ps1
```

## 2. The maps

The mod changes one of Revision's maps (the Hong Kong helibase). The repository holds the
difference, not the map. Rebuild it from your own copy:

```powershell
python tools\map_patch.py apply-all
```

It checks your original map and the result by SHA-256, and refuses to write anything if
your Revision version is not the one the patch was made from. In that case the mod still
runs; the helibase simply keeps its original look.

## 3. Build

```powershell
.\build.ps1 -Isolated
```

- `-Isolated` compiles in a fresh `DevInstall\Build-<id>` folder made of hard links, so
  an open editor or a running check never locks the files. The three newest are kept.
- A good build ends with `Success - 0 error(s), 0 warnings` and leaves
  `dist\UnatcoContinues.u`.
- The voice package is optional: it is compiled only if `src\UnatcoVoices` exists, and it
  is not in this repository. Without it every line plays as a subtitle.

## 4. Checks without the game

```powershell
.\tools\check-hongkong.ps1 -BuildSystem <the Build folder>\System
```

From the build's `System` folder you can also run the commandlets:

```powershell
.\ucc.exe UnatcoContinues.UCRouteCheckCommandlet
.\ucc.exe UnatcoContinues.UCDialogueCheckCommandlet
```

Each prints `N checked, 0 failed`.

## 5. Install

Close the game first.

```powershell
.\install.ps1
```

It copies the package into Revision's `System` folder and the maps from `maps\` into a
separate `UnatcoMaps` folder, which it registers in `Revision.ini` *before* Revision's own
maps (a backup of the ini is made). The original maps are never touched.

Then, once, still with the game closed:

```powershell
.\tools\tour-keys.ps1
```

It adds the mod's console commands and keys to `RevisionUser.ini` (a backup is made):
`uc` and the **Home** key for the debug menu, and the keys of the presentation mode.

## 6. In the game

- **Start the mod once**: open the console and type `uc` (or
  `summon UnatcoContinues.UCDbgMenu`). This starts the mod's director and gives JC an
  invisible item that restarts it on every map from then on; it is saved with your game.
- Play it for real from mission 4: find the evidence at NSF headquarters, do **not** send
  the signal, go back to Paul.
- Or use the debug menu: each button sets the game state as if you had played up to that
  point and jumps there.
