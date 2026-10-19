# Playing the mod

You do not need to build anything to play.

## You need

- For the Revision version: Deus Ex: Game of the Year Edition and Deus Ex: Revision (Steam).
- For the original-game version: Deus Ex: Game of the Year Edition. See
  [the original Deus Ex](#the-original-deus-ex-no-revision) below.

## Install with the installer (easiest)

Download `UNATCO-Continues-Revision-Setup` (or `UNATCO-Continues-DeusEx-Setup` for the original
game) from the [Releases page](https://github.com/Gabby16Bitbox/unatco-continues/releases), close the
game and run it. If Windows says *"Windows protected your PC"*, click *More info*, then *Run
anyway* (the installers are not signed). To remove the mod: Windows' *Installed apps*.

## Install by hand (from this repository)

The repository has no compiled packages: build the mod first ([tutorial 1](docs/tutorials/01-setup-build-install.md)).

1. Download this repository (green **Code** button, **Download ZIP**) and unpack it.
2. Close the game.
3. Double-click **`Install mod.bat`**.

It copies the mod's package into Revision's `System` folder, makes the mod's maps from your
own copy of Revision's maps and puts them in a separate `UnatcoMaps` folder (your original maps
are not touched; the mod only ships its changes, never Revision's maps), tells Revision to look
there first, and adds a console command to start the mod. Backups of the two
configuration files it changes are made next to them (`Revision.ini.bak_maps2`,
`RevisionUser.ini.bak_tour`).

If your game is not in the default Steam folder, edit the path in `config.ps1` first.

## Start

1. Start Deus Ex: Revision and load or begin a game.
2. Open the console (key **T**, then delete the word `Say`) and type:

   ```
   unatcostart
   ```

   You see "UNATCO Continues: mod loaded." The mod is now part of that game: it restarts
   by itself on every map and is saved with your saves. You do this once per playthrough.

## Where the new story begins

Mission 4, New York. Paul asks you to send a distress signal from the NSF headquarters.

1. Go to the NSF headquarters and find the evidence (the uplink code).
2. **Do not send the signal.**
3. Go back to Paul at the 'Ton hotel and talk to him.

From his answer on, you are on the new route. If you send the signal, the game continues
exactly as the original.

In a hurry? Type `unatco` in the console (or press **Home**): a menu lets you jump straight to
each part of the new story.

## Good to know

- There are no voice recordings in this repository: the new lines appear as subtitles.
- Work in progress: see [what works and what is next](docs/STATUS.md).

## Uninstall

Delete `UnatcoContinues.u` from `Revision\System` and the `UnatcoMaps` folder from
`Revision`. Restore the two `.bak` files if you want the configuration exactly as before.

## The original Deus Ex (no Revision)

The mod also runs in the original Deus Ex (Game of the Year Edition, Steam). Work in progress: the
Hong Kong opening (the Harbourline rooftop, the butcher's of Wan Chai Street) and Battery Park.

1. Close the game and double-click **`Install mod (original Deus Ex).bat`**.
   It puts the mod and its maps (made from your own copy of the original maps, which are not touched)
   in a new `Deus Ex\UnatcoMaps` folder, tells the game to look there first and adds the console
   commands. Backups: `DeusEx.ini.bak_unatco`, `User.ini.bak_unatco` in `Deus Ex\System`.
2. Start Deus Ex, load or begin a game, press **T**, delete `Say` and type `exec unatcostart.txt`
   (`exec unatco.txt` or the **Home** key opens the menu that jumps to each part of the new story;
   `exec unatcopaul.txt` takes you to Paul at the 'Ton for the choice). The original game
   does not run typed aliases as Revision does, and allows `summon` only with the cheats on: these
   two little files in `Deus Ex\System` turn them on for a moment and off again.

Uninstall: delete `Deus Ex\UnatcoMaps` and put back the two `.bak_unatco` files.
