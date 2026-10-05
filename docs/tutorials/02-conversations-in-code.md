# 2. Writing a conversation in code

Deus Ex conversations are normally authored in ConEdit and stored in packages. The mod
builds them **at run time, in UnrealScript**, with a small builder class, `UCCon`. They
are real native conversations: the game plays them with its own cameras, subtitles,
choices and flags.

## The smallest example

```unrealscript
local UCCon c;

c = new(Level) class'UCCon';
c.Begin('UC_Messenger', "UCMessenger", False);   // name, owner's BindName, first person?
c.Once();                                        // plays once (sets UC_Messenger_Played)
c.Line("UCMessenger", "JCDenton", "Denton?");
c.Line("JCDenton", "UCMessenger", "Who's asking?");
c.SetFlag('MaxChenMeetingAvailable', True);
c.Done();
c.AttachTo(messenger);                           // the actor whose list it joins
```

## The builder

| Call | Effect |
|---|---|
| `Begin(name, owner, bFirstPerson)` | Starts a conversation. First person = overheard, no cameras. |
| `Line(speaker, speakingTo, text)` | A line. Cameras cut to the speaker automatically. |
| `Once()` | Plays once. |
| `Radius(n)` | Also starts by itself when JC comes within `n` units. |
| `NoFrob()` | Cannot be started by talking to the actor. |
| `Passive()` | Runs by itself, no clicks, no choices. |
| `Require(flag, value)` | Exists only if the flag has that value. |
| `SetFlag(flag, value)` | Sets a flag when reached. |
| `Choice(text1, label1, text2, label2)` | Two answers for JC. |
| `Label(l)`, `Jump(l)`, `IfFlag(flag, value, l)`, `EndHere()` | Branching inside the conversation. |
| `Goal(...)`, `Trigger(tag)` | Add an objective; fire a map event. |
| `Done()`, `AttachTo(actor)` | Close it and attach it. |

## Variants

Two ways, both used in the mod:

- **decided when the conversation is built**, with ordinary code:

  ```unrealscript
  if (Anna747())
      c.Line("GuntherHermann", "JCDenton", "Denton. Agent Navarre is dead. ...");
  else
      c.Line("GuntherHermann", "JCDenton", "Denton. You should be on your way to Hong Kong. ...");
  ```

- **decided while it plays**, with flags: `IfFlag('UC_Messenger_Played', True, "Told")`
  jumps to the label `Told`.

When several conversations compete on the same actor, the first valid one in the list
wins. `AttachTo` puts a conversation at the *head* of the list, so attach them in reverse
order of priority.

## Things that will bite you

- Create the builder with `new(Level)`. Objects without an owner crash the game when it
  saves the map on a level change.
- Keep the builder in a **local** variable.
- An actor's conversation list is not saved with the map. Re-attach on every map load,
  checking by name that it is not there already.
- A string literal cannot be longer than about 256 characters.
- A line without a recording is shown as text; nothing else is needed.
- The engine's own limits are in [tutorial 3](03-scenes-and-flags.md).

## Replacing an original conversation

Remove it from the actor's list by name and attach yours; if a map trigger starts the
original by name, give yours the same name. Set the flags the rest of the game expects
(for instance the original's `_Played` flag) yourself.

## From code to document

`tools/export_dialogues.py` reads these calls back out of the source and writes
[the narrative design document](../NARRATIVE_DESIGN.md). Give a new conversation a title
and a place in `tools/narrative_manifest.py`; if you forget, it still appears, at the end.
