//=============================================================================
// UCEffect - an effect on an object of the map, made by an interaction of the map editor ("An effect on
// it", UCLink's effect): the game's own effects, attached to the object (they follow it when it moves).
//   mist       cold mist pouring out low (the steam vents' ParticleGenerator, with their hiss)
//   smoke      smoke rising from its top (as a leaking barrel)
//   sparks     sparks with their crackle (as an object hit by an EMP)
//   fire       flames, smoke and their light (the game's Fire, as a burning body)
//   blinklight a small light blinking (faster as its time runs out, when it has one), optionally beeping
//   pulse      a light pulsing slowly
// On an effect point (UCEffectPoint) the effect sits exactly on the point and goes along its arrow (its
// rotation); with the option "exact" (in the action's colour field) it sits exactly on the object, without
// the offsets above (not lowered to the floor, not on top), going the way it always goes.
// Seconds 0: until an action stops it ("Stop its effects"); a new effect of the same kind on the same
// object takes the place of the old one. This actor is the light of blinklight and pulse; it owns the
// generators of the others and takes them away with it. Saved with the game.
//=============================================================================
class UCEffect extends Light;

var string Target;          // the object
var string Kind;
var float  Life;            // seconds left (0 = until stopped)
var bool   bTimed;
var bool   bBeep;
var byte   Hue, Sat;
var ParticleGenerator Gen;
var Fire   Flames;
var float  blinkT, beepT;
var bool   bStarted;
var bool   bPoint;          // on an effect point: exactly there, blown along its arrow
var bool   bExact;          // exactly on the object (no offsets)

function Actor Obj()
{
	local Actor A;

	if (Target == "")
		return None;
	foreach AllActors(class'Actor', A)
		if (string(A.Name) ~= Target && !A.bDeleteMe)
			return A;
	return None;
}

// the colour of a light effect, by name (red by default)
function SetColour(string c)
{
	Sat = 0;
	if (InStr(c, "GREEN") >= 0)
		Hue = 85;
	else if (InStr(c, "BLUE") >= 0)
		Hue = 160;
	else if (InStr(c, "YELLOW") >= 0)
		Hue = 36;
	else if (InStr(c, "ORANGE") >= 0)
		Hue = 20;
	else if (InStr(c, "WHITE") >= 0)
	{
		Hue = 0;
		Sat = 255;
	}
	else
		Hue = 0;
	bBeep = InStr(c, "BEEP") >= 0;
}

// size of the object (a barrel 1): the effects grow with it
function float SizeOf(Actor A)
{
	return FClamp(A.CollisionRadius / 30.0, 0.4, 4.0);
}

// Where the effect goes: the object, or where a door (a mover) stands shut (a blown mover is moved far away).
function vector Spot(Actor A)
{
	if (Mover(A) != None)
		return Mover(A).BasePos;
	return A.Location;
}

