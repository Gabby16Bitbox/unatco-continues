# Continuing the mod

The project is open source so that anyone can pick it up: fix it, extend the story, or
reuse the tools for another Deus Ex mod. This page is the shortest path from a download
to a working change.

## 1. Get it running

Windows. You need Deus Ex GOTY and Deus Ex: Revision (Steam), Python 3, 7-Zip, and the
Deus Ex SDK installer. The full walk-through is
[tutorial 1](docs/tutorials/01-setup-build-install.md); in short:

```powershell
.\setup.ps1                              # development copy of the game (DevInstall)
python tools\map_patch.py apply-all      # rebuild the modified maps from your own
.\build.ps1 -Isolated                    # compile -> dist\UnatcoContinues.u
.\install.ps1                            # game closed
```

If your game is not in the default Steam folder, change the paths in `config.ps1`.

## 2. Find your way

| You want to... | Look at |
|---|---|
| read the story and every line | [docs/NARRATIVE_DESIGN.md](docs/NARRATIVE_DESIGN.md) |
| know what works and what is next | [docs/STATUS.md](docs/STATUS.md) |
| understand how the mod is organised | [tutorial 3](docs/tutorials/03-scenes-and-flags.md) |
| add or change dialogue | [tutorial 2](docs/tutorials/02-conversations-in-code.md) |
| check a scene in the game without playing to it | [tutorial 4](docs/tutorials/04-automatic-photos.md) |
| find something in the original game | [tutorial 5](docs/tutorials/05-reading-game-data.md) |
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
  `maps\` and publish the change as a patch (`python tools\map_patch.py make-all`).
- Back up a configuration file before changing it. Install only with the game closed.
- Follow the writing rules in the narrative design document: how each character speaks,
  what each character can know, one-way InfoLinks, characters who never vanish in view.
- Say in the pull request what you verified in the game and what you did not.
- Do not commit game files, recordings, or keys. `.gitignore` is a whitelist for this
  reason: a new kind of file has to be allowed on purpose.

## 5. Maps

`maps\patches\*.ucpatch` are the differences between Revision's maps and the mod's.
`apply-all` rebuilds the maps into `maps\`; `install.ps1` copies them into a separate
folder the game reads first. To edit a map: `.\edit-map.ps1 <MapName>`, save, then
`make-all` to refresh the patch. The scripted edits made so far are in `maps\editing`.

## 6. Voices (optional)

The mod works without recordings: a line without audio is shown as a subtitle. No
recording is published. If you want to produce voices for your own build, the tools are in
`tools\voices` (their README is in Italian):

1. Copy `elevenlabs_key.example.txt` to `elevenlabs_key.txt` and replace `[Insert yours]`
   with your ElevenLabs key. The real file is ignored by git: never commit it.
2. Copy `voices.example.json` to `voices.json` and put a voice id of *your* account for
   each character.
3. `python tools\voices\make_voices.py list` shows the lines; `generate` writes the audio
   into `src\UnatcoVoices`, and `build.ps1` then compiles the voice package too.

`tools\voices\unvoiced_lines.py` lists the lines that have no recording yet.
