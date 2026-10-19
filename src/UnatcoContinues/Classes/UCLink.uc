//=============================================================================
// UCLink - an interaction made in the map editor (Properties > Interactions): "when this
// happens to an object, do these things". No Tag or Event to write by hand: the link hooks
// itself to its object when the map starts (it takes the object's Event, keeping the event
// the object had: that one is triggered too), then runs its actions, each after its delay.
//
//   When     opened (has opened), closed (starts closing), destroyed (a door), leave (JC walks out of a
//            trigger), animdone (the object's animation has finished), used (a button, any object JC uses), code,
//            wrongcode (a keypad), option (a computer's special option), enter (a trigger zone),
//            laser, alarm, dies (a character: killed or knocked out), any (whatever the object
//            triggers), picked (an item JC picks up), gone (an object destroyed), near (JC comes
//            within NearDist), start (the map starts: no object), npcused (a character has used the
//            object: UCNpcUse), finished / stopped (a timer, UCTimer, ran out / was stopped), arrived (a
//            character sent with goto/run is there). "used" on an object made usable (UCUsable): when JC
//            has finished using it (its UCUsable triggers the link, the link hooks nothing)
//   Act[i]   "delay|verb|target|a|b|c" (see DoAct)
//
// Every link of an object shares the Tag UCL_<object> (UCL_<object>_Fail for a keypad's wrong
// code, UCL_<object>_Opt<n> for a computer's option); the editor makes them (editor\links.py).
// It logs "UCLink <name> - <what it does>" in Revision.log every time it runs.
//=============================================================================
class UCLink extends UCEditorStory;

var() string Source;          // the object (its name in the map); empty when When=start
var() name   When;
var() int    Option;          // When=option: which special option of the computer (0-3)
var() float  NearDist;        // When=near
var() bool   bOnce;           // only the first time
var() string Label;           // the sentence the editor shows
var() string Act[24];

var name  PassEvent;          // the object's own event before the link took it: triggered too
var bool  bDone, bPolled, bWas, bHurry;
var int   Step;
var float Waited, Delay;

// UCLightMemory keeps the original type of each light, shared by all interactions.

function PostBeginPlay()
{
	Super.PostBeginPlay();
	Hook();
}

function Actor ActorCalled(string s)
{
	local Actor A;

	if (s == "")
		return None;
	foreach AllActors(class'Actor', A)
		if (string(A.Name) ~= s && !A.bDeleteMe)
			return A;
	return None;
}

// The object's event becomes this link's Tag.
function Hook()
{
	local Actor A;
	local Keypad K;
	local Computers C;

	if (Source == "" || When == 'start' || When == 'picked' || When == 'gone' || When == 'near'
		|| When == 'cutstart' || When == 'cutdone'      // a cutscene (UCCutscene) triggers UCL_<name>_Start / _End
		|| When == 'npcused' || When == 'finished' || When == 'stopped' || When == 'arrived')
		return;                                         // (UCNpcUse, UCTimer trigger their tags; arrived is watched)
	if (When == 'used' && UsableOf(Source) != None)    // JC has finished using it: its UCUsable triggers this
		return;
	if (When == 'animdone')                 // the end of the object's animation: its UCMotion's Event
	{
		HookMotion();
		return;
	}
	A = ActorCalled(Source);
	if (A == None)
	{
		Log("UCLink" @ Name @ "- its object" @ Source @ "is not in the map");
		return;
	}
	if (When == 'wrongcode')
	{
		K = Keypad(A);
		if (K != None && K.FailEvent != Tag)
		{
			PassEvent = K.FailEvent;
			K.FailEvent = Tag;
		}
	}
	else if (When == 'option')
	{
		C = Computers(A);
		if (C != None && Option >= 0 && Option < ArrayCount(C.specialOptions) && C.specialOptions[Option].TriggerEvent != Tag)
		{
			PassEvent = C.specialOptions[Option].TriggerEvent;
			C.specialOptions[Option].TriggerEvent = Tag;
		}
	}
	else if (A.Event != Tag)
	{
		PassEvent = A.Event;
		A.Event = Tag;
	}
}

function HookMotion()
{
	local UCMotion Mo;

	foreach AllActors(class'UCMotion', Mo)
		if (Mo.Target ~= Source && Mo.Event != Tag)
		{
			PassEvent = Mo.Event;
			Mo.Event = Tag;
		}
}

