# 6. The presentation mode used for the video

A separate mode made to record a presentation video quickly. It is not part of the played
mod. It jumps from one new scene to the next and shows a one-line caption saying what is
happening, for example *"If you leave the hotel, you find Gunther:"*.

## Using it

1. Close the game and run `.\tools\tour-keys.ps1` once: it adds the console commands and
   two keys to the user ini (a backup is made).
2. In the game, console: `uctour` (or **Home** and the *VIDEO* button).

| Key / command | Effect |
|---|---|
| **Page Up** / `ucnext` | next step |
| **Page Down** / `uchide` | remove the caption |
| `ucagain` | restart the current step |
| `ucstop` | leave the mode |

Nothing advances by itself and no dialogue is cut: the person recording decides. A
caption fades in and stays until it is removed or the next one replaces it.

## The steps

Nine chapters and four **variants**, a variant being the same scene replayed with a
different past: Gunther if Anna Navarre died on the 747, Anna if she had to kill Lebedev
herself, the trooper who replaces her if she is dead, the helibase officer if JC heard
Lebedev name Majestic 12.

Each step sets the game state as if the player had arrived there, gives JC some equipment,
and loads the map **from scratch**, so a take can be repeated as often as needed. The
Italian run sheet is in [VIDEO_PRESENTAZIONE.md](../VIDEO_PRESENTAZIONE.md).

## How it is built

- `UCTour` holds the steps and the captions (function `Cue`). A caption appears at the
  start of a step, when a flag becomes true, or while a given conversation plays.
- `UCDbgTour` prepares the state for each step and jumps.
- `UCCaptionWindow` draws the caption above everything, in the black band of the
  cinematic format during dialogues. The engine has no alpha blending for interface
  elements, so the fade is done with two tricks: the text is drawn "translucent" with its
  colour scaled up, and the black plate is drawn "modulated" from a small grey gradient
  texture, picking the column that gives the wanted darkness.

Adding a step means adding its map, its state and its captions in those two classes.
