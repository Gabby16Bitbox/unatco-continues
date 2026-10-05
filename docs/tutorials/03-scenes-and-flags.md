# 3. Scenes, flags and the rules of the conversation engine

## The pieces

- **`UCMod`** is the director. It starts on every map, reads the flags, and decides what
  the map should contain on the UNATCO route: which scene to start, which original
  triggers to disable, who is friendly.
- **A scene** (`UCScene` and its subclasses) is an actor whose state code reads like a
  script: wait for this, say that, send him there.

  ```unrealscript
  state Playing
  {
  Begin:
      if (Talking()) { Sleep(0.25); Goto('Begin'); }   // wait for a dialogue to end
      FireTag('hangar_open');                          // a map event
      TitleCard("HONG KONG");
      ...
  }
  ```

- **Flags** are the memory. The game's own flags say what the player did (who killed
  Lebedev, whether Anna is alive); the mod's flags say what happened on the new route and
  what each character has learned. A scene never remembers anything else: if the player
  leaves the map half-way and comes back, the scene restarts and works out from the flags
  where it was.

## Rules learned the hard way

**Pointers.** Never keep a pointer to the player, to the flags or to a window in a member
variable across ticks: the engine crashes on the next map change. Fetch, use, drop.

**Initial state.** A `GotoState` in `PostBeginPlay` is undone by the engine. Use
`InitialState` in the default properties.

**Conversations.**

- Two NPCs more than 300 units apart cannot have an exchange: the whole conversation
  refuses to start. JC is exempt, so distant lines are addressed to him.
- An overheard conversation is cut when JC is more than 300 units from the actor that
  started it, unless it has a radius. Always give overheard conversations a wide `Radius`.
- Everyone who speaks or listens is frozen for the whole conversation. To let a character
  keep walking while he answers, put him back in his walking state on every tick
  (`UCScene.KeepWalking`).
- The game keeps one second between two conversations with the same actor.
- Ambient chatter is a conversation too. A scene that waits "until nobody is talking" can
  wait forever next to a group of chatting NPCs: check *which* conversation is playing.
- `_Played` flags expire one mission later. A flag the story needs for longer must be set
  by the mod.

**Walking characters.**

- A character can only path to a spot connected to the map's path network. Send him to a
  path node first, then a last straight leg.
- Doors are opened by "using" them, as NPCs do. Some map doors are not marked as doors at
  all: for the AI they are walls.
- Doors that open on a timer from a map trigger close again: open them from the scene
  when the character is near.
- Give a walking scene a fallback for when a character gets stuck, and apply it only when
  JC is not looking.

**Characters never vanish in view.** A scripted character who has to leave walks to a
sensible, visible place and is removed only when JC cannot see him.

**Original content is switched off, not deleted.** A trigger that cannot be destroyed has
its tag changed so it never receives its event.

## UnrealScript reminders

- Names are case-insensitive: a local called `trig` hides a function called `Trig`.
- The source files are Latin-1.