function StartEffect(string newKind, float secs, string opts)
{
	local Actor A;
	local vector loc;
	local float size;
	local Sound snd;
	local rotator r;
	local vector hitLoc, hitNormal, at;

	A = Obj();
	if (A == None)
	{
		Log("UCEffect - its object" @ Target @ "is not in the map");
		Destroy();
		return;
	}
	Kind = Caps(newKind);
	Life = secs;
	bTimed = secs > 0;
	SetColour(Caps(opts));
	bPoint = UCEffectPoint(A) != None;
	bExact = bPoint || InStr(Caps(opts), "EXACT") >= 0;
	size = SizeOf(A);
	if (bPoint)
		size = 1.0;                             // (a point has no size: the size of a barrel's)
	at = Spot(A);
	SetLocation(at);
	if (Mover(A) == None)
		SetBase(A);                             // (it follows the object; a door is left where it was)
	LightType = LT_None;
	if (Kind == "MIST")
	{
		loc = at;                               // low: a little above the floor under the object
		if (!bExact)
		{
			if (Trace(hitLoc, hitNormal, loc - vect(0,0,600), loc, False) != None)
				loc.Z = FMin(loc.Z, hitLoc.Z + 24);
			else
				loc.Z -= A.CollisionHeight * 0.6;
		}
		r = A.Rotation;
		if (!bPoint)
			r.Pitch -= 1500;
		Gen = Spawn(class'ParticleGenerator', Self,, loc, r);
		if (Gen != None)
		{
			Gen.particleTexture = Texture'Effects.Smoke.SmokePuff1';
			Gen.riseRate = -4;
			Gen.ejectSpeed = 70;
			Gen.particleLifeSpan = 3;
			Gen.particleDrawScale = 0.5 * size;
			Gen.checkTime = 0.08;
			Gen.numPerSpawn = 2;
			Gen.bRandomEject = True;
			if (bPoint)                         // a jet along the arrow
				Gen.ejectSpeed = 110;
		}
		snd = Sound(DynamicLoadObject("Ambient.Ambient.SteamVent", class'Sound', True));
	}
	else if (Kind == "SMOKE")
	{
		loc = at;
		if (!bExact)
			loc += vect(0,0,1) * A.CollisionHeight;
		r = rot(16384,0,0);
		if (bPoint)
			r = A.Rotation;
		Gen = Spawn(class'ParticleGenerator', Self,, loc, r);
		if (Gen != None)
		{
			Gen.particleTexture = Texture'Effects.Smoke.SmokePuff1';
			Gen.particleDrawScale = 1.5 * size;
			Gen.frequency = 0.9;
			Gen.checkTime = 0.12;
			Gen.riseRate = 90;
			Gen.ejectSpeed = 40;
			Gen.bRandomEject = True;
			if (bPoint)
			{
				Gen.ejectSpeed = 90;
				Gen.riseRate = 40;
			}
		}
	}
	else if (Kind == "SPARKS")
	{
		loc = at;
		r = rot(16384,0,0);
		if (bPoint)
			r = A.Rotation;
		Gen = Spawn(class'ParticleGenerator', Self,, loc, r);
		if (Gen != None)
		{
			Gen.particleTexture = Texture'Effects.Fire.SparkFX1';
			Gen.particleDrawScale = 0.1;
			Gen.bRandomEject = True;
			Gen.ejectSpeed = 120;
			Gen.bGravity = True;
			Gen.bParticlesUnlit = True;
			Gen.frequency = 0.6;
			Gen.checkTime = 0.25;
			Gen.numPerSpawn = 6;
			Gen.particleLifeSpan = 1.2;
			Gen.riseRate = 10;
			Gen.spawnSound = Sound(DynamicLoadObject("DeusExSounds.Generic.Spark2", class'Sound', True));
			if (bPoint)
				Gen.ejectSpeed = 200;
		}
	}
	else if (Kind == "FIRE")
	{
		loc = at;
		if (!bExact)
			loc += vect(0,0,1) * (A.CollisionHeight * 0.5);
		Flames = Spawn(class'Fire', Self,, loc);
		if (Flames != None)
		{
			Flames.DrawScale = size;
			Flames.AddFire(1.5);
			if (bPoint && Flames.fireGen != None)  // its flames blown along the arrow (a burst gas pipe)
			{
				Flames.fireGen.SetRotation(A.Rotation);
				Flames.fireGen.ejectSpeed = 160;
				Flames.fireGen.riseRate = 10;
				Flames.fireGen.particleLifeSpan = 0.8;
			}
		}
	}
	else if (Kind == "BLINKLIGHT" || Kind == "PULSE")
	{
		LightType = LT_Steady;
		if (Kind == "PULSE")
			LightType = LT_Pulse;
		LightEffect = LE_NonIncidence;
		LightBrightness = 255;
		LightHue = Hue;
		LightSaturation = Sat;
		LightRadius = Clamp(int(3 + size * 2), 3, 16);
		LightPeriod = 32;
	}
	else
	{
		Log("UCEffect - no effect called" @ newKind);
		Destroy();
		return;
	}
	if (Gen != None)
		Gen.SetBase(Self);
	if (snd != None)
	{
		AmbientSound = snd;
		SoundRadius = 40;
		SoundVolume = 200;
	}
	bStarted = True;
	Log("UCEffect" @ Name @ "-" @ Kind @ "on" @ Target @ "for" @ secs @ "s (0: until stopped)" @ Gen @ Flames @ "at" @ loc
		@ "point" @ bPoint @ "exact" @ bExact @ "rot" @ r);
}

// blink: faster as the end comes (a timed one), like a LAM
function float BlinkRate()
{
	if (!bTimed || Life > 20)
		return 1.0;
	if (Life > 10)
		return 0.5;
	if (Life > 0.75)
		return 0.3;
	return 0.1;
}

function Tick(float deltaTime)
{
	local float rate;

	Super.Tick(deltaTime);
	if (!bStarted)
		return;
	if (Obj() == None && Flames == None && Gen == None && Kind != "BLINKLIGHT" && Kind != "PULSE")
	{
		Destroy();
		return;
	}
	// The game's generators freeze when they were not drawn for 2 s and JC is not within 320 units (a
	// new one, never drawn, would never start): one of ours is kept awake while JC is in its area.
	if (Gen != None && Gen.proxy != None && GetPlayerPawn() != None && VSize(GetPlayerPawn().Location - Gen.Location) < 4000)
		Gen.proxy.LastRenderTime = Level.TimeSeconds;
	if (bTimed)
	{
		Life -= deltaTime;
		if (Life <= 0)
		{
			Log("UCEffect" @ Name @ "-" @ Kind @ "on" @ Target @ "is over");
			Destroy();
			return;
		}
	}
	if (Kind == "BLINKLIGHT")
	{
		rate = BlinkRate();
		blinkT += deltaTime;
		if (blinkT >= rate)
			blinkT = 0;
		if (blinkT < rate * 0.5)
			LightType = LT_Steady;
		else
			LightType = LT_None;
		if (bBeep)
		{
			beepT += deltaTime;
			if (beepT >= rate)
			{
				beepT = 0;
				PlaySound(Sound'DeusExSounds.Generic.Beep4', SLOT_None, 0.5,, 1280);
			}
		}
	}
}

function Destroyed()
{
	if (Gen != None)
		Gen.DelayedDestroy();
	if (Flames != None)
		Flames.Destroy();
	Gen = None;
	Flames = None;
	Super.Destroyed();
}

defaultproperties
{
     bStatic=False
     bNoDelete=False
     bMovable=True
     LightType=LT_None
     LightRadius=4
}
