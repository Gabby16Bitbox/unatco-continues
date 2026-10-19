//=============================================================================
// UCNavRoute - a character walking a route of the walkable area (UCNavMesh), corner after corner (Gabby,
// 17 Oct 2026). The character has the game's own orders, GoingTo or RunningTo, towards a UCMark: the mark
// goes on to the next corner just before the character gets to it, so it walks the whole way without
// stopping. The game moves straight to a mark it can reach, without path nodes. On the last leg the route
// ends and the game's GoingTo takes the character to the place, as an editor "Walk to a place" always did
// (UCLink.Arrived: "they get where they were sent").
//
// Stopped short of a corner (the game's GoingTo stops at its mark), it is sent on again. Stuck for a few
// seconds (Stuck): a door in the way is opened, as the characters do; otherwise the route is made again
// from where the character is (pushed off it, backing off from a corner); at last the game's own way.
// Tested in Battery Park on 18 Oct 2026: a trooper walked some 4500 units across the park without path nodes.
//=============================================================================
class UCNavRoute extends Info
	transient;

var ScriptedPawn Who;
var UCMark Mark;
var name MarkTag, Orders;
var vector Spot;
var vector Corner[64];
var int NumCorners, Next, DoorTries, Replans;
var float Stalled, Closest;

// Sends sp to spot on the walkable area (bRun: running), with the orders to the mark markTag (the editor's
// "Walk to a place" uses UCEdGo_<name>, so that "they get where they were sent" works as before). False: no
// walkable area in the map or no way on it, nothing done (send them the old way).
static function bool Send(ScriptedPawn sp, vector spot, bool bRun, optional name markTag)
{
	local UCNavMesh M;
	local UCNavRoute R;
	local UCMark old;
	local DeusExPlayer P;

	if (sp == None || sp.Health <= 0)
		return False;
	M = class'UCNavMesh'.static.Of(sp);
	if (M == None || !M.Route(sp.Location - vect(0,0,1) * sp.CollisionHeight, spot - vect(0,0,1) * sp.CollisionHeight))
		return False;
	if (markTag == '')
	{
		P = DeusExPlayer(sp.GetPlayerPawn());
		if (P != None && P.rootWindow != None)
			markTag = P.rootWindow.StringToName("UCNav_" $ sp.Name);
		if (markTag == '')
			markTag = 'UCNavMark';
	}
	foreach sp.AllActors(class'UCNavRoute', R)
		if (R.Who == sp)
			R.Destroy();
	foreach sp.AllActors(class'UCMark', old, markTag)
		old.Destroy();
	R = sp.Spawn(class'UCNavRoute', sp,, sp.Location);
	if (R == None)
		return False;
	R.Who = sp;
	R.MarkTag = markTag;
	R.Spot = spot;
	R.TakeRoute(M);
	R.Mark = sp.Spawn(class'UCMark',, markTag, R.CornerAt(0));
	if (R.Mark == None)
	{
		R.Destroy();
		return False;
	}
	if (bRun)
		R.Orders = 'RunningTo';
	else
		R.Orders = 'GoingTo';
	sp.Log("UCNav:" @ sp.Name @ "goes to" @ spot @ "through" @ R.NumCorners @ "points, running" @ bRun);
	sp.SetOrders(R.Orders, markTag, True);
	return True;
}

// The corners of M's last route, where the character's centre goes; the long legs in pieces, because the
// game's own test "can I walk straight there" (GoingTo's ActorReachable) says no beyond 1000 units.
function TakeRoute(UCNavMesh M)
{
	local int i, k, n, parts;
	local vector c, prev;

	prev = Who.Location - vect(0,0,1) * Who.CollisionHeight;
	for (i = 0; i < M.NumCorners && n < 64; i++)
	{
		c = M.CornerAt(i);
		parts = int(VSize((c - prev) * vect(1,1,0)) / 600) + 1;
		for (k = 1; k < parts && n < 63; k++)
		{
			Corner[n] = prev + (c - prev) * (float(k) / float(parts)) + vect(0,0,1) * Who.CollisionHeight;
			n++;
		}
		Corner[n] = c + vect(0,0,1) * Who.CollisionHeight;
		n++;
		prev = c;
	}
	NumCorners = n;
	Corner[n - 1] = Spot;
	Next = 0;
	DoorTries = 0;
	Stalled = 0;
	Closest = 1000000;
}

// (an array this big cannot be reached from another object's code: this does it)
function vector CornerAt(int i)
{
	return Corner[i];
}

// still on the way (not on the last leg yet)
function bool OnTheWay()
{
	return Next < NumCorners - 1;
}

function Advance()
{
	Next++;
	DoorTries = 0;
	Stalled = 0;
	Closest = 1000000;
	Mark.SetLocation(Corner[Next]);
}

// No nearer to the corner for 3 seconds (something in the way the walkable area does not know, or the game
// backed the character off a wall corner): see the comment at the top.
function Stuck()
{
	local Actor hit;
	local vector hitLoc, hitNormal;
	local UCNavMesh M;

	Stalled = 0;
	Closest = 1000000;
	hit = Who.Trace(hitLoc, hitNormal, Corner[Next], Who.Location, True);
	if (DeusExMover(hit) != None && Who.IsDoor(hit) && DoorTries < 3)
	{
		DoorTries++;
		Log("UCNav:" @ Who.Name @ "opens" @ hit.Name);
		Who.CheckOpenDoor(hitNormal, hit);          // then back to GoingTo, where it was
		return;
	}
	M = class'UCNavMesh'.static.Of(Who);
	if (Replans < 4 && M != None && M.Route(Who.Location - vect(0,0,1) * Who.CollisionHeight, Spot - vect(0,0,1) * Who.CollisionHeight))
	{
		Replans++;
		TakeRoute(M);
		Log("UCNav:" @ Who.Name @ "held up at" @ Who.Location @ ": the way again from there," @ NumCorners @ "points");
		Mark.SetLocation(Corner[0]);
		Who.SetOrders(Orders, MarkTag, True);
		return;
	}
	Log("UCNav:" @ Who.Name @ "stuck at" @ Who.Location @ ": the game's own way");
	Mark.SetLocation(Spot);
	Destroy();
}

function Tick(float deltaTime)
{
	local float dist;

	if (Who == None || Who.Health <= 0 || Mark == None || Who.OrderTag != MarkTag || Who.Orders != Orders)
	{
		Destroy();                              // new orders, gone, dead: the route is over
		return;
	}
	if (!OnTheWay())
	{
		Destroy();                              // the last leg: the game's GoingTo / RunningTo ends there
		return;
	}
	dist = VSize((Corner[Next] - Who.Location) * vect(1,1,0));
	if (dist < Who.CollisionRadius + 64 && Abs(Corner[Next].Z - Who.Location.Z) < 120)
	{
		Advance();
		return;
	}
	if (Who.IsInState(Orders))
	{
		if (dist < Closest - 8)
		{
			Closest = dist;
			Stalled = 0;
		}
		else
			Stalled += deltaTime;
		if (Stalled > 3)
			Stuck();
	}
	else if (Who.IsInState('Standing'))
	{
		Stalled += deltaTime;
		if (Stalled > 0.5)                      // stopped at the mark short of the corner: on again
		{
			Stalled = 0;
			Who.SetOrders(Orders, MarkTag, True);
		}
	}
	else
		Stalled = 0;                            // talking, fighting, scared, backing off: the route waits
}

defaultproperties
{
     bHidden=True
}
