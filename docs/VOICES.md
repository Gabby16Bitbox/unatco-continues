# Voices: how they could be made

UNATCO Continues ships **no voices**. Every new line is written in the script and shown as a subtitle;
the game plays a voice for a line only when it finds one. This page explains, for information, how
voices can be added, so that anyone who wants them can make their own.

## How the mod finds a voice

Each line has a key made from who says it and what they say (`src/UnatcoContinues/Classes/UCVoice.uc`):

```
VoiceKey(speaker, text)          = Key(speaker + "|direct|" + text)     (said in person)
VoiceKey(speaker, text, radio)   = Key(speaker + "|radio|" + text)      (an InfoLink, everyone but JC)
Key(s): h = 7; for each character c of s: h = (h * 31 + code(c)) mod 16777213
```

The mod looks for the sound `UnatcoVoices.V<key>` (for example `UnatcoVoices.V15094030`). If the
package `UnatcoVoices.u` has it, the line is voiced; if not, it stays a subtitle. Speaker names are the
ones in the script (`JCDenton`, `Jock`, `GuntherHermann`...); all the lines and their speakers are in
the [narrative design document](NARRATIVE_DESIGN.md) and in the mod's code (`Line(...)`, `Say(...)`).

## The workflow

1. **List the lines.** For each line: the speaker, the exact text (the key depends on every
   character) and whether it is said in person or over the InfoLink.
2. **Choose a voice for each character.** Record them yourself or with voice actors. Use only
   voices you are allowed to use: do not copy a real person's voice (an actor's included) without
   their permission.
3. **Record each line** with a little direction (calm, urgent, over a radio...). Keep the takes
   that sound right.
4. **Prepare the audio** the way Deus Ex reads it: WAV, PCM 16-bit, mono, 22050 Hz. InfoLink lines
   sound better with a light radio filter; lines said in person stay dry. Even out the loudness
   between characters.
5. **Name each file** `V<key>.wav` with the key above, and put them in `src/UnatcoVoices/Sounds/`.
6. **Make the package.** `src/UnatcoVoices/Classes/UnatcoVoices.uc`:

   ```
   class UnatcoVoices extends Object;
   #exec AUDIO IMPORT FILE="Sounds\V15094030.wav" NAME="V15094030"
   ...one line per file
   ```

   `build.ps1` compiles it with the mod when that file exists (`dist\UnatcoVoices.u`). Put
   `UnatcoVoices.u` next to the mod's package (Revision: `Revision\System`; the original game:
   `Deus Ex\UnatcoMaps`).

The mod waits for each voice to finish before the next line (and in the original game it measures
the game's clock against the real one, so a voice is never cut short).