function Trigger(Actor Other, Pawn EventInstigator)
{
	local Actor A;
	local DeusExMover M;

	if (PassEvent != '')
		foreach AllActors(class'Actor', A, PassEvent)
			A.Trigger(Other, EventInstigator);
	M = DeusExMover(Other);
	if (When == 'closed' || When == 'leave' || When == 'start' || When == 'picked' || When == 'gone' || When == 'near'
		|| When == 'arrived')
		return;
	if (When == 'opened' && M != None && M.bDestroyed)
		return;
	if (When == 'destroyed' && (M == None || !M.bDestroyed))
		return;
	Fire();
}

function UnTrigger(Actor Other, Pawn EventInstigator)
{
	local Actor A;

	if (PassEvent != '')
		foreach AllActors(class'Actor', A, PassEvent)
			A.UnTrigger(Other, EventInstigator);
	if (When == 'closed' || When == 'leave')
		Fire();
}

function Fire()
{
	if ((bOnce && bDone) || IsInState('Running'))
		return;
	bDone = True;
	Log("UCLink" @ Name @ "-" @ Label);
	GotoState('Running');
}

// a cutscene was skipped: what it still had to do happens now (its "when it starts" actions)
function Hurry()
{
	if (!IsInState('Running'))
		return;
	bHurry = True;
	GotoState('Running', 'Next');
}

// the map starts
function StartStory()
{
	if (When == 'start')
		Fire();
}

// what has no event of its own: watched every half second, it runs when it becomes true
function TickStory()
{
	local Actor A;
	local DeusExPlayer P;
	local bool bNow;

	if (When != 'picked' && When != 'gone' && When != 'near' && When != 'arrived')
		return;
	P = Plr();
	A = ActorCalled(Source);
	if (When == 'arrived')
		bNow = Arrived(ScriptedPawn(A));
	else if (When == 'near')
		bNow = A != None && P != None && VSize(P.Location - A.Location) <= NearDist;
	else if (When == 'picked')
		bNow = A == None || (Inventory(A) != None && Pawn(A.Owner) != None);
	else
		bNow = A == None;
	if (!bPolled)
	{
		bPolled = True;
		bWas = bNow;
		if (bNow && When != 'near' && When != 'arrived')
			Log("UCLink" @ Name @ "- its object" @ Source @ "is not in the map");
		return;
	}
	if (bNow && !bWas)
		Fire();
	bWas = bNow;
}

// ---------------------------------------------------------------- the actions
function string Field(string s, int n)
{
	local int i;

	while (n > 0)
	{
		i = InStr(s, "|");
		if (i < 0)
			return "";
		s = Mid(s, i + 1);
		n--;
	}
	i = InStr(s, "|");
	if (i >= 0)
		return Left(s, i);
	return s;
}

// Fixed recipients stay connected when they move. The checkbox adds current entrants,
// evaluated when this action executes (including its delay), without double execution.
function bool AreaKind(Actor A, string kind)
{
	if (A == None || A == Self || A.bDeleteMe || PlayerPawn(A) != None || string(A.Name) ~= Source)
		return False;
	if (kind == "light") return Light(A) != None;
	if (kind == "character") return ScriptedPawn(A) != None;
	if (kind == "object") return Decoration(A) != None || Inventory(A) != None || Mover(A) != None;
	return False;
}

// Snapshot recipients before running actions: changing an alliance must not change
// which actors the same action has already selected. Chunks avoid a hard group limit.
function QueueRecipient(Actor A, out UCLinkGroup First, out UCLinkGroup Tail, out int Slot)
{
	local UCLinkGroup G;
	if (A == None || (First != None && First.Contains(A.Name))) return;
	if (Tail == None || Slot >= 128)
	{
		G = Spawn(class'UCLinkGroup');
		if (G == None) return;
		if (First == None) First = G;
		if (Tail != None) Tail.NextGroup = G.Name;
		Tail = G;
		Slot = 0;
	}
	Tail.SetMember(Slot,A.Name);
	Slot++;
}

function RunRecipients(UCLinkGroup First, string s)
{
	local UCLinkGroup G, N;
	local int i;
	G = First;
	while (G != None)
	{
		for (i=0; G.GetMember(i) != ''; i++)
			DoAct("0|" $ Field(s,1) $ "|" $ string(G.GetMember(i)) $ "|" $ Field(s,3) $ "|" $ Field(s,4) $ "|" $ Field(s,5));
		N = G.Next();
		G.Destroy();
		G = N;
	}
}

