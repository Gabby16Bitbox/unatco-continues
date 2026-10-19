//=============================================================================
// UCHBCharge - a Luminous Path charge on the door of one of the refrigerated containers in the garage of
// Harbourline Tower (Mission 6, 06_HongKong_WanChai_Rooftop; plan 5.3). The map places one, hidden, on
// the door of containers 2, 4 and 6 (container = the number). A planter of the Path arms it (Arm): it
// shows up (a LAM's body a little larger, its lit skin drawn unlit: it reads on the dark door), a small red
// light blinks and it beeps like a LAM (faster as the time runs out) and counts its fuse down. JC defuses it
// by clicking it: its collision (10 x 8) stands out of the door, so the crosshair's trace (DeusExPlayer.
// HighlightCenterObject: the first mover hit wins) finds it before the door behind it. If the time runs out
// it blows: the container's door goes (UCHBReefer<N>Door), the cold mist pours out (UCHBReefer<N>Mist), the
// vent keeps hissing; nothing says what was inside.
// Bullets, blasts and EMP do nothing to it (bInvincible); it can't be picked up or pushed.
// Everything lives in the actor (saved with the game): armed, seconds left, defused, blown.
// Flags (expiration 99): UC_HB_Charge<N>Planted, UC_HB_Charge<N>Defused, UC_HB_Container<N>Blew and
// UC_HB_ContainerBlew. The HUD's countdown is UCSceneHarbourline's (ChargeTick).
//=============================================================================
class UCHBCharge extends DeusExDecoration;

var() int container;        // the container's number: 2, 4 or 6
var() float fuse;           // seconds from Arm() to the blast
var bool bArmed;            // a planter has armed it
var bool bDefused;          // JC defused it
var bool bBlown;            // the time ran out
var float fuseLeft;         // seconds left while armed
var float beepT;            // seconds since the last beep
var float armedFor;         // seconds since it was armed (UCSceneHarbourline's barks)

function bool IsArmed()
{
	return bArmed && !bDefused && !bBlown;
}

// The flags of this charge (literal names, as the narrative manifest lists them): 0 planted, 1 defused,
// 2 its container blew.
function name ChargeFlag(int kind)
{
	switch (container * 10 + kind)
	{
		case 20: return 'UC_HB_Charge2Planted';
		case 21: return 'UC_HB_Charge2Defused';
		case 22: return 'UC_HB_Container2Blew';
		case 40: return 'UC_HB_Charge4Planted';
		case 41: return 'UC_HB_Charge4Defused';
		case 42: return 'UC_HB_Container4Blew';
		case 60: return 'UC_HB_Charge6Planted';
		case 61: return 'UC_HB_Charge6Defused';
		case 62: return 'UC_HB_Container6Blew';
	}
	return '';
}

function name ReeferDoorTag()
{
	switch (container)
	{
		case 2: return 'UCHBReefer2Door';
		case 4: return 'UCHBReefer4Door';
		case 6: return 'UCHBReefer6Door';
	}
	return '';
}

function name ReeferMistTag()
{
	switch (container)
	{
		case 2: return 'UCHBReefer2Mist';
		case 4: return 'UCHBReefer4Mist';
		case 6: return 'UCHBReefer6Mist';
	}
	return '';
}

function SetFlag(name flagName)
{
	local DeusExPlayer P;

	P = DeusExPlayer(GetPlayerPawn());
	if (flagName != '' && P != None && P.FlagBase != None)
		P.FlagBase.SetBool(flagName, True,, 99);
}

// A planter has set it: it shows up on the door and the countdown starts (seconds: a fuse of its own,
// 0 = the map's fuse).
function Arm(optional float seconds)
{
	if (bArmed || bDefused || bBlown)
		return;
	bArmed = True;
	fuseLeft = fuse;
	if (seconds > 0)
		fuseLeft = seconds;
	beepT = 0;
	bHidden = False;
	SetCollision(True, False, False);       // JC can click it, nobody bumps into it
	Skin = Texture'LAM3rdTex1';             // steady: the light blinks (Tick)
	bUnlit = True;
	LightType = LT_Steady;
	SetFlag(ChargeFlag(0));
	PlaySound(Sound'DeusExSounds.Generic.Beep4', SLOT_None, 1.0,, 1280);
	Log("UCHBCharge: the charge on container" @ container @ "is armed," @ fuseLeft @ "s");
}

// JC clicks it while it counts down: defused, the light goes out, it stays on the door.
function Frob(Actor Frobber, Inventory frobWith)
{
	if (IsArmed() && DeusExPlayer(Frobber) != None)
		Defuse(DeusExPlayer(Frobber));
}

