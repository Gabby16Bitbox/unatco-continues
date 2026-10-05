# Playing the mod

You do not need to build anything to play.

## You need

- Deus Ex: Game of the Year Edition and Deus Ex: Revision, both installed from Steam.

## Install

1. Download this repository (green **Code** button, **Download ZIP**) and unpack it.
2. Close the game.
3. Double-click **`Install mod.bat`**.

It copies the mod's package into Revision's `System` folder, puts the modified map in a
separate `UnatcoMaps` folder (your original maps are not touched), tells Revision to look
there first, and adds a console command to start the mod. Backups of the two
configuration files it changes are made next to them (`Revision.ini.bak_maps2`,
`RevisionUser.ini.bak_tour`).

If your game is not in the default Steam folder, edit the path in `config.ps1` first.

## Start

1. Start Deus Ex: Revision and load or begin a game.
2. Open the console (key **T**, then delete the word `Say`) and type:

   ```
   ucstart
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

In a hurry? Type `uc` in the console (or press **Home**): a menu lets you jump straight to
each part of the new story.

## Good to know

- There are no voice recordings in this repository: the new lines appear as subtitles.
- Work in progress: see [what works and what is next](docs/STATUS.md).

## Uninstall

Delete `UnatcoContinues.u` from `Revision\System` and the `UnatcoMaps` folder from
`Revision`. Restore the two `.bak` files if you want the configuration exactly as before.
