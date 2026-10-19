//=============================================================================
// UCHeldFlare - the flare a pawn holds in the Animation Studio's flare animations (Gabby, 17 Oct 2026:
// the Special Agent at Eva's landing zone lights the flare and holds it up, arm straight, open palm).
// It is a real flare of the game (DeusEx.Flare: its light, hiss, smoke and sparks follow it, as
// LightFlare sets them on it), moved every tick onto the prop's place on the hand; this follower itself
// draws nothing. The flare is found again by Tag (the pawn's name) when the animation changes from
// UCFlareLight to UCFlareHold, so it is one flare. Lit from frame LitFrame of UCFlareLight (the strike)
// and always in UCFlareHold; it burns for ever (LifeSpan 0, as UCSceneBatteryPark's old ground flare).
// If the pawn dies or stops holding it (another animation), the flare drops where it is.
//=============================================================================
class UCHeldFlare extends UCAnimProp;

var Flare Held;
var() float LitFrame;          // the frame of UCFlareLight where the cap is struck (of its FrameCount)

function Flare FindFlare()
{
	local Flare f;

	if (Who == None)
		return None;
	foreach AllActors(class'Flare', f, Who.Name)
		return f;
	f = Spawn(class'Flare',, Who.Name, Location, Rotation);
	if (f == None)
		return None;
	f.SetPhysics(PHYS_None);
	f.SetCollision(False, False, False);
	f.bCollideWorld = False;
	return f;
}

function bool ShouldBurn()
{
	if (Who == None)
		return False;
	if (Who.AnimSequence == 'UCFlareHold')
		return True;
	return Who.AnimSequence == 'UCFlareLight' && Track != None && Track.FrameCount > 0
		&& Who.AnimFrame * Track.FrameCount >= LitFrame;
}

function Burn(Flare f)
{
	//#if revision
	local FlareLight fl;
	//#endif

	if (f.gen != None || f.AmbientSound != None)
		return;
	f.LightFlare();
	f.LifeSpan = 0;
	if (f.gen != None)
		f.gen.LifeSpan = 0;
	//#if revision
	// Revision's flare has more pieces than the original game's (its sparks, its flame and a FlareLight)
	if (f.flaregen != None)
		f.flaregen.LifeSpan = 0;
	if (f.flamething != None)
		f.flamething.LifeSpan = 0;
	foreach AllActors(class'FlareLight', fl)
		if (fl.Owner == f)
			fl.LifeSpan = 0;
	//#endif
}

// LightFlare puts its smoke, sparks, flame and light on the flare with SetBase, but a base moved by SetLocation
// leaves them behind (seen in game, 17 Oct: the flame stayed where it was struck): they are set again here,
// where LightFlare puts them (the smoke and the light at the burning +Y end).
function MoveEffects(Flare f)
{
	//#if revision
	local FlareLight fl;
	//#endif
	local vector X, Y, Z;
	local rotator r;

	GetAxes(f.Rotation, X, Y, Z);
	if (f.gen != None)
		f.gen.SetLocation(f.Location + Y * f.CollisionRadius * 1.05);
	//#if revision
	if (f.flaregen != None)
	{
		f.flaregen.SetLocation(f.Location + Y * f.CollisionRadius * 0.8);
		r = f.Rotation;
		r.Roll = 0;
		r.Yaw += 16384;
		f.flaregen.SetRotation(r);
	}
	if (f.flamething != None)
	{
		f.flamething.SetLocation(f.Location);
		f.flamething.SetRotation(f.Rotation);
	}
	foreach f.ChildActors(class'FlareLight', fl)
		fl.SetLocation(f.Location + Y * f.CollisionRadius * 1.05 + vect(0,0,40));
	//#endif
}

function Bind(UCAnimPropTrack T, ScriptedPawn P)
{
	Super.Bind(T, P);
	DrawType = DT_None;
	Held = FindFlare();
}

function Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);
	if (bDeleteMe)
		return;
	DrawType = DT_None;
	if (Held == None || Held.bDeleteMe)
		Held = FindFlare();
	if (Held == None || bHidden)
		return;
	Held.SetLocation(Location);
	Held.SetRotation(Rotation);
	if (ShouldBurn())
		Burn(Held);
	MoveEffects(Held);
}

// The follower goes when the animation changes or the pawn dies: the flare stays only in the hand of a
// pawn still holding it (the next flare animation picks it up), else it falls.
function Destroyed()
{
	if (Held != None && !Held.bDeleteMe && (Who == None || Who.bDeleteMe || Who.Health <= 0
		|| (Who.AnimSequence != 'UCFlareLight' && Who.AnimSequence != 'UCFlareHold')))
	{
		Held.Tag = 'UCDroppedFlare';
		Held.bCollideWorld = True;
		Held.SetCollision(True, False, False);
		Held.SetPhysics(PHYS_Falling);
	}
	Super.Destroyed();
}

defaultproperties
{
	LitFrame=10.000000
}