function Defuse(DeusExPlayer P)
{
	if (!IsArmed())
		return;
	bDefused = True;
	Skin = Texture'BlackMaskTex';
	bUnlit = False;
	LightType = LT_None;
	SetCollision(False, False, False);
	PlaySound(Sound'DeusExSounds.Generic.Beep3', SLOT_None, 1.5,, 1024);
	if (P != None)
		P.ClientMessage("Charge on container" @ container @ "defused.");
	SetFlag(ChargeFlag(1));
	Log("UCHBCharge: the charge on container" @ container @ "is defused," @ fuseLeft @ "s left");
}

// The time ran out: a small blast (it hurts who stands by it; Kwan nothing, UCHBKwan), the container's
// door torn off, the cold mist and the hiss of the vent (this actor, hidden, keeps it).
function Blow()
{
	local DeusExMover door;
	local ParticleGenerator gen;
	local UCEffectPoint pt;
	local UCEffect fx;
	local Actor A;
	local DeusExPlayer P;
	local Sound hiss;
	local name dTag, mTag;

	if (bBlown)
		return;
	bBlown = True;
	fuseLeft = 0;
	Spawn(class'ExplosionMedium',,, Location);
	Spawn(class'ExplosionLight',,, Location);
	PlaySound(Sound'DeusExSounds.Weapons.LAMExplode', SLOT_None, 2.0,, 2048);
	bHidden = True;
	LightType = LT_None;
	SetCollision(False, False, False);
	HurtRadius(40, 200, 'Exploded', 5000, Location);
	dTag = ReeferDoorTag();
	mTag = ReeferMistTag();
	if (dTag != '')
		foreach AllActors(class'DeusExMover', door, dTag)
			if (!door.bDestroyed)
			{
				door.FragmentClass = class'MetalFragment';
				door.NumFragments = 10;
				door.FragmentSpread = 40;
				door.FragmentScale = 1.2;
				door.bDrawExplosion = True;
				door.BlowItUp(None);
			}
	if (mTag != '')
	{
		foreach AllActors(class'ParticleGenerator', gen, mTag)
			if (!gen.bSpewing)
				gen.Trigger(Self, None);
		// the mist from the map editor's Effect Points with that Tag: along their arrows, until stopped
		foreach AllActors(class'UCEffectPoint', pt, mTag)
		{
			fx = Spawn(class'UCEffect',,, pt.Location);
			if (fx != None)
			{
				fx.Target = string(pt.Name);
				fx.StartEffect("mist", 0, "");
			}
		}
	}
	// what an Interactions rule of the editor hooked on this charge ("whatever it triggers") does
	if (Event != '')
		foreach AllActors(class'Actor', A, Event)
			A.Trigger(Self, None);
	hiss = Sound(DynamicLoadObject("Ambient.Ambient.SteamVent", class'Sound', True));
	if (hiss != None)
	{
		AmbientSound = hiss;
		SoundRadius = 40;
		SoundVolume = 200;
	}
	SetFlag(ChargeFlag(2));
	SetFlag('UC_HB_ContainerBlew');
	P = DeusExPlayer(GetPlayerPawn());
	if (P != None && VSize(P.Location - Location) < 900)
		P.ShakeView(0.5, 300, 12);
	Log("UCHBCharge: container" @ container @ "blew");
}

// Its light blinks and it beeps like a LAM, faster as the time runs out.
simulated function Tick(float deltaTime)
{
	local float rate;

	Super.Tick(deltaTime);
	if (!IsArmed())
		return;
	armedFor += deltaTime;
	fuseLeft -= deltaTime;
	if (fuseLeft <= 0)
	{
		Blow();
		return;
	}
	if (fuseLeft <= 0.75)
		rate = 0.1;
	else if (fuseLeft <= 10)
		rate = 0.3;
	else if (fuseLeft <= 20)
		rate = 0.5;
	else
		rate = 1.0;
	if (fuseLeft % rate > rate * 0.5)
		LightType = LT_None;
	else
		LightType = LT_Steady;
	beepT += deltaTime;
	if (beepT >= rate)
	{
		beepT = 0;
		PlaySound(Sound'DeusExSounds.Generic.Beep4', SLOT_None, 0.5,, 1280);
	}
}

defaultproperties
{
     container=2
     fuse=45.000000
     bInvincible=True
     bPushable=False
     bHighlight=True
     bFlammable=False
     bExplosive=False
     bCanBeBase=False
     HitPoints=100
     ItemName="Explosive charge"
     ItemArticle="an"
     bTravel=False
     bHidden=True
     Physics=PHYS_None
     Mesh=LodMesh'DeusExItems.LAMPickup'
     Skin=Texture'DeusExItems.Skins.BlackMaskTex'
     DrawScale=1.500000
     LightType=LT_None
     LightEffect=LE_NonIncidence
     LightBrightness=220
     LightHue=0
     LightSaturation=32
     LightRadius=2
     CollisionRadius=10.000000
     CollisionHeight=8.000000
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
     Mass=5.000000
     Buoyancy=2.000000
}
