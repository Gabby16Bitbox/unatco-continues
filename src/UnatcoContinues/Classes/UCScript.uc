//=============================================================================
// UCScript - the base of the scripts written in the map editor (Tools > Scripts). A script is an
// invisible object placed in the map; give it a Tag and the editor's Interactions (or any trigger,
// or another script) can set it off. Write only the events you need:
//
//   Started()                         once, when the map is running and JC is in it
//   Triggered(Other, EventInstigator) whenever something triggers its Tag
//   Repeat()                          every RepeatEvery seconds (set it in the Inspector; 0 = never)
//
// and use the helpers below: Player(), Say("..."), Find('Tag'), FindNamed("Name"), TriggerTag('Tag'),
// GetFlag('Name'), SetFlag('Name', True), Give(class'Medkit'). log("...") writes a line to the
// editor's Console. Everything else of UnrealScript works as in any Deus Ex actor.
//=============================================================================
class UCScript extends Actor
	abstract;

var() float RepeatEvery;        // seconds between two Repeat() (0: Repeat is never called)
var bool bScriptStarted;

// ---------------------------------------------------------------- the events to write
function Started();
function Triggered(Actor Other, Pawn EventInstigator);
function Repeat();

// ---------------------------------------------------------------- helpers
// JC (None for a moment while a map loads)
final function DeusExPlayer Player()
{
	return DeusExPlayer(GetPlayerPawn());
}

// a line in the game's message area (top left)
final function Say(coerce string Text)
{
	if (Player() != None)
		Player().ClientMessage(Text);
}

// the first actor with this Tag (None if there is none)
final function Actor Find(name ActorTag)
{
	local Actor A;

	if (ActorTag == '')
		return None;
	foreach AllActors(class'Actor', A, ActorTag)
		return A;
	return None;
}

// the actor with this name (its name in the editor's Hierarchy, e.g. "Light29")
final function Actor FindNamed(string ActorName)
{
	local Actor A;

	foreach AllActors(class'Actor', A)
		if (string(A.Name) ~= ActorName)
			return A;
	return None;
}

// sets off everything with this Tag: doors, triggers, lights, other scripts...
final function TriggerTag(name ActorTag)
{
	local Actor A;

	if (ActorTag == '')
		return;
	foreach AllActors(class'Actor', A, ActorTag)
		A.Trigger(Self, Player());
}

// the game's flags (the ones the Story and the conversations use)
final function bool GetFlag(name FlagName)
{
	return Player() != None && Player().FlagBase.GetBool(FlagName);
}

final function SetFlag(name FlagName, bool bValue)
{
	if (Player() != None)
		Player().FlagBase.SetBool(FlagName, bValue,, 99);
}

// a new item straight into JC's inventory (as if he picked it up)
final function Inventory Give(class<Inventory> ItemClass)
{
	local Inventory item;

	if (Player() == None || ItemClass == None)
		return None;
	item = Spawn(ItemClass,,, Player().Location);
	if (item != None)
		item.Frob(Player(), None);
	return item;
}

// ---------------------------------------------------------------- what calls the events
function PostBeginPlay()
{
	Super.PostBeginPlay();
	if (RepeatEvery > 0)
		SetTimer(RepeatEvery, True);
}

event Tick(float DeltaTime)
{
	if (bScriptStarted || Player() == None)
		return;
	bScriptStarted = True;
	Disable('Tick');
	Started();
}

function Trigger(Actor Other, Pawn EventInstigator)
{
	Triggered(Other, EventInstigator);
}

function Timer()
{
	if (bScriptStarted)
		Repeat();
}

defaultproperties
{
	bHidden=True
	Texture=Texture'Engine.S_Trigger'
	DrawType=DT_Sprite
	CollisionRadius=16.000000
	CollisionHeight=16.000000
}