function bool TagKind(Actor A, string verb)
{
	if (A == None || A == Self || A.bDeleteMe || PlayerPawn(A) != None || string(A.Name) ~= Source
		|| UCObjectTag(A) != None || UCLinkGroup(A) != None || UCLink(A) != None) return False;
	if (Left(verb,5) == "light") return Light(A) != None;
	if (verb == "open" || verb == "close" || verb == "toggle" || verb == "lock" || verb == "unlock" || verb == "blow") return DeusExMover(A) != None;
	if (verb == "attack" || verb == "hostile" || verb == "friend" || verb == "neutral" || verb == "stand" || verb == "wander"
		|| verb == "follow" || verb == "goto" || verb == "run" || verb == "leave" || verb == "appear") return ScriptedPawn(A) != None;
	return True;
}

function DoTag(string s)
{
	local Actor A;
	local UCLinkGroup First,Tail;
	local int Slot;
	if (Field(s,7) == "") return;
	foreach AllActors(class'Actor',A)
		if (TagKind(A,Field(s,1)) && class'UCObjectTag'.static.Matches(A,Field(s,7))) QueueRecipient(A,First,Tail,Slot);
	RunRecipients(First,s);
}

function DoArea(string s)
{
	local Actor A;
	local UCLinkGroup G, First,Tail;
	local vector center;
	local string kind, wanted;
	local int i,Slot;
	local float radius;

	kind = Field(s,7);
	radius = float(Field(s,8));
	center.X = float(Field(s,9));
	center.Y = float(Field(s,10));
	center.Z = float(Field(s,11));
	wanted = Field(s,13);
	G = UCLinkGroup(ActorCalled(Field(s,12)));
	while (G != None)
	{
		for (i=0; G.GetMember(i) != ''; i++)
		{
			A = ActorCalled(string(G.GetMember(i)));
			if (AreaKind(A,kind) && class'UCObjectTag'.static.Matches(A,wanted)) QueueRecipient(A,First,Tail,Slot);
		}
		G = G.Next();
	}
	if (Field(s,6) == "area+" && radius > 0)
		foreach AllActors(class'Actor',A)
			if (AreaKind(A,kind) && VSize(A.Location-center) <= radius && class'UCObjectTag'.static.Matches(A,wanted))
				QueueRecipient(A,First,Tail,Slot);
	RunRecipients(First,s);
}

