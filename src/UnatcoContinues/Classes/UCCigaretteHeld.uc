//=============================================================================
// UCCigaretteHeld - the lit cigarette in the hand of a pawn playing the Animation Studio's smoking
// animation (UCTrackLeanSmoke, which reads the frames of the editor's track of the animation when the map
// has one): the cigarette (UCCigarette's look) on the hand, a thin wisp of smoke
// rising from its burning tip (the model's -Y end), and a puff breathed out in front of the mouth at
// ExhaleFrame of the animation, after each drag (UCLeanSmoke: the drag at frames 20-30, the smoke at 40).
//=============================================================================
class UCCigaretteHeld extends UCAnimProp;

var ParticleGenerator wisp;
var ParticleGenerator puff;
var float puffT;
var float lastFrame;
var() float ExhaleFrame;       // the frame where the smoke comes out of the mouth (of the track's FrameCount)

function vector Tip()
{
	return Location + ((vect(0,-6.16,0) * DrawScale) >> Rotation);
}

function Bind(UCAnimPropTrack T, ScriptedPawn P)
{
	local int i;

	Super.Bind(T, P);
	// the cigarette's look, whatever stands in for it in the Studio (a flare: the same model, so the size
	// the Studio gives it is the cigarette's)
	Mesh = class'UCCigarette'.default.Mesh;
	Skin = class'UCCigarette'.default.Skin;
	Texture = class'UCCigarette'.default.Texture;
	for (i = 0; i < 8; i++)
		MultiSkins[i] = class'UCCigarette'.default.MultiSkins[i];
	wisp = Spawn(class'ParticleGenerator', Self,, Tip(), rot(16384,0,0));
	if (wisp != None)
	{
		wisp.bRandomEject = True;
		wisp.ejectSpeed = 2;
		wisp.riseRate = 9;
		wisp.checkTime = 0.15;
		wisp.frequency = 0.7;
		wisp.particleLifeSpan = 2.2;
		wisp.particleDrawScale = 0.03;
		wisp.particleTexture = Texture'Effects.Smoke.SmokePuff1';
	}
}

function Exhale()
{
	local vector mouth;
	local rotator r, l;

	if (Who == None)
		return;
	r = Who.Rotation;
	r.Pitch = -1200;
	l = Who.Rotation;
	l.Yaw -= 16384;                // his left: UCLeanSmoke leans the body that way, the head goes with it
	mouth = Who.Location + vect(0,0,1) * (Who.BaseEyeHeight - 6) + vector(Who.Rotation) * 9 + vector(l) * 5;
	if (puff != None)
		puff.DelayedDestroy();
	puff = Spawn(class'ParticleGenerator', Self,, mouth, r);
	if (puff == None)
		return;
	puff.bRandomEject = True;
	puff.ejectSpeed = 18;
	puff.riseRate = 6;
	puff.checkTime = 0.08;
	puff.frequency = 1.0;
	puff.numPerSpawn = 2;
	puff.particleLifeSpan = 2.6;
	puff.particleDrawScale = 0.07;
	puff.particleTexture = Texture'Effects.Smoke.SmokePuff1';
	puffT = 1.1;
}

function Tick(float DeltaTime)
{
	local float frame;

	Super.Tick(DeltaTime);
	if (bDeleteMe)
		return;
	if (wisp != None)
		wisp.SetLocation(Tip());
	if (puff != None && puffT > 0)
	{
		puffT -= DeltaTime;
		if (puffT <= 0)
		{
			puff.DelayedDestroy();
			puff = None;
		}
	}
	if (bHidden || Track == None || ExhaleFrame <= 0)
		return;
	frame = Who.AnimFrame * Track.FrameCount;
	if (lastFrame < ExhaleFrame && frame >= ExhaleFrame)
		Exhale();
	lastFrame = frame;
}

function Destroyed()
{
	if (wisp != None)
		wisp.DelayedDestroy();
	if (puff != None)
		puff.DelayedDestroy();
	Super.Destroyed();
}
defaultproperties
{
	ExhaleFrame=40.000000
}
