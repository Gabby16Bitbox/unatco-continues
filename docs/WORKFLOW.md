# Workflow and tools

How *UNATCO Continues* is made. Gabby writes and directs the story, the levels are built in
**DeusEdix** (a map editor for Deus Ex, *coming soon*), the scripted part is UnrealScript, and a
set of small tools checks the result in the game.

## How a mission is made

1. **The story.** The mission is written first: scenes, dialogue, choices and their consequences
   ([the mission scripts](MISSION_SCRIPTS.md), the [narrative design document](NARRATIVE_DESIGN.md)).
2. **The map.** The levels are built and dressed in DeusEdix: geometry, objects, lights, AI paths,
   links between maps, then a rebuild and a test in the game from the editor.
3. **The scripting.** UnrealScript in `src/UnatcoContinues/Classes`. Conversations are built in
   code (see [tutorial 2](tutorials/02-conversations-in-code.md)); scripted events are "scenes"
   (see [tutorial 3](tutorials/03-scenes-and-flags.md)).
4. **The build.** `build.ps1` for Revision, `tools\build_vanilla.ps1` for the original game.
5. **Checks without the game.** Commandlets and a headless map check load the real maps and
   verify what can be verified without a player: actors created, conversations attached, original
   conversations removed, doors where the code expects them, nobody hostile.
6. **Install and play** (only when the game is closed). Scenes that can really go wrong (a
   character who has to walk through doors, a new sequence) are also checked with automatic photos
   ([tutorial 4](tutorials/04-automatic-photos.md)).
7. **Playtest.** Gabby plays it; what needs fixing goes back to step 2 or 3.

## Rules that came out of the work

- **Never edit the game's own maps.** Work on copies in `maps/`; installed copies go in a
  separate folder the game reads first.
- **Back up a configuration file before changing it.**
- **Install only when the game is closed.**
- **Do not over-test.** Every in-game test takes minutes. Automatic checks first; the game
  only for what matters.
- **Say what was not verified.** A report states what was seen in the game and what is
  only in the code.
- **Write down what the engine taught you.** Most of the hard-won knowledge is in
  [tutorial 3](tutorials/03-scenes-and-flags.md): the limits of the conversation system,
  what happens to pointers on a map change, how characters path through doors.
- **Narrative rules are checked like code.** How each character speaks, what each
  character can know, one-way InfoLinks, characters who never vanish in view (see the
  [narrative design document](NARRATIVE_DESIGN.md)).

## The tools

All in `tools/`, written during the project. Python 3 and PowerShell, no dependencies.

### Reading the game

| Tool | What it does |
|---|---|
| `ue1pkg.py` | Minimal reader of Unreal Engine 1 packages: finds objects, dumps their properties, prints a conversation as readable text, lists every actor of a class in a map. |
| `convtools.py` | Searches the game's conversations by name, by owner or by text, and dumps one in full. |
| `mapplot.py` | Top-down plot of a map's navigation points and chosen actors. |
| `bspmap.py` | Accurate floor plan from a map's BSP geometry, with optional markers. |
| `floors.py` | Floor heights under given points. |
| `floodcheck.py` | Flood fill over the floors: can the player (or an NPC) get from here to there? |
| `bspsurf.py` | Lists the surfaces of a map's fixed geometry: texture, flags and the brush each came from. |

### Changing maps without the editor

| Tool | What it does |
|---|---|
| `set_actor_props.py`, `set_surf_flags.py`, `set_texture_prop.py` | Change single properties inside a package. |
| `lightbits.py` | Reads and edits a map's light-map shadow masks (used to remove shadows left by deleted objects without rebuilding the lighting). |
| `fix_brush_surfs.py` | Rebuilds the surfaces of a mover imported from text. |
| `editor_bridge/` | Inspect, plan and apply property and mover changes on private copies of maps, try them in the game, undo. |

### Both games

| Tool | What it does |
|---|---|
| `uc_variant.py`, `build_vanilla.ps1` | Build the original-game version from the same source (`//#if revision` markers). |
| `convert_vanilla_map.py`, `vanilla_pieces.py` | Turn a Revision map into one for the original game, piece by piece. |
| `mappatch.py` | Make the map patches the installers apply to the player's own copy of the game. |
| `build_installers.py` | Build the two installers. |

### Checking the result

| Tool | What it does |
|---|---|
| `check-hongkong.ps1` + `UCHKCheck` | Loads copies of the maps in a headless server and checks what the mod did to them. |
| `UCRouteCheckCommandlet`, `UCDialogueCheckCommandlet` | Engine-side checks of conversations, flags and cameras. |
| `shots.ps1` + `UCShotRunner` | Automatic in-game photos: jump to a scene, move the camera or the player, wait for a flag or a map, click through a conversation, log where a character is. |
| `export_dialogues.py` + `narrative_manifest.py` | Generate the narrative design document from the code. |

### Making the video

| Tool | What it does |
|---|---|
| `UCTour`, `UCCaptionWindow`, `tour-keys.ps1` | The presentation mode: a tour of the new scenes with one-line captions ([tutorial 6](tutorials/06-presentation-mode.md)). |
| `make_fade_texture.py` | Creates the small gradient texture the captions use to fade in. |

### Around the editor

| Tool | What it does |
|---|---|
| `patch-windrvlite.ps1` | Patches the *development copy* of one Revision DLL so the old SDK editor responds to the mouse. |
| `UnrealEd-WASD.ahk` | WASD movement in the 2000-era editor. |
| `dxkeys.ps1` | Sends key presses and console text to the running game. |

### Voices

No voices are published. How voices could be added: [VOICES.md](VOICES.md).

## What is not here

The game binaries, the SDK, the exported game sources and any voice recording.
