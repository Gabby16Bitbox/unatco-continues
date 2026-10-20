# 7. The map editor

A map editor that runs in the browser, made for this mod. It opens the mod's maps and the
original Revision maps in 3D, with the game's real models and textures, and lets you change
them without UnrealEd:

- move, rotate, scale, copy and delete objects and whole structures (a helipad, a building);
- add any object of the game, blocks (walls, platforms) and ready-made pieces of other levels;
- replace the texture of an object or a structure with your own picture;
- change the properties that matter for a mission (locked doors, keypad codes, computer
  passwords, what a crate contains, what a guard does and carries...);
- write the mission's **story**: dialogues, InfoLinks, events and actions, compiled into the mod
  for you;
- make your own **characters** from the faces, bodies and clothes of the game's characters;
- make **new maps** (an empty room or a copy of any map) and **link** them to each other and to the
  campaign.

The original game files are never modified: existing maps are edited on a private copy, and
everything ends up in the mod's own folders.

## Start it

You need the development setup of [tutorial 1](01-setup-build-install.md), plus:

| | |
|---|---|
| Python 3.10 or newer with Pillow, in `tools\mapkit\.venv` | `python -m venv tools\mapkit\.venv` then `tools\mapkit\.venv\Scripts\pip install Pillow` |
| `tools\mapkit\bin\UCMapKitHost.exe` | the program that edits maps without UnrealEd; build it with `tools\mapkit\host\build_host.ps1` (Visual Studio C++) |
| An internet connection | the page loads three.js (the 3D engine) from a CDN |

**Development only:** Local geometry (Experimental) opens a separate desktop window and
requires `pywebview==6.2.1` in the Python environment running `editor/server.py`. Install it
with `tools\mapkit\.venv\Scripts\python.exe -m pip install pywebview==6.2.1`. The DeusEdix
installer already includes this dependency.

