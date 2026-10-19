//=============================================================================
// UCEditorStory - base of the stories written in the map editor ("Storia"): the editor
// (tools\mapkit\story.py) generates one subclass per map, UCEd_<map>, with the dialogues
// attached to the characters and objects of the map and the events of the mission (JC
// arrives somewhere, a flag becomes true, the map starts). UCCampaign spawns UCEd_<map> at every
// map load (conversations attached from script are not saved with the map: they are
// attached again here, and again whenever the game clears them).
//
// The generated class fills SetupStory() (attach) and TickStory() (events, dialogues that
// start when JC comes near). Flags of the editor start with UCEd.
//=============================================================================
class UCEditorStory extends Info;

var bool bRouteOnly;        // only on the UNATCO route (flag UNATCORouteCommitted)
var bool bStarted;          // the "at the start of the map" events have run
var float attachTime;
var string lastWhy;         // last reason logged for a dialogue that did not start
var name hideList[16];      // characters that vanish as soon as JC cannot see them
var name showList[16];      // characters that appear as soon as JC cannot see their place

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0.5, True);
}

function DeusExPlayer Plr()
{
	return DeusExPlayer(GetPlayerPawn());
}

function bool GetF(name f)
{
	local DeusExPlayer P;

	P = Plr();
	return P != None && P.FlagBase != None && P.FlagBase.GetBool(f);
}

function SetF(name f, bool v)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None && P.FlagBase != None)
		P.FlagBase.SetBool(f, v,, 99);
}

function Actor ActorNamed(name n)
{
	local Actor A;

	foreach AllActors(class'Actor', A)
		if (A.Name == n)
			return A;
	return None;
}

function bool HasCon(Actor A, name conName)
{
	local ConListItem item;

	if (A == None)
		return False;
	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
			return True;
	return False;
}

function Conversation FindCon(Actor A, name conName)
{
	local ConListItem item;

	if (A == None)
		return None;
	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
			return item.con;
	return None;
}

function bool HasCopy(Actor A, name conName, string version)
{
	local ConListItem item;
	if (A==None) return False;
	for (item=ConListItem(A.conListItems); item!=None; item=item.next)
		if (item.con!=None && item.con.conName==conName && item.con.CreatedBy==version)
			return True;
	return False;
}

// Replace at the original priority. Keeping its name also preserves mission-script InfoLinks
// and the game's <conversation>_Played flag; DataLinkTrigger continues to resolve that name.
function ReplaceCon(Actor A, name originalName, optional Conversation replacement)
{
	local ConListItem item, previous, following, inserted;
	local bool found;
	if (A==None) return;
	item=ConListItem(A.conListItems);
	while (item!=None)
	{
		following=item.next;
		if (item.con!=None && item.con.conName==originalName)
		{
			if (!found && replacement!=None)
			{
				inserted=new(Level) class'ConListItem'; inserted.con=replacement; inserted.next=following;
				if (previous==None) A.conListItems=inserted; else previous.next=inserted;
				previous=inserted;
			}
			else if (previous==None) A.conListItems=following;
			else previous.next=following;
			found=True;
		}
		else previous=item;
		item=following;
	}
	if (!found && replacement!=None)
	{
		inserted=new(Level) class'ConListItem'; inserted.con=replacement;
		inserted.next=ConListItem(A.conListItems); A.conListItems=inserted;
	}
}

function ClearVoiceRefs() { class'UCVoiceBank'.static.Clear(Self); }

// Resolve cross-conversation jumps after every copy has been attached, so their
// order in the editor cannot send a jump back into an unedited original.
function Conversation BoundCopy(Conversation target)
{
	local Actor A;
	local ConListItem item;
	foreach AllActors(class'Actor', A)
		for (item=ConListItem(A.ConListItems); item!=None; item=item.next)
			if (item.con!=None && item.con.conName==target.conName
				&& item.con.conOwnerName==target.conOwnerName && Left(item.con.CreatedBy,9)=="DeusEdix:")
				return item.con;
	return target;
}

function RebindCopyJumps()
{
	local Actor A;
	local ConListItem item;
	local ConEvent e;
	local ConEventJump jump;
	foreach AllActors(class'Actor', A)
		for (item=ConListItem(A.ConListItems); item!=None; item=item.next)
			if (item.con!=None && Left(item.con.CreatedBy,9)=="DeusEdix:")
				for (e=item.con.eventList; e!=None; e=e.nextEvent)
				{
					jump=ConEventJump(e);
					if (jump!=None && jump.jumpCon!=None) jump.jumpCon=BoundCopy(jump.jumpCon);
				}
}

