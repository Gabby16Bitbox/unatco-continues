# Continuing the mod

The project is open source so that anyone can pick it up: fix it, extend the story, or
reuse the tools for another Deus Ex mod. This page is the shortest path from a download
to a working change.

## 1. Get it running

Windows. You need Deus Ex GOTY and Deus Ex: Revision (Steam), Python 3, 7-Zip, and the
Deus Ex SDK installer. The full walk-through is
[tutorial 1](docs/tutorials/01-setup-build-install.md); in short:

```powershell
.\setup.ps1              # development copy of the game (DevInstall)
.\build.ps1 -Isolated    # compile -> dist\UnatcoContinues.u
.\install.ps1            # game closed
```

- **Clone into a short folder path** (for example `C:\Dev\unatco-continues`). The SDK
  compiler crashes without a useful message when the path is long; `build.ps1` stops with
  an explanation instead.
- If your game is not in the default Steam folder, change the paths in `config.ps1`.
- This sequence was tested from a fresh clone on the author's machine.

## 2. Find your way

| You want to... | Look at |
|---|---|
| read the story and every line | [docs/NARRATIVE_DESIGN.md](docs/NARRATIVE_DESIGN.md) |
| know what works and what is next | [docs/STATUS.md](docs/STATUS.md) |
| see where the story is meant to go | [docs/CAMPAIGN_CONCEPT.md](docs/CAMPAIGN_CONCEPT.md) |
| understand how the mod is organised | [tutorial 3](docs/tutorials/03-scenes-and-flags.md) |
| add or change dialogue | [tutorial 2](docs/tutorials/02-conversations-in-code.md) |
| check a scene in the game without playing to it | [tutorial 4](docs/tutorials/04-automatic-photos.md) |
| find something in the original game | [tutorial 5](docs/tutorials/05-reading-game-data.md) |
| change a map or write a mission's dialogues and events without UnrealEd | [tutorial 7: the map editor](docs/tutorials/07-map-editor.md) |
| see how the work is done day to day | [docs/WORKFLOW.md](docs/WORKFLOW.md) |

Where the code is:

- `UCMod.uc` - the director: what each map contains on the UNATCO route.
- `UCScene*.uc` - scripted events (Gunther at the hotel, the helibase arrival, Tong's lab).
- `UCHKStory.uc`, `UCHKWorld.uc` - Hong Kong: conversations, factions, objectives.
- `UCCon.uc` - the conversation builder.
- `UCDbg*.uc` - debug jumps (key **Home** in the game): the fastest way to reach a scene.
- `UCHKCheck.uc`, `UC*CheckCommandlet.uc` - the checks that run without the game.

## 3. Make a change

1. Work in `src\UnatcoContinues\Classes`. The files are Latin-1; comments are in Italian
   (the project's working language), identifiers and all in-game text in English.
2. `.\build.ps1 -Isolated` must end with `0 error(s), 0 warnings`.
3. Run the checks:
   ```powershell
   .\tools\check-hongkong.ps1 -BuildSystem <Build folder>\System
   ```
   and, from that `System` folder, `.\ucc.exe UnatcoContinues.UCRouteCheckCommandlet` and
   `UCDialogueCheckCommandlet`. All must report `0 failed`. Add a check when you add
   something a check can verify.
4. If you touched dialogue, regenerate the script document:
   ```powershell
   python tools\export_dialogues.py
   ```
   A new conversation gets its title and place in `tools\narrative_manifest.py`.
5. Look at it in the game. For anything that moves, use the automatic photos.

## 4. Rules of the house

- The game folder is read-only. Never edit the game's own maps: work on the copies in
  `maps\`.
- Back up a configuration file before changing it. Install only with the game closed.
- Follow the writing rules in the narrative design document: how each character speaks,
  what each character can know, one-way InfoLinks, characters who never vanish in view.
- Say in the pull request what you verified in the game and what you did not.
- Do not commit game files, recordings, or keys. `.gitignore` is a whitelist for this
  reason: a new kind of file has to be allowed on purpose.

## 5. Maps

`maps\*.dx` are the maps the mod modifies. They are NOT in the repository: Revision's maps
belong to Revision's authors. The repository carries only our differences, as patches
(`maps\patches\*.ucpatch`, listed in `maps\patches.json` with the original maps they start
from): after changing a map run `python tools\mappatch.py all` (then `check`), and commit the
patches. `install.ps1` writes the maps into a separate folder the game reads first (from
`maps\*.dx` when you have them, else from the patches and the player's own `Revision\Maps`),
so the originals stay untouched. To edit a map: `.\edit-map.ps1 <MapName>` copies the original into
`maps\` the first time and opens UnrealEd on it. The scripted edits made so far are in
`maps\editing`. Never commit a `.dx`.

## 5b. Publishing a build for players

Players install from `release\UnatcoContinues.u` (see [PLAY.md](PLAY.md)). After a change
you want them to have: build, run the checks, then copy `dist\UnatcoContinues.u` over
`release\UnatcoContinues.u` and commit it.

## 6. Voices (optional)

The mod works without recordings: a line without audio is shown as a subtitle. No
recording is published. How to add voices to your own build: [docs/VOICES.md](docs/VOICES.md).
