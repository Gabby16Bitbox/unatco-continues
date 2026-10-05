# 5. Reading maps and game data without the editor

Most questions about the original game can be answered from its files in seconds.
The tools are plain Python, no dependencies.

## What is in a map?

```powershell
python tools\ue1pkg.py <map.dx> class TriadRedArrow
python tools\ue1pkg.py <map.dx> class DeusExMover Tag,Location,InitialState
python tools\ue1pkg.py <map.dx> dump MaxChen0
```

`class` lists every actor of a class with the properties you ask for; `dump` prints all
the properties of one object; `find` searches object names.

## What does a conversation say, and when does it play?

```powershell
python tools\ue1pkg.py <ConversationsText.u> conv Conversation1316
```

prints the owner, how it is started, the flags it requires, and every event in order:
lines, choices, flags set, jumps, triggers. This is how the mod's writing was checked
against the way each character speaks in the game, and how the requirements of the
original conversations were found.

## Where can a character walk?

```powershell
python tools\bspmap.py <map.dx> plan.png -440 -250 --grid=250 --bounds=-1700,800,-3100,400 --mark=430,-2505
python tools\floors.py <map.dx> -560,0 -1025,-253
python tools\floodcheck.py <map.dx> flood.png -440 -330 -1071,3 --exit=max,430,-2505
```

- `bspmap.py` draws the real floor plan of a height band from the map's geometry, with
  your markers on it.
- `floors.py` tells the floor heights under a point: where to stand a character.
- `floodcheck.py` floods the floor from a start point and tells which targets are
  reachable.
- `mapplot.py` plots the navigation points: a route for a scripted character is a list of
  path nodes.

The Red Arrow who leads JC through the Lucky Money was planned entirely this way: the
doors and their triggers from `ue1pkg.py`, the route from the plan and the path nodes, the
standing spot beside the office doors from the floor plan.

## Small changes inside a package

`set_actor_props.py`, `set_surf_flags.py` and `set_texture_prop.py` change single values
in place. For anything involving geometry or lighting, work on a copy and keep a backup:
the format is unforgiving.
