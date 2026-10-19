//=============================================================================
// UCNpcUse - a character of the map goes and uses an object (an interaction of the map editor: "Go and
// use an object", UCLink's npcuse). UCLink spawns it: the character walks there with the game's own AI
// (orders GoingTo a mark beside the object, on the side nearest to him that has floor and no wall), then
// faces the object and stays crouched (or standing) for the seconds of the use, then the interactions
// "When a character has used it" of the object run (UCL_<object>_Npc) and he stands there.
// If something takes him away (he fights, he is hit) the use waits; it goes on when the game gives him
// back to his orders (it starts again from where it was). New orders, his death, or a way he cannot find
// end it. Everything lives in this actor (saved with the game); the mark is made again after a load.
//=============================================================================
class UCNpcUse extends UCEditorStory;

var string Who;             // the character (his name in the map)
var string What;            // the object
var float  Secs;            // seconds of the use
var bool   bCrouch;
var int    Phase;           // 0 walking, 1 using, 2 over
var vector Spot;            // where he stands to use it
var float  useLeft;            // seconds of the use left
var float  bestDist;        // the nearest he has come (a way he cannot find: no progress)
var float  stuckT;          // seconds with no progress
var float  checkT;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0, False);
}

function Actor Called(string s)
{
	local Actor A;

	if (s == "")
		return None;
	foreach AllActors(class'Actor', A)
		if (string(A.Name) ~= s && !A.bDeleteMe)
			return A;
	return None;
}

function ScriptedPawn Guy()
{
	local ScriptedPawn sp;

	sp = ScriptedPawn(Called(Who));
	if (sp == None || sp.Health <= 0 || sp.bDeleteMe)
		return None;
	return sp;
}

function name MarkTag()
{
	return StringToName("UCEdUse_" $ Who);
}

// Beside the object, on the side nearest to the character: a free spot with floor under it and nothing
// solid between it and the object (eight directions round it).
function vector UseSpot(ScriptedPawn sp, Actor A)
{
	local vector dir, cand, best, hitLoc, hitNormal, onFloor;
	local float r, d, bestD;
	local int i;

	r = A.CollisionRadius + sp.CollisionRadius + 8;
	bestD = 1000000;
	best = A.Location + Normal((sp.Location - A.Location) * vect(1,1,0)) * r;
	for (i = 0; i < 8; i++)
	{
		dir.X = Cos(i * 0.785398);
		dir.Y = Sin(i * 0.785398);
		dir.Z = 0;
		cand = A.Location + dir * r;
		cand.Z = A.Location.Z;
		if (!FastTrace(cand, A.Location))
			continue;
		if (Trace(hitLoc, hitNormal, cand - vect(0,0,400), cand, False) == None)
			continue;
		onFloor = hitLoc + vect(0,0,1) * sp.CollisionHeight;
		if (!FastTrace(onFloor, cand))
			continue;
		d = VSize(sp.Location - onFloor);
		if (d < bestD)
		{
			bestD = d;
			best = onFloor;
		}
	}
	if (bestD >= 1000000 && Trace(hitLoc, hitNormal, best - vect(0,0,400), best, False) != None)
		best = hitLoc + vect(0,0,1) * sp.CollisionHeight;
	return best;
}

function Go()
{
	local ScriptedPawn sp;
	local Actor A;
	local UCMark mark;
	local name t;

	sp = Guy();
	A = Called(What);
	if (sp == None || A == None)
	{
		Log("UCNpcUse" @ Who @ "- cannot use" @ What @ "(not in the map)");
		Over(False);
		return;
	}
	t = MarkTag();
	if (Spot == vect(0,0,0))
		Spot = UseSpot(sp, A);
	foreach AllActors(class'UCMark', mark, t)
		mark.Destroy();
	Spawn(class'UCMark',, t, Spot);
	bestDist = VSize(sp.Location - Spot);
	stuckT = 0;
	if (sp.bInWorld)
		sp.SetOrders('GoingTo', t, True);
	Log("UCNpcUse" @ Who @ "- goes to use" @ What @ "at" @ Spot);
}