function VoiceRef(string speaker, string text, string path)
{
	class'UCVoiceBank'.static.Register(Self,speaker,text,path);
}

// The name the conversations use for this actor (its BindName); the editor gives one only to
// actors that had none (the conversations of the original game use the name they have).
function Actor Bound(name actorName, string bindName)
{
	local Actor A;

	A = ActorNamed(actorName);
	if (A == None)
		return None;
	if (A.BindName == "")
	{
		A.BindName = bindName;
		if (ScriptedPawn(A) != None)
			ScriptedPawn(A).ConBindEvents();
		else if (DeusExDecoration(A) != None)
			DeusExDecoration(A).ConBindEvents();
	}
	return A;
}

function bool Talking()
{
	local DeusExPlayer P;

	P = Plr();
	return P == None || P.conPlay != None;
}

// A dialogue that starts when JC comes near: only if he can see the speaker (radius
// conversations of the game go through walls).
function bool NearTalk(Actor A, name conName, float dist)
{
	local DeusExPlayer P;
	local Conversation c;

	P = Plr();
	if (A == None || P == None || Talking() || VSize(P.Location - A.Location) > dist)
		return False;
	if (Pawn(A) != None && (Pawn(A).Health <= 0 || !Pawn(A).LineOfSightTo(P)))
		return Why(conName, "JC is near but out of sight");
	c = FindCon(A, conName);
	if (c == None)
		return Why(conName, "not attached to" @ A.Name);
	if (!P.CheckFlagRefs(c.flagRefList))
		return Why(conName, "conditions not met");
	if (c.bDisplayOnce && GetF(StringToName(string(conName) $ "_Played")))
		return False;
	if (!P.StartConversation(A, IM_Other, c, False, False))
		return Why(conName, "the game refused to start it (state" @ A.GetStateName() $ ")");
	Log("UCEd: dialogue" @ conName @ "started with" @ A.Name);
	return True;
}

// Why a dialogue near JC does not start, once per reason (in the game's log).
function bool Why(name conName, string reason)
{
	if (lastWhy != (string(conName) $ reason))
	{
		lastWhy = string(conName) $ reason;
		Log("UCEd: dialogue" @ conName @ "-" @ reason);
	}
	return False;
}

function name StringToName(string s)
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None || P.rootWindow == None)
		return '';
	return P.rootWindow.StringToName(s);
}

// Events
function bool Near(vector spot, float dist)
{
	local DeusExPlayer P;

	P = Plr();
	return P != None && VSize(P.Location - spot) <= dist;
}

function Goal(name goalName, string text, bool bDone)
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	if (P.FindGoal(goalName) == None)
		P.AddGoal(goalName, True).SetText(text);
	if (bDone)
		P.GoalCompleted(goalName);
}

function Note(string text)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None)
		P.AddNote(text, False, True);
}

function Message(string text)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None)
		P.ClientMessage(text);
}

function TriggerTag(name tagName)
{
	local Actor A;

	foreach AllActors(class'Actor', A, tagName)
		A.Trigger(Self, Plr());
}

function Talk(name actorName, name conName)
{
	local Actor A;
	local DeusExPlayer P;
	local Conversation c;

	P = Plr();
	A = ActorNamed(actorName);
	c = FindCon(A, conName);
	if (P != None && c != None && !Talking())
		P.StartConversation(A, IM_Other, c, False, False);
}

// ---------------------------------------------------------------- actions on characters
function ScriptedPawn Pawned(name n)
{
	local ScriptedPawn sp;

	sp = ScriptedPawn(ActorNamed(n));
	if (sp == None || sp.Health <= 0)
		return None;
	return sp;
}

// JC could see this place (line of sight from his eyes, wherever he is looking).
function bool JCSees(vector spot)
{
	local DeusExPlayer P;

	P = Plr();
	return P != None && FastTrace(spot, P.Location + vect(0,0,1) * P.BaseEyeHeight);
}

// Walks or runs to a point (on the floor below it), then stays there.
function NpcGo(name n, vector spot, bool bRun)
{
	local ScriptedPawn sp;
	local UCMark mark;
	local name markTag;
	local vector hitLoc, hitNormal;

	sp = Pawned(n);
	if (sp == None || !sp.bInWorld)
		return;
	if (Trace(hitLoc, hitNormal, spot - vect(0,0,2000), spot, False) != None)
		spot = hitLoc + vect(0,0,1) * sp.CollisionHeight;
	markTag = StringToName("UCEdGo_" $ n);
	foreach AllActors(class'UCMark', mark, markTag)
		mark.Destroy();
	Spawn(class'UCMark',, markTag, spot);
	Log("UCEd:" @ n @ "goes to" @ spot @ "running" @ bRun);
	if (bRun)
		sp.SetOrders('RunningTo', markTag, True);
	else
		sp.SetOrders('GoingTo', markTag, True);
}

