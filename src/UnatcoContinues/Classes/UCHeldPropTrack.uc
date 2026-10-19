//=============================================================================
// UCHeldPropTrack - a prop track of the Animation Studio (UCAnimPropTrack) for the mod's own scenes
// in the game's original maps, where no map rebuild writes the tracks: the scene spawns a generated
// subclass (UCTrack*, made by tools\make_prop_tracks.py from the Studio's bake, its frames in its
// defaultproperties) and the track follows every pawn playing that animation. The one difference from
// UCAnimPropTrack: the follower it makes is PropActor (a UCAnimProp that does more: UCHeldFlare burns a
// real flare, UCCigaretteHeld smokes). One chunk only (64 frames at most): runtime actors have no names
// to chain chunks by.
// In a map the editor rebuilt, the map may hold the editor's own track of the same animation (the Studio's
// latest placement of the prop, shown as its stand-in, a flare for the cigarette): this track takes it over
// (Gabby, 18 Oct 2026). Its followers read that track's frames, and its own plain followers go away.
//=============================================================================
class UCHeldPropTrack extends UCAnimPropTrack;

var class<UCAnimProp> PropActor;
var UCAnimPropTrack Frames;    // the frames the followers read: the editor's track of the animation, or this one
var bool bLooked;

// the editor's track of the same animation in this map, if there is one: its timer stopped, its plain
// followers gone (they showed the Studio's stand-in); else this class's own frames
function UCAnimPropTrack FramesToRead()
{
	local UCAnimPropTrack T;
	local UCAnimProp A;

	if (bLooked)
		return Frames;
	bLooked = True;
	Frames = Self;
	foreach AllActors(class'UCAnimPropTrack', T)
		if (T != Self && UCHeldPropTrack(T) == None && T.bRoot && T.AnimationName == AnimationName
			&& T.ModelName == ModelName && T.ModelPackage == ModelPackage)
		{
			T.SetTimer(0, False);
			foreach AllActors(class'UCAnimProp', A)
				if (A.Owner == T)
					A.Destroy();
			if (!T.bLinked)
				T.LinkChunks();
			if (T.Appearance != None)
				Frames = T;
			break;
		}
	return Frames;
}

function Timer()
{
	local ScriptedPawn P;
	local UCAnimProp A, Existing;
	local UCAnimPropTrack F;

	if (!bRoot)
		return;
	if (!bLinked)
		LinkChunks();
	if (Appearance == None || Appearance.default.Mesh == None)
	{
		SetTimer(0, False);
		return;
	}
	F = FramesToRead();
	foreach AllActors(class'ScriptedPawn', P)
	{
		if (!F.Matches(P))
			continue;
		Existing = None;
		foreach ChildActors(class'UCAnimProp', A)
			if (!A.bDeleteMe && A.Who == P)
			{
				Existing = A;
				break;
			}
		if (Existing == None)
		{
			A = Spawn(PropActor, Self,, P.Location);
			if (A != None)
				A.Bind(F, P);
		}
	}
}
defaultproperties
{
	PropActor=Class'UnatcoContinues.UCAnimProp'
	bRoot=True
	ModelPackage=UCAnims
}