function DoAct(string s)
{
	local string verb, target, a, b, c;
	local Actor T;
	local DeusExMover M;
	local DeusExPlayer P;
	local Sound snd;
	local name n;

	if (Field(s, 6) == "group" || Field(s, 6) == "area+") { DoArea(s); return; }
	if (Field(s, 6) == "tag") { DoTag(s); return; }
	verb = Field(s, 1);
	target = Field(s, 2);
	a = Field(s, 3);
	b = Field(s, 4);
	c = Field(s, 5);
	P = Plr();
	T = ActorCalled(target);
	if (target != "" && T == None)
	{
		Log("UCLink" @ Name @ "-" @ verb @ ":" @ target @ "is not in the map any more");
		return;
	}
	if (T != None)
		n = T.Name;
	M = DeusExMover(T);
	// doors
	if (verb == "open" && M != None)
		DoorOpen(M);
	else if (verb == "close" && M != None)
		DoorShut(M);
	else if (verb == "toggle" && M != None)
	{
		if (M.KeyNum == 0 && !M.bOpening)
			DoorOpen(M);
		else
			DoorShut(M);
	}
	else if (verb == "lock")
		DoorDo(n, 2);
	else if (verb == "unlock")
		DoorDo(n, 3);
	else if (verb == "blow")
		DoorDo(n, 4);
	else if (verb == "key" && M != None && P != None && P.KeyRing != None && M.KeyIDNeeded != '')
	{
		P.KeyRing.GiveKey(M.KeyIDNeeded, a);
		P.ClientMessage("Nanokey received:" @ a);
	}
	// characters
	else if (verb == "attack")
		NpcHostile(n, True, a == "alone");
	else if (verb == "hostile")
		NpcHostile(n, False, a == "alone");
	else if (verb == "friend")
		NpcFriend(n);
	else if (verb == "neutral")
		NpcNeutral(n);
	else if (verb == "stand")
		NpcOrders(n, 'Standing');
	else if (verb == "wander")
		NpcOrders(n, 'Wandering');
	else if (verb == "follow")
		NpcOrders(n, 'Following');
	else if (verb == "goto" || verb == "run")
		NpcGo(n, vect(1,0,0) * float(a) + vect(0,1,0) * float(b) + vect(0,0,1) * float(c), verb == "run");
	else if (verb == "navgo" || verb == "navrun")      // on the walkable area (UCNavMesh)
		NpcWalk(n, vect(1,0,0) * float(a) + vect(0,1,0) * float(b) + vect(0,0,1) * float(c), verb == "navrun");
	else if (verb == "leave")
		Hide(n);
	else if (verb == "appear")
		Show(n);
	// lights, objects, devices
	else if (verb == "lighton" || verb == "lightoff" || verb == "lighttoggle")
		LightSet(T, Mid(verb, 5));
	else if (verb == "hide" && T != None)
	{
		T.bHidden = True;
		T.SetCollision(False, False, False);
	}
	else if (verb == "show" && T != None)
	{
		T.bHidden = T.default.bHidden;
		T.SetCollision(T.default.bCollideActors, T.default.bBlockActors, T.default.bBlockPlayers);
	}
	else if (verb == "on" && T != None)
		T.Trigger(Self, P);
	else if (verb == "off" && T != None)
		T.UnTrigger(Self, P);
	else if (verb == "explode")
	{
		if (T != None)
			Boom(T.Location, float(a), float(b));
		else
			Boom(Location, float(a), float(b));
	}
	// sounds, messages, the story
	else if (verb == "sound")
	{
		snd = Sound(DynamicLoadObject(a, class'Sound', True));
		if (snd == None)
			Log("UCLink" @ Name @ "- no sound" @ a);
		else if (float(c) <= 0 && P != None)
			P.PlaySound(snd, SLOT_None, FMax(0.1, float(b)),, 100000);
		else if (T != None)
			T.PlaySound(snd, SLOT_None, FMax(0.1, float(b)),, float(c));
		else
			PlaySound(snd, SLOT_None, FMax(0.1, float(b)),, float(c));
	}
	else if (verb == "anim" || verb == "animback" || verb == "animstop")
		Animate(target, verb, M);
	else if (verb == "cutplay" && UCCutscene(T) != None)
		UCCutscene(T).Play();
	else if (verb == "cutstop" && UCCutscene(T) != None)
		UCCutscene(T).Stop();
	else if (verb == "message")
		Message(a);
	else if (verb == "goal")
		Goal(StringToName(a), b, c == "done");
	else if (verb == "note")
		Note(a);
	else if (verb == "flag")
		SetF(StringToName(a), b != "0");
	else if (verb == "travel")
		TravelTo(a);
	// timers, characters using objects, effects
	else if (Left(verb, 5) == "timer" && UCTimer(T) != None)
		TimerDo(UCTimer(T), Mid(verb, 5), float(a));
	else if (verb == "npcuse")
		NpcUse(target, a, float(b), c != "stand");
	else if (verb == "effect" && T != None)
		Effect(T, a, float(b), c);
	else
		Log("UCLink" @ Name @ "- cannot" @ verb @ target);
}

// ---------------------------------------------------------------- the editor's building blocks
// The usable object of the map editor on this object (Properties > Usable), if it has one.
function UCUsable UsableOf(string objName)
{
	local UCUsable U;

	foreach AllActors(class'UCUsable', U)
		if (U.Target ~= objName)
			return U;
	return None;
}

// A character sent with goto/run (UCEditorStory.NpcGo: orders to the mark UCEdGo_<name>) is there.
function bool Arrived(ScriptedPawn sp)
{
	local UCMark mark;
	local UCNavRoute R;
	local name t;
	local bool bThere;

	if (sp == None || sp.Health <= 0)
		return False;
	foreach AllActors(class'UCNavRoute', R)          // still on the way: its mark is at a corner, not the place
		if (R.Who == sp && R.OnTheWay())
			return False;
	t = StringToName("UCEdGo_" $ sp.Name);
	if (t == '' || sp.OrderTag != t || (sp.Orders != 'GoingTo' && sp.Orders != 'RunningTo'))
		return False;
	foreach AllActors(class'UCMark', mark, t)
		if (VSize((sp.Location - mark.Location) * vect(1,1,0)) <= sp.CollisionRadius + 48 && Abs(sp.Location.Z - mark.Location.Z) < 80)
			bThere = True;
	return bThere && !sp.IsInState('GoingTo') && !sp.IsInState('RunningTo');
}