Then double-click **`Editor mappe.bat`** in the project folder. A black window opens (that is
the editor's server: close it to stop the editor) and the browser opens
<http://localhost:8790>.

## Opening and closing maps

The editor starts on **New Map / Open Map**, with a card for Dr. Hale's tutorial and your eight
most recent maps. **New Map** opens the existing empty-room/copy dialog. **Open Map** searches
your maps, recent maps and original levels grouped by mission. You can search by filename,
location or mission name. The list in the top bar remains a quick switcher:

- **Script-built maps**: maps made from scripts (`tools\mapkit\maps\`), including new empty rooms.
  Your changes are kept next to the script and applied on every rebuild.
- **Mod maps**: your project's copies of existing maps (`maps\`).
- **Original maps (you edit a copy)**: every Revision map. Changes are saved separately and built on a copy.

The first time you open a map the editor analyses it (from a few seconds to a minute); after
that it opens at once.

**Browse for a .dx file...** imports a map into the project's `maps` folder. Check the copy name
and press **Import copy**. Existing names are refused: choose another name to keep both maps.
The original file and the game's folders stay untouched. A map without a build is marked
**Not built yet**; pending edits/builds are marked **Changed, not installed**.

**File > Close map** returns to the start screen. If the map or Story has unsaved changes, choose
**Save changes**, **Discard** or **Cancel**. Saving here stores your work; **Apply in game** and
**Rebuild** are still separate operations. **Settings > General > When the editor opens** chooses
**Start screen** (the default) or **Last map**. **Clear recent** clears the list and last-map memory.

## Interactive tutorial

**Help > Interactive tutorial** opens an eight-room training wing run by Dr. Elias Hale.
The route turns through an L-shaped loading bay and a horseshoe drill course, with smaller
rooms for conversation, materials and reading. Observation glass is used in reception and security.
**Show me** frames the lesson and selects its object. The panel notices completed exercises:

1. **Reception**: fly around the editor; meet Hale behind the original training observation window.
2. **Stores**: select and move a crate, then place a new crate on top of the Crate stockpile platform around the corner. Pulsing circles guide you from the Objects search to the crate and the drop zone.
3. **Door systems**: connect the wall button to either leaf of the double door; both leaves open together.
4. **Drill hall**: give the trooper a greeting animation in the horseshoe practice course.
5. **Lab office**: write a dialogue for the scientist.
6. **Materials workshop**: select the plain crate, open **Textures > Edit**, paint its skin and
   choose **On this object only > Apply**. Hale's smiling demonstration crate is beside it.
   Merely saving a picture in My textures does not complete this exercise.
7. **Film stage**: frame *The Last Cup*, a guarded mug of coffee. **Tools > Add a cutscene camera**
   (or **+ Cutscene**) records the first view. Move the playhead to about four seconds, move the
   camera or change its framing, and press **K** for another key. Play the complete preview, then
   connect the **SCREENING** button to the camera with **Play the cutscene**. The exercise checks
   for two distinct keys in the stage, a preview of the current shot and a working button rule.
8. **Field test and library**: **Apply in game** in Story, **Rebuild**, then **Play from here**.
   Test the door, greeting, dialogue, painted crate and screening button; finish with the library's tips.

The map is generated locally from the script in `tools/mapkit/tutorial/` and the installed game's
assets. Reception, observation booths and door leaves reuse selected architecture from the local
`00_Training`, preserving scale and texture alignment. Original map files are never modified or
bundled. The burgundy reception floor uses the engine's mirror flag; the browser's Lit preview
does not reproduce that reflection, so use **View in game** to inspect it.

**The advanced wing** is optional and opens north of the library, for those who want more than the
basics. Every basic step offers **Advanced ›**, and **Advanced wing** sits next to **Finish**; the panel
counts the training and the wing apart and never moves from one to the other by itself:

- **Interrogation**: a dialogue with **JC's answers** (choices), a consequence that opens the vault, and
  a story flag the informant remembers next time.
- **Demolition range**: a timer that counts down, what happens when it runs out, and a keypad that
  defuses the bomb.
- **Ambush yard**: a trigger zone that sends two attackers at JC.
- **Code lab**: your first script (**Tools > Scripts**), wired to a button with an interaction, then
  tried live with the **Console** while the game runs.

Dr. Hale speaks his lines (his voice is in the editor and in the game). The speaker button in the head
of his panel (**Mute tutorial audio**) silences his voice and the background music.

Exercise edits and custom dialogue are kept when the tutorial's stock text is updated.
**Start over** on the last step clears the training edits and story and rebuilds the map.
The first time the editor opens, Hale offers the course; it remains available in Help.

## Moving around

The controls are those of Unreal Engine 5 (they are also listed under **Help**).

| | |
|---|---|
| Hold the right mouse button and move the mouse | look around |
| Right mouse + `W` `A` `S` `D`, `Q` `E` | fly (`Shift` = faster) |
| Mouse wheel | forward and back |
| Middle mouse drag | pan |
| Left click | select an object, or a structure by clicking its walls |
| `F` | focus the selected object |
| `L` | lighting of the view: Shaded, Lit, Unlit (see below) |

## Lighting of the view

Like *Lit* and *Unlit* in Unity or Unreal, the list next to **Help** (or the `L` key) changes how
the 3D view is lit:

| | |
|---|---|
| **Shaded** | the editor's own soft light: everything is easy to see; good for building |
| **Lit** | the game's lighting: the light and the shadows of every lamp, their colour, how far they reach, spotlights, the ambient light of each zone. What you see is close to what the game shows |
| **Unlit** | the textures only, without any light |

In **Lit**:

- Walls, floors and ceilings show the map's real lightmaps, with their shadows.
- Objects and characters are lit vertex by vertex like the engine does: the side facing a lamp is
  bright, the other side dark. A lamp lights an object only if the object's centre can see it.
- Neon signs, screens and other *unlit* surfaces stay at full brightness, as in the game.
- A slider appears next to the list: it makes the whole view brighter or darker, to compare with
  your screen. It does not change the game.

**Lit** shows the lighting of the **last rebuild**: lamps you add, move or change are not shown
until you press **Rebuild**. An object you add or move takes the lamps around its new place at
once, but without their shadows until the rebuild.

## The screen

The layout follows the familiar hierarchy, scene, inspector and asset browser arrangement:

- **Menus and toolbar**: File, Edit, View, Map, Tools, Window, Settings and Help.
  The Windows app uses a native menu above the editor; the browser keeps these menus in the
  top bar. Save, Rebuild and Play remain beside the current map. Themes and Rounded variants
  are in Settings.
- **Hierarchy** (left): every object of the level. The structures (helipad, buildings...) with
  their objects inside, then the other objects by kind: characters, lights, objects, doors,
  triggers, AI paths, blocks. Click a line to select it, double-click it (or press `F`) to go to
  it, the bin deletes it. The search box finds any object by name or kind. Bulbs identify lights,
  people identify NPCs, and cubes, doors and routes identify objects, movers and AI paths.
  NPC icons show their configured relation towards JC at map start: **green** for allies,
  **grey** for neutral characters and **red** for enemies. Class defaults and unsaved relation
  changes are included, and Undo updates the colour too. Hover over an icon for its meaning.
  Player starts have a flag and helicopters have their own icon. A single piece taken out of a
  structure has the piece icon, not the structure's.
- **Browser** (bottom), the media library, its sections on the left. **Game**: **Objects** (every
  object of the game: your own characters first, then the most used, the ways in and out of a map,
  decorations, weapons, characters...), **Models** (every 3D model), **Pieces** (every object of the
  original levels made of brushes, whole: see *Adding things*), **Sounds**. **Prefabs**: the
  structures and nests you saved, reusable in every level of the project. **Imported**: **My
  models** and **My sounds**, what you brought in with **Import...** (or dropped on the editor).
  The **Console** tab next to it shows the running game's log (see *Scripts and the Console*).
  Click a tile, then a floor or a wall to place it, or drag it onto the 3D view; sounds are dragged
  (see *Sounds*). **+ Create** adds a block, a hole, water, a zone portal, a sign or a cutscene camera;
  **Characters...** opens the Character Creator. Nothing assembled by hand is in the library: the
  structures of the map you are editing are in the Hierarchy.
- **Inspector** (right): the selected object's transform and relevant properties in foldouts.
  Changes and Messages can be expanded when needed. Right-click an object for actions for
  its type: a character offers Dialogues and Animation Studio; a light offers Light settings.
  The **padlock** at the top keeps the Inspector on this object while you select others (to drag
  something onto its fields); press it again to follow the selection.
- **The 3D view's toolbar** (top left of the view, like Unity's): **Move**, **Rotate**, **Scale**
  (`W` `E` `R`), **grid snap** (`G`) with its **grid step** and **rotation step**, and the **bulb**
  that shows or hides the icons of lights, AI paths and logic points (see *Objects*).
- **Panels**: drag a panel tab to the left, right or bottom edge, or into the scene to float it.
  The panel menu also offers docking and hiding. Resize by dragging its edge. **Window** shows
  hidden panels and offers Default, Scene and Inspect layouts, plus Reset layout. The layout
  is remembered on this computer. Floating panels remain inside the editor window.

### Visibility, selection and game activation

- The **eye** hides an object only in the scene view. Its game behaviour is unchanged.
- The **lock** prevents accidental selection and edits in the scene. You can still select its
  Hierarchy row to inspect it or unlock it. View > Show all objects and Unlock all objects recover
  these editor-only states, which are remembered per map on this computer.
- **Enabled in game** controls whether an actor exists in the next playable Rebuild. An unchecked
  object remains in the editor with its properties, animation and dialogue configuration intact.
  Toggle it back on and rebuild to restore it. This change supports Undo and Save; structural
  BSP groups use the eye and lock, without an actor activation switch.

Authored interactions involving inactive actors are skipped with a build message. Original mission
scripts may still expect their actors, so test the mission after disabling one. For existing .dx
maps, the editable source is retained in `maps/.authoring/` with its edits; keep that folder with
the project when moving it. Build caches can be reconstructed from the retained source.

The viewport uses a coloured bulb for lights, a camera for cutscene cameras, a walking figure for
AI path points, a speaker for sounds and distinct symbols for triggers and other logic objects.


## Objects

Click an object to select it. Then:

| | |
|---|---|
| `W` / `E` / `R` | the arrows move, rotate or scale it (also from the 3D view's toolbar); or type the numbers in the right panel |
| `End` (or the floor icon) | drop it onto whatever is below |
| `Ctrl+D` or right click > Duplicate | duplicate the whole selection, keeping rotation, scale and spacing |
| `Alt` + drag a transform handle | duplicate in place, then move the copies with the handle; one Undo removes the copies and their move |
| `Ctrl+C`, `Ctrl+V` | copy and paste where you are looking, even into another map: open the other map, copy, come back, paste |
| `Delete` (or the bin icon) | delete |
| `Ctrl+Z` / `Ctrl+Y` | undo / redo (also `Ctrl+Shift+Z`): a texture applied from the Texture Editor is one step, Ctrl+Z takes it away and Ctrl+Y puts it back |
| `G` | grid snap on/off; its steps are in the 3D view's toolbar |

In the Inspector, hold the **X**, **Y** or **Z** label and drag left or right to move along
that axis. Each pixel changes the coordinate by **1 Unreal unit**, even with grid snap on;
hold `Shift` for **0.1 unit** per pixel. The object moves in the view as you drag. Release to
keep the move, `Esc` to cancel, or `Ctrl+Z` to undo the whole drag in one step. This also works
for blocks and structures (their objects follow). Click the number to type an exact value.

**Rotate (`E`)** turns an object every way, as in Unity: the green ring turns it round, the red and
blue rings tip it forward or onto its side (a book lying on a lectern, a tilted sign), the outer ring
turns it as seen from the camera. The Inspector shows **Rotation**, **Pitch** and **Roll**; type them
for exact values. Pieces, structures, blocks, characters, doors and groups all support three-axis
rotation. Selection outlines follow the object's orientation rather than expanding along the map's axes.
An NPC's AI may turn it again while playing; editor placement does not disable its behaviour.

**Scale (`R`)**: drag the middle square to scale evenly, as in Unity: right or up makes it bigger,
left or down smaller, 1% for every pixel the mouse moves (5% steps with grid snap). It never flips
inside out, however far you drag. The coloured handles scale one axis (blocks and structures).

**Grid snap** (`G`, or the magnet in the 3D view's toolbar): moves go in steps of the **grid step**
(units: a door is 64 wide), turns in steps of the **rotation step** (degrees). Type any number in the
two boxes, or pick one with their arrow; they are the same as Settings > Editing.

**Icons**: the bulb in the 3D view's toolbar hides the symbols of lights, AI path points and logic
points, to see the level as it is. Hidden icons cannot be clicked in the view: pick them in the
Hierarchy.

Objects scale all together (in Deus Ex an object has a single size, and its collision follows).
Objects whose name starts with `UC` are used by the mod's scripts: you can move them, but keep
them in the same room.

### Several objects at once

**Ctrl+click** or **Shift+click** adds an object to the selection (or takes it away) in the 3D
view; in the Hierarchy, Ctrl+click adds one row and **Shift+click** picks every row in between.
**Ctrl+drag** or **Shift+drag** in the 3D view selects every object inside the rectangle. The gizmo moves them
together (**W**) and turns them about their middle (**E**). **Delete**, **Ctrl+D**, **Alt+drag**
and **End** (drop to floor) act on the selection. Pieces are included in rectangle selection too.
Objects, blocks and structures can be selected together; the panel lists them.
If a protected member cannot be duplicated, the whole operation stops with a visible warning:
it never silently copies only the lights. Un-nest to duplicate independent scenery, or use a reusable prefab.
**Ctrl+C / Ctrl+V** can transfer several actors or blocks between maps; for mixed selections
containing structures use **Save as prefab** instead. Alt+click away from a transform handle still selects a face.

**Drop to floor** and **Stick to surface** also work on independent Pieces and multi-selections.
They use the actual geometry, ignoring the selected objects themselves. If no reachable surface is
found, the editor reports it without changing the object or adding an empty Undo step.

### Folders (nests): keep things together

Like a nest in Premiere: select some things (Ctrl+click, Ctrl+drag) and press **Ctrl+G** (or
**Edit > Nest**, or right click > **Create folder**). They become one folder in the Hierarchy, at the
top, and one thing in the 3D view: a click on any of them picks the whole folder, the gizmo moves and
turns it all; a **double click** picks one thing inside it.

- A new folder's name is ready to type: type it and press **Enter**, or click anywhere else to keep
  it (**Esc** keeps the old name). Later, **F2**, **Enter** or right click > **Rename** names it again.
- The **+** at the top of the Hierarchy makes an empty **Folder** (inside the folder chosen, if any):
  drag things into it. An empty folder stays until you delete it (**Del**, or its bin).

### Cubes, wedges and cylinders

The Hierarchy's **+** also makes a **Cube**, a **Wedge** (a ramp, high at its +X side) or a
**Cylinder** (16 sides), 128 units wide, where the 3D view looks (standing on the floor there) and
inside the folder chosen. Move it (**W**), turn it any way (**E**), resize it (**R**, or Width, Depth
and Height in the Inspector); **Shape** in the Inspector changes one into another.

Give it a texture like a wall: pick one in the Inspector's **Texture** field, or drag a texture
thumbnail onto the block (or click the thumbnail, then the block). Until the next **Rebuild** the
block shows its texture the way the game will map it; Rebuild puts it in the game. **Kind** makes it
a detail block or a hole (a round hole with a cylinder); water, zone portals, moving blocks and signs
are always boxes.

Dragging an object into or out of a Nest keeps its world position, rotation and scale. A drop
hint names the destination; cycles, locked groups and unsupported structural moves are refused.
One drop is one Undo step. A Nest containing lights or other fixed-size actors can move and rotate,
but cannot be scaled as a whole.

- **Un-nest** (**Ctrl+Shift+G**, right click, or the button in the Inspector) takes everything out
  again.
- One thing at a time: **drag** it in the Hierarchy out of the nest (anywhere outside it), or onto
  another nest to move it there. Nests can hold other nests.
- **Delete** on a nest deletes it with what it holds; **Ctrl+D** duplicates it as a new nest.
- A nest is the editor's own way of keeping things together: the map itself does not change.

The structures of the map are nests too. Open one in the Hierarchy: its **pieces** (each brush of
the script, each piece pasted from another level) and its objects are listed inside it.

- **Un-nest** a structure (Ctrl+Shift+G, or the **Un-nest** button) to take it apart: its pieces
  become structures of their own, its objects become free. They show apart at once; **Rebuild**
  makes them separate structures of the map. What the map script describes under one comment stays
  together in a nest named after that comment, so a big structure comes apart one level at a time.
- **Drag one piece or one object out** of a structure in the Hierarchy to take only that one out
  (right click > **Take out of...** does the same). On an object, the Inspector has **take it out**
  next to *Part of*.
- Nothing jumps: what comes out stays exactly where it is now. **Ctrl+Z** puts it back.

## Structures

A structure is a group of walls, lights and objects that belong together: the helipad, a
building, a staircase. Click one of its walls, or pick it in the **Hierarchy**.

- Move and rotate it with the gizmo or the numbers; its lights and objects follow.
- **Scale** stretches it, one axis at a time if you want. Textures repeat over the bigger
  surface, unless you tick *stretch textures*.
- **Copy**, **Duplicate**, **Reset** (put it back as it was), **Delete**.
- Structures with doors or lifts can be moved and rotated; their native motion keys follow.
  Their size remains protected from scaling.
- **Un-nest** takes it apart into its pieces and objects (see *Nests* above).

In existing maps, moving pieces of the map makes the rebuild recalculate geometry and lighting:
check the result with **View in game**. Some original maps cannot be rebuilt (Wan Chai Street,
for example): there you can only change objects, not the map's geometry.

## Adding things

- **Objects** (the browser at the bottom): search any object of the game ("crate", "barrel",
  "lamp", "guard"...), pick it, then click a floor or a wall to place it. `Shift`+click places
  more copies.
- `B` adds a **block**: a wall or a platform with the texture you choose; tick *solid* to make
  it walkable.
- **Pieces** (the browser): fences, chain-link, grates, railings, pipes, vents, cables, signs and
  neon, lamps, windows, ladders, beams and columns, wall and floor panels, shelves, awnings... In
  Deus Ex these are not objects but brushes (geometry) the level designers made: the editor takes
  them from the original levels, each one whole (the brushes that make it, nothing around it) and
  only once even if the game repeats it a hundred times. The tile says how often the game uses it
  and where. Click one, then a floor (it stands on it) or a wall (its front faces out): it becomes
  part of the map with **Rebuild**, like a pasted structure; move, turn and copy it as one.
  The first time, the Pieces tab reads the game's original maps to find them (**Generate Pieces**):
  several maps at once, a few minutes in all; after that only changed maps are read again.
- **Game doors and elevators** are in **Objects → Movers**, under **Doors** or **Elevators · two stops**.
  Pieces contains static geometry; Movers contains native moving brushes. Choose a textured preview,
  place it in an opening and **Rebuild**. Doors are individual leaves/panels; use them in Play to
  open and close. Lifts start when the player steps on, wait four seconds at the other stop,
  then return. Leave room for their original travel, including space below a descending lift.
  Geometry, textures, movement and assigned sounds come from your selected installed game.
  Each placement has an independent tag; original locks, keys, mission events, return groups
  and external controllers are removed. Immediately after placement the Inspector identifies it as
  a **DeusExMover**, with activation, move/wait times and door locking. These settings are saved and
  support Undo and independent duplicates. After Rebuild, **Edit mover…** selects the native actor
  for its tags, interactions, Door sounds and Animate settings. Moving, turning, duplicating and Undo
  work as with a piece. A mover placed by an older version can be selected as a native actor after Rebuild.
  Multi-floor/script-controlled mechanisms and unsupported tilted movers are not listed as ready-made
  pieces. This does not cut a doorway or build an elevator shaft, buttons or navigation automatically.
  On upgrade, **Refresh scan** adds the mover library using existing reference caches where possible;
  its first pass also extracts missing mover previews locally. No game assets are shipped.
- **Prefabs** (the browser): select a structure or a nest and choose **Save as prefab…** (in the
  Inspector, the right-click menu or the Prefabs tab). It is kept as it is now, built, and can be
  placed in any level of the project as an independent copy.
- Walls, roads, floors and ceilings: draw them (see *Drawing walls, roads, floors and ceilings*
  below), or use **+ Block** (`B`) with the game's wall and floor textures, or start from a room
  (**New map**).

### Drawing walls, roads, floors and ceilings

**Tools > Draw wall / Draw road / Draw floor / Draw ceiling** (or the same buttons in **+ Create**).
Click points on the ground one after the other; `Shift` keeps the line at 45 degrees; the points snap
to an 8-unit grid. **Enter**, a double click or a click on the first point again finishes; `Backspace`
takes the last point away, `Esc` stops.

- **Wall**: a wall along the line, 160 high and 16 thick, with clean corners.
- **Road**: the asphalt with a sidewalk and a curb on each side.
- **Floor**: a slab over the shape you drew (any outline, also with corners going in).
- **Ceiling**: the same slab at the top of walls of its **Height**: the ceiling of a room, with
  ceiling tiles underneath.

Select a drawn shape to change it in the Inspector: height, thickness, width, sidewalks and every
texture. Move and turn it with the gizmo. **Rebuild** makes it part of the map.

## Textures

The **Textures** section of the right panel lists the pictures of the selected object (one per
skin) or structure (one per texture of its faces). **Edit** opens it in the **Texture Editor**;
**Import** opens a picture of yours (PNG, JPG...) there; **Export** downloads the PNG for another
paint program; **Original** goes back to the game's texture.

**Choosing a texture**: every texture field (a block's, a hole's, a drawn wall's...) has a small
picture of its texture next to it. Click the picture: a grid opens with the textures of this map,
**All textures** of the game (search by name) and every package. A click tries a texture at once,
a double click (or Enter) keeps it, Esc closes. The pictures of a package are made from your game the
first time you open it (a few seconds), then they are kept. You can still type a name in the field.

**Drag the small picture** of a texture onto a wall, floor or ceiling of the map (or click it, then
click the face): that face takes the texture, previewed while you hover. `Esc` cancels, `Ctrl+Z`
undoes it, **Rebuild** puts it in the game. It works on built faces, not on models.

### Faces and texture alignment

**Alt+click** a wall, floor or ceiling to select its face. **Shift+Alt+click** adds or removes
faces. **Edit > Face selection** (`Q`, configurable in Settings) lets you select faces with plain
clicks and add them with Shift. In fly mode, Q still moves down. The selected faces are highlighted
and the right panel shows **Surface**. Selecting an object returns to its normal inspector.

Choose a loaded **Texture** and press **Apply**, or use **Align**:

| Alignment | Result |
| --- | --- |
| Floor / Wall | Reset the mapping to horizontal / vertical alignment |
| One Tile | Fit one complete texture to the source face's width and height |
| One Tile U / V | Fit the width / height of one tile and preserve the texture's proportions |
| Around a cylinder | Wrap one tile continuously around all vertical side faces of the brush; the caps stay unchanged |

Cylinder sides must form one closed outline and use the same texture. **Pan U/V** adds whole
texels to the offset. **Scale U/V** multiplies the tile size (2 is twice as large, 0.5 is half).
**Rotate 90°**, **Flip U** and **Flip V** change its orientation. **Select whole brush** selects all
its visible faces; a structure's **Surfaces** section can select the faces of all its brushes.

These operations affect the full source face, including pieces split by BSP cuts. They are stored
in order: **Save** keeps them, **Rebuild** shows the result. Undo (`Ctrl+Z`) removes the last edit.
Changing UVs also rebuilds lighting because the game's lightmaps use those coordinates. Changes
are written to both the rendered surfaces and their source brushes, so later geometry rebuilds
keep them. If the source brush or its face layout is replaced outside the editor, select the new
faces again.

### Shadow detail

In **Surface > Shadows**, choose **Low**, **Normal** or **High**. High makes finer shadows and
uses more map memory; Low is coarser. Normal clears both special detail flags. A selected
structure also has **Shadows for the whole structure**, which includes every face of its brushes.

**Rebuild** recalculates lighting. On an existing map, shadow or UV edits alone do not rebuild
geometry or AI paths. **Messages** reports the lightmap sample count and shadow storage before
and after the build. The size difference depends on the faces and lights in the map.

### Texture Editor

The texture opens at its full size (the HDTP ones at 1024). On the left the tools, with their keys
(the keys are Photoshop's; **F1** or the right-click menu lists them all). The pointer shows the tool:
a small cross for the brushes (the circle around it is the brush's size), a bucket, a dropper, the
text cursor with a T, a target while Alt picks the clone stamp's source.

| Tool | |
|---|---|
| **Brush** (B) | paints the colour; size, hardness (soft or sharp edge), opacity (see *Brush keys* below) |
| **Eraser** (E) | makes pixels see-through: the texture becomes *masked*, like the game's fences and grates |
| **Fill** (G) | fills the area of similar colours (tolerance; *only the touching area* or every pixel of that colour) |
| **Colour picker** (I, or Alt with a brush) | takes the colour of a pixel. Under the tools, as in Photoshop: the **colour** (front square) and the **background colour** (back square), click one to choose it, `X` or ⇄ swaps them; the last colours used are below (click: the colour, right-click: the background colour) |
| **Clone stamp** (S) | Alt+click where to copy from, then paint: covers a stain or a seam with another part of the texture |
| **Soften** (U) | blurs where you paint (hard edges, seams; it wraps round the edges as the texture tiles) |
| **Lighten** (O) / **Darken** (Shift+O) | worn edges, light, dirt, shadows where you paint |
| **Text** (T) | words on the texture (a label, a number, graffiti): click where they go and type there. Its handles make it bigger or smaller, its edge (or `Ctrl`+drag) moves it; `Ctrl+Enter` or a click elsewhere paints it (the click starts the next one), `Esc` drops it. Font, size, bold, outline, shadow and opacity are in the bar and show at once |
| **Select** (M) | a rectangle: painting and adjustments stay inside it; drag its handles to change it; *Focus*, *Crop…*, *Clear* (see-through), Esc for none |

The wheel zooms (at 8x and more a pixel grid shows), the middle button or Space+drag moves the
picture, `Ctrl+0` fits it, `Ctrl+1` shows it at its real pixels, `Ctrl++` / `Ctrl+-` zoom. Ctrl+Z / Ctrl+Y
undo and redo.

**Brush keys** (as in Photoshop):

- `[` and `]` (the two keys right of P on any keyboard, `è` and `+` on an Italian one): smaller and
  bigger; with `Shift`, softer and harder.
- `Alt` + right drag: left and right change the size, up and down the hardness (the inner circle).
- `1` … `9`, `0`: opacity (or strength) 10% … 90%, 100%; two digits typed quickly give that value
  (`4` then `5`: 45%).
- `Shift`+click: a straight line from the last point painted.
- `X` swaps the two colours, `D` puts back black and white.
- Holding a tool's key uses that tool only until the key is let go (hold `E` to erase a moment, then
  the brush is back); a quick press changes tool.
- Layers: `Ctrl+Shift+N` a new layer, `Ctrl+J` the selection on a layer of its own (or the layer
  duplicated), `Ctrl+E` merge down. `Ctrl+I` inverts the colours, `V` lifts the selection to move it.

**Focus** (`F`): the view zooms onto the selection, to paint a small part closely. Nothing is cut;
`F` or `0` shows the whole texture again.

**Crop…** cuts the texture down to the selection, after a preview (as in Photoshop or GIMP): what goes
away is dimmed, the handles adjust the rectangle, and the bar shows its size and the size it will have
in the game. **Snap to power of two** keeps the sides at 8, 16, 32... 1024 pixels, so the game does
not stretch it. **Enter** crops, **Esc** leaves the texture as it is; after a crop, `Ctrl+Z` puts the
whole texture back. Cropping is rarely what an object needs: a model's skin is cut and stretched over
the whole model, and on walls the piece fills the tile the whole texture filled. To work on a part,
use Focus.

**Copy and paste**: `Ctrl+C` copies the selection as you see it (all the layers), `Ctrl+X` cuts it.
Select where it goes and press `Ctrl+V`: the piece appears there (with no selection, where it came
from), floating. Drag it, or move it with the arrows (1 pixel; `Shift`: 10). **Enter**, **Put down** or
a click outside paints it on the active layer; `Esc` drops it. A picture copied in another program (a
photo, a screenshot) always lands inside the texture, in the middle of the selection or of the
texture, made smaller to fit when it is bigger; its handles size it, as `Ctrl+T` does, and it keeps its
own pixels, so it stays sharp when made bigger again. To make a picture the whole texture, use **Open…**.

**Free transform** (`Ctrl+T`, as in Photoshop): the selection (or the whole layer) is lifted off the layer.
Drag it to move it; its corners and sides scale it (`Shift`: in proportion); just outside a corner the
cursor turns and dragging turns it (`Shift`: 15° steps). The bar flips it, turns it 90° or resets it.
**Enter** (or a click outside) keeps it, one `Ctrl+Z` for all of it; `Esc` puts it back as it was. If the
active layer is empty there (a fresh *Paint layer* over the picture), the visible layer below is transformed.
A pasted piece has the same handles. In a web browser `Ctrl+T` opens a new tab: use the right-click menu.

**Right click** (without moving the mouse; a right drag still moves the view) opens a menu as in Photoshop:
free transform, flip and turn the selection, copy / cut / paste, fill with the colour (`Alt+Backspace`) or
the background colour (`Ctrl+Backspace`), clear, focus, crop, deselect (`Ctrl+D`), select all, take the colour
under the pointer, swap the colours, undo and redo.

On the right:

- **Preview**: the texture repeated 3 x 3 (as on a wall: seams show at once) and, for an object,
  the object itself turning with the texture as you paint it. **Game colours** shows it with the 256
  colours Deus Ex keeps.
- **Adjust** (the selection, or the whole picture): brightness, contrast, hue, saturation and
  lightness (live, then **Apply**); *Colorize* (the brush colour over the picture, keeping its light
  and dark: a blue crate made red), *Grey*, *Invert*, *Blur*, *Sharpen*, *Noise* (fine grain), *Grime*
  (patches of dirt, as on worn walls).
- **Tile and size**: *Make seamless* (the edges blend with the other side: it repeats without a
  line), *Offset ½* (the seams come to the middle to paint over them, then Offset again), flips, turn
  90 degrees, *Resize* (sides a power of two: 32 to 2048).
- **Put it in the game**:
  - **On this object only** (one object's skin) / **On this structure only** (the faces of the
    structure with that texture);
  - **On every object of the map with this texture** (every crate of that kind, every chair...) /
    **On every face of the map with this texture**;
  - **Only keep it in My textures**, or *also keep it* while applying it.

**My textures** (top bar of the editor) are your pictures kept for later: open one to edit it or to
put it on something else. They are files in `tools\mapkit\textures\_library\`.

The picture becomes a texture of the map: 256 colours, sides a power of two (the editor shows the
size it will have), see-through pixels make it masked. A structure's texture keeps the size of the
one it replaces on the walls (the same tiling). **Rebuild** puts it in the game.

## Properties and connections

The **Properties** section shows, in plain words, what matters for a mission:

Sliders keep their numeric value and available previews in sync while you drag (light colour,
light and sound reach). Release to keep the change, `Esc` to cancel it, or `Ctrl+Z` to undo the
whole drag. You can also type the number or use the arrow keys. Lighting on walls still needs
**Rebuild**; the Lit view's brightness slider changes only the editor's view.

| Object | Properties |
|---|---|
| everything | **Engine tag (legacy)** (the native target name), **Event** (what it triggers), and the separate **Scripting tag** for new groups |
| doors | locked, key that opens it, can be lockpicked and lock strength, can be broken and door strength, JC can open it by hand, opens from one side only, opening time, stays open |
| keypads | code, locks/unlocks instead of opening, event on a wrong code |
| computers, ATMs | accounts (login and password; account number and PIN), network (the logo on the screen), special options (buttons after logging in that show a message and trigger an event) |
| personal computers | **Emails**: for each account, emails with sender, subject and text |
| public terminals | **Bulletins**: title and text, read without logging in |
| security computers | the cameras, turrets and doors they control |
| keys (NanoKey) | Key ID, description |
| crates and containers | what is inside |
| books, newspapers, datacubes | **What it says**: the text JC reads, on several lines; the game text it shows otherwise (Game text) |
| characters | orders (standing, wandering, patrolling, sitting...), order target, faction, relations (see Factions), what they carry, names, conversation name, health, invincible, important; **Patrol route** and **Animation** (see below) |
| patrol points | wait here (seconds), next point, animation while waiting |
| wander points | what a wandering character looks at when it stops here, and for how long |
| triggers | triggered by, only once, radius, height, message to JC |
| sound effects | sound, plays when JC walks in or when triggered, heard in JC's head or within a distance, volume, pitch, again after |
| doors (sounds) | starts opening, open, starts closing, shut, while moving, heard within, volume |
| map exits and arrival points | where the exit leads (a map and its arrival point) and whether it is active |
| lights | colour (a colour picker and the hue slider, as in UnrealEd), saturation, brightness, radius, type (steady, pulsing, flickering...), effect (spotlight, torch...), cone, period, fog brightness and radius, special lit |

A field shows the value you set, otherwise the map's, otherwise the game's default for that kind
of object. Changes are applied by **Rebuild**, without touching the lighting.

**Lights**: select one (in the 3D view or under *Lights* in the Hierarchy). The Inspector shows
its colour and its properties, the same ones UnrealEd has. The sphere of the light takes the new
colour at once, and while it is selected a wire sphere shows how far it reaches. The lighting of
the walls and of the objects (the **Lit** view, the game) changes with **Rebuild**, which
recalculates the lighting when a light changed.

**Books, newspapers and datacubes**: select one (or place one from Objects). The Inspector
shows the document read from your installed game. **Edit a copy** starts with its original
text and formatting; **Write text** starts a new document. Use **Insert paragraph** (or `<P>`)
for paragraph breaks, then **Save text** and **Build**. Keep existing game tags for player
names, colours and formatting. Source line breaks alone are whitespace in this format.

**Restore original** removes only your document override. Other properties and the game's
text packages remain unchanged; Undo also restores a removed override. An empty saved text
is intentionally empty, so use Restore original to go back. Existing SpecialText documents
remain readable and are included when making a copy. Each override belongs to this object
in this map and is listed under Changes. Long documents are kept in safe-sized chunks.

The game reads the copy through its own text parser. Datacubes become DataVault notes;
books and newspapers follow the player's literature preference. The copy gets its own note
identity, so an old original note in a save is not rewritten. Start the rebuilt map to test it.

**Computers**: under *Accounts* the logins and passwords; *Special options* are the buttons JC finds
after logging in (for example "Open the vault" with *Triggers* = the Tag of the vault door: the
door opens; *Account* limits a button to one login). *Emails* (personal computers) are written per
account: JC reads them after logging in with it, and can add them to the DataVault. *Bulletins*
(public terminals) need no login. Emails and bulletins replace the game's own on that computer; an
account shows the same emails on every computer of the same mission, as in the game. In the map
they are hidden `UCTextBlock` objects; the mod makes them into the texts the computers read when
the map starts (`UCCampaign`), so they work only with the mod running.

**Holes**: **+ Hole** in the bottom bar, then click a wall: a doorway 64 wide and 112 high,
standing on the floor below, through the wall; on a floor, a pit; on a ceiling, an opening. A hole
cuts away the walls, floors and ceilings it touches when the map is rebuilt (UnrealEd's subtractive
brush); its sides take the texture of the surface you clicked (change it in the panel). Resize it
with **R** or the numbers in the panel; any block can become a hole (*Kind*: Solid block, Detail block,
Hole). The 3D view previews the cut at once: the walls, floors and ceilings inside the hole's box
disappear while you place, move or resize it. The faces of the hole's sides (with their texture)
appear after **Rebuild**, when the engine really cuts it. **A new room**: a hole the size of the room next to an existing one, then a doorway between
them; the new room is dark until it has a light: **Light it** (in the panel of a room-sized hole)
puts one in the middle under its ceiling.

**Signs**: **+ Sign** in the bottom bar, then click a wall (or a floor: the sign stands on it,
facing you). Write the text in the panel (Enter for a new line), choose a style and the size. The
styles include the original game's own: the **UNATCO** plate, **DANGER**, **CAUTION**, **RESTRICTED
AREA**, the red **STOP** plate, yellow and UNATCO blue plates and a shipping label, with the
narrow capitals and the coloured bands of the game's signs; and notice, warning stripes, street,
red or blue neon, green screen. **Plate** sets the band and the **screws**, **Wear** how old the
enamel looks (grime, scratches, chips). The text is drawn into a picture that becomes a texture of
the map, on the front of a thin iron block: any letters work, Chinese too. The preview in the 3D view
shows it before the rebuild.

**Connections** shows who triggers what, also with arrows in the 3D view: orange = this object
triggers (or opens) the other one, blue = the other one triggers (or opens) this. It covers
Event and Tag, keypads, security computers, keys and doors (Key ID), and patrols (a character's first
patrol point, each point's next one). Click a name to select that object. Example: select a keypad
and you see its code and the door it opens.

## Interactions (when this happens, do that)

No Tag or Event to write: at the top of an object's Properties, its **Interactions** say in plain words
what happens when something happens to it.

- **+ When it...**: what starts it. A door: *it has opened*, *it starts closing*, *it is blown up*. A
  button or any object JC uses: *JC uses it*. A keypad: *the right code is typed*, *a wrong code is
  typed*. A computer: *JC chooses an option of it* (write the text of the button on its screen and what
  the screen says after). A trigger zone: *JC walks in*. A laser: *JC breaks its beam*. An alarm: *it
  sounds the alarm*. A character: *they are killed or knocked out*. An item: *JC picks it up*. An object:
  *it is destroyed*. Most things: *JC comes near* (within a distance you choose).
- **+ Then...**: *something to an object (click it)*: click it in the 3D view or in the Hierarchy, and
  the list shows only what that object can do:
  - doors: open, close, open or close, lock, unlock, blow up, give JC its key;
  - characters: attack JC (*alone*: their faction stays out of it), turn hostile, become friendly or
    neutral, stand still, wander about, follow JC, walk or run to a place (click it), leave or come
    back (only when JC does not see them);
  - lights: turn on, turn off, turn on or off;
  - cameras, turrets, alarms, lasers, sound effects: switch on, switch off, play it;
  - any object: vanish, appear again, an explosion there (damage and radius), a sound from it.

  Or without an object: a message on the screen, a goal (the same name completes it later), a note in
  the DataVault, a flag (the Story's flags: an interaction can start a Story event), a sound (from an
  object or in JC's head), take JC to another map.
- Every action has its **after ... s**: seconds from the moment the rule starts (the door opens, 2 s
  later the alarm sounds). **once**: only the first time.
- **🔗 Connect to...**: click another object, and the rule is made with what the two usually do
  together: a button or a keypad opens a door, a zone sends a guard at JC, a switch turns a light on or
  off. The object that can start something acts on the other; change what it does afterwards.
- Each rule is also written as a sentence ("When JC uses button UCLButton: open door UCLDoor, turn off
  light UCLLamp, after 1 s the message ..."). Green arrows in the 3D view go from the object to what it
  acts on; the Properties of that object list the rules acting on it (click one to go to its object).
- **Far away or out of view**: when the other end of an arrow is off the screen (or behind you), a
  green label on the edge of the view points towards it, with its name and distance (*to light
  Light114 · 307 m*, or *from ...* for an object acting on this one); click it and the camera goes
  there. An object in view but very far gets the label just above it. **both** next to an action
  frames the object and the one it acts on together. A rule that takes JC to another map shows
  *takes JC to ...* by the object.
- **Logic** (top bar): every interaction of the map, grouped by object and editable there too, like an
  event sheet. **+ When the map starts** is for what happens at once (a message, a goal, a guard
  that leaves).
- **Check** lists rules whose objects were deleted, actions without an object, sounds not chosen,
  texts left empty, maps that do not exist.

**Rebuild** puts them in the game. The game's own Tag and Event (**Connections (Tag / Event)**) still
work: an object with an Event of its own keeps triggering it as well.

## Scripting tags

Select an object and open **Inspector > Scripting tag**. A scripting tag groups objects for new
interactions in the current map. Several objects can share one tag; it is not a unique object ID,
a faction or a Story flag.

### Auto, Custom and Original

- **Auto** follows the object's type or current state. Characters use `neutral`, `friendly` or
  `enemy` according to their attitude towards JC. Lights use the nearest major colour:
  `red`, `orange`, `yellow`, `green`, `cyan`, `blue`, `purple`, `magenta` or `pink`; very low colour
  saturation becomes `white`. Brightness and switching a light off do not change its colour tag.
- Typing a tag makes it **Custom**. `JOHN` stays `JOHN` when you change the character's faction,
  attitude or appearance. Even typing the same value as the automatic tag makes it manual.
  **Auto** explicitly returns it to automatic behaviour.
- Objects with an authored native tag start in **Original** mode, keeping that tag as their
  scripting label. **Auto** opts into automatic labels; **Original**, when available, restores
  the inherited label after an override.

Use 1-64 ASCII letters, digits or underscores, starting with a letter or underscore: `JOHN_2`,
not `John Smith`. Matching ignores case but matches the whole tag: `GREEN` matches `green`,
not `greenish`.

### Target a tag or filter a group

In an object's **Interactions**, add a starting event, then choose **+ Then... > objects with a
tagâ€¦**. Enter the **Tag** and choose the action. A light action affects matching lights, not
characters that happen to have the same tag. The match count is a preview of the current map;
automatic tags can change before the action runs in the game.

For a local group, choose **+ Then... > a group within a radiusâ€¦**. Set **Group** to **Lights**,
enter `green` in **Tag**, and choose the **Radius** and **Center**. An empty Tag accepts all tags.
**Refresh group** captures the current matching objects. Saved members remain connected if moved;
**Include newcomers** also adds matching objects in the zone when the action runs. The tag filter
is checked at execution, and the radius reaches through walls: it does not detect room boundaries.

Try this with a green light, a red light and a button: use the button's **JC uses it** event,
target `green`, choose the action that turns lights off, then **Rebuild** and test in the game.
Only matching lights should switch off. Save and Rebuild after changing tags or their interactions.

### Native tags and story safety

**Scripting tag** is separate from **Engine tag (legacy)**, the native **Event** and the
character's **BindName**. A scripting override does not rename these identities or reconnect the
original campaign. This applies to every character, including Anna, not just newly placed NPCs.
Do not change an engine tag merely to put an object in a new scripting group.

A tag selects recipients; a Story flag remembers what happened. Assigning `JOHN` does not make
Anna an ally, kill her or rewrite her later appearances. Changing AI, alliances, dialogue or
character outcomes can still affect the campaign. Use [Mission graph](#mission-graph-read-only)
to inspect the recorded dependencies before making those changes.


## Factions

Every character belongs to a **faction** (UNATCO, Cop, triad_red for the Red Arrow, triad_lum for the
Luminous Path, mj12...) and has **relations**: how they treat JC (`Player`) and each other faction
when the map starts, *friendly*, *neutral* or *hostile*. Members of the same faction are always
friends. A relation can be **fixed**: it never changes by itself. If it is not fixed, it works as
in the game: attack them and they turn hostile.

- **A character's relations**: select them; in **Properties** set *Faction* and edit the
  *Relations* list (faction, attitude, fixed). The field suggests every faction of the game and of
  the map.
- **The Factions panel** (top bar) lists the factions of the map, how many characters each has
  (click the number to see and select them) and how they treat JC. *Change a whole faction*
  sets a relation for all its members at once, for example *Red Arrow towards JC becomes hostile*.
- **During the mission** (after a dialogue, when a flag is set, when JC reaches a point) use the
  Story: the action *A faction...* turns a whole faction friendly, neutral or hostile towards JC
  or another faction; *A character... joins a faction* moves one character; the event *a faction
  turns hostile to JC* reacts when that happens (JC shot one of them, or the story turned them).
- **Only one character**: *A character... becomes hostile to JC* (or *attacks JC right now*). Tick
  **alone** to keep the rest of their faction out of it: in the game, someone who attacks calls his
  friends for help, and characters treat neutrals as friends, so without *alone* the others may
  join the fight. With *alone* the character leaves their faction and does not call for help. If JC
  then fires a gun in front of the others, they may still react to the shooting, as in the game.

To place a character: **Objects** (the browser), search its name ("Red Arrow", "MJ12",
"civilian", "dog"...), click the floor; then set its orders, faction and relations in Properties.
To make a character of your own, see the next section.

## Characters

The **Character Creator** (**Characters** in the top bar, or **Characters...** in the browser)
makes characters of your own from the bodies, faces and clothes of the game's characters.

1. **+ New**, or **Start from** a character of the game: it takes their whole look, their
   behaviour and their weapons.
2. **Body**: the kind of body (man in a long coat, man in a suit, man in a uniform, woman in a
   dress, heavy man, child...). The pieces it shares with the old one stay: a face, the trousers.
3. **Look**: every piece of the body (*Face*, *Top*, *Legs*, *Long coat*, *Glasses*,
   *Hat / helmet*...) has the versions that exist in the game. The arrows go through them, the
   button with the number opens them all as pictures; under it, which character of the game wears
   it. Faces fit every body of the same kind (all the men, all the women), trousers every body with
   the same legs. **Random face** and **Random clothes** mix them for you.
4. **Behaviour**: *Civilian* (goes about their business, runs away from fights), *Soldier*
   (guards, takes cover, fights back), *Criminal* (attacks when provoked). **When placed**: stands,
   walks around, sits, dances. **Health** (100 is normal).
5. **Faction** and **Towards JC** (friendly, neutral, hostile, fixed), as in Factions above. To
   make a faction of your own (a new gang), give the same faction name to all its characters.
6. **Carries**: up to four weapons or items (a weapon needs its ammo too).
7. **Save**. The preview turns: drag it to turn it, the wheel zooms.

The character is now the first entry of **Objects** in the browser: click it and click a floor,
as many times as you want (each copy can still change its own properties in the Inspector).
**Place in map** does the same from the Creator. If you change a saved character and save it
again, its copies already placed in the open map change too (save the map and Rebuild).

Characters are files in `tools\mapkit\characters\` (one `.json` each): **Export** saves one
anywhere, to share it; **Import** loads one made by someone else. **Duplicate** makes a variant.

In the game they keep exactly the look you gave them (the HDTP models do not replace it), and
their corpse wears the same clothes, also after JC carries it and puts it down. They have the walk, eye height and pain sounds of the body's
original character (a woman's body has a woman's voice). They say nothing by themselves: give
them dialogues in the Story (they have their own conversation name, `UCEd_<their name>`).

The first time, the Creator reads the characters of the game (a few seconds). Characters need
the mod's classes `UCCustomCivilian`, `UCCustomSoldier`, `UCCustomThug`: they are part of the mod,
so **Install** puts them in the game together with the map.

## Animation: any object, doors and elevators too

Select an object (a model, a decoration, a light, a door, an elevator, a block) and **Animate...**: the
Animation panel opens at the bottom, like Premiere's Motion or Unity's Animation window. It has rows for
**Position**, **Rotation** and **Scale**, with their values at the playhead and their keys on the timeline.

- Move the **playhead** (click or drag on the timeline), then move, turn or scale the object with the gizmo
  (W, E, R) or type its values: every change is a **key** at that time (the first one also puts a key at 0,
  where it rests). **◆** adds or takes away a key of that row; drag a key to move it in time; click a key
  to choose its **curve** (linear, smooth, ease in, ease out, hold) or to delete it.
- **▶** plays it (the gizmo hides while it plays), **◀** plays it backwards, **■** goes back to the start.
  **Once**, **Loop** or **Back and forth**; **at the start**: it plays when the map starts.
- Positions are offsets from where the object stands, so moving the object moves its whole animation.
  Rotation in degrees: 360 is a whole turn (two keys 0 and 360: it spins once).
- **Doors, elevators and moving blocks** are the engine's movers: up to 8 keys, no scale, and whoever stands
  on them moves with them. A door you animate still opens when JC uses it, with your movement (a door that
  slides can swing on its hinge instead). A block becomes a **moving block** (*Kind* in its panel, or
  *Animate...* on it) and moves in the game as you animate it: a lift, a platform, a crusher.
- In the **Interactions**: *Then... → Play its animation*, *Play it backwards*, *Stop its animation*, and
  *When → its animation has finished* to chain things. Each rule has a **Timeline**: its actions as bars at
  their time (an animation as long as it lasts); drag a bar to when it should happen.

## Collision boxes

**Objects > Triggers > Collision box**: a box (purple in the 3D view; its **Width**, **Depth** and **Height**
in its Properties). In its Interactions: *JC walks in* and *JC walks out*; *Anyone, not only JC* counts the
characters too; *Only once*; a *Message to JC*. Tick **Solid** and it is an **invisible wall** (orange):
JC cannot walk through it (Rebuild makes the wall), and *JC walks in* is when he touches it, to keep him in
an area or tell him why he cannot go on.

## Cutscenes

A cutscene is a camera that flies along keys on a timeline, like the camera paths of a video editor or of
the Minecraft film mods: the player watches, then gets JC back where he was.

1. Look at the first view you want and press **+ Cutscene** (bottom bar): a *Cutscene camera* is made, its
   first key is that view, and its timeline opens at the bottom with **🎥 Look through** on (the 3D view
   becomes the game's screen: 16:9, with the black bars).
2. Click the timeline further on (the red playhead), fly the camera there (right mouse + WASD, the mouse
   to turn) and press **K** (or **◆ Key**). Each key keeps the camera's place, where it looks, its **Roll**
   (tilt) and its **Zoom** (field of view: smaller = closer). Do it for every key.
3. **▶** (or Space) plays it in the editor: the picture as the game shows it, black bars, subtitles, fades.
   **■** goes back to the start; Esc stops, then stops looking through.
4. The camera flies **through** the keys without slowing down at them (a curve in time, as in video
   editors): it starts gently at the first key and stops gently at the last. Click a key to change what it
   does there: *Smooth* (passes through), *Stop here* (slows down to it and starts again), *Linear*
   (straight to the next key at the same speed), *Hold* (stays until the next key, then jumps); its Zoom,
   Roll, *Go there*, *Set to the view* (the key becomes what you see now), *Delete key*. Drag a key along the
   timeline to change its time: keys far apart in space but close in time make the camera fast there.
5. **Path**: *Smooth through the keys* (a curve that does not stop at each key) or *Straight lines*.
   **Even speed** spaces the keys so the camera keeps the same speed all along. **Looks at**: a character
   the camera always turns to (the keys still give its place, roll and zoom).
6. **✂ New shot** cuts at the playhead: the shot so far ends there and a new one starts with the view you
   have (fly elsewhere and press K for its first key). Between two shots the film jumps, no flight.
   *Join with the shot before* takes a cut away.
7. **Subtitles**: **+** at the playhead, then *Who* (a name, in yellow), the line, how long (0: as long
   as the text needs), a sound or a voice. Drag them along the timeline.
8. **Events**: **+** at the playhead, then click a door, a character, a light... in the 3D view or the
   Hierarchy: it happens at that second (the door opens at 3.2 s, the guard runs off). They are the
   Interactions *When it starts* of the cutscene (in its Properties, where you can add messages, sounds,
   goals): drag them along the timeline to change their second. *When it has ended* is in its Properties
   too (a guard attacks, JC goes to another map).
9. Options: *Fade in* / *out* (seconds from and to black), *black bars*, *can be skipped* (a click or
   Space skips it: what was still to happen at once), *only once*, *at the start of the map*, *JC visible
   where he stands* (a stand-in of JC stays there while the camera flies), *Length*.

**What plays it**: an interaction **Play the cutscene** (select a collision box, **🔗 Connect to...**, click
the camera: *When JC walks into it: play the cutscene*), a button, a door, a character killed...; a Story
event or dialogue (action **Play a cutscene**: under a flag, after a talk); or *at the start of the map*.
A cutscene that starts during a conversation waits for its end.

In the game JC does not move, cannot be hurt and is not seen while it plays; the stories of the map and
the collision boxes wait. At the end he is back where he was, looking where he looked, with his weapon.
**Check map** warns about a cutscene with no keys or one nothing plays.

## Models: every 3D model, and your own

The **Models** tab of the browser (next to Objects and Pieces) lists every 3D model the game can load, by
package: Deus Ex's (DeusExDeco, DeusExCharacters, DeusExItems), HDTP's, Revision's, the packages of other
mods (Packages...) and yours (**UCModels**). Search by name; a package shows its previews the first time it
is opened (a few seconds). Click a model, then a floor or a wall: it is placed as an object of its own (the
mod's `UCMeshDeco`) with a collision round it, at the size the game uses it. Its Properties: **Model**
(*Replace…*: click another one in the Models tab), name, solid, cannot be destroyed, strength, JC can push
it, and the Interactions of any object.

**Replace a model, keep the logic:** select a mesh object, then **Inspector > Model > Replace…**.
Click the replacement in **Models** (including imported models). This changes the mesh and its skins,
not the actor's class or name: tags, links, AI, dialogue, inventory, transform, pivot and collision stay.
The old per-object texture overrides are removed with the old model. **Cancel** or **Esc** leaves it
unchanged; **Ctrl+Z** restores the entire replacement, including those textures. **Rebuild** applies it
in game. The appearance is reapplied once after the initial HDTP setup; later gameplay effects remain
controlled by the original class. Characters need compatible animation sequences and attachments;
corpses and inventory/first-person models still follow the original class. Brush doors/elevators and
map structures are not mesh actors, so they do not offer this command.

**Import model...** (Models tab) makes your own: a model made in Blender, 3ds Max, Maya... saved as
**glTF / GLB** (best: its textures inside), **FBX**, **OBJ** (with its .mtl) or **DAE**. Choose the file
together with its textures (Ctrl+click). The preview shows it next to JC (about 90 units tall); set its
**height** in units (a door is 128), **turn** it, **stand it up** (a model made with Z up comes lying
down), make it **two-sided** (leaves, cloth, thin panels). **Import**: Deus Ex's own importer makes it a
model of the mod's package `UCModels` (in the game at once when it is closed, else with Install), and it is
ready to place. Up to 30000 triangles and 8 textures (made 256 colours, as the game's); transparent
parts of a picture become see-through (masked). Your models are listed at the bottom of the Import window,
where they can be deleted.

**Animated models.** A glTF/GLB, FBX or DAE with a skeleton (or shape keys) and animations keeps them. Deus
Ex's models have no bones: every animation of the game is a series of frames of the model's points. The
Import window lists the file's animations: tick the ones to keep and give each a name (the game's own names,
such as *Walk*, *Run* or *BreatheLight*, are offered), choose how many **frames a second** they are kept at
(15 by default; more is smoother and heavier) and which one the model **loops in the map**. Each animation is
played and recorded frame by frame into the model, as a sequence of its own. A placed model plays its loop in
the game (*IdleAnim* in its Properties, *IdleRate* for its speed); in the editor it shows its first frame. At
most 4000 frames, and 3 million frames x points per model: for a long animation, fewer frames a second or a
simpler model. A clip that walks away from its place (root motion) walks away in the game too: export it "in
place" (Mixamo has the option). Some files cannot be used as they are: an FBX the browser's FBX reader cannot
open (one with very many shape keys runs it out of memory) or one whose skeleton does not fit its model as
read (a scaled armature, two skeletons: the Import window says so and leaves the animations out). Saving the
model as glTF/GLB from Blender, with the armature's scale applied, solves both. A flat model (a rug, a panel)
takes the height you give as the size of its longest side.

**Simplify.** Today's models often have 100 000 triangles or more; Deus Ex's own characters about 1000. When a
model is too detailed for the game (more than 30000 triangles or 8191 points) the Import window says so and
offers **Simplify**: give the triangles to keep (3000 by default; 2000-3000 suits a character, a few thousand a
big object) and the model is made lighter where its shape changes least, its textures' layout counted too. It
keeps a part of the model's own points, so the textures, the skeleton, the shape keys and the animations stay
as they were. It also works on a model that is not too detailed, to make it lighter; **Original** goes back to
it as it was read. (The simplifier is meshoptimizer, MIT licence, Arseny Kapoulkine.) A model made of
thousands of separate small pieces, such as tufts of fur, keeps more points for its triangles.

## Zones: water, rooms of their own, rain and snow, the sky

Deus Ex divides a map into **zones**: closed areas, each with its own light, sound, fog, gravity, damage,
water. The editor makes them the way the game does.

- **+ Water** (bottom bar): click a floor: a pool 256 x 256, 96 deep, cut into it. Its surface is a zone
  portal, so the water is a zone of its own: JC swims and dives, the view turns blue under water. In its
  panel: the **liquid** (clean water, dirty water, toxic water that hurts with radiation, a burning liquid),
  where the **surface** is, a **place name**; untick *cut a pool* to fill a basin the map already has. Resize
  it with **R** or the numbers.
- **+ Portal**: click the floor in a doorway: an invisible sheet fills it exactly (it finds the walls and
  the top by itself). Put one in every opening of a room: the room becomes a zone of its own.
- **Objects > Zones**: put one inside the closed area. **Zone**: its *place name*, *ambient light* and
  *colour*, *sound of the zone* (heard everywhere in it), *hurts* (damage per second, kind of damage:
  radiation, burned, shocked, poison gas...; a message), *kills at once*, *own gravity*, *ground friction*
  (0.2 = ice). **Rain zone** and **Snow zone** (Revision's): rain or snow falls round JC in the whole zone.
  **Water zone**, **Sky zone** for those who build them by hand.
- **The sky**: a **hole** in a ceiling (+ Hole, click the ceiling) with **open to the sky** ticked shows
  the sky through it. A map with no sky of its own gets a sky box (Hong Kong at night, New York at night,
  stars, sunset, clouds, bright clouds, orange haze: choose it in the hole's panel).
- **Map > Sky & time of day**: **Day**, **Sunset** or **Night**. It paints a sky of your own (its
  colours or stars), or uses a picture of yours or one of the game's skies, and sets the light:
  a sun shining in through every hole open to the sky, on the side of the sun, and the ambient light
  of the map. Deus Ex has no sun of its own: the sun is made of lights. **Rebuild** puts it in the game.
- **Clouds** (same window), over any of those skies: **None**, **Soft**, **Puffy**, **Streaks** (long
  wisps along the wind) or **Game's** (the game's own cloud textures: the Hong Kong cloud bank, the wide one,
  the fluffy blue ones, the subtle one), and ↻ for other painted clouds of the same kind. **Amount** and
  **Brightness** (painted clouds), **Size**, **Height** (how high the layer is: its far edge, in degrees over
  the horizon; low clouds reach down to it), **Wind** (how fast they move; 0 = still) and **Wind from** (the
  direction, measured like the sun's). The preview shows them as the game will, moving: drag it to look
  round and up. They are made the way the game's own levels make them (Wan Chai Street): a sheet in the sky
  box whose texture the engine moves (Auto U Pan, at the speed the sky zone gives), so they work the same in
  the original Deus Ex and in Revision. The painted sky keeps the far clouds under the layer's edge. The
  clouds go in the sky box the editor makes, so a map that has a sky of its own (most of the game's maps)
  keeps its own clouds.

After **Rebuild**, Messages say if a zone is not closed (it leaks into the zone round it, often the whole
map: its water, damage or fog would not be where you meant) or if the start of the map is inside a zone.

## Packages of other mods

**Packages...** (bottom bar, next to *Characters...*) lists the packages (.u) in the game's folders
that the editor does not load yet (`Deus Ex\System`, `Revision\System`, `Revision\HDTP\System`),
and **Another .u file** takes one kept elsewhere. Tick them and **Apply**: the page loads again and
their actors are in the palette. Decorations, characters, weapons and items with a 3D model go to their
usual group, with the real model. Triggers, zones and other logic go under the package's name. They have
their Properties and Interactions, and are placed, saved and rebuilt like the game's own.

A map that uses them needs the package in the game too: a package kept outside the game's folders must
also be copied into `Deus Ex\System` (or `Revision\System`). Packages with only textures, sounds or
models (no actor classes) add nothing to the palette.

## Scripts and the Console

**Tools > Scripts...** writes UnrealScript inside the editor. A script is an invisible object placed
in the map (it extends `UCScript`): **Started** runs when the map starts, **Triggered** when an
interaction sets it off through its Tag, **Repeat** every few seconds. Helpers do the common things:
the player, say a line, find an object, trigger a Tag, read and set flags, give an item. **Compile**
builds the scripts' own package in a few seconds and lists the problems by line: click one to go
there. **Place in map** puts the script in the level: give it a Tag in the Inspector and set it off with
an **Interaction** like any object.

The **Console** (a tab next to the Browser, or **Window > Console**) shows the game's log while the
game runs, as it is written: **Scripts** shows only the lines from scripts (`log()`) and from the
Console, **Problems** only errors and warnings. During **Play**, the line at the bottom sends a
command to the game's own console (`summon`, `set`, a cheat...).

## Mods: export, install, play

When a campaign is finished, **File > Export mod...** saves it as one file (`.dxmod`) in
`Documents\DeusEdix Mods`: its maps, its packages, a picture (the view you frame in the 3D view), its
name, author and description, and the map it starts on. The editor refuses maps that need something the game does not have.

In the **Projects** window, **Mods** lists the mods installed in both games:

- **Install mod...**, or drop a `.dxmod` (or a downloaded mod's `.zip`) on the window. Classic mods
  for Deus Ex or Revision are installed from their zip too (maps and packages; programs inside them
  are not run nor copied; a mod that replaces the game's own packages needs its own installer).
- **Play** starts the game on the mod's first map, **Starts on** chooses another, **Remove** takes it
  away. A mod lives in its own folder (`DeusEdixMods`): the game's settings and other mods are not
  changed.

## Map settings

**Map** in the top bar:

- **Music**: Revision plays a track for every moment of the map: exploring (and the intro before
  it), combat, conversations, leaving the map, death. *Same as the map* takes the whole set of a map of
  the game; each moment can also be chosen on its own among every track of the game, and **▶** plays
  it. (The PS2 soundtrack option of Revision gets the same tracks, or the copied map's own PS2 set.)
- **Information**: the name of the place (*Place*: the save list, the DataVault), the author, and up
  to four **opening lines** written on the screen when JC arrives ("Liberty Island, New York").
- **Ambient light**: the light everything has where no lamp reaches, and its colour (Deus Ex maps
  use 0-20; maps with zones have their own in each zone).

**Apply**, then **Rebuild**. In the map they are its DeusExLevelInfo, its LevelInfo and a music actor
of the mod's own (`UCMusicInfo`, a DXOggMusicInfo of Revision).

### Player characters per map

Create and save a human character in **Characters...**, then choose **Use as player**
to use its appearance in the open map. Alternatively, open **Map settings > Player
character** and select it under **This map**. **Apply**, **Save**, then **Rebuild**.
The Player Start inspector has a **Change** shortcut to the same setting; Player
Start still chooses only where and in which direction the player appears.

For a campaign-wide choice, expand **Project default**, choose a character and press
**Set default**. Rebuild each affected map. A map may inherit that default or override
it with another character (including **JC Denton**). Thus map A can use one protagonist,
map B another, and returning to A restores its chosen appearance. Map overrides use
the map's normal Undo/Redo and Save; the project default is saved separately.

This first version changes the third-person body and eight skin slots only. Inventory,
health, credits, skills, augmentations and story flags stay shared. First-person weapon
hands, player voice, dialogue identity and mission scripts remain those of the game's
normal player; changing appearance does not rewrite the campaign. Separate protagonist
inventories are not available yet. All 17 human body templates in Character Creator
are supported, including the different builds, uniforms, dresses and smaller bodies.
Their gameplay collision and eye height remain those of the normal player: this is
an appearance change, not a different-sized player or a different playable species.
Imported arbitrary meshes and non-human bodies are not enabled by this feature.

Rebuild automatically adapts missing crouch-walk, weapon and other player motions
from the installed game's player animations, including one-frame NPC placeholders.
Existing usable animations, original frames and textures are preserved; the added
motions are retargeted approximations, not newly authored bespoke animations.
Footstep callbacks are retained. The copied body is stored in
the private map, never over the game's original package. Preparation is cached;
the first build of a body can take a few extra seconds. No game meshes or animation
frames are bundled with DeusEdix.

Each configured map exposes an automatic **Player is ...** condition to the story tools
(`UCEdPlayer_<character-id>`; hyphens become underscores). Only the current identity's
flag is true. The choice survives normal map travel and native Save/Load in Original
and Revision. Leaving configured project maps restores the original player's appearance.
The editor prevents deletion of characters used by a project default or saved map;
select a replacement first. A missing or unsupported character stops Rebuild with an
explanation. Ordinary maps which have never enabled player characters stay unchanged.

## Sounds

**Objects > Sounds > Ambient sound**: click where it should be heard (rain on a window, the hum of a
machine room, wind on a roof, a crowd), then **Choose...** its sound in its Properties: the list has
every sound of the game, the loops for places first; search by word (*rain*, *hum*, *wind*, *water*)
and **▶** listens to it. *Heard within* is how far (the sphere in the 3D view), *Volume*, *Pitch*.
Objects (a TV, a fridge, a generator) and lamps (the buzz of a neon) have the same **Sound** in their
Properties.

**Sound effects** (once, when something happens), in **Objects > Sounds**:

- **Sound effect: when JC walks in**: a zone (the purple cylinder, *Radius* and *Height* in its
  Properties): it plays when JC enters it. *Only once*, or again every time (*Again after* a few
  seconds).
- **Sound effect: when triggered**: it plays when something triggers it. It gets a Tag of its own
  (`SoundFX1`...): put that Tag in the **Event** of a door (it plays when the door has finished
  opening), a button, a keypad (right code), a **Trigger** (*Objects > Sounds > Trigger*: a zone JC
  walks into), or use it from the Story. The Connections show the arrow.
- After placing one, the sound list opens: choose its sound. In its Properties: *Heard in JC's head*
  (a radio, a voice: as loud wherever he is) or heard from its place within *Heard within* (the
  circles in the 3D view), *Volume*, *Pitch*. A sound effect that walks-in also triggers its own Event,
  like any trigger.

**Doors** have their sounds in their Properties (**Door sounds**): when it starts opening, when it is
open, when it starts closing, when it is shut, and over and over while it moves; *Heard within* and
*Volume*. The doors of the game have theirs already; a door copied from another map keeps them.

### Sounds in the browser, and your own

**Sounds** and **My sounds** use tiles like the object browser. Click a tile to select it and
inspect its duration, source, format, channels and sample rate. **Play** draws the real waveform
and playback position in both the tile and Inspector. The Inspector also offers seeking, preview
volume and loop preview; these controls do not change the sound in the game. Select a scene
object to return to its properties. Then drag a sound:

- onto the **3D view**: a sound effect there, that plays when JC walks into its zone and is heard within
  its radius (both in its Properties, with the circles in the view);
- onto a **door** or another object with sounds of its own: a menu asks which one (a door's opening,
  closing, moving sound; the hum of a lamp or a machine);
- onto a **sound in the Inspector**: it replaces that one.

**Your own sounds**: **Import...** (top of the browser), or drop the files anywhere on the editor:
WAV, MP3, OGG, FLAC. They are made mono (a sound heard from a place is mono in the game), 16 bit,
44.1 kHz, and become sounds of the editor's own package (*UCSounds* in UNATCO Continues,
*DeusEdixSounds* in DeusEdix), which the game plays like its own; it is installed with your maps. Up to
10 minutes each. Importing the same name creates a numbered copy and keeps the previous sound.
Drop one audio file on an object's sound field to import and assign it directly. Other file drops
import into the browser, with a visible drop hint. A cancelled asset drag never leaves placement
active. **Download WAV** in the imported sound's Inspector exports a usable file; dragging a
prepared imported tile to the desktop also works in browsers that support file drag-out.
**Delete sound…** in its Inspector removes it after confirmation (maps that use it lose it).

## Check map

**Check** in the top bar lists what is wrong or missing, with **go to**:

- errors: no Player start, a map exit to a map that does not exist, a character that patrols without a
  route, an object or a light inside a wall or a floor (as last rebuilt: stuck, invisible, or lighting
  nothing);
- warnings: an event (or a keypad's, a security computer's) that triggers nothing, a patrol point
  leading to no point, patrol points with the same Tag, no light in the map, characters but no AI paths;
- notes: a door whose key is not in this map (JC must bring it), unsaved changes.

What you added or changed is checked fully; the original objects of a map of the game only for what
breaks the map (they have links the story and the game's scripts use).

## AI paths and patrols

The characters of Deus Ex walk on a network of **path nodes**: they go from node to node along
the links the editor of the game works out from them (UnrealEd's *Paths Define*). The map editor
makes that network at every **Rebuild**.

- **AI paths** in the top bar (or **P**) shows the network as the last rebuild made it: green lines
  are links both ways, yellow lines one way only. A place without lines is a place characters
  cannot find their way to (they can still walk there in a straight line when they see it).
- To add paths: **Objects > AI > Path node**, click the floor where characters must be able to
  walk (along corridors, through doors, round corners: one every 300-500 units, each in sight of the
  next), then **Rebuild**. The other points of the same group: *Patrol point*, *Wander point*
  (wandering characters stop there and look at its *Look at* Tag), *Hide point* (where scared
  characters hide).
- The points rest on the floor by themselves: Deus Ex makes no link from a point floating higher
  than about 20 units, so the rebuild puts every path point of your maps 15 units above the floor
  below it, as UnrealEd does. The original maps have their points higher (up to about 40 units): for
  the links the rebuild rests them on the floor too, then puts each back where it was. The links of an
  original map that the rebuild does not make again (Battery Park's subway stairs) are kept, as long as
  both their points are still where they were and nothing has been built across them.

**Navigation** (the route icon in the 3D view's toolbar, next to the icons button): the two layers of
navigation, each shown or hidden by itself, ticked in its menu: **AI paths** (the nodes' network, **P**)
and **Walkable area** (the navigation mesh), one, the other or both; then **Test route** and **Fill AI
paths**. The same are in the *View* and *Map* menus.

**Test route** (the Navigation menu, or *View > Test a route*): click where a character starts, then
where it must go. With the AI paths shown, the editor draws the way the game's AI would take, node to
node, with its length; if no path node is near one of the two places it says so. With the walkable area
alone, it draws the straight way on it. Click again for another test, **Esc** to close.

**Walkable area** (the Navigation menu, or *View > Walkable area*) shows where a man can walk in the
map: the editor makes a navigation mesh of the map's floors (with Recast, the library many games use
for this, which comes with the editor; it takes a second or two) and colours the floor JC can reach
from where he starts:

- **green**: near the AI paths, characters find their way there;
- **amber**: walkable, but far from any path node: put one there if characters must go;
- **red**: no path node reaches it: characters cannot find their way there.

Only the main network counts: path points the last rebuild left linked among themselves but not to
the rest (a group apart) do not make their floor green, and the status bar says how many there are.
Roofs and places JC cannot reach are not coloured; the status bar says how big they are. With the
walkable area shown, **Test route** also draws the straight way on it (in the accent colour) next to
the AI's node-to-node one, with its length: where the two are very different, the network makes the
characters walk round. The walkable area knows the map's walls and floors, not the furniture and the
other objects, so it can show a way through a crate or a barricade.

**Fill AI paths** (*Map > Fill AI paths*) puts the path nodes for you: one wherever JC can walk and no
node of the network is near enough, about 450 units apart, each where a man can walk straight to the
next one, away from the walls and outside the furniture. Where a group of points does not reach the
main network, it adds nodes along the way between them (at the corners). They are ordinary path nodes,
added as if placed by hand: **Ctrl+Z** takes them all away, and the next **Rebuild** (or *Map > Rebuild
AI paths*) links them; the walkable area counts them at once. After the rebuild, run it again: it joins
what the game left apart, and says which groups it cannot join (steep stairs or a ledge the game does
not link): put a few nodes there by hand, closer together. On Battery Park it adds about 170 nodes and
the floor goes from 23% to 97% green.

**Patrol route**: select a character; at the end of its Properties, **Draw route**, then click the
floor where they walk, point after point, and press **Enter** (or Esc). They walk it in a loop: after
the last point, back to the first. The route is drawn in orange with numbers; the dashed line is
where they start from. Every point has a **wait** (seconds they stop there, turned the way the point
faces: turn it with **E**) and **✕** takes it out of the route. **+ Add points** goes on drawing,
**Clear route** removes it. The character's *Orders* become *Patrolling* and its *Order target* the
first point; each patrol point's *Next point* is the following one (all of this is also in their
Properties, and in Connections).

## Animations

**What a character does when idle**: in its Properties, *Animation > When idle* lists the animations
of its model (breathing, idle gestures, sitting, cowering, dancing...) with their length; **▶** plays
it on the character in the 3D view. In the game they do it while standing (Orders *Standing*) or
while waiting at a patrol point, instead of breathing; *Speed* plays it slower or faster. In a
conversation, in a fight or running away they are as the game makes them.

**At a patrol point**: select the point, *Animation while waiting* (the animations of the characters
patrolling through it): they do it while they wait there. When the point had no wait, it gets one
long enough for the animation.

Both work through the mod: `UCAnimSet` objects in the map (made by the rebuild), so the mod must be
installed (**Install** does it).

**Pose here** (*Animation > Pose here...* in a character's Properties, or right-click it): poses the
character where it stands, against the map around it, instead of in the Studio's empty room: a hand
on a railing or a desk, the back against a wall. The character shows its skeleton's handles: drag the
**hands** (orange) and the **feet** (blue) onto the map and they stick to what is under the pointer (a
hand lies on it, the palm against it, the fingers pointing on away from the shoulder; a foot stands on
it); **Alt** moves them freely. A handle that sticks stays where it touches, and grabbing it again moves
nothing until the pointer moves. A thin railing is easy to miss by a pixel: dragged near it, the hand
gets onto it, and slipping just past its edge does not drop the hand onto the floor behind it. The **hips**
(green) move the body (**Shift**: up and down) and, with **Ctrl**, the whole character moves in the map
to come closer to what it leans on, the hands that hold on staying where they are. A handle turns
red when the arm or the leg cannot reach. A hand that sticks closes by itself as on what it holds:
round a railing or an edge (the surface ends just past the fingers), relaxed on a table top; the
**Grip** sliders override it. **Start from** gives a ready pose, placed on what you click next:
**Railing** (both hands on it), **Elbows** (leaning on it), **Wall** (the back against it), **Table** (both
hands on the top) and **Sit** (on an edge, a crate, a bench, facing the camera): the character turns,
comes close enough for its arms to reach (never into what it holds; it leans more when it cannot come
closer) and puts its hands and feet down; a seat too high to sit on with the feet on the floor is said.
The panel leans, turns and bends the upper body, closes the hands (**Grip**) and keeps the character
breathing. **Save** makes it an animation of the Animation
Studio (`Pose<name>`), puts it on the character's models and gives it to the character as what it does
when idle, with *Stays put* (it never turns away from what it leans on); **Rebuild** puts it in the
map. Opening Pose here again on that character goes back to the same pose. **Animate in the Studio...**
saves the pose as a new animation with the name you give it, without changing the character, and opens it
in the Animation Studio: the pose is its first key, to go on animating from there. **Ctrl+Z** and **Ctrl+Y** (or
the arrows in the panel) step back and forth through the changes made while posing, the character's place
in the map included; *Reset* (standing again) is one of them, so a mistake never means starting over.
**Esc** or *Cancel* leaves without changing anything.

### Animation Studio

**Animations** in the top bar (or *Animation Studio...* in a character's Properties) opens the
Studio, to make new animations for the characters, change the game's, or bring in animations from
other programs.

Deus Ex animates its characters frame by frame, without a skeleton. The Studio finds a skeleton in
every model by itself, from the game's own animations: the parts of the body that always move
together are a bone, the points where two of them turn are the joints. It takes a moment the first
time a model is opened; *Make the skeleton again* redoes it.

Every human gets the same skeleton of 17 bones. The joints are placed where a body has them
(shoulders, elbows, hips, knees and ankles at their usual share of the height) and then fitted to the
model's own motion, so a long coat or a skirt does not move a knee; the knee sits on the line from
the hip to the ankle, a little forward. Children are the same skeleton, smaller.

The game's characters never bend their wrists, so the hands are found from the model itself: the
vertices of the lower arm with the skin's texture (the head's) are the hand, and the wrist is where
the sleeve ends; with gloves or bare arms, what lies past the wrist. The animations made before the
hands had bones (18 October 2026) keep the skeleton they were made with, so they look the same.

- **Character** and **Model**: the character to work on, and its model. A soldier of the game can
  have two: the original and the HDTP one (Revision's high definition models). The Studio shows the
  one the game shows and puts every animation on both.
- **Game animations**: click one to play it. **Copy** makes it an animation of yours, to change.
- **+ New**: an animation of your own, starting from the rest pose. Click a ball of the skeleton (or
  the body) to pick a bone and turn it with the rings; the hips also move (**G** or **W** move, **R** or
  **E** turn).
  Every change is a **key** at that frame (the yellow diamonds on the timeline); between keys the
  Studio moves smoothly. Go to another frame (the slider, the arrow keys), pose again. **Space**
  plays. **Delete** removes the key of the frame, *Mirror* swaps left and right, *Reset bone* puts a
  bone back, *From game ... Pose* copies the pose of a frame of a game animation. *Frames* and *fps*
  give its length, *loops* whether it repeats.
- **Import file**: an animation made elsewhere, on any human skeleton: **BVH** (motion capture: free
  libraries such as CMU's), **FBX** (for example from Mixamo: download it in FBX, with or without
  skin) or **glTF/GLB** (Blender exports it). The Studio recognises the bones by their usual names
  (Hips, Spine, LeftArm, LeftForeArm, LeftUpLeg, upperarm_l, thigh_l...) and moves each bone of the
  Deus Ex skeleton the way the file's does, whatever the file's rest pose (a T-pose too) and size. It
  stays in place: walking forward is the game's job. The bones the file does not have follow their
  parent (they are listed). A file on the Studio's own skeleton (see **Export .glb**) comes back as it
  was made: the body's motion and the frame rate too.
- **IK** (the buttons **L hand**, **R hand**, **L foot**, **R foot** under the frame's title): an arm
  or a leg moved by its hand or foot. A box at the hand or foot is the controller: **G** moves it and
  the limb follows, **R** turns the hand or foot; the diamond (the *pole*) is where the elbow or the
  knee points. The controller has keys of its own (its row in the list, *Key controller*), and a foot
  on IK stays where it is while the body moves. Clicking the button again goes back to turning the
  bones one by one (FK): the bones get keys holding the IK's poses.
- **Grip** (in the panel when a hand, or an arm's IK, is selected): how far the hand is closed, from 0
  (open) to 100. It is keyed on its own row (*Left grip*, *Right grip*) like a bone. The game's models
  have no fingers of their own, so the closing is the game's: the way the model's own animations close
  its hands (holding a rifle), so it looks as in the game. The HDTP models never close their hands in
  their animations: their fingers bend at the knuckles instead. Without grip keys the hands are as
  before.
- **Export .glb**: the character with its skeleton, its weights, its textures and the animation open,
  for Blender or any other program that reads glTF. In Blender set the scene to the
  animation's frame rate (the Studio says it), then *File > Import > glTF 2.0*. Animate there,
  export glTF again and **Import file** here.
- **Graph editor**: pick a bone and click its curves (or **Edit curves**) to adjust its X/Y/Z rotations
  in degrees. **Ctrl+Space** or the maximize button fills the Studio with it, and again gives the view
  back; it fits the curves when it opens.
  **Body position** edits the character's position (X forward, Y up, Z right). Opening the graph
  does not change an animation. Enabling curves retains its poses at every game frame, including
  imported motion; constant axes start with one key. The graph and the game bake use the same curves.
  Click or Shift-click keys, drag to change their frame/value, or type precise values. **Smooth**
  rounds the movement without overshooting the neighboring values, **Linear** maintains a constant
  speed, and **Hold** retains a value until the next key. Interpolation applies after the selected key.
  Add a key at the playhead, duplicate selected keys there, or delete them; collisions with other keys
  are rejected. Fit all/selected, mouse-wheel zoom and middle-button drag help navigate. Graph keys
  affect their selected channel; the yellow timeline keys remain whole poses.
- **Numbers**: hold the label of a number (X, Y, Z, Scale %, Frames, fps) and drag left or right; a
  faster mouse makes bigger steps, **Shift** is fine, **Esc** puts it back. One drag is one undo step.
- **Keys as in Blender**: **G** move, **R** rotate, **S** scale (props), **Alt+G / Alt+R / Alt+S**
  back to rest; **I** keys the bone (**Shift+I** the pose), **Alt+I** or **X** deletes the key;
  **Up / Down** the next and previous key, **Shift+Left / Right** the first and last frame;
  **Ctrl+C / Ctrl+V** copy and paste a pose (**Ctrl+Shift+V** mirrored); **F** or **Numpad .** looks at
  the selection; **Numpad 1 / 3 / 7** front, right and top (**Ctrl**: the other side). In the Graph:
  **A** all keys, **Alt+A** none, **G** moves the keys with the mouse (a click or Enter places them,
  Esc or a right click puts them back), **X** delete, **Shift+D** duplicate, **I** a key at the
  playhead, **T** easing, **Home** fit, **F** fit the selected keys.
- **Undo / Redo**: the Studio keeps its own history, including posing, curves and animation settings.
  Use the graph buttons or **Ctrl+Z**, **Ctrl+Shift+Z / Ctrl+Y**. One drag is one undo step.
- **Save** puts it in the game: it becomes frames of the model, like the game's own, for every model
  of the character (original and HDTP), in the mod's package `UCAnims.u`, installed in the game when
  it is closed.

To use it: a character's Properties, *When idle*, the group *Animation Studio (yours)*. Every human
character can use it: the Studio puts it on that character's models when you choose it (a few
seconds). In the game the character gets a copy of its model with your animations added (all the
game's are still there), whatever model the game gave it (HDTP or not).

Animations are files in `tools\mapkit\anims\` (`<name>.json`: the keys of the bones), the
skeletons in `anims\rigs\`, the frames made for each model in `anims\baked\`.

### Props attached to bones

In Animation Studio, open **Props** and choose **+ Add prop**. Search the game's objects (for example
`Liquor40oz` for a bottle), select one and attach it. The selected bone is used; the default hips
selection attaches to **Right hand**. **Bone** can move the attachment to any other bone.

- **Click the prop in the view** to select it (a yellow box): the gizmo moves (**G**), turns (**R**)
  and scales (**S**) it in every direction; it stays in its bone's frame. **Alt+G / Alt+R / Alt+S**
  put its offset, turn or size back.
- **Offset** and **Rotation** fit the grip in bone-local axes (X forward, Y up, Z right at rest).
  **Scale %** changes the object's size. **Snap to bone** resets its offset and rotation.
- **Enabled** includes or excludes it in both the preview and game; **Remove** removes this attachment
  only. All prop edits support the Studio's Undo/Redo and stay with the saved animation.
- Pose the arm normally and scrub or play: the prop follows the bone. **Save**, assign the animation
  to the character, then **Rebuild** the map to include the attachments. Saving alone does not rebuild maps.

Props are visual accessories, not pickups: no collision, inventory or AI changes. They appear only
while the character plays that animation, follow its speed and loops, and disappear when it changes
animation or dies. Up to eight props per animation, on Original and HDTP character models. This first
version has a fixed grip throughout the animation: no keyed pickup/drop or hand switching yet.
The game's `Cigarettes` object is a packet, not a single cigarette.

## New map

**New map** (top bar, next to the list of maps) makes a map of your own:

- **Name** and **Mission**: the file becomes `<mission>_<name>.dx` (for example `06_Warehouse_9`).
  The map belongs to that part of the campaign: the mission's goals, flags and InfoLinks work in it.
  **Place name** is what the game shows as the location (optional).
- **An empty room** to build in: its size (width, depth, height; a door is 64 x 128) and the
  textures of floor, walls and ceiling (smooth concrete by default). It has lights, the start of the
  map and an arrival point called *Start*. It is a map script (`tools\mapkit\maps\new_<map>.py`)
  built at once: add Pieces, Objects, characters and blocks, then **Rebuild**.
- **A copy of a map**: any map of the game or of the mod under the new name, as a map of the mod
  (`maps\`): change it as you like, the original stays as it is.

**Install** puts the new map in the game.

## Links between maps

JC leaves a map through a **map exit**: he walks into it and the next map loads. He appears at an
**arrival point** of that map, or at its start (its PlayerStart). Both are in **Objects > Level**
(with *Player start*), or in the **Links** panel.

- Place a **Map exit** where it makes sense (a doorway, the end of an alley, the top of a stair).
  In its Properties, **Leads to** lists every map; **arriving at** lists the arrival points of the
  map you chose (the game's own ones too), or *the start of the map*.
- Place an **Arrival point** where JC should appear, turned the way he should look. Its Tag is its
  name: other maps lead to `<this map>#<Tag>`.
- **Links** (top bar) shows the ways out of this map (where each exit leads), its arrival points,
  and every map of the game or of the mod with an exit that leads here.
- A dialogue or an event of the Story can also take JC to another map (action *Take JC to another
  map*).

**To put a new map in the campaign**: open the map of the campaign JC should come from (for
example `06_HongKong_WanChai_Market`; the editor makes the mod's copy, the original stays as it is).
Place a map exit there, leading to your map at *Start*. In your map, place a map exit back to that
map, at one of its arrival points (the list shows the game's own) or at a new arrival point you place
there. Rebuild both maps and **Install**. **Play from here** lets you try the way in. The exits
are read from the built maps: after a Rebuild, Links and the lists show them.

## Mission graph (read only)

The map icon at the top of the **Inspector**, to the right of its padlock, opens **Mission graph**
in a separate analysis window. A pinned Inspector uses the object displayed there. The analyser reads
saved maps, characters, flags, conversations and scripts in the active project: Original, Revision
and UNATCO are analysed separately, without mixing their game variants.

### First inspection

1. Select Anna or another character and open **Mission graph**. The default view is **Rules**.
2. Choose **Mission** and **Map**. The mission starts from the selected map's number; **All missions**
   also shows later appearances. Rules are grouped by mission and map. **Map not resolved** means the
   scanner has not established a map, not that the rule runs everywhere.
3. Expand a rule card. **When**, **Conditions** and **Actions** describe the source block. **Reads flags**
   are states that it checks; **Writes flags** are states that it changes. These are not current values
   from a running save. Separate branches stay separate; conditions retain AND, OR and negation.
4. Click a flag. **Who writes it** and **Who checks it** list the scanned rules across all missions.
   Open an entry to see that rule, even if it concerns another character. **Back to Anna Navarre**
   (or your starting selection) restores the original subject and mission filter.
5. **Details → Source statements & conditions** shows the file, line and individual source spans.
   Notes explain actor loops, inherited script bindings, partial control flow and unresolved names.

For a first Anna exercise, choose **Mission 03**, map **03_NYC_UNATCOHQ**, and find **MS_AnnaDeskHome**.
The block checks **AnnaAtDesk** and **MS_AnnaDeskHome**, sets Anna's home position and marks the latter
flag true. Click **MS_AnnaDeskHome** to compare its readers and writers. Original and Revision may
both have source definitions in a Revision project; this does not prove that both execute.

Rules match the selected subject by explicit class, dialogue identity or actor reference. A flag whose
name starts with that identity is separately labelled **Matching flag name · not an actor reference**.
Unrelated flags from other branches of the same script are not automatically treated as this
character's rules. A script may select several instances of a class; a conversation owner is an
identity, not a guaranteed instance in the selected map.

**Who writes it** and **Who checks it** name scripts, conversations or authored rules, not necessarily
the character performing the action. No writer found does not mean that a flag is unused: the engine,
missing source code and computed flag names may add accesses that cannot be resolved statically.
Conversation events and choices are separate records; their branch order is not simulated.

**Connections** in the view selector keeps the previous graph available: **Dialogues**, **Behaviour**,
**Story states** and **Other appearances** open filterable reference lists. Select a reference to see
one path, then click an arrow for its explanation or expand **Direct connections** to continue.
**Clear path** clears that path. **Find…** searches project-wide; Back still restores your first object.
Other appearances are separate instances with a shared class or identity, not proof of a unique
character across maps. Shared scripts may also concern other characters. Arrows are references,
not execution order. Long lists use **Show more**.

### Findings and coverage

**Findings** lists issues on the current graph selection/path, with an expandable project list:

- **Error**: a verifiable saved-reference problem, such as a rule targeting an actor deleted from a
  fully decoded map.
- **Review**: a possible problem that needs checking, such as a destination outside scanned maps.
- **Unverified**: missing sources, incomplete maps, computed names or runtime actor selection.

**More → Coverage** reports what was scanned. Rule cards reconstruct literal access and lexical
if/else conditions, not full execution. Function calls, inherited dispatch, jumps, returns and switch
branches may need source review; partial control flow is marked. Map guards are explicit when found;
script bindings are candidate scopes, and numbered mission grouping follows the source/map naming.
Authored rule cards retain saved conditions/actions, including choices, without simulating them.

The graph is not a live debugger, a narrative consistency checker or a visual script editor. It cannot
prove that a rule runs, that branches conflict, or that changing a character is safe. No errors means
neither complete coverage nor no risk.

### Refreshing the analysis

**Refresh** reads saved project files again; reopening can reuse a cached scan. Unsaved changes are
not included. **More → Read game sources** explicitly reads installed packages into local analysis
caches when sources are missing or stale; progress stays visible. After an analysis-service update,
restart DeusEdix before refreshing so that the new backend is loaded.

Scanning never saves or Rebuilds maps, compiles runtime code, changes dialogue, writes flags or alters
a running game. Generated maps need an existing built snapshot; missing coverage is reported instead
of silently building one. **Esc** closes the window. Inspecting a rule does not apply any change.


## Story

**Story** (top bar), or **Dialogues...** on a selected character, opens the story of the map.
It has three lists: dialogues, InfoLinks and events. **Save** keeps your work; **Apply in game**
turns it into the mod's code, compiles it and installs it (the game must be closed; it takes from
a few seconds to two minutes). *Applies* at the top chooses whether the story runs only on the
UNATCO route (the default) or always.

Everything is checked before it is applied: an empty line, an answer that leads nowhere or a
missing character are listed under the panel.

### Dialogues

A dialogue belongs to a character or an object. It starts **when JC talks to them** (a click) or
**when JC gets close** (within a distance, and only if the character can see him), once or every
time, and only if the flags under *Only if* have the given values. Steps play in order:

| Step | |
|---|---|
| Line | the speaker, JC or another character of the map says something |
| JC's answers | 2 to 6 answers; each one goes to its own label; an answer can show up only if a flag has a value |
| Label | a point the answers and jumps go to |
| If a flag... | jumps to a label if a flag has a value |
| Go to a label | jumps |
| Set a flag, Goal | changes the story's memory, adds or completes a goal |
| Trigger an event | triggers the objects with that Tag (a door, an alarm, a light) |
| Give JC an item | a weapon, ammo or an item; the game shows "Received" in the conversation |
| Actions | things that happen as soon as the dialogue ends (see Actions) |
| End of dialogue | closes the dialogue; put one at the end of every branch |

Characters keep the conversation name they have in the original game, so their original
dialogues keep working.

**Priority.** A character can have more than one dialogue (one if JC killed someone, one if
that someone is alive, one for everything else). When more than one could start, the **first from the
top** whose *Only if* conditions hold is the one that plays: put the most specific ones first
and the general one last. **▲ ▼** next to *Priority* move a dialogue before or after the same
character's other dialogues. A dialogue set to play once is skipped after it has played, and the
next one plays.

**Who is this?** The lists of characters show the name in the map, what they are, their
conversation name and the part of the map they are in (for example `UCRoofGuard0 (Special
Projects Security) · UCHKGuard — Roof access`). The target button next to a list (and **Show in
scene** next to the speaker) shows that character in the 3D view: the panel steps aside to a bar,
the character is selected with its properties on the right; **Back to the story** (or Esc)
brings the panel back as it was. The same button is next to the characters and doors of the
actions and of the event *a character dies*.

The Story panel shows your dialogues and a separate **Original conversations** list. Dialogues
written directly in the mod's code (`src/UnatcoContinues/Classes/UCScene*.uc`) are not listed.

### Original conversations and Game voices

Open an original map, then **Map > Story...**. **Original conversations** lists its characters'
dialogues and the mission's InfoLinks. Select a character in the list, or select one in the 3D view
and open **Dialogues...**. The script shows how it starts, its flag conditions, speakers, answers,
jumps and other events. Click **▶** beside a line to hear its original voice; click again to stop.
Expand an event to inspect its details. Mission-wide InfoLinks are included because some are
started by mission scripts, so a listed call is not guaranteed to happen at that exact location.

In the media browser, **Game voices** searches by a sentence, a character or a conversation name.
Filter by **Mission** and **Character**, open a character and conversation, then listen to a line.
**Show more lines** loads the next results. **Voices** chooses an installed package: Revision's
normal JC, its female JC variant, or the original Deus Ex. The `F` packages are for female JC;
they are not French translations. Text and voices come from your installed packages.

Choose **Type > Ambient NPC phrases** in Game voices to find barks and non-interactive
reactions. The filter starts across all missions, then you can narrow it by character or
mission, search a phrase and play it. These reactions are read-only; their voices can still
be used by reference on your own Story lines.

Under Original conversations, **Mission flags** lists literal flag names used by the map's
actual mission script and its parent classes. Search names or functions, expand a flag to see
its operation, class, function and source line. Boolean flags also appear in Story suggestions
with their origin; integer counters are listed for reference, not offered as boolean switches.
These are references in the installed scripts, not live values from a save. Dynamic flag names
are not guessed. If a package has no script source, the panel reports that limitation.

Original flags, goal names and notes also appear in the Story suggestions, with conversation names
as their source. Characters with original conversations have a speech icon in the hierarchy.
Their **BindName** is read only in the Inspector because the game uses it to attach conversations.

**Replace a voice:** use **Record** or **Import...** under an original line, or drop one of your
sounds onto its voice bar. The original text and story logic stay intact. The same speaker saying
the same text uses the same recording, including occurrences in other conversations. **×** removes
that recording and restores the original voice. Close Revision and press **Apply in game** after
adding or removing a dub. The game uses the recording with its normal speaking animation; lines
without a dub keep their own original audio. Radio calls support replacement voices too.

**Use a game voice:** drag a line from **Game voices** onto one of your Story voice bars. You can
also click **Select voice** in the browser, then **Use game voice** on your line. Only a reference is
saved: the player's installed game supplies the audio. Changing the text or speaker clears this
reference so an old recording does not silently speak the wrong words. Your own recordings take
priority over references for the same speaker and text.

**Edit a copy** creates an editable dialogue with the original owner, activation rules, priority,
conditions and voice references. It keeps the original conversation name, so mission-script calls
and the game's “already played” flag still work. Edit its lines and steps, then **Save** and
**Apply in game**. Credits, skill points, inventory checks, choice requirements, animations, random
branches, trading events, notes and jumps into other conversations are preserved. The copy uses
the editor's automatic cameras; a notice explains this. Existing missing or repeated labels are
reported for review. An unsupported event blocks conversion and is listed instead of being dropped.

**Switch off** disables that conversation in this map. On an editable copy, the checkbox keeps its
steps so you can turn it back on. **Restore original** removes the map's override; apply again and
reopen the map in the game. Recordings for matching lines are separate: remove a dub from its voice
bar if you want its original audio as well. After changing compiled stories, test from a fresh map
start; saves made against an older version of your story can retain older state.

The original game packages stay unchanged. The catalogue and preview audio stay in the local
`editor/cache/_gamecons` and `editor/cache/_gamevoices` folders; neither is part of the editor's
repository or installer. Original voices are never imported into the editor's sound package.

### InfoLinks

An InfoLink is a radio call. It is **one-way**: only the caller speaks; JC never answers by
radio (if JC has to report something, set a flag). Choose the caller among the portraits of
the game (Alex Jacobson, Walton Simons, Jock, Paul Denton, Sam Carter, Jaime Reyes, Anna Navarre,
Gunther Hermann, Tracer Tong, Bob Page, Morgan Everett, Gary Savage, Stanton Dowd, Daedalus,
Icarus) or *someone else* with any name. Each line gets its own screen, timed like the game's.

An InfoLink never starts over a conversation or another InfoLink: it waits. As in Deus Ex, its
text goes to the history and its actions happen at the start, so an InfoLink cut short counts as
heard. Events and dialogues play it (action *Play an InfoLink*); **+ Event that plays it**
creates the event for you, and *Plays when* lists what plays it.

**No talking while it plays** (on unless you turn it off): while the call is on screen, clicking
people starts no dialogue, because a dialogue would hide the InfoLink window and the game would
cut the call. As soon as it ends, people can be talked to again. Turn it off for a call that may
play while JC is busy with someone.

### Events

An event happens **when JC gets close to a point**, **when a flag changes**, **at map start**,
**when a character dies or is knocked out**, **when a faction turns hostile to JC**, or **when JC has
an item**, once or every time, and
only if its conditions are met. For the point, select an object in the scene and press *Use the
selected object*, or look at the spot and press *Use the point in front of the camera*.

### Actions

Events, dialogues (step *Actions*) and InfoLinks can do:

| Action | |
|---|---|
| Set a flag, Goal, Datavault note, On-screen message | the story's memory and what the player reads |
| Start a dialogue, Play an InfoLink, Play a cutscene | |
| Trigger an event (Tag) | doors, alarms, lights of the map |
| A character... | walks or runs to a point, stops, wanders around, follows JC, becomes hostile to JC (attacks when he sees him), attacks JC right now, becomes neutral or friendly, vanishes, reappears, joins a faction |
| A faction... | becomes hostile, neutral or friendly towards JC or another faction (fixed or not) |
| A door... | opens, closes, locks, unlocks, blows up |
| Take JC to another map | with an arrival point (Tag) if you want |

Nobody vanishes or appears in front of JC: a character waits until JC cannot see that spot. To
make someone appear later, untick **There from the start** in their Inspector (Behaviour): they are
not in the map when it starts (the editor still shows them, in the Hierarchy too), and they come in
with *reappears* (a story event) or the interaction **Come back** (after a button, a zone...), then
**Walk to a place** sends them on.

**On the walkable area** (under *Walk / Run to a place*, in the Interactions and in the Story; on by
default for the ones you make now): the character finds the way on the walkable area (*View >
Walkable area*), the way a man would walk, and needs no path nodes on the way. Each **Rebuild** of a
map that uses it puts the walkable area into the map (*Walkable area for the game: N polygons* in
Messages). In the game the mod plans the route (the corners where it turns) and the character walks it
with the game's own orders, so it opens the doors it can open and animates as always. If it gets held
up, the mod plans the route again from where it stands. Without a walkable area in the map, or with no
way on it, the character takes the AI paths as before. What it knows that the view does not:

- crates, barricades and the other blocking objects (JC climbs over them and squeezes past them;
  characters cannot), and the invisible walls for characters (*BlockAll*);
- locked doors, which are walls for characters. A Battery Park trooper cannot get into Castle Clinton:
  its two doors are locked.

Old actions (without the tick) and the characters of the original maps keep the AI paths. For
**Tools > Scripts**: *Map settings > walkable area in the game* puts it into the map even with no
action using it; then `class'UCNavRoute'.static.Send(somePawn, aPlace, bRun)` sends a character, and
`class'UCNavMesh'.static.Of(self).Route(a, b)` plans a route (`NumCorners`, `CornerAt(i)`).

### Flags

Flags are the story's memory: one dialogue sets them, another requires them. The flag field
suggests the flags the mod already uses, plus two kinds the story makes by itself:
`UCEd<code>_<id>_Played` (a dialogue has been played) and `UCEd<code>_<id>_Heard` (an InfoLink
has been heard); the InfoLink panel shows its own.

**What happened to a character.** The mod remembers, for the whole game, every character JC
killed or knocked out, in every map: no flag to set by hand. The **👤** button next to every flag
field (*Only if*, *If a flag...*, events, *Set a flag*) picks it: the map (this one or any other),
the character and *was killed*, *was knocked out*, *was killed or knocked out* or *is alive*. The
field then reads, for example, *👤 TriadRedArrow0 (06_HongKong_WanChai_Street) was killed*.
Example: two dialogues for Simons in a later map, the first *Only if* that Red Arrow member was
killed, the second with no condition: Simons brings it up only if JC killed him.

They are ordinary flags (`UCFate<map code>_<name>_Dead`, `_KO`, `_Down`), so a story can also
set them itself with **Set a flag**: a character who "dies" in a cutscene counts as killed. The
last value written wins. A knocked-out character that is killed later counts as killed; one
carried to another spot keeps its fate.

### Example: a guard gives JC a weapon, then a radio call

1. Select the guard in the scene and press **Dialogues...**: a new dialogue opens with the guard
   as the speaker. Set *Starts* to *when JC gets close*.
2. Write his line. Add **JC's answers** with three answers (GEP gun, crossbow, sniper rifle).
3. Each answer created its own branch at the bottom: a label (`answer1`, `answer2`...), a line
   and **End of dialogue**. In each branch add **Give JC an item** with that weapon and move it
   up (↑) under the label.
4. In each branch, before **End of dialogue**, add **Actions** with *A character... (the guard)
   walks to a point*, and pick the point.
5. Create an **InfoLink**: caller Alex Jacobson, one or two lines.
6. In the guard's dialogue, add to the **Actions** step *Play an InfoLink* (Alex's).
7. **Apply in game**, open the game and walk to the guard.

### When something does not start

The game's log (`Revision\System\Revision.log`) explains it, in lines starting with `UCEd:`:
why a "when JC gets close" dialogue did not start (JC out of sight, its conditions, the game
refusing it), where a character was sent, which door was used, which InfoLink played.

### Voices: dubbing the lines

Every line of a dialogue or an InfoLink can have its own voice, like the game's recorded lines:

- **● Record** under the line: the window shows the line to read (as in a dubbing room); **Record**,
  speak, **Stop**, **▶ Listen**, then **Use this take** (or **Again**). The silence before and after is
  cut, a quiet take is raised to the level of the game's voices. **⚙** next to Record (or **Settings >
  Microphone**) chooses the microphone.
- **Import...** takes a recorded file (WAV, MP3, OGG, FLAC); a file from Windows or one of **My sounds**
  can also be dropped on the line.
- **▶** listens to it, **✕** takes it away.

In the game the character says it **from their mouth, and the lips follow**: as in Deus Ex, there is
nothing to prepare for the lips, the engine moves the mouth (seven shapes: A, E, F, M, O, T, U and closed)
with the sound of the line while it plays. An InfoLink's voice comes over the radio, with the portrait.
The voice belongs to the line: change its text and the voice follows it when you **Save**. It plays after
**Apply in game**. Voices are kept in the editor's sounds package (*UCSounds* in UNATCO Continues,
*DeusEdixSounds* in DeusEdix), installed with your maps. A line too long for one subtitle (over about 250
letters) is shown in two parts: split it into two lines to give each its voice.