function bool Mine(ScriptedPawn sp)
{
	return sp.Orders == 'GoingTo' && sp.OrderTag == MarkTag();
}

function bool There(ScriptedPawn sp)
{
	return VSize((sp.Location - Spot) * vect(1,1,0)) <= sp.CollisionRadius + 32 && Abs(sp.Location.Z - Spot.Z) < 80;
}

function Pose(ScriptedPawn sp, Actor A)
{
	local rotator r;

	sp.Acceleration = vect(0,0,0);
	r = rotator(A.Location - sp.Location);
	r.Pitch = 0;
	r.Roll = 0;
	sp.DesiredRotation = r;
	if (bCrouch && sp.AnimSequence != 'CrouchShoot' && sp.HasAnim('CrouchShoot'))
		sp.TweenToCrouchShoot(0.3);
}

function Over(bool bDone)
{
	local ScriptedPawn sp;
	local UCMark mark;
	local name t;

	Phase = 2;
	t = MarkTag();
	if (t != '')
		foreach AllActors(class'UCMark', mark, t)
			mark.Destroy();
	sp = Guy();
	if (bDone)
	{
		Log("UCNpcUse" @ Who @ "- has used" @ What);
		if (sp != None && Mine(sp))
			sp.SetOrders('Standing', '', True);
		TriggerTag(StringToName("UCL_" $ What $ "_Npc"));
	}
	Destroy();
}

function Tick(float deltaTime)
{
	local ScriptedPawn sp;
	local Actor A;
	local UCMark mark;
	local bool bMark;
	local float d;

	Super.Tick(deltaTime);
	if (Phase >= 2 || Plr() == None || Plr().rootWindow == None)
		return;
	if (Spot == vect(0,0,0))
	{
		Go();
		return;
	}
	sp = Guy();
	A = Called(What);
	if (sp == None || A == None)
	{
		Log("UCNpcUse" @ Who @ "- the use of" @ What @ "is over: he or the object is gone");
		Over(False);
		return;
	}
	if (!Mine(sp))
	{
		Log("UCNpcUse" @ Who @ "- has other orders (" $ sp.Orders $ "): no use of" @ What);
		Over(False);
		return;
	}
	checkT += deltaTime;
	if (checkT >= 0.5)              // after a load the mark (transient) is gone: made again
	{
		checkT = 0;
		foreach AllActors(class'UCMark', mark, MarkTag())
			bMark = True;
		if (!bMark)
		{
			Go();
			return;
		}
	}
	if (Phase == 0)
	{
		if (There(sp) && (sp.IsInState('Standing') || VSize(sp.Velocity) < 20))
		{
			Phase = 1;
			if (useLeft <= 0)
				useLeft = FMax(0.1, Secs);
			Log("UCNpcUse" @ Who @ "- at" @ What @ "," @ useLeft @ "s");
			return;
		}
		d = VSize(sp.Location - Spot);
		if (d < bestDist - 16)
		{
			bestDist = d;
			stuckT = 0;
		}
		else if (sp.IsInState('Standing') || sp.IsInState('GoingTo'))
		{
			stuckT += deltaTime;
			if (stuckT > 20)
			{
				Log("UCNpcUse" @ Who @ "- cannot reach" @ What);
				Over(False);
			}
		}
		return;
	}
	// using it: only while he is there and standing (fighting, hit: it waits)
	if (!There(sp))
	{
		Phase = 0;
		return;
	}
	if (!sp.IsInState('Standing'))
		return;
	Pose(sp, A);
	useLeft -= deltaTime;
	if (useLeft <= 0)
		Over(True);
}

defaultproperties
{
     Secs=3.000000
     bCrouch=True
     bRouteOnly=False
}
