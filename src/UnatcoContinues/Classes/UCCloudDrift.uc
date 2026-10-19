//=============================================================================
// UCCloudDrift - clouds of a sky box that drift slowly (the rooftop of Mission 6).
//
// The engine's own drift (a surface with Auto U/V Pan) goes at a fixed speed in pixels of the texture,
// too fast for Gabby (17 Oct 2026). Here the cloud sheet is a Mover (Tag = CloudTag), a little longer than
// the sky box along Drift: it is moved by Drift units a second and, after exactly one repeat of its
// texture (Wrap), put back by that much: the texture is the same there, so the jump is not seen.
//=============================================================================
class UCCloudDrift extends Info;

var() name   CloudTag;       // the cloud sheet: a Mover with this Tag
var() vector Drift;          // units a second
var() float  Wrap;           // one repeat of its texture along Drift (units)

var Mover  Sheet;
var vector Base;
var float  Gone;

function PostBeginPlay()
{
	local Mover M;

	Super.PostBeginPlay();
	foreach AllActors(class'Mover', M, CloudTag)
	{
		Sheet = M;
		break;
	}
	if (Sheet == None)
		Log("UCCloudDrift" @ Name @ "- no cloud sheet" @ CloudTag);
	else
		Base = Sheet.Location;
}

function Tick(float dt)
{
	local float d;

	if (Sheet == None || Wrap <= 0 || VSize(Drift) <= 0)
		return;
	Gone += dt * VSize(Drift);
	Gone = Gone % Wrap;
	d = Gone;
	Sheet.SetLocation(Base + Normal(Drift) * d);
}

defaultproperties
{
     Wrap=1024.000000
     bAlwaysRelevant=True
}
