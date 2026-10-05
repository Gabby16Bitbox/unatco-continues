# Workflow and tools

How *UNATCO Continues* is made: one person directing, AI coding agents doing the
implementation, and a set of small tools that let the agents check their own work inside
the game.

## Who does what

| Who | Role |
|---|---|
| **Gabby** | Direction and every creative decision: what the story does, how a scene should feel, what stays and what goes. Plays the result, edits maps by hand in UnrealEd when geometry is involved, does the voice acting. |
| **Claude Code** (Anthropic) | Main coding agent. Researches the original game's data, writes the UnrealScript, the tools and the checks, builds, installs, and verifies in game with automatic photos. Keeps the documentation and its own project notes up to date. |
| **Codex** (OpenAI) | Second coding agent, working in the same folder on separate parts: the voice pipeline and the map "editor bridge" (an MCP server that lets an agent inspect and change private copies of maps). |
| **ChatGPT** | Used by Gabby to draft dialogue specifications, which are then checked against the game and adapted (see the narrative design document). |

The agents do not share a conversation. They share the folder, the documentation, and
short hand-off notes written for each other.

## The loop

1. **Request.** Gabby describes a result in the game, in plain language: "when you leave
   the hotel Gunther should be there", "the officer should run to you".
2. **Research.** Before writing anything, the agent reads the game's own data: which
   actors a map contains, where the path nodes are, which flags a conversation needs,
   what the original lines say. This is done offline with the tools below, without
   opening the game or the editor.
3. **Implementation.** UnrealScript in `src/UnatcoContinues/Classes`. Conversations are
   built in code (see [tutorial 2](tutorials/02-conversations-in-code.md)); scripted
   events are "scenes" (see [tutorial 3](tutorials/03-scenes-and-flags.md)).
4. **Build** in an isolated folder (`build.ps1 -Isolated`), so the editor or a running
   check never blocks it.
5. **Automatic checks without the game.** Commandlets and a headless map check load the
   real maps and verify what can be verified without a player: actors created,
   conversations attached, original conversations removed, doors where the code expects
   them, nobody hostile.
6. **Install** (only when the game is closed).
7. **A look in the game.** The agent starts the game, jumps to the scene, takes
   photos and reads positions and flags from the log
   ([tutorial 4](tutorials/04-automatic-photos.md)). Only the things that can really go
   wrong are tested this way: a character who has to walk through doors, a new sequence.
8. **Report.** What changed, what was verified and how, what was not. Then Gabby plays it.
9. **Notes.** Documentation and the agent's persistent notes are updated, so the next
   session starts from what was learned.

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
| `maps/editing/*.py` | The scripted edits made to the helibase map, kept as code. |
| `editor_bridge/` | Codex's MCP server for agents: inspect, plan and apply property and mover changes on private copies of maps, try them in the game, undo. |

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

## What is not here

The voice recordings and the scripts that produce them are not part of this repository.
The game binaries, the SDK and the exported game sources never are.
