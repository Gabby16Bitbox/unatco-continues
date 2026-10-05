# 1. Setup, build, install

Windows, PowerShell. Paths are in `config.ps1`: change them there if your game is
installed somewhere else.

## What you need

- Deus Ex GOTY and Deus Ex: Revision installed from Steam.
- The Deus Ex SDK (for `ucc.exe` and UnrealEd) and Python 3.
- This repository.

## The development copy

The game folder is treated as **read-only**. `setup.ps1` creates `DevInstall/`: a copy of
Revision's `System` folder, links to the game's assets, the SDK, and the configuration
files the compiler looks for. Everything is compiled there.

```powershell
.\setup.ps1
```

`docs/NOTE_DI_SVILUPPO.md` (in Italian) lists what was needed to make the SDK tools run
on a current Windows and with Revision's packages.

## Build

```powershell
.\build.ps1 -Isolated
```

- `-Isolated` compiles in a fresh `DevInstall\Build-<id>` folder made of hard links, so
  an open editor or a running check never locks the files. The three newest are kept.
- A good build ends with `Success - 0 error(s), 0 warnings` and leaves the packages in
  `dist\`.
- The build script also expects the voice package sources (`src\UnatcoVoices`), which are
  not published here. Without them you need to remove that package from `build.ps1` and
  `make-ini.ps1`; the mod itself works without voices and shows the lines as subtitles.

## Checks without the game

```powershell
.\tools\check-hongkong.ps1 -BuildSystem <the Build folder>\System
```

From the build's `System` folder you can also run the commandlets:

```powershell
.\ucc.exe UnatcoContinues.UCRouteCheckCommandlet
.\ucc.exe UnatcoContinues.UCDialogueCheckCommandlet
```

Each prints `N checked, 0 failed`.

## Install

Close the game first.

```powershell
.\install.ps1
```

It copies the packages into Revision's `System` folder and the modified maps into a
separate `UnatcoMaps` folder, which it registers in `Revision.ini` *before* Revision's own
maps (a backup of the ini is made). The original maps are never touched.

## In the game

- The mod starts by itself on every map.
- Key **Home** (or `uc` in the console) opens the debug menu: each button sets the game
  state as if you had played up to that point and jumps there.
- Play it for real from mission 4: find the evidence at NSF headquarters, do **not** send
  the signal, go back to Paul.