// The same on the walkable area (UCNavMesh, UCNavRoute): the way a man would walk, without path nodes. With no
// walkable area in the map, or no way on it, the old way (NpcGo, on the path nodes).
function NpcWalk(name n, vector spot, bool bRun)
{
	local ScriptedPawn sp;
	local vector hitLoc, hitNormal;

	sp = Pawned(n);
	if (sp == None || !sp.bInWorld)
		return;
	if (Trace(hitLoc, hitNormal, spot - vect(0,0,2000), spot, False) != None)
		spot = hitLoc + vect(0,0,1) * sp.CollisionHeight;
	if (!class'UCNavRoute'.static.Send(sp, spot, bRun, StringToName("UCEdGo_" $ n)))
		NpcGo(n, spot, bRun);
}

// Standing, Wandering, Following (JC), Attacking (JC).
function NpcOrders(name n, name orders)
{
	local ScriptedPawn sp;

	sp = Pawned(n);
	if (sp != None && sp.bInWorld)
	{
		Log("UCEd:" @ n @ "orders" @ orders);
		sp.SetOrders(orders, '', True);
	}
}

function NpcFriend(name n)
{
	local ScriptedPawn sp;

	sp = Pawned(n);
	if (sp == None)
		return;
	sp.ChangeAlly('Player', 1.0, True);
	if (sp.bInWorld && (sp.IsInState('Attacking') || sp.IsInState('Seeking') || sp.IsInState('Alerting')
		|| sp.IsInState('Fleeing') || sp.Orders == 'Attacking'))
		sp.SetOrders('Standing', '', True);
}

// ---------------------------------------------------------------- factions (the game's alliances)
// Every living member of a faction changes its attitude towards another faction ('Player' = JC):
// level 1 friendly, 0 neutral, -1 hostile. bFixed: it never changes again by itself (the game's
// bPermanent: attacks do not agitate it). Hostile members attack JC when they see him.
function FactionTowards(name faction, name other, float level, bool bFixed)
{
	local ScriptedPawn sp;
	local int n;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.Alliance == faction && sp.Health > 0)
		{
			sp.ChangeAlly(other, level, bFixed);
			if (other == 'Player' && level >= 0 && sp.bInWorld && (sp.IsInState('Attacking')
				|| sp.IsInState('Seeking') || sp.IsInState('Alerting') || sp.Orders == 'Attacking'))
				sp.SetOrders('Standing', '', True);
			n++;
		}
	Log("UCEd: faction" @ faction @ "towards" @ other @ level @ "fixed" @ bFixed @ "(" $ n @ "characters)");
}

// One character turns hostile to JC: he attacks when he sees him (bAttackNow: at once, wherever JC
// is). bAlone: he leaves his faction first (a faction of his own), so when JC fights back his former
// friends neither defend him nor fight him (in the game, friends of someone who is attacked turn on
// the attacker); without it, his faction may join in, as in the game.
function NpcHostile(name n, bool bAttackNow, bool bAlone)
{
	local ScriptedPawn sp;

	sp = Pawned(n);
	if (sp == None)
		return;
	if (bAlone)
	{
		// his own faction, and no calls for help: in the game every character treats neutrals as
		// friends (bLikesNeutral) and helps a friend in distress (an attacker sends distress)
		Isolate(sp);
		sp.bEmitDistress = False;
	}
	sp.ChangeAlly('Player', -1.0, True);
	if (bAttackNow && sp.bInWorld)
		sp.SetOrders('Attacking', '', True);
	Log("UCEd:" @ n @ "hostile to JC, attack now" @ bAttackNow $ ", alone" @ bAlone @ "(faction" @ sp.Alliance $ ")");
}

function NpcNeutral(name n)
{
	local ScriptedPawn sp;

	sp = Pawned(n);
	if (sp == None)
		return;
	sp.ChangeAlly('Player', 0.0, False);
	if (sp.bInWorld && (sp.IsInState('Attacking') || sp.IsInState('Seeking') || sp.IsInState('Alerting')
		|| sp.IsInState('Fleeing') || sp.Orders == 'Attacking'))
		sp.SetOrders('Standing', '', True);
}

