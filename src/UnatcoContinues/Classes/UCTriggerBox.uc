//=============================================================================
// UCTriggerBox - a box or upright cylinder: when JC (or anyone, bAnyPawn) walks into the volume it
// triggers its Event, and untriggers it when he leaves (the interactions "JC walks in" / "JC walks out").
// Unreal's actors only collide as cylinders: the box is checked every frame (the cylinder of the pawn
// against the box, BoxX/BoxY/BoxZ = half its width, depth and height, round the actor).
// bSolidBox: the editor also builds an invisible solid brush of the same size (an invisible wall): then
// "walks in" means that JC touches it.
//=============================================================================
class UCTriggerBox extends Trigger;

var() float BoxX, BoxY, BoxZ;
var() bool  bCylinder;
var() float CylinderRadius, CylinderHeight;
var() bool  bSolidBox;
var() bool  bAnyPawn;
var bool  bInside, bSpent;
var Pawn  Who;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetCollision(False, False, False);         // the box does the work, not the cylinder
}

function bool InBox(Pawn P)
{
	local vector d;
	local float m, k, r;

	if (P == None || P.Health <= 0 || P.bHidden)
		return False;
	m = 1;
	if (bSolidBox)
		m = 6;                                  // against an invisible wall: touching it
	d = P.Location - Location;
	k = FMax(0.01, DrawScale);
	if (bCylinder)
	{
		r = FMax(2, CylinderRadius) * k + P.CollisionRadius + m;
		return d.X * d.X + d.Y * d.Y <= r * r
			&& Abs(d.Z) <= FMax(2, CylinderHeight) * k + P.CollisionHeight + m;
	}
	return Abs(d.X) <= FMax(2, BoxX) * k + P.CollisionRadius + m && Abs(d.Y) <= FMax(2, BoxY) * k + P.CollisionRadius + m
		&& Abs(d.Z) <= FMax(2, BoxZ) * k + P.CollisionHeight + m;
}

// a cutscene of the editor is playing (UCCutscene): JC is an invisible camera, nothing changes
function bool InCutscene()
{
	local Pawn Pl;

	Pl = GetPlayerPawn();
	return Pl != None && Pl.bHidden && Pl.IsInState('Interpolating');
}

function Pawn Inside()
{
	local Pawn P;

	if (!bAnyPawn)
	{
		P = Level.PawnList;
		for (P = Level.PawnList; P != None; P = P.nextPawn)
			if (P.IsA('PlayerPawn') && InBox(P))
				return P;
		return None;
	}
	for (P = Level.PawnList; P != None; P = P.nextPawn)
		if (InBox(P))
			return P;
	return None;
}

function Tick(float dt)
{
	local Pawn P;
	local Actor A;

	if (bSpent || InCutscene())
		return;
	P = Inside();
	if (P != None && !bInside)
	{
		if (ReTriggerDelay > 0 && Level.TimeSeconds - TriggerTime < ReTriggerDelay)
			return;
		TriggerTime = Level.TimeSeconds;
		bInside = True;
		Who = P;
		Log("UCTriggerBox" @ Name @ "- in:" @ P.Name);
		if (Message != "" && P.IsA('PlayerPawn'))
			P.ClientMessage(Message);
		if (Event != '')
			foreach AllActors(class'Actor', A, Event)
				A.Trigger(Self, P);
	}
	else if (P == None && bInside)
	{
		bInside = False;
		Log("UCTriggerBox" @ Name @ "- out");
		if (Event != '')
			foreach AllActors(class'Actor', A, Event)
				A.UnTrigger(Self, Who);
		if (bTriggerOnceOnly)
			bSpent = True;
	}
}

// triggered by something else: as a Trigger, it passes it on
function Trigger(Actor Other, Pawn EventInstigator)
{
}

defaultproperties
{
     BoxX=64.000000
     BoxY=64.000000
     BoxZ=64.000000
     bCylinder=False
     CylinderRadius=64.000000
     CylinderHeight=64.000000
     bCollideActors=False
}