// start (seconds: its own when 0), stop, pause, resume
function TimerDo(UCTimer T, string how, float secs)
{
	if (how == "start")
		T.StartIt(secs);
	else if (how == "stop")
		T.StopIt();
	else if (how == "pause")
		T.PauseIt();
	else if (how == "resume")
		T.ResumeIt();
}

// A character goes to an object and uses it (UCNpcUse); a new use of his replaces the one he was on.
function NpcUse(string who, string what, float secs, bool bCrouch)
{
	local UCNpcUse U;

	foreach AllActors(class'UCNpcUse', U)
		if (U.Who ~= who)
			U.Destroy();
	U = Spawn(class'UCNpcUse');
	if (U == None)
		return;
	U.Who = who;
	U.What = what;
	U.Secs = FMax(0, secs);
	U.bCrouch = bCrouch;
	U.Go();
}

// An effect on an object (UCEffect); "off" stops every effect on it, a new one replaces the same kind.
// On an effect point (UCEffectPoint) it sits on the point and goes along its arrow; opts may hold "exact".
function Effect(Actor T, string kind, float secs, string opts)
{
	local UCEffect E;

	foreach AllActors(class'UCEffect', E)
		if (E.Target ~= string(T.Name) && (kind ~= "off" || E.Kind ~= kind))
			E.Destroy();
	if (kind ~= "off" || kind == "")
	{
		Log("UCLink" @ Name @ "- effects on" @ T.Name @ "stopped");
		return;
	}
	E = Spawn(class'UCEffect',,, T.Location);
	if (E == None)
		return;
	E.Target = string(T.Name);
	E.StartEffect(kind, secs, opts);
}

// The animation of an object (its UCMotion, made in the editor's Animation panel); a door without one
// opens and shuts.
function Animate(string target, string verb, DeusExMover M)
{
	local UCMotion Mo;
	local bool bAny;

	foreach AllActors(class'UCMotion', Mo)
		if (Mo.Target ~= target)
		{
			bAny = True;
			if (verb == "animstop")
				Mo.StopIt();
			else
				Mo.Play(verb == "animback");
		}
	if (!bAny && M != None)
	{
		if (verb == "anim")
			DoorOpen(M);
		else if (verb == "animback")
			DoorShut(M);
	}
}

// On, off or the other way: the kind of light (steady, flickering...) comes back when it is
// turned on again. The editor makes these lights non-static (their light can change).
function LightSet(Actor T, string mode)
{
	local UCLightMemory M, Found;
	if (T == None) return;
	foreach AllActors(class'UCLightMemory', M)
		if (M.Target == T) { Found = M; break; }
	if (mode == "toggle")
	{
		if (T.LightType == LT_None) mode = "on";
		else mode = "off";
	}
	if (mode == "off" && T.LightType != LT_None)
	{
		if (Found == None) Found = Spawn(class'UCLightMemory');
		if (Found != None) { Found.Target = T; Found.OriginalType = T.LightType; }
		T.LightType = LT_None;
	}
	else if (mode == "on" && T.LightType == LT_None)
	{
		if (Found != None && Found.OriginalType != LT_None) T.LightType = Found.OriginalType;
		else T.LightType = LT_Steady;
	}
	Log("UCLink" @ Name @ "- light" @ T.Name @ mode);
}

function Boom(vector loc, float dmg, float radius)
{
	local ExplosionLarge E;
	local ExplosionLight L;

	if (radius <= 0)
		radius = 256;
	E = Spawn(class'ExplosionLarge',,, loc);
	L = Spawn(class'ExplosionLight',,, loc);
	if (L != None)
		L.size = 8;
	if (E != None)
		E.PlaySound(sound'LargeExplosion1', SLOT_None, 2.0,, radius * 16);
	if (dmg > 0)
		HurtRadius(dmg, radius, 'Exploded', dmg * 100, loc);
}

state Running
{
Begin:
	Step = 0;
	Waited = 0;
	bHurry = False;
Next:
	if (Step < ArrayCount(Act) && Act[Step] != "")
	{
		Delay = float(Field(Act[Step], 0));
		if (!bHurry && Delay > Waited)
		{
			Sleep(Delay - Waited);
			Waited = Delay;
		}
		DoAct(Act[Step]);
		Step++;
		Goto('Next');
	}
	GotoState('');
}

defaultproperties
{
     bRouteOnly=False
     NearDist=256.000000
}