// A faction of his own: neutral and fixed with his former faction, both ways.
function Isolate(ScriptedPawn sp)
{
	local ScriptedPawn other;
	local name old, own;

	old = sp.Alliance;
	own = StringToName("UCEdAlone_" $ sp.Name);
	if (old == own || own == '')
		return;
	sp.SetAlliance(own);
	sp.ChangeAlly(own, 1.0, True);
	if (old != '' && old != 'None')
	{
		sp.ChangeAlly(old, 0.0, True);
		foreach AllActors(class'ScriptedPawn', other)
			if (other != sp && other.Alliance == old)
				other.ChangeAlly(own, 0.0, True);
	}
}

// A character joins another faction (and is friendly to it for good).
function NpcJoin(name n, name faction)
{
	local ScriptedPawn sp;

	sp = Pawned(n);
	if (sp == None)
		return;
	sp.SetAlliance(faction);
	sp.ChangeAlly(faction, 1.0, True);
	Log("UCEd:" @ n @ "joins the faction" @ faction);
}

// At least one living member of the faction is hostile to JC (shot at, or turned by the story).
function bool FactionHostile(name faction)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.Alliance == faction && sp.Health > 0 && sp.GetAllianceType('Player') == ALLIANCE_Hostile)
			return True;
	return False;
}

// Characters never vanish or pop up in view: they wait until JC cannot see them.
function Hide(name n)
{
	local int i;

	for (i = 0; i < ArrayCount(showList); i++)
		if (showList[i] == n)
			showList[i] = '';
	for (i = 0; i < ArrayCount(hideList); i++)
		if (hideList[i] == n)
			return;
	for (i = 0; i < ArrayCount(hideList); i++)
		if (hideList[i] == '')
		{
			hideList[i] = n;
			return;
		}
}

function Show(name n)
{
	local int i;

	for (i = 0; i < ArrayCount(hideList); i++)
		if (hideList[i] == n)
			hideList[i] = '';
	for (i = 0; i < ArrayCount(showList); i++)
		if (showList[i] == n)
			return;
	for (i = 0; i < ArrayCount(showList); i++)
		if (showList[i] == '')
		{
			showList[i] = n;
			return;
		}
}

function TickHideShow()
{
	local ScriptedPawn sp;
	local int i;

	for (i = 0; i < ArrayCount(hideList); i++)
		if (hideList[i] != '')
		{
			sp = Pawned(hideList[i]);
			if (sp == None || !sp.bInWorld)
				hideList[i] = '';
			else if (!JCSees(sp.Location) && !JCSees(sp.Location + vect(0,0,1) * sp.BaseEyeHeight))
			{
				Log("UCEd:" @ sp.Name @ "leaves (JC does not see him)");
				sp.LeaveWorld();
				hideList[i] = '';
			}
		}
	for (i = 0; i < ArrayCount(showList); i++)
		if (showList[i] != '')
		{
			sp = Pawned(showList[i]);
			if (sp == None || sp.bInWorld)
				showList[i] = '';
			else if (!JCSees(sp.WorldPosition) && !JCSees(sp.WorldPosition + vect(0,0,1) * sp.BaseEyeHeight))
			{
				Log("UCEd:" @ sp.Name @ "comes back (JC does not see the place)");
				sp.EnterWorld();
				showList[i] = '';
			}
		}
}

// ---------------------------------------------------------------- doors, maps
// A door opens and shuts as when JC uses it: through the state of the mover (its Open: and Close:
// code), so it plays its sounds, triggers its Event when it has opened (a DoOpen() alone does not:
// Mover.FinishedOpening is called by that code) and, if it is timed, shuts again by itself. A door
// in no such state just moves.
function bool DoorState(DeusExMover M)
{
	return M.InitialState != '' && M.IsInState(M.InitialState) && (M.InitialState == 'TriggerOpenTimed'
		|| M.InitialState == 'TriggerToggle' || M.InitialState == 'TriggerControl' || M.InitialState == 'TriggerPound'
		|| M.InitialState == 'BumpOpenTimed' || M.InitialState == 'BumpButton' || M.InitialState == 'StandOpenTimed');
}

function DoorOpen(DeusExMover M)
{
	if (M.bDestroyed)
		return;
	M.bLocked = False;
	if (M.KeyNum != 0 || M.bInterpolating)
		return;
	Log("UCEd: door" @ M.Name @ "opens (" $ M.GetStateName() $ ")");
	if (DoorState(M))
		M.GotoState(M.InitialState, 'Open');
	else
		M.DoOpen();
}