## Save, rebuild, test, install

| Button | |
|---|---|
| **Save** (`Ctrl+S`) | writes your changes to the map's changes file |
| **Rebuild** | saves and builds the map with your changes (about a minute) |
| **View in game** | opens the game on the last rebuilt map and shows a screenshot from where you are in the editor (the first time, the game has to start); **Close game** closes it |
| **Install** | puts the rebuilt map into the mod and into the game; the game must be closed |
| **Revert all changes** (Changes panel) | forgets every change made on this map |

**View in game** shows the last rebuild: rebuild first to see your changes.

### Play from here

**Play from here** opens the game on this map with JC standing on the floor below the camera,
looking where you look, and then the controls are yours: walk around, talk, test a dialogue or an
event. In its window you choose:

- **Mission state**: *the map as it starts*, or one of the states the mod prepares for this map
  (for Wan Chai Street: *Tonnochi Road*; for the rooftop: *just landed with Jock* or *raid over,
  JC at the top of the service stair*). They set the story's flags and items as if you had played
  up to there.
- **UNATCO route**: on by default, because the editor's story runs on that route.
- **Other flags**: any flag, as `Name=1` or `Name=0`, separated by commas.
- **Install first**: shown when the game would miss your last rebuild; the game plays the
  installed map, so leave it ticked.

