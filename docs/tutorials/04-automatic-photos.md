# 4. Automatic in-game photos

A way for a coding agent (or for you) to see a scene in the real game without playing to
it: the game starts, jumps to the scene, follows a list of steps, takes screenshots, logs
facts, and closes.

```powershell
.\tools\shots.ps1 -Name gunther -Setup UCDbgTour2 -Delay 5 -Shots @(
  'h;hud;1',
  's;player;1190;897;-455;0;0',      # put JC in front of Gunther
  'w;wait;2',
  'line1;view',                      # photo of what is on screen
  'n;next',                          # a click: next line of the dialogue
  'line2;view',
  'where;where;UCGunther',           # his position and state, in the log
  'f;flag;GuntherTonEncounterPlayed' # the value of a flag, in the log
)
```

The photos are converted to PNG in `shots\<date>-<name>\`; the facts are lines starting
with `UCShot` in the game's log.

## Steps

Each step is `label;action;arguments`.

| Action | Effect |
|---|---|
| `view` | Photo of what the player sees (a dialogue too). |
| `cam;x;y;z;lookX;lookY;lookZ` | Photo from a free camera. |
| `player;x;y;z;yaw;pitch` | Move JC, look, photo. |
| `follow;Tag` | Photo from behind the character with that tag. |
| `where;Tag` | Position and state of a character or mover, in the log. |
| `flag;Name` | Value of a flag, in the log. |
| `hand` | What JC holds, in the log. |
| `wait;seconds` | Wait. |
| `waitflag;Name;seconds`, `waitmap;MAP;seconds` | Wait until a flag is true, or a map is loaded. |
| `console;command` | Any console command, such as `summon UnatcoContinues.UCDbgTourNext`. |
| `talk;Tag` | As if JC clicked the character; logs why a conversation would not start. |
| `next` | A click: the next line of the dialogue. |
| `hud;1` | Keep the interface in the photos (needed to read overheard lines). |
| `torch;1` | Light on. |

`-Setup` is a debug class (`UCDbg...`) that sets the flags and jumps to the map; `-Flags
'Name=1,Other=0'` changes flags afterwards, to try variants. If the map changes in the
middle of the list, the steps go on from where they were.

## How it works

`shots.ps1` writes a section for `UCShotRunner` in the game's user ini, starts the game,
waits for it to close, converts the screenshots and removes the section. `UCShotRunner` is
an actor that does nothing unless that section says it is active.

## Good to know

- A photo is a moment. For timing, log positions with `where` at intervals.
- Taking a photo puts JC's weapon away and `where` turns his view: do not judge those two
  things from photos.
- The game must be closed before a run, and nobody should touch it during one.
- It takes minutes. Use the checks that need no game first.