function DoorShut(DeusExMover M)
{
	if (M.bDestroyed || (M.KeyNum == 0 && !M.bInterpolating))
		return;
	Log("UCEd: door" @ M.Name @ "shuts (" $ M.GetStateName() $ ")");
	if (DoorState(M))
		M.GotoState(M.InitialState, 'Close');
	else
		M.DoClose();
}

// 0 open, 1 close, 2 lock, 3 unlock, 4 blow up
function DoorDo(name n, int what)
{
	local DeusExMover m;

	m = DeusExMover(ActorNamed(n));
	if (m == None || m.bDestroyed)
		return;
	Log("UCEd: door" @ n @ "action" @ what @ "position" @ m.KeyNum);
	switch (what)
	{
		case 0:
			DoorOpen(m);
			break;
		case 1:
			DoorShut(m);
			break;
		case 2:
			m.bLocked = True;
			break;
		case 3:
			m.bLocked = False;
			break;
		case 4:
			m.FragmentClass = class'MetalFragment';
			m.NumFragments = 12;
			m.FragmentSpread = 48;
			m.FragmentScale = 1.5;
			m.bDrawExplosion = True;
			m.BlowItUp(None);
			break;
	}
}

function TravelTo(string url)
{
	local DeusExPlayer P;
	local UCCutscene C;

	foreach AllActors(class'UCCutscene', C)       // JC back to himself before he leaves
		if (C.bPlaying)
			C.Finish(False, True);
	P = Plr();
	if (P != None)
		Level.Game.SendPlayer(P, url);
}

// An InfoLink (UCEdInfoLink): None when it was already heard and plays only once. The heard
// flag is set now, at the start: an interrupted InfoLink counts as heard, as in the game.
function bool TutorialGuidance(string caller)
{
	local DeusExLevelInfo info;

	if (!(caller ~= "EliasHale"))
		return False;
	foreach AllActors(class'DeusExLevelInfo', info)
		if (info.mapName ~= "00_DeusEdix_Tutorial")
			return True;
	return False;
}

function UCEdInfoLink InfoLink(name heardFlag, bool bOnce, string caller, string callerName)
{
	local UCEdInfoLink s, old;
	local bool bGuidance;

	if (bOnce && GetF(heardFlag))
		return None;
	SetF(heardFlag, True);
	bGuidance = TutorialGuidance(caller);
	if (bGuidance)
		foreach AllActors(class'UCEdInfoLink', old)
			if (!old.bDeleteMe && old.caller ~= caller)
				old.CancelGuidance();
	s = Spawn(class'UCEdInfoLink');
	if (s != None)
	{
		s.caller = caller;
		s.callerName = callerName;
		s.bQuickStart = bGuidance;
	}
	return s;
}

// ---------------------------------------------------------------- conditions of events
// Dead or knocked out (the body replaces the character).
function bool Dead(name n)
{
	local Actor A;

	A = ActorNamed(n);
	return A == None || (Pawn(A) != None && Pawn(A).Health <= 0);
}

function bool HasItem(string className)
{
	local DeusExPlayer P;
	local class<Inventory> cls;

	P = Plr();
	cls = class<Inventory>(DynamicLoadObject(className, class'Class', True));
	return P != None && cls != None && P.FindInventoryType(cls) != None;
}

// filled by the generated class
// a cutscene of the editor is playing (UCCutscene): JC is an invisible camera
function bool InCutscene()
{
	local DeusExPlayer P;

	P = Plr();
	return P != None && P.bHidden && P.IsInState('Interpolating');
}

// a cutscene of the editor (from a story event or dialogue)
function PlayCut(name n)
{
	local UCCutscene C;

	foreach AllActors(class'UCCutscene', C)
		if (C.Name == n)
			C.Play();
}

function SetupStory();
function TickStory();
function StartStory();

function Timer()
{
	if (Plr() == None || Plr().FlagBase == None)
		return;
	if (InCutscene())
		return;          // a cutscene of the editor: JC is not really where the camera is (UCCutscene)
	if (bRouteOnly && !GetF('UNATCORouteCommitted'))
		return;
	attachTime -= 0.5;
	if (attachTime <= 0)
	{
		attachTime = 2.0;
		SetupStory();             // attaches only what is missing
	}
	if (!bStarted)
	{
		bStarted = True;
		StartStory();
	}
	TickHideShow();
	TickStory();
}

defaultproperties
{
     bRouteOnly=True
     bHidden=True
}