The game takes about 30 seconds to open. Close it normally, or with **Close game**: the editor
puts the game's settings back by itself. Apply the story in the Story panel before playing, or
the game will not have your latest dialogues. For existing maps,
**Install** keeps the previous copy in `maps\backup\`, refuses if the mod's copy was changed by
something else since your rebuild, and archives the changes, which are now part of the map.

## Where things are kept

| | |
|---|---|
| `maps\<map>.edits.json` (or next to the map script) | your changes to a map |
| `maps\` | the mod's maps; `install.ps1` copies them into the game's `UnatcoMaps` folder |
| `tools\mapkit\story\<map>.json` | the map's story; `UCEd_<map>.uc` in `src\UnatcoContinues\Classes` is generated from it |
| `tools\mapkit\textures\<map>\` | the pictures you imported or made in the Texture Editor; `textures\_library\` = My textures |
| `tools\mapkit\prefabs\` | what you copied with `Ctrl+C` |
| `tools\mapkit\anims\` | the Animation Studio's animations, skeletons (`rigs`) and frames (`baked`); `dist\UCAnims.u` is made from them |
| `tools\mapkit\editor\cache\` | what the editor computed (models, textures, animations of the game, AI paths, class defaults); safe to delete |
| `tools\mapkit\editor\cache\game-revision\`, `game-vanilla\` | what is made from the game itself, once for every project of that game: the models of its objects and their previews, the original maps read for the Pieces, texture pictures, conversations, voices, animations, characters. A new project opens with all of it ready; safe to delete (it is made again) |

## Local geometry (Experimental)

Enable **Settings > Editing > Local geometry (Experimental)**, then choose **Map > Local geometry (Experimental)** or the same command in the Rebuild menu. The tool opens a separate window with a private copy of the map currently shown. Rebuild normally first if you want to include saved editor changes; those changes are not applied automatically inside this tool. The temporary tutorial does not use it.

Select a source brush and enter its movement, scale or rotation. These transforms use that brush's pivot. **Before / After** show the compiled geometry after verification. The default **Area · Full check** reconstructs the affected area and still uses a Full rebuild to check the result. **Isolated box**, **Convex CSG** and **Buried detail** offer independent verification without Full only for supported geometry. Unsupported changes are refused; a successful edit on one brush does not imply that every edit on the map is supported.

Results are experimental copies outside the normal project build. **Show result** opens their folder; **Continue from result** starts another edit from the verified copy. To keep one in your project, use **Open map > Browse .dx** to import it as a new map. Rebuild its **Lighting** and **Paths** before Play or Install. The tool does not replace the project's map or install a result automatically. Verification can take a few minutes and this preview is not a speed guarantee.

The feature uses the engine from your installed game. No game maps, packages, textures or engine DLLs are included in DeusEdix.

## Limits

- Some original maps cannot be rebuilt (Wan Chai Street): only objects can change there.
- A map's BSP has a limit (65536 nodes): Rebuild optimises it as UnrealEd did, so the big maps of
  Revision stay under it; a map that still goes over says so in Messages (fewer or simpler blocks there).
- Stretching a structure of an existing map needs a rebuild of its geometry, so it works only
  where the map can be rebuilt.
- The Animation Studio works on human characters (the skeleton has hips, spine, head, arms and
  legs): animals and robots can play and use the game's animations, not new ones. The fingers and the
  face do not move (Deus Ex has no bones for them: the mouth is the game's lip sync).
- New animations are as smooth as the frames of the model allow: a character with few vertices (the
  original models) bends at the joints like the game's own animations do.
- Original maps that cannot be rebuilt (Wan Chai Street) cannot get Pieces either (they need a
  rebuild of the geometry); a copy of such a map has the same limit.
- Characters of the Creator have no barks (the short lines the game's characters say by
  themselves) and keep the bodies of the game: new 3D models cannot be imported.
- The editor does not make voices by itself: record or import them for each line (see *Voices*).
- The **Lit** view is close to the game but not identical: lamps that flicker or pulse are shown
  steady, coronas and fog are not drawn, and some objects can have a different skin in the game.
- The story runs only on the UNATCO route unless you choose *always*.
- Animations move objects, not characters (their AI walks them: give them orders and patrols). The keys of
  a door or an elevator are the engine's: at most 8, and the same curve for all of them.
- Imported models do not move by themselves (no skeletal animations: characters are made with the Character Creator), and their
  collision is a cylinder round them (untick *Solid* for a long table JC should reach over). A map that uses
  them needs the mod's `UCModels.u` (Install puts it in the game).
- A zone works only when its area is closed: walls and zone portals all round. Water and portals change the
  geometry: they need a map that can be rebuilt.
- Interactions run through the mod (`UCLink`): a map that uses them needs UNATCO Continues installed.
  Security cameras give no event when they see JC (the game has none): use a zone instead.
- A door opened by an interaction or a Story action behaves as when JC opens it (it triggers its Event
  when it has opened): a door that shuts by itself after some
  seconds (*stays open*) shuts again.

## How it works inside

For developers; the details are in [`tools/mapkit/README.md`](../../tools/mapkit/README.md).

- `tools\mapkit\editor\server.py` is a small local web server; the page is
  `editor\static\` (three.js). `data.py` turns a map into geometry, textures and objects;
  `dxmaps.py` analyses and edits existing maps; `props.py` is the Properties panel; `textures.py`
  converts pictures; `characters.py` reads the bodies, pieces and textures of the game's characters
  for the Character Creator (`static\characters.js`); `gamelib.py` finds the objects of the original
  levels for **Pieces** (clusters of detail brushes, counted once); `newmap.py` makes new maps;
  `maplinks.py` reads the exits and arrival points of every map offline (`tools\ue1pkg.py`).
- Maps are read and written by `tools\mapkit\bin\UCMapKitHost.exe`, which runs the editor
  engine of the game's own `Editor.dll` (the same file as in Deus Ex's `System` folder) without
  UnrealEd and adds commands of its own (`UC_SET`, `UC_DEL`, `UC_PROP`, `UC_SCALE`, `UC_SURFTEX`,
  `UC_MESHES`, `UC_DEFAULTS`...). The editor does not need UnrealEd or the SDK to run.
- The story is turned into UnrealScript by `tools\mapkit\story.py`: one class `UCEd_<map>` per
  map, built on `UCEditorStory` (actions, events) and `UCCon` (native Deus Ex conversations);
  InfoLinks use `UCEdInfoLink`. `UCCampaign` spawns the class when the map loads. **Apply in game**
  compiles it with `build.ps1`, which runs `UCMapKitHost.exe --make` (the compiler inside
  `Editor.dll`, as `ucc make` does): no UCC.exe needed. A mistake in the code shows as
  `<file>(<line>) : Error, <message>` in the Story panel's messages.
- The characters of the Creator are `UCCustomCivilian`, `UCCustomSoldier` and `UCCustomThug`
  (`src\UnatcoContinues\Classes`): the map sets their `Mesh`, `MultiSkins` and `LookBody` (the
  game character whose body it is); `UCCustomLook` gives them that body's gender, walk and voice
  and dresses their corpse (`UCCustomCarcass`). A carried body (`POVCorpse`) keeps only its class, so
  when JC picks one up its look goes into a hidden item of his inventory (`UCCorpseLook`, it travels
  with him to the next map) and the body he puts down takes it back.
- Interactions (`editor\links.py`, `edits['links']`): each rule is a `UCLink` actor of the mod
  (`src\UnatcoContinues\Classes\UCLink.uc`, built on `UCEditorStory`): `Source`, `When`, `Act(i)` =
  `delay|verb|target|a|b|c`. When the map starts it hooks itself to its object: the object's `Event` (a
  keypad's `FailEvent`, a computer option's `TriggerEvent`) becomes its Tag `UCL_<object>`, and the old
  event is still triggered (`PassEvent`). Picked up, destroyed and JC near are watched every half second.
  Doors move through their own state (`GotoState(InitialState, 'Open')`), so they trigger their Event when
  they have opened. Lights that interactions switch are made non-static (`UC_PROP <light> bStatic False`)
  and change their `LightType` in the game. Revision.log: `UCLink <name> - <the sentence>`.
- Animations (`editor\motions.py`, `edits['motions']`): an object gets a `UCMotion` actor of the mod
  (`Target`, `PosT/PosV/PosE`, `RotT/RotV/RotE`, `ScaleT/ScaleV/ScaleE`, `Mode`, `bAutoPlay`) that moves it
  every frame; a mover gets the keys in its own `KeyPos`/`KeyRot`/`NumKeys` (`UC_PROP` after the import,
  `MoverGlideType`, `bDynamicLightMover`) and its `UCMotion` gives it the time of each step (`Seg`) as its
  `MoveTime`, also when it opens by itself. A moving block is built as a `DeusExMover` (`InitialState
  TriggerControl`, not frobbable). Interactions: verbs `anim`, `animback`, `animstop`; `animdone` hooks the
  `UCMotion`'s Event. Collision boxes: `UCTriggerBox` (a Trigger without collision that checks every frame
  the cylinder of JC, or of every pawn, against its box, then triggers / untriggers its Event); solid: an
  invisible semisolid brush of its size (`motions.wall_ops`).
- Cutscenes (`editor\cutscenes.py`, `edits['cutscenes'][<UCCutscene actor>]`, the page `static\cutscene.js`): the
  placed `UCCutscene` actor gets its keys as properties (`KeyT/KeyP/KeyR/KeyF/KeyE/KeyS`, `NumKeys`, `Line*`,
  `Length`, `FadeIn/Out`, `bBars`, `bSkippable`, `bOnce`, `bAutoPlay`, `bShowJC`, `LookAt`, `bStraight`). In the game
  (`UCCutscene.uc`) JC goes into the state `Interpolating` (as in the game's own intro: no input, no weapon, not
  detectable, no saving), without collision, invisible and falling (a falling JC cannot be drawn into a
  conversation), and is moved every frame so that his eyes are at the camera (`Pose`: a Catmull-Rom spline in
  time, Hermite segments with the tangents `(next - previous) / (their time apart)`, so the speed does not drop at
  a key; at rest at the first and last key, one-sided across a cut, zero at a "stop" key; `ViewRotation` with
  roll, `DesiredFOV`/`FOVAngle`); a `JCDouble` stands
  where he was; `UCCutWindow` draws the bars, the fade (`UCFade`), the subtitles. Interactions: verbs `cutplay`,
  `cutstop`; `cutstart` / `cutdone` are `UCL_<name>_Start` / `_End`, which the cutscene triggers; skipping
  hurries the `cutstart` links (`UCLink.Hurry`). `UCEditorStory.Timer` and `UCTriggerBox` wait while it plays
  (`InCutscene`); the Story action `cutscene` is `PlayCut('<name>')`. Revision.log: `UCCutscene <name> - plays /
  ends`.
- Models (`editor\models.py`): the host's `UC_MESHLIST` lists every mesh loaded; a package's models are
  exported by placing one `UCMeshDeco` per mesh and `UC_MESHES` (the same as the palette). The size comes from
  the DrawScale of the game's class that uses the mesh (`UC_CLASSES` also prints the DrawScale). Import: the
  page reads the file with three.js (glTF, FBX, OBJ, DAE loaders), turns it to Unreal's axes and units, welds
  the vertices and sends triangles with UVs on their corners; the server writes Unreal's two 3D files
  (`_a.3d`: the frames of Deus Ex's 16-bit vertices, one or every baked frame of an animated model, `_d.3d`:
  triangles, UVs, textures, kind; an animated model's clips are played by three.js's AnimationMixer and read
  with `getVertexPosition` at the chosen frame rate, kept as `frames.bin` and made `MESH SEQUENCE`s) and the host
  runs Deus Ex's own importer (`UC_MESHIMPORT` = `UEditorEngine::meshImport`, with `MESHMAP SCALE`,
  `TEXTURE IMPORT` of 8-bit PCX, `MESHMAP SETTEXTURE`) and saves the package (`UC_SAVEPKG`). The sources
  stay in `tools\mapkit\models\<name>\`; `UCModels.u` is made again from all of them.
- Zones (`editor\zones.py`): a pool is a subtractive box and a sheet brush whose polygon is
  Portal|Translucent|NotSolid (and the brush TwoSided), as the water of the game's maps, with a `WaterZone` in
  it; a zone portal is a sheet Portal|Invisible|NotSolid|TwoSided; the sky is `Marker_sky` with FakeBackdrop
  on the top of a hole, and a sky box (a closed room of `CoreTexSky` textures with a `SkyZoneInfo`) far from
  the map. After the build the T3D says which zone every zone actor ended up in (`Region`).
- Packages of other mods (`editor\packages.py`, `tools\mapkit\packages.json`): added to the
  `EditPackages` of every run of the host (`kit.py`), so its engine loads them at startup. The class
  lists (`cache\_palette\classes.json`, `defaults.json`) are made again. Their classes without a model
  go under the package's name.
- AI paths: the host's `UC_PATHS` reads the network of a map (`Level.ReachSpecs`, the links not
  pruned) into the cache's `paths.json`; before `PATHS DEFINE` the builds run `UC_NAVDROP`, which
  rests the path points on the floor (15 above it: Deus Ex links no point higher than about 20).
- Holes are subtractive brushes (`BRUSH SUBTRACT` in `dxmaps.py`, `Scene.sub` in script maps), after
  everything the map has. Map settings (`editor\mapsettings.py`): `UC_PROP @LevelInfo` /
  `@DeusExLevelInfo` (the host's `@Class` = the first actor of that class: after `MAP NEW` the actors
  are not named as in the saved map) and a `UCMusicInfo` plus `UC_PROP @@DXOggMusicInfo` (every music
  actor gets the same tracks); the presets come from the original maps (`tools\mapkit\refs`), the
  tracks from `Revision\Music` (served at `/music/` for listening). Sounds (`editor\sounds.py`):
  `UC_SOUNDS` lists every sound of Ambient.uax, RSounds.uax, MoverSFX.uax, DeusExSounds.u and
  Precipitation.u; a sound effect is the mod's `UCSoundFX` (a Trigger: it plays `FXSound` on touch,
  `bOnTouch`, or when triggered by its Tag, and logs `UCSoundFX <name> played <sound>` in Revision.log);
  door sounds are the movers' own `OpeningSound`, `OpenedSound`, `ClosingSound`, `ClosedSound`,
  `MoveAmbientSound`; a sound is exported with `OBJ EXPORT ... FILE=x.wav` (the exporter goes by the
  extension) for the browser; the builds `OBJ LOAD` the packages the map's sounds use. Check map: the
  links in the page, the objects in solid geometry with the host's `UC_ACTORS check` on the map as last
  rebuilt (`/api/check`).
- Texture Editor (`static\texedit.js`): the texture at full size comes from the host's `UC_TEXDUMP
  <texture> <file> 2048` (it loads a mip that is not loaded yet through its own lazy loader; colour 0 of a
  masked texture is see-through) into `cache\_texfull`; painting is canvas 2D (a stroke = the brush's
  mask along the path, drawn over the picture as it was through the tool's source: a colour, the picture
  moved, blurred, lighter or darker). *On every object* is `retexture` kind `actors`: at Rebuild,
  `textures.wearers()` finds the objects whose model wears the old texture (the editor's last look at
  the map, and the objects added since) and gives each `MultiSkins(slot)`.
- Animations: `UC_ANIMDUMP` writes a model with every frame of every sequence (`editor\anims.py`
  reads it; the 3D view and the Studio play it). The Studio (`static\studio.js`) finds the skeleton
  with rigid fits of every bone in every frame (Horn's method), gives each vertex the bone that
  explains its motion best and puts the joints where two bones turn about; poses are rotations of the
  bones from the rest pose, blended on the vertices (two bones near a joint) and baked into the
  model's frames (int16, the model's own units). `UC_ANIMNEW` copies a model (every frame, triangle,
  LOD and skin) with the new sequences after its frames into the package `UCAnims`, `UC_ANIMSAVE`
  writes `UCAnims.u`. In the game `UCAnimSet` gives the character `UCAnims.<its model>` (whatever
  model the game gave it: Revision's HDTP Facelift changes some) and plays the chosen animation while
  it is idle or waiting at a patrol point (`PatrolPoint.PatrolAnim`, a field the game never uses).
