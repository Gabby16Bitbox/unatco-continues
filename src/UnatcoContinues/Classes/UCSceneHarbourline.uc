//=============================================================================
// UCSceneHarbourline - Mission 6 opening, Harbourline Tower in Wan Chai (06_HongKong_WanChai_Rooftop):
// Gabby's mission doc "Mission 6 - Hong Kong opening" (build plan hk6_plan.md). The roof, phases 1-3:
//  1. The landing, first arrival only (UC_HB_LandingSeen): the screen is black from the very first
//     frame (ArrivalBlack, called by UCTraveler on arrival: UCHBBlackWindow) and JC is in the game's
//     cutscene state (no input, no saving: StartBlack). Eva's helicopter comes down from high above the
//     pad while a camera watches it with the neon city behind; JC is aboard (hidden). It is all moved
//     every frame in Tick with eased speeds (the smooth-motion rule of Battery Park), never with the map
//     editor's UCMotion/UCCutscene (they stop at every key). Then the cockpit talk (UC_EvaRooftop) with
//     JC now visible beside the door, then a moment of black before control returns (CockpitTalk, LandEnd); the
//     "HONG KONG" title card (UC_HB_TitleShown) and Alex's InfoLink (UCSceneHBAlexCall 1:
//     UC_HB_AlexArrival, goal UCHBMeetKwan).
//  2. The roof: Lam greets JC once in passing (UC_HBLamGreet) and answers up to three questions when
//     clicked (UC_HBLam); two guards talk between themselves as JC walks to the door
//     (UC_HBGuardsTalk), then each has a line of his own (UC_HBGuard1Line, UC_HBGuard2Line). Lam and the
//     guards start only once JC has left the spot where he got out (PeopleTick). No clicked talk while
//     an InfoLink plays (FrobTalks).
//  3. The control room: Lam's datacube (UCHBDatalog: UC_HB_DatalogRead) and the desk PC's mail
//     (UC_HB_Mail4Read once JC reads "Re: temperatures", MailWatch).
//  4. The garage (DockTick): one of Kwan's men has seen JC's photo (UC_HBGuardPhoto); Kwan's welcome
//     (UC_HBKwanWelcome) is cut on "bro-" by the Luminous Path's blast (its trigger UCHBBreachCue:
//     Trigger, then Breach: UC_HB_BreachStarted, the squad revealed behind the closed doors, Kwan to
//     cover (UCHBKwan), the goals).
//  5. The attack (FightTick): the squad of the Luminous Path comes in (UCHBPathFighter, its leader
//     UCHBPathLeader), its planters arm the charges on containers 2, 4 and 6 (UCHBCharge: the countdown
//     on the HUD, ChargeTick, UCHBChargeTimer); Kwan shouts from cover. The squad falls back to the canal
//     when its leader is out (given up, knocked out, dead) or it is down to two with no charge left to
//     set (CallRetreat); the fight is over when nobody of it is left in the garage and no charge counts
//     down (BreachOver: UC_HB_BreachOver). The garage's barks go one at a time (QueueBark).
//  6. After the fight (AfterTick): Kwan's debrief (UC_HBKwanAfter: the airstrip, goal UCHBAirstrip), the
//     squad leader if he was taken (UC_HBLeaderTalk: handed over to Kwan, into the cold room, or let go,
//     out to the canal; a leader knocked out comes round where he fell, D6: LeaderSwap), Kwan's men
//     talking (GarageBarks), the sirens, Alex's second call by the van (UCSceneHBAlexCall 2).
// The way out (Gabby's D2): the service stair up to Wan Chai Street (the butcher's shop) is locked from
// the start until the attack is over (UC_HB_BreachOver: ExitLock); the freight lift doesn't run from the
// blast to the end of the fight (UseLift). Mission 6 stays open: nothing ends it and nothing makes JC
// travel.
// The freight lift is the old flow's (UCSceneHKArrival, which this extends: UCTransitButton finds
// subclasses too). The old flow's liaison, checkpoint guard, Simons call, yard briefing and cargo raid
// are switched off here (their functions are overridden). The scene is transient: after a reload it
// rebuilds its state from the flags (the once-flags of its talks are made to last: KeepOnceFlags).
// Spawned by UCCampaign.RouteTick in 06_HongKong_WanChai_Rooftop.
// The map provides: BlackHelicopter Tag 'chopper' (UCRoofChopper), Lam (Tag UCHBLam, BindName
// "UCHBLam"), two roof guards (BindName "UCHBGuard1"/"UCHBGuard2"), the desk PC named or tagged
// UCHBDeskPC (its emails from the map editor, comptexts.py); in the garage Kwan (UCHBKwan), the guards
// (BindName "UCHBGuardA", "UCHBGuardB", "UCHBGuardC", "UCHBGateGuard0" and "UCHBGateGuard1"), the gate
// and the bay shutter (DeusExMovers, Tag UCHBGarageGate / UCHBShutter), the Path's squad
// (UCHBPathFighter, UCHBPathLeader), the charges (UCHBCharge), the containers' doors and mist
// (UCHBReefer<N>Door / UCHBReefer<N>Mist), the cold room's door (Tag UCHBColdDoor), the sirens (Tag
// UCHBSiren), the van (Tag UCHBVan or UCTransportVan), the service stair's door (Tag UCShopBackDoor) and
// level change (Teleporter Tag UCShopUp). The places the scene sends people to are its own (GateSpot()
// to CanalExitSpot(): keep them in step with hk_rooftop.py).
//=============================================================================
class UCSceneHarbourline extends UCSceneHKArrival transient;

var Conversation evaCon;    // Eva's cockpit talk (UC_EvaRooftop): started by the scene at the end of the landing
var Conversation barkCon;   // a line said in passing, started by the scene (Bark)
var bool bSmokerMissing;    // the smoker was not found (logged once: SmokerTalk)
var int landPhase;          // the landing: 0 none, 1 coming down, 2 on the pad (the shot holds), 3 the shot
                            // is over, 4 Eva's talk (JC visible beside the door), 5 after it (black)
var float landT;            // seconds since the landing shot started
var float holdT;            // seconds on the pad before the shot ends; then seconds of the talk, of the black
var float descentV;         // the helicopter's speed going down (eased, no jolts)
var float soundT;           // seconds left to bring the rotor's sound back to the map's level
var vector camA, camB;      // the landing camera: from where to where it moves (CamPath)
var Inventory savedHand;    // what JC held: given back when he steps out (GiveBackHand)
var bool bLandingHadShadow; // restore only a shadow that existed before the landing hid JC
var bool bAlexSpawned;
var float titleWait;        // seconds after the title card before Alex calls
var float mailT;            // seconds the "Re: temperatures" email has been on the desk PC's screen
var int lamFails, guardFails;   // roof lines the game refused (who can't talk: hurt, angry): given up at 8
var name noClick[16];       // talks that take no clicks while an InfoLink plays (FrobTalks)
var int numNoClick;
var int onceKept;           // the once-flags already made to last (a bit for each OnceFlag)
// the garage (phases 4-5)
var bool bCue;              // Kwan's welcome reached the blast's cue (Trigger): cueT seconds to "bro-"
var float cueT;
var int photoTries;         // times the guard's "Is that him?" was queued (given up at 8)
var bool bBreachRun;        // the blast's later doors and Kwan's shout, breachT seconds after it
var float breachT;
var int breachStep;
var float chargeT;          // seconds since the last ChargeTick
var bool bChargesSeen;      // ChargeTick has seen the charges once (what happened before a load is not news)
var int armedBits, defusedBits, blownBits;     // a bit (1 << container) for each charge already seen so
// the barks of the garage, one at a time (QueueBark): who, which talk, how important, from when
var ScriptedPawn qWho[8];
var name qCon[8];
var int qPrio[8];
var float qReady[8];
var byte qMoving[8];        // (1: who says it keeps moving)
var int qN;
var float qUntil[8];        // (when it is dropped: its moment has gone)
var byte qTries[8];         // (times the game refused it: it is tried again until then)
var float lastBarkEnd;      // when the last bark ended
var float lastBarkStart;    // when the last bark started (3 seconds between two starts)
// the fight and after it (phases 5-6)
var float breachAge;        // seconds of the fight this scene has seen (FightTick)
var float spotNext;         // the next "spotted" bark not before this time (6 seconds apart)
var bool bRetreatCalled;    // the squad has been called back (its two barks)
var bool bAfterDone;        // the end of the fight's once-per-scene work is done (AfterStart)
var bool bAlexReport;       // Alex's second call spawned
var bool bEscortSent;       // one of Kwan's men walks the leader to the cold room
var UCTransitGuard escortGuard; // that man: he comes for the taken leader and walks him to the cold room's door
var float garageNext;       // the garage's barks after the fight: the next not before this time
var bool bGoalsSet;         // the attack's goals are in JC's log (BreachGoals)
var float leaderUnseenT;    // seconds the squad leader, still fighting, has been out of JC's sight (SafetyTimeout)
var bool bTimeoutCalled;    // the fight's safety timeout has sent the squad back
var bool bLeaderSlipped;    // the safety timeout took the squad leader away unseen (neither killed nor taken)
var float offLiftAt;        // when JC came out of the dock lift (0: not yet): Kwan sets off 2 s later
var bool bKwanComing;       // Kwan is walking up to JC for his welcome

function PostBeginPlay()
{
	Super.PostBeginPlay();
	Tag = 'UCHBBreachCue';      // Kwan's welcome triggers it (phase 4: the garage blast)
}

// The engine's Spawn() gives the new actor its Tag (the spawner's: none) after PostBeginPlay: the welcome's
// trigger would find nobody (UCCampaign spawns the scene without one). Set again when the sequence starts.
function CueTag()
{
	if (Tag != 'UCHBBreachCue')
	{
		Tag = 'UCHBBreachCue';
		Log("UCHarbourline: Tag UCHBBreachCue set (the welcome's trigger)");
	}
}

event Destroyed()
{
	local UCHBBlackWindow win;
	local int i;

	win = Black();
	if (win != None)
		win.Close(0);
	savedHand = None;
	evaCon = None;
	barkCon = None;
	for (i = 0; i < ArrayCount(qWho); i++)
		qWho[i] = None;
	Super.Destroyed();
}

// --- places -----------------------------------------------------------------
function vector PadPose()   { return vect(304, -528, 80); }   // Eva's helicopter on the pad, yaw 16384
function vector JCSpot()    { return vect(0, -320, 52); }     // PlayerStart: west of the pad rim lights, still beside Eva
function float LandHeight() { return 760; }                    // where the landing starts, above the pad
// the garage (plan 4.1-4.5, the map's Build B): keep these in step with hk_rooftop.py
function vector GateSpot()      { return vect(-29424, 448, 64); }    // the garage gate (UCHBGarageGate): the blast
function vector KwanCoverSpot() { return vect(-30240, -150, 48); }   // the aisle between containers 2 and 3
function vector KwanCoverLook() { return vect(-29700, -150, 48); }   // what Kwan faces from there: the hall
function vector KwanAfterSpot() { return vect(-29960, 140, 48); }    // where he waits for JC after the attack
function vector ShutterSpot()   { return vect(-29712, -445, 120); }  // the bay-1 shutter (UCHBShutter)
function vector CustodySpot()   { return vect(-30772, 412, 48); }    // the taken squad leader stands in front of the cold room's door
function vector ColdRoomSpot()  { return vect(-30832, 600, 48); }    // inside the cold room (door UCHBColdDoor)
function vector ColdGuardSpot() { return vect(-30915, 408, 48); }    // the man who walked him there, by the door (its west side)
function vector CanalExitSpot() { return vect(-28960, 1080, 48); }   // the lane's dead end "to the canal"
function bool PastBend(vector v) { return v.X > -29260 && v.Y > 960; }      // round the lane's bend
function bool InLane(vector v)   { return v.Y > 452 && v.X > -29600; }     // out through the gate

// The landing shot: the camera moves (eased in and out) from the first place to the second while it
// watches the helicopter come down, the neon city behind it. The first pair with a clear view is used
// (FastTrace sees only the level, not props or the helicopter): tune them from photos.
function bool CamPath(int i, out vector p0, out vector p1)
{
	switch (i)
	{
		case 0:     // south-east, over the street corner
			p0 = vect(900, -1300, 640);
			p1 = vect(700, -1000, 200);
			return True;
		case 1:     // south, over the avenue, east of the billboard
			p0 = vect(60, -1040, 400);
			p1 = vect(120, -980, 190);
			return True;
		case 2:     // east, over the side street
			p0 = vect(1150, -420, 420);
			p1 = vect(900, -460, 200);
			return True;
		case 3:     // on the roof, north of the pad
			p0 = vect(420, 300, 330);
			p1 = vect(420, -80, 150);
			return True;
	}
	return False;
}

function PickCamPath()
{
	local vector a, b, pad;
	local int i;

	pad = PadPose();
	for (i = 0; CamPath(i, a, b); i++)
		if (FastTrace(a, pad + vect(0,0,1) * LandHeight()) && FastTrace(b, pad + vect(0,0,60)) && FastTrace(a, b))
		{
			camA = a;
			camB = b;
			Log("UCHarbourline: landing camera" @ i @ a @ "->" @ b);
			return;
		}
	CamPath(0, camA, camB);
	Log("UCHarbourline: no landing camera with a clear view, using the first");
}

function BlackHelicopter Chopper()
{
	local BlackHelicopter h;

	foreach AllActors(class'BlackHelicopter', h, 'chopper')
		return h;
	return None;
}

function ScriptedPawn GuardPawn(string who)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.BindName ~= who && sp.Health > 0 && sp.bInWorld)
			return sp;
	return None;
}

function bool Within(ScriptedPawn sp, float dist)
{
	local DeusExPlayer P;

	P = Plr();
	return sp != None && P != None && sp.Health > 0 && VSize(sp.Location - P.Location) < dist && P.LineOfSightTo(sp);
}

// --- the old flow, switched off -----------------------------------------------
// Harbourline's people: friends of JC and of each other, enemies of the Luminous Path (UCHBPath).
// Before the talks are attached: the guards' conversation lists are emptied here.
function Friendly()
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (UCTransitGuard(sp) != None || sp.Alliance == 'Harbourline')
		{
			sp.ChangeAlly('Player', 1.0, True);
			sp.ChangeAlly('Harbourline', 1.0, True);
			sp.ChangeAlly('UCTransport', 1.0, True);    // guards of a game saved with the old alliance
			sp.ChangeAlly('UCHBPath', -1.0, True);
			if (UCTransitGuard(sp) != None)
				sp.ConListItems = None;
		}
}

function YardTalks()
{
}

function StartRaid()
{
}

function RaidTick()
{
}

function WoundedTalks()
{
}

// --- the talks ------------------------------------------------------------------
function RoofTalks()
{
	local BlackHelicopter heli;
	local ScriptedPawn lam, g1, g2;
	local UCCon c;

	foreach AllActors(class'BlackHelicopter', heli, 'chopper')
	{
		// the pilot is Eva (Jock is dead from Battery Park on): the cockpit exchange of the mission
		// design, started by the scene once the helicopter is down, then what she says if JC goes back
		heli.BindName = "Eva";
		heli.FamiliarName = "Eva";
		heli.UnfamiliarName = "Eva";
		heli.ConListItems = None;
		class'UCSceneBatteryPark'.static.PaintEva(heli);   // her dark blue helicopter, as at Battery Park
		c = new(Level) class'UCCon';
		c.Begin('UC_EvaRooftop', "Eva", False);
		c.Once();
		c.WideShot();
		c.Line("Eva", "JCDenton", "Harbourline Tower. I'm dropping you here and staying with the chopper.");
		c.Line("JCDenton", "Eva", "Copy that.");
		c.Line("Eva", "JCDenton", "My orders are to log when you come back. And who with.");
		c.Line("JCDenton", "Eva", "Simons' orders?");
		c.Line("Eva", "JCDenton", "Orders. Get out, Denton.");
		c.Done();
		c.AttachTo(heli);
		evaCon = c.con;
		c = new(Level) class'UCCon';
		c.Begin('UC_EvaRooftopAgain', "Eva", False);
		c.Once();
		c.WideShot();
		c.Require('UC_EvaRooftop_Played', True);
		c.Line("Eva", "JCDenton", "I've got nothing to say to you, Denton.");
		c.Done();
		c.AttachTo(heli);
		c = new(Level) class'UCCon';
		c.Begin('UC_EvaRooftopLast', "Eva", False);
		c.WideShot();
		c.Require('UC_EvaRooftopAgain_Played', True);
		c.Line("Eva", "JCDenton", "Go. It's your brother's clock that's running, not mine.");
		c.Done();
		c.AttachTo(heli);
	}

	lam = PawnTag('UCHBLam');
	if (lam != None)
	{
		lam.ConListItems = None;
		// the greeting in passing: started by the scene (Bark), never by a click
		c = new(Level) class'UCCon';
		c.Begin('UC_HBLamGreet', "UCHBLam", True);
		c.Passive();
		c.Once();
		c.NoFrob();
		c.Line("UCHBLam", "JCDenton", "Agent Denton. Mr. Kwan is waiting for you on the ground floor. The elevator is past the control room.");
		c.Done();
		c.AttachTo(lam);
		// clicked: the greeting first if JC has not heard it, then three answers; a question asked
		// is not offered again, "Thanks." ends it
		c = new(Level) class'UCCon';
		c.Begin('UC_HBLam', "UCHBLam", False);
		c.IfFlag('UC_HBLamGreet_Played', True, "Ask");
		c.Line("UCHBLam", "JCDenton", "Agent Denton. Mr. Kwan is waiting for you on the ground floor. The elevator is past the control room.");
		c.SetFlag('UC_HBLamGreet_Played', True);
		c.Label("Ask");
		c.Choices();
		c.Answer("What are you shipping?", "Cargo", 'UC_HBLamAskedCargo', False);
		c.Answer("How long have you worked here?", "Years", 'UC_HBLamAskedYears', False);
		c.Answer("Thanks.", "Thanks");
		c.Label("Cargo");
		c.Line("JCDenton", "UCHBLam", "What are you shipping?");
		c.Line("UCHBLam", "JCDenton", "Refrigerated goods. Medicine, I think. I watch the roof, not the containers.");
		c.SetFlag('UC_HBLamAskedCargo', True);
		c.Jump("Ask");
		c.Label("Years");
		c.Line("JCDenton", "UCHBLam", "How long have you worked here?");
		c.Line("UCHBLam", "JCDenton", "Long enough not to ask questions. I'd recommend the same, agent.");
		c.SetFlag('UC_HBLamAskedYears', True);
		c.Jump("Ask");
		c.Label("Thanks");
		c.Line("JCDenton", "UCHBLam", "Thanks.");
		c.Line("UCHBLam", "JCDenton", "Enjoy your stay in Hong Kong.");
		c.Done();
		c.AttachTo(lam);
	}

	// the two guards between the pad and the door: their exchange (overheard: started by the scene
	// with a wide radius, or by a click), then a line each
	g1 = GuardPawn("UCHBGuard1");
	g2 = GuardPawn("UCHBGuard2");
	if (g1 != None)
	{
		g1.ConListItems = None;
		c = new(Level) class'UCCon';
		c.Begin('UC_HBGuard1Line', "UCHBGuard1", True);
		c.Passive();
		c.Require('UC_HBGuardsTalk_Played', True);
		c.Line("UCHBGuard1", "JCDenton", "Hear those drums down at the market? The Path's been holding ceremonies for three nights.");
		c.Done();
		c.AttachTo(g1);
	}
	if (g2 != None)
	{
		g2.ConListItems = None;
		c = new(Level) class'UCCon';
		c.Begin('UC_HBGuard2Line', "UCHBGuard2", True);
		c.Passive();
		c.Require('UC_HBGuardsTalk_Played', True);
		c.Line("UCHBGuard2", "JCDenton", "Stay away from the railing, the wind up here is treacherous.");
		c.Done();
		c.AttachTo(g2);
	}
	if (g1 != None && g2 != None)
	{
		c = new(Level) class'UCCon';
		c.Begin('UC_HBGuardsTalk', "UCHBGuard1", True);
		c.Passive();
		c.Once();
		c.Line("UCHBGuard1", "UCHBGuard2", "Big shipment going out tonight?");
		c.Line("UCHBGuard2", "UCHBGuard1", "Five a.m. And Kwan wants everyone awake until the last container's gone.");
		c.Line("UCHBGuard1", "UCHBGuard2", "A UNATCO agent... I thought they'd send the other one. The one who got himself in trouble.");
		c.Line("UCHBGuard2", "UCHBGuard1", "Keep your voice down. That's his brother.");
		c.Done();
		c.AttachTo(g1);
		c.AttachTo(g2);
	}

	SmokerTalk();
}

// the guard on his smoke break at the control room's counter (Gabby, 18 Oct 2026): clicked, a line in
// passing, never a talk; the four in this order the first time, then any of them. The elevator is in the
// lobby's north wall: on the left of whoever comes in by the checkpoint door. Put back by the scene's loop
// whenever his list has lost it (Friendly empties the guards' lists; a load rebuilds them)
function SmokerTalk()
{
	local ScriptedPawn smoker;
	local UCCon c;

	smoker = PawnTag('UCHBSmoker');
	if (smoker == None && !bSmokerMissing)
		Log("UCHarbourline: no smoker (UCHBSmoker) to give his lines");
	bSmokerMissing = smoker == None;
	if (smoker != None && !HasCon(smoker, 'UC_HBSmokerLine'))
	{
		c = new(Level) class'UCCon';
		c.Begin('UC_HBSmokerLine', "UCHBSmoker", True);
		c.Passive();
		c.RandomBegin(self, True, False, True);
		c.RandomLabel("Lift");
		c.RandomLabel("Break");
		c.RandomLabel("Bother");
		c.RandomLabel("Lam");
		c.Label("Lift");
		c.Line("UCHBSmoker", "JCDenton", "The elevator? On the left as you came in. Can't miss it.");
		c.EndHere();
		c.Label("Break");
		c.Line("UCHBSmoker", "JCDenton", "This is my cigarette break, agent. Five minutes. That's all I get all night.");
		c.EndHere();
		c.Label("Bother");
		c.Line("UCHBSmoker", "JCDenton", "Don't bother me. I'm on my break.");
		c.EndHere();
		c.Label("Lam");
		c.Line("UCHBSmoker", "JCDenton", "Whatever it is, ask Lam. I'm smoking.");
		c.Done();
		c.AttachTo(smoker);
		Log("UCHarbourline: the smoker's lines (UC_HBSmokerLine)");
	}
}

// A line said in passing. The game cuts a first-person talk as soon as JC is 300 units from who
// started it, unless it was started by radius (DeusExPlayer.CheckActiveConversationRadius): so it
// starts as one, with a wide radius, only while it plays (BarkTick); left on, the game would start it
// by itself, also through walls. The conversation is passed directly, so its flags are not checked:
// that is the caller's job. (As UCSceneBatteryPark.Bark.) bMoving: who says it does not stop for it
// (Kwan running for cover: the game leaves his state alone).
function bool Bark(ScriptedPawn sp, name conName, int radius, optional bool bMoving)
{
	local ConListItem item;
	local bool bCan, bStarted;

	if (sp == None || Plr() == None || barkCon != None)
		return False;
	for (item = ConListItem(sp.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
		{
			item.con.bInvokeRadius = True;
			item.con.radiusDistance = radius;
			// a fighter of the Path in the fight (the game's state Attacking: bCanConverse False, and its
			// StartConversation asks CanConverse) still shouts: only for this call
			bCan = sp.bCanConverse;
			if (UCHBPathFighter(sp) != None && UCHBPathFighter(sp).bActivated)
				sp.bCanConverse = True;
			bStarted = Plr().StartConversation(sp, IM_Radius, item.con, bMoving, False);
			sp.bCanConverse = bCan;
			if (bStarted)
			{
				barkCon = item.con;
				return True;
			}
			item.con.bInvokeRadius = False;
			return False;
		}
	return False;
}

function BarkTick()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	// the guards' exchange started by a click gets the same wide radius while it plays
	if (barkCon == None && P.conPlay != None && P.conPlay.con != None && !P.conPlay.con.bInvokeRadius
		&& P.conPlay.con.conName == 'UC_HBGuardsTalk')
	{
		barkCon = P.conPlay.con;
		barkCon.bInvokeRadius = True;
		barkCon.radiusDistance = 900;
		return;
	}
	if (barkCon == None)
		return;
	if (P.conPlay != None && P.conPlay.con == barkCon)
		return;
	barkCon.bInvokeRadius = False;
	barkCon = None;
	lastBarkEnd = Level.TimeSeconds;
}

// Eva's cockpit talk, as soon as JC is on his feet beside the helicopter (or near it again after a
// reload that came before it).
function EvaTick()
{
	local BlackHelicopter h;
	local DeusExPlayer P;

	if (landPhase != 0 || evaCon == None || GetF('UC_EvaRooftop_Played') || Talking() || InfoBusy())
		return;
	h = Chopper();
	P = Plr();
	if (h == None || P == None || P.bHidden || P.Physics == PHYS_Falling || VSize(P.Location - h.Location) > 700)
		return;
	if (P.StartConversation(h, IM_Other, evaCon, False, False))
		Log("UCHarbourline: Eva's cockpit talk");
}

// After Eva: the title card, then Alex's call.
function AlexTick()
{
	local UCSceneHBAlexCall alex;

	if (!GetF('UC_EvaRooftop_Played') || Talking())
		return;
	if (!GetF('UC_HB_TitleShown'))
	{
		SetF('UC_HB_TitleShown', True);
		TitleCard("HONG KONG");
		titleWait = 4.0;
		return;
	}
	if (titleWait > 0)
	{
		titleWait -= 0.25;
		return;
	}
	if (GetF('UC_HB_AlexArrival') || bAlexSpawned || InfoBusy())
		return;
	foreach AllActors(class'UCSceneHBAlexCall', alex)
		return;
	bAlexSpawned = True;
	alex = Spawn(class'UCSceneHBAlexCall');
	if (alex != None)
		alex.which = 1;
	Log("UCHarbourline: Alex's call 1");
}

// Lam greets JC once Alex's call is over, when JC comes near and sees him; the guards talk when JC
// walks past them. Neither starts while JC is still where he got out of the helicopter (Gabby's review:
// "on approach", "walking past"): he has to walk off first. When both could start the nearer goes first,
// and the other then reaches a little further (JC was held up). Someone who can't talk (hurt, angry: the
// game refuses the line) is given up after a few tries and holds nobody up.
function PeopleTick()
{
	local ScriptedPawn lam, g1, g2;
	local DeusExPlayer P;
	local bool bLam, bGuards;
	local float rLam, rGuards;

	P = Plr();
	if (P == None || !GetF('UC_HB_AlexArrival') || Talking() || InfoBusy() || barkCon != None)
		return;
	if (VSize((P.Location - JCSpot()) * vect(1,1,0)) < 160)
		return;
	lam = PawnTag('UCHBLam');
	g1 = GuardPawn("UCHBGuard1");
	g2 = GuardPawn("UCHBGuard2");
	rLam = 450;
	if (GetF('UC_HBGuardsTalk_Played'))
		rLam = 600;
	rGuards = 380;
	if (GetF('UC_HBLamGreet_Played'))
		rGuards = 600;
	bLam = lamFails < 8 && !GetF('UC_HBLamGreet_Played') && Within(lam, rLam);
	bGuards = guardFails < 8 && !GetF('UC_HBGuardsTalk_Played') && g1 != None && g2 != None
		&& (Within(g1, rGuards) || Within(g2, rGuards));
	if (bLam && bGuards)
	{
		if (FMin(VSize(g1.Location - P.Location), VSize(g2.Location - P.Location)) < VSize(lam.Location - P.Location))
			bLam = False;
		else
			bGuards = False;
	}
	if (bLam)
	{
		if (Bark(lam, 'UC_HBLamGreet', 700))
			Log("UCHarbourline: Lam greets JC");
		else
		{
			lamFails++;
			if (lamFails >= 8)
				Log("UCHarbourline: Lam can't talk, no greeting");
		}
		return;
	}
	if (bGuards)
	{
		if (Bark(g1, 'UC_HBGuardsTalk', 900))
			Log("UCHarbourline: the roof guards talk");
		else
		{
			guardFails++;
			if (guardFails >= 8)
				Log("UCHarbourline: the roof guards can't talk, no exchange");
		}
	}
}

// No clicked talk while an InfoLink plays (Gabby's review): a third-person talk hides the HUD and Alex's
// window with it, and his lines would go by unseen. The talks of the people JC can click (Lam, Eva, the
// guards, Kwan...) take no clicks while InfoBusy() and take them again after; the ones switched off are
// remembered by name (a talk put back after a load comes back clickable and is switched off again).
function FrobTalks()
{
	local ScriptedPawn sp;
	local bool bBusy;

	bBusy = InfoBusy();
	if (!bBusy && numNoClick == 0)
		return;
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.ConListItems != None)
			FrobOff(sp, bBusy);
	if (Chopper() != None)
		FrobOff(Chopper(), bBusy);
	if (!bBusy)
		numNoClick = 0;
}

function FrobOff(Actor A, bool bOff)
{
	local ConListItem item;
	local int i;
	local bool bListed;

	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
	{
		if (item.con == None || Left(string(item.con.conName), 3) != "UC_")
			continue;
		bListed = False;
		for (i = 0; i < numNoClick; i++)
			if (noClick[i] == item.con.conName)
				bListed = True;
		if (!bOff)
		{
			if (bListed)
				item.con.bInvokeFrob = True;
			continue;
		}
		if (!item.con.bInvokeFrob)
			continue;
		if (!bListed)
		{
			if (numNoClick >= ArrayCount(noClick))
				continue;
			noClick[numNoClick] = item.con.conName;
			numNoClick++;
		}
		item.con.bInvokeFrob = False;
	}
}

// The game sets a talk's once-flag (<name>_Played) with its own expiration, the next mission (ConPlayBase,
// MissionScript): the ones this mission's story reads are set again here, with UC_'s 99, once seen.
function name OnceFlag(int i)
{
	switch (i)
	{
		case 0:  return 'UC_EvaRooftop_Played';
		case 1:  return 'UC_EvaRooftopAgain_Played';
		case 2:  return 'UC_EvaRooftopLast_Played';
		case 3:  return 'UC_HBLamGreet_Played';
		case 4:  return 'UC_HBLam_Played';
		case 5:  return 'UC_HBGuardsTalk_Played';
		case 6:  return 'UC_HBGuard1Line_Played';
		case 7:  return 'UC_HBGuard2Line_Played';
		case 8:  return 'UC_HBGuardPhoto_Played';
		case 9:  return 'UC_HBKwanWelcome_Played';
		case 10: return 'UC_HBKwanAfter_Played';
		case 11: return 'UC_HBKwanAgain_Played';
		case 12: return 'UC_HBLeaderTalk_Played';
	}
	return '';
}

function KeepOnceFlags()
{
	local int i;
	local name n;

	for (i = 0; i < 30; i++)
	{
		n = OnceFlag(i);
		if (n == '')
			return;
		if ((onceKept & (1 << i)) == 0 && GetF(n))
		{
			SetF(n, True);
			onceKept = onceKept | (1 << i);
		}
	}
}

// The desk PC: JC has had the email "Re: temperatures" on the screen for a second. In the map
// editor it is email 2 of UCHBDeskPC (UCTextBlock UCEmail_06_HongKong_WanChai_Rooftop_UCHBDeskPC_2,
// inbox 06_EmailMenu_HBSEC, comptexts.py); the first email of an inbox is selected by itself when it
// opens, so it is never the first. The email's name cannot be read from here (ComputerUIWindow's
// emailInfo is too large for a context expression): its subject is, in the selected row of the list
// (second field) and in the header above the text.
function MailWatch()
{
	local Computers comp;
	local ComputerScreenEmail w;
	local bool bOn;

	if (GetF('UC_HB_Mail4Read'))
		return;
	foreach AllActors(class'Computers', comp)
	{
		if ((comp.Name != 'UCHBDeskPC' && comp.Tag != 'UCHBDeskPC') || comp.termwindow == None)
			continue;
		w = ComputerScreenEmail(comp.termwindow.winComputer);
		if (w == None || w.lstEmail == None)
			continue;
		//#if revision
		if (InStr(Caps(w.lstEmail.GetField(w.lastFocusRowId, 1)), "TEMPERATURE") >= 0)
			bOn = True;
		//#else
		//// the original game's email list has no lastFocusRowId: the subject above the text says it
		//if (False)
		//	bOn = True;
		//#endif
		else if (w.winEmailSubject != None && InStr(Caps(w.winEmailSubject.GetText()), "TEMPERATURE") >= 0)
			bOn = True;
	}
	if (!bOn)
	{
		mailT = 0;
		return;
	}
	mailT += 0.25;
	if (mailT >= 1.0)
	{
		SetF('UC_HB_Mail4Read', True);
		Log("UCHarbourline: the container-4 email was read (UC_HB_Mail4Read)");
	}
}

function RoofTick()
{
	local ScriptedPawn lam;
	local DeusExMover door;

	// the game rebuilds the conversation lists after a load: put the talks back
	lam = PawnTag('UCHBLam');
	if (!Talking() && ((lam != None && !HasCon(lam, 'UC_HBLam')) || (Chopper() != None && !HasCon(Chopper(), 'UC_EvaRooftop'))))
		RoofTalks();
	EvaTick();
	AlexTick();
	PeopleTick();
	MailWatch();
	// a map built before Harbourline (its checkpoint door is not frobbable): open it as JC comes
	door = DeusExMover(FirstTag('UCRoofCheckpoint'));
	if (door != None && !door.bFrobbable && VSize(Plr().Location - door.Location) < 320)
		OpenDoor('UCRoofCheckpoint', True);
}

// --- the landing --------------------------------------------------------------------
// Out of view: the helicopter high above the pad, turned 60 degrees, collision off while it moves.
function PlaceHigh(BlackHelicopter h)
{
	local rotator r;

	h.SetCollision(False, False, False);
	class'UCHeliBlock'.static.Follow(h, False);
	h.bCollideWorld = False;
	h.SetPhysics(PHYS_None);
	h.SetLocation(PadPose() + vect(0,0,1) * LandHeight());
	r.Yaw = 16384 - 10923;
	h.SetRotation(r);
	h.SoundRadius = 255;
	h.SoundVolume = 255;
}

// On the pad, as the map has it.
function SettleChopper(BlackHelicopter h)
{
	local rotator r;

	h.SetCollision(False, False, False);
	h.bCollideWorld = False;
	h.SetPhysics(PHYS_None);
	h.SetLocation(PadPose());
	r.Yaw = 16384;
	h.SetRotation(r);
	h.SetCollision(True, True, True);
	class'UCHeliBlock'.static.Follow(h, True);    // its tail boom sticks out of the cylinder (Gabby, 18 Oct)
	h.bCollideWorld = True;
	h.SoundRadius = 48;
	h.SoundVolume = 100;
}

// The very first frame of a first arrival is black: UCTraveler.TravelPostAccept calls this on arrival,
// before anything is drawn (the scene itself starts half a second later), so the roof is never seen
// before the landing. The landing takes the black over (StartBlack); with no landing to come it fades by
// itself (UCHBBlackWindow) or at once (ReleaseBlack). The conditions are Playing.Begin's for a landing.
static function ArrivalBlack(DeusExPlayer P)
{
	local DeusExLevelInfo info, i;

	if (P == None || P.FlagBase == None)
		return;
	foreach P.AllActors(class'DeusExLevelInfo', i)
		info = i;
	if (info == None || !(info.MapName ~= "06_HongKong_WanChai_Rooftop"))
		return;
	if (!P.FlagBase.GetBool('UNATCORoute_DepartedNYC') || P.FlagBase.GetBool('UC_HB_LandingSeen')
		|| P.FlagBase.GetBool('UC_RooftopIntroduced') || P.FlagBase.GetBool('UC_EvaRooftop_Played'))
		return;
	if (class'UCHBBlackWindow'.static.Make(P, 6.0) != None)
		Log("UCHarbourline: first arrival, black from the first frame");
}

// The black of the landing, if it is up (found among the root window's children: no pointer is kept).
function UCHBBlackWindow Black()
{
	if (Plr() == None)
		return None;
	return class'UCHBBlackWindow'.static.Find(DeusExRootWindow(Plr().rootWindow));
}

// No landing to come (a reload, the garage): a black made on arrival goes.
function ReleaseBlack()
{
	local UCHBBlackWindow win;

	win = Black();
	if (win != None)
		win.Close(0.5);
}

// The black (and the bars) at once, the helicopter out of view, and JC in the game's cutscene state (as
// the game's intro and the map editor's UCCutscene): no input, no weapon, no saving. The game's arrival
// autosave waits until he has stepped out (MissionScript and Autosave refuse 'Interpolating' and try
// again later), and so do the quick save and the menu's: no game can be saved during the landing or
// Eva's talk. The black may already be there (ArrivalBlack).
// The blob shadow is a separate decal: hiding the player mesh does not remove it, and
// Interpolating does not run the normal player shadow update. Never leave a ghost on the pad.
function HideLandingPlayer()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	P.bHidden = True;
	if (P.Shadow != None)
		bLandingHadShadow = True;
	P.KillShadow();
}

function RevealLandingPlayer()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	P.bHidden = False;
	if (bLandingHadShadow && P.Style != STY_Translucent)
		P.CreateShadow();
	bLandingHadShadow = False;
}

function StartBlack()
{
	local BlackHelicopter h;
	local DeusExPlayer P;

	h = Chopper();
	if (h != None)
		PlaceHigh(h);
	P = Plr();
	if (P == None)
		return;
	class'UCHBBlackWindow'.static.Make(P, 2.0);
	HideLandingPlayer();
	if (P.IsInState('Interpolating'))
		return;
	savedHand = P.inHand;
	if (savedHand != None)
		P.PutInHand(None);          // (refused while the game still counts JC as travelling: the state hides it)
	if (P.CarriedDecoration != None)
		P.DropDecoration();
	P.Velocity = vect(0,0,0);
	P.Acceleration = vect(0,0,0);
	P.NextState = '';
	P.GotoState('Interpolating');
	Log("UCHarbourline: black, JC in the cutscene state");
}

function LandStart()
{
	local BlackHelicopter h;

	h = Chopper();
	if (h == None || Plr() == None)
	{
		landPhase = 3;
		return;
	}
	PlaceHigh(h);
	PickCamPath();
	CutsceneStart(camA, h);
	HideLandingPlayer();
	CamLookAt(h);
	landT = 0;
	holdT = 0;
	descentV = 0;
	landPhase = 1;
	Log("UCHarbourline: the landing starts");
}

function Touchdown(BlackHelicopter h)
{
	SettleChopper(h);
	h.SoundRadius = 255;
	h.SoundVolume = 255;
	soundT = 3.0;            // the rotor quietens to the map's level over 3 seconds (EaseSound)
	descentV = 0;
	holdT = 0;
	landPhase = 2;
	Log("UCHarbourline: Eva's helicopter is down");
}

// Eva's talk starts AFTER touchdown: under the black, position and reveal JC beside the
// cockpit before StartConversation creates its camera. Only the landing hides him. The
// game takes JC out of the cutscene state for the talk and puts him back in it at its end (NextState):
// no input, no saving in between. False: it can't start (JC steps out and she talks then: EvaTick).
function bool CockpitTalk()
{
	local BlackHelicopter h;
	local DeusExPlayer P;
	local UCCam cam;
	local rotator r;

	h = Chopper();
	P = Plr();
	if (h == None || P == None || evaCon == None || GetF('UC_EvaRooftop_Played'))
		return False;
	if (VSize(h.Location - PadPose()) > 4)
		SettleChopper(h);
	cam = FindCam();
	if (cam != None)
		cam.Destroy();
	P.ViewTarget = None;
	P.bBehindView = False;
	P.SetLocation(JCSpot());
	r = rotator(PadPose() - JCSpot());
	r.Pitch = 0;
	r.Roll = 0;
	P.SetRotation(r);
	P.ViewRotation = r;
	RevealLandingPlayer();
	P.NextState = 'Interpolating';
	if (!P.StartConversation(h, IM_Other, evaCon, False, False))
	{
		P.NextState = '';
		Log("UCHarbourline: Eva's cockpit talk can't start, JC steps out first");
		return False;
	}
	holdT = 0;
	landPhase = 4;
	Log("UCHarbourline: Eva's cockpit talk, JC visible beside the helicopter");
	return True;
}

// While the talk plays the black of the shot's end lifts on it (the conversation has its own bars);
// when it is over, black at once: JC gets out (state Landing, LandEnd).
function TalkTick(float dt, UCHBBlackWindow win)
{
	local DeusExPlayer P;

	P = Plr();
	holdT += dt;
	if (landPhase == 4)
	{
		if (win != None)
		{
			win.bBars = False;
			win.fade = FClamp(1 - holdT / 0.8, 0, 1);
		}
		if (P == None || P.conPlay == None)
		{
			landPhase = 5;
			holdT = 0;
			if (win != None)
				win.fade = 1;
		}
		return;
	}
	if (win == None && P != None)
		win = class'UCHBBlackWindow'.static.Make(P, 1.0);
	if (win != None)
	{
		win.bBars = False;
		win.fade = 1;
	}
}

// JC steps out beside the door, facing the cockpit, back in the game's normal state with what he held;
// the black lifts on his own view.
function LandEnd()
{
	local DeusExPlayer P;
	local BlackHelicopter h;
	local UCHBBlackWindow win;
	local rotator r;

	h = Chopper();
	if (h != None && VSize(h.Location - PadPose()) > 4)
		Touchdown(h);
	P = Plr();
	if (P != None)
	{
		P.SetLocation(JCSpot());
		r = rotator(PadPose() - JCSpot());
		r.Pitch = 0;
		r.Roll = 0;
		P.SetRotation(r);
		P.ViewRotation = r;
	}
	CutsceneEnd();
	RevealLandingPlayer();
	if (P != None)
	{
		P.NextState = '';
		if (P.IsInState('Interpolating'))
			P.GotoState('PlayerWalking');
		P.bDetectable = True;
		P.ShowHud(True);
		GiveBackHand(P);
	}
	win = Black();
	if (win != None)
	{
		win.bBars = False;
		win.fade = 1;
		win.Close(0.8);
	}
	landPhase = 0;
	Log("UCHarbourline: the landing is over, JC steps out");
}

// What JC held goes back in his hands. The cutscene state hides it and takes it out of his hands
// (DeusExPlayer.Interpolating) even when the game refused to put it away (JC still "travelling").
function GiveBackHand(DeusExPlayer P)
{
	local Weapon W;

	if (P == None || savedHand == None || savedHand.bDeleteMe || savedHand.Owner != P)
	{
		savedHand = None;
		return;
	}
	W = Weapon(savedHand);
	if (W != None)
		W.bHideWeapon = False;
	if (P.inHand != savedHand)
		P.PutInHand(savedHand);
	else if (W != None && P.Weapon == None)
		P.Weapon = W;
	savedHand = None;
}

// A game saved in the middle of the landing by an older version of this scene (the landing can't be
// saved any more): the helicopter on the pad, JC back on his feet beside it, level, under a short black.
function Recover()
{
	local BlackHelicopter h;
	local DeusExPlayer P;
	local UCHBBlackWindow win;
	local rotator r;

	h = Chopper();
	if (h != None && VSize(h.Location - PadPose()) > 4)
	{
		SettleChopper(h);
		Log("UCHarbourline: helicopter put back on the pad");
	}
	else if (h != None && h.bCollideActors)
		class'UCHeliBlock'.static.Follow(h, True);   // a game saved before the tail had its row
	P = Plr();
	if (P == None || !P.bHidden || P.bCollideActors || FindCam() != None || landPhase != 0)
		return;
	win = class'UCHBBlackWindow'.static.Make(P, 1.0);
	P.SetLocation(JCSpot());
	r = rotator(PadPose() - JCSpot());
	r.Pitch = 0;
	r.Roll = 0;
	P.SetRotation(r);
	P.ViewRotation = r;
	CutsceneEnd();
	P.NextState = '';
	if (P.IsInState('Interpolating'))
		P.GotoState('PlayerWalking');
	P.bDetectable = True;
	P.ShowHud(True);
	if (win != None)
		win.Close(0.8);
	Log("UCHarbourline: JC back on his feet (a game saved during the landing)");
}

function EaseSound(float dt)
{
	local BlackHelicopter h;
	local float f;

	soundT = FMax(0, soundT - dt);
	h = Chopper();
	if (h == None)
		return;
	f = soundT / 3.0;
	f = f * f * (3 - 2 * f);
	h.SoundRadius = byte(Clamp(int(48 + 207 * f), 0, 255));
	h.SoundVolume = byte(Clamp(int(100 + 155 * f), 0, 255));
}

// Every frame: first the garage (FrameTick: it must never be skipped by the landing's returns below);
// then, during the landing, the helicopter comes down with an eased speed (fast high up, slowing near the
// pad, as Eva's at Battery Park), straightening as it comes; the camera glides from its first place to
// its last; the fades; Eva's talk. UCCam re-aims at the helicopter after this (spawned later, it ticks
// later).
event Tick(float dt)
{
	local BlackHelicopter h;
	local UCCam cam;
	local UCHBBlackWindow win;
	local float height, want, f, stepZ;
	local rotator r;

	FrameTick(dt);
	if (soundT > 0)
		EaseSound(dt);
	// Some player variants recreate their decal. Suppress it only in the landing,
	// never while Eva's conversation camera is showing JC.
	if (landPhase >= 1 && landPhase <= 3)
		HideLandingPlayer();
	if (landPhase == 0 || landPhase == 3)
		return;
	win = Black();
	if (win != None)
		win.Keep(Self, 1.0);
	if (landPhase >= 4)
	{
		TalkTick(dt, win);
		return;
	}
	h = Chopper();
	if (h == None)
	{
		landPhase = 3;
		return;
	}
	landT += dt;
	cam = FindCam();
	if (cam != None)
	{
		f = FClamp(landT / 6.5, 0, 1);
		cam.shotPosition = camA + (camB - camA) * (f * f * (3 - 2 * f));
	}
	if (landPhase == 1)
	{
		if (win != None)
			win.fade = FClamp(1 - landT / 1.5, 0, 1);
		height = h.Location.Z - PadPose().Z;
		want = FClamp(height * 0.8, 16, 300);
		descentV += FClamp(want - descentV, -250 * dt, 250 * dt);
		stepZ = descentV * dt;
		if (height - stepZ <= 0.05)     // this frame's step reaches the pad
		{
			Touchdown(h);
			return;
		}
		h.SetLocation(h.Location - vect(0,0,1) * stepZ);
		f = FClamp((height - 60) / (LandHeight() - 60), 0, 1);
		r.Yaw = 16384 - int(10923 * f * f * (3 - 2 * f));
		h.SetRotation(r);
		return;
	}
	// on the pad: the shot holds a moment, then goes to black
	holdT += dt;
	if (win != None && holdT > 1.4)
		win.fade = FClamp((holdT - 1.4) / 0.6, 0, 1);
	if (holdT >= 2.0)
		landPhase = 3;
}

// --- the garage (phases 4-5) ----------------------------------------------------------------------
// Every frame: the cut on "bro-", the blast's later doors, the charges' countdown (every 0.25 s, also
// while the lift rides: the lift's states don't run the loop).
function FrameTick(float dt)
{
	if (Plr() == None)
		return;
	if (bCue)
		CueTick(dt);
	if (bBreachRun)
		BreachSteps(dt);
	chargeT += dt;
	if (chargeT >= 0.25)
	{
		chargeT = 0;
		ChargeTick();
	}
}

function UCHBKwan Kwan()
{
	local UCHBKwan k;

	foreach AllActors(class'UCHBKwan', k)
		if (k.bInWorld && !k.bDeleteMe)
			return k;
	return None;
}

function Conversation ConOf(Actor A, name conName)
{
	local ConListItem item;

	if (A == None)
		return None;
	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
			return item.con;
	return None;
}

// A conversation with the camera (third person) is playing (barks don't count).
function bool CinematicTalk()
{
	local DeusExPlayer P;

	P = Plr();
	return P != None && P.conPlay != None && P.conPlay.con != None && !P.conPlay.con.bFirstPerson;
}

function bool WelcomePlaying()
{
	local DeusExPlayer P;

	P = Plr();
	return P != None && P.conPlay != None && P.conPlay.con != None && P.conPlay.con.conName == 'UC_HBKwanWelcome';
}

// Kwan's talks (attached again after a load: the game rebuilds the conversation lists). Phase 6's
// (the debrief, the custody) go here too.
function KwanTalks(UCHBKwan k)
{
	local UCCon c;

	if (k == None)
		return;
	k.ConListItems = None;
	k.BindName = "VictorKwan";
	// the welcome, a few metres from him (cinematic, once): the blast cuts his last line on "bro-"; its
	// trigger (UCHBBreachCue, this scene: Trigger) comes just before that line
	c = new(Level) class'UCCon';
	c.Begin('UC_HBKwanWelcome', "VictorKwan", False);
	c.Once();
	c.Require('UC_HB_BreachStarted', False);
	c.Line("VictorKwan", "JCDenton", "Agent Denton. Victor Kwan, Harbourline security. Welcome to Hong Kong.");
	c.Line("JCDenton", "VictorKwan", "I was told you have a vehicle for me.");
	c.Trigger('UCHBBreachCue');
	c.Line("VictorKwan", "JCDenton", "Ready and fueled. And I have a man who knows the area around the airstrip where your bro-");
	c.Done();
	c.AttachTo(k);
	// what he shouts as he runs for cover (a bark: Breach, BreachSteps)
	c = new(Level) class'UCCon';
	c.Begin('UC_HBKwanBreach', "VictorKwan", True);
	c.Passive();
	c.NoFrob();
	c.Line("VictorKwan", "JCDenton", "The Path! Everyone to the containers!");
	c.Done();
	c.AttachTo(k);
	// what he shouts from cover during the fight (barks: PlantBarks, OnChargeBlew)
	c = new(Level) class'UCCon';
	c.Begin('UC_HBKwanOpens', "VictorKwan", True);
	c.Passive();
	c.NoFrob();
	c.Line("VictorKwan", "JCDenton", "If one of those opens, nobody walks out of here!");
	c.Done();
	c.AttachTo(k);
	c = new(Level) class'UCCon';
	c.Begin('UC_HBKwanFour', "VictorKwan", True);
	c.Passive();
	c.NoFrob();
	c.Line("VictorKwan", "JCDenton", "They're going for number four. Number four!");
	c.Done();
	c.AttachTo(k);
	c = new(Level) class'UCCon';
	c.Begin('UC_HBKwanContainers', "VictorKwan", True);
	c.Passive();
	c.NoFrob();
	c.Line("VictorKwan", "JCDenton", "The containers, Denton! Not my men, the containers!");
	c.Done();
	c.AttachTo(k);
	c = new(Level) class'UCCon';
	c.Begin('UC_HBKwanBlew', "VictorKwan", True);
	c.Passive();
	c.NoFrob();
	c.Line("VictorKwan", "JCDenton", "Get away from that container! Nobody breathe near that stuff!");
	c.Done();
	c.AttachTo(k);
	// after the fight, at his place (DebriefTick, or a click): the debrief (plan 6.2). JC's question is
	// asked face to face (the InfoLinks are one-way); the container-4 answer only if JC read the email
	// (UC_HB_Mail4Read), two answers at most; it ends with the airstrip (UC_HB_AirstripKnown, goal
	// UCHBAirstrip).
	c = new(Level) class'UCCon';
	c.Begin('UC_HBKwanAfter', "VictorKwan", False);
	c.Once();
	c.Require('UC_HB_BreachOver', True);
	c.Line("VictorKwan", "JCDenton", "Is it over? ...Good. We have maybe ten minutes before the military police get here. What you saw tonight didn't happen.");
	c.Line("JCDenton", "VictorKwan", "They wanted to destroy the shipment. Why?");
	c.Line("VictorKwan", "JCDenton", "Because they're fanatics, agent. The Path sees demons everywhere. It's medicine. I'm sure you were told.");
	c.IfFlag('UC_HB_ContainerBlew', True, "Blew");
	c.Line("VictorKwan", "JCDenton", "The client will be relieved. So will Simons, I imagine.");
	c.Jump("Mail");
	c.Label("Blew");
	c.Line("VictorKwan", "JCDenton", "You let a container go up, agent. That goes in my report. It's not a threat, it's my job.");
	c.Label("Mail");
	c.IfFlag('UC_HB_Mail4Read', False, "Airstrip");
	c.Choices();
	c.Answer("Container 4. They were after it by number.", "Four");
	c.Answer("Tell me about the airstrip.", "Ask");
	c.Label("Four");
	c.Line("JCDenton", "VictorKwan", "Container 4. They were after it by number.");
	c.Line("VictorKwan", "JCDenton", "...You read other people's mail, Agent Denton.");
	c.Jump("Airstrip");
	c.Label("Ask");
	c.Line("JCDenton", "VictorKwan", "Tell me about the airstrip.");
	c.Label("Airstrip");
	c.Line("VictorKwan", "JCDenton", "The airstrip you're looking for is past the harbor, to the north. The pilot's name is Lo. If he's still alive.");
	c.SetFlag('UC_HB_AirstripKnown', True);
	c.Goal('UCHBAirstrip', "Find the private airstrip north of the harbor where Paul's plane landed. Kwan's pilot is Lo.", False);
	c.Done();
	c.AttachTo(k);
	// then, if JC goes back to him
	c = new(Level) class'UCCon';
	c.Begin('UC_HBKwanAgain', "VictorKwan", True);
	c.Passive();
	c.Require('UC_HBKwanAfter_Played', True);
	c.Line("VictorKwan", "JCDenton", "Past the harbor, to the north. Ask for Lo.");
	c.Done();
	c.AttachTo(k);
}

// One of Kwan's men has seen JC's photo (a bark, once, as JC comes in).
function GuardTalks(ScriptedPawn ga)
{
	local UCCon c;

	if (ga == None)
		return;
	c = new(Level) class'UCCon';
	c.Begin('UC_HBGuardPhoto', "UCHBGuardA", True);
	c.Passive();
	c.Once();
	c.NoFrob();
	c.Line("UCHBGuardA", "JCDenton", "Is that him? He looked younger in the photo.");
	c.Done();
	c.AttachTo(ga);
}

// The garage, every 0.25 s while JC is down there: the way out shut until the attack is over, the
// talks put back after a load, Kwan's moment, then the welcome (before the blast) or the fight (after).
function DockTick()
{
	local UCHBKwan k;
	local ScriptedPawn ga;

	ExitLock(!GetF('UC_HB_BreachOver'));
	k = Kwan();
	ga = GuardPawn("UCHBGuardA");
	if (k != None && !Talking() && !HasCon(k, 'UC_HBKwanBreach'))
		KwanTalks(k);
	if (ga != None && !Talking() && !HasCon(ga, 'UC_HBGuardPhoto'))
		GuardTalks(ga);
	KwanTick(k);
	if (!GetF('UC_HB_BreachStarted'))
		WelcomeTick(k, ga);
	else
		BreachTick();
}

// Kwan can't die (D7) and, from the blast to the end of the fight, he is in cover (after a load, after
// anything that took him out of it: his orders say HBCover).
function KwanTick(UCHBKwan k)
{
	if (k == None)
		return;
	if (!k.bInvincible)
		k.bInvincible = True;
	if (GetF('UC_HB_BreachStarted') && !GetF('UC_HB_BreachOver') && k.Orders != 'HBCover' && !CinematicTalk())
	{
		k.TakeCover(KwanCoverSpot(), KwanCoverLook());
		Log("UCHarbourline: Kwan runs for cover");
	}
	else if (GetF('UC_HB_BreachOver') && k.Orders != 'HBDebrief' && !CinematicTalk())
	{
		k.Debrief(KwanAfterSpot());
		Log("UCHarbourline: Kwan comes out of cover");
	}
}

// Before the blast (plan 4.9): as JC comes in, one of Kwan's men has seen his photo ("Is that him?":
// within 450 of Kwan, who JC can see: off the lift, on his way to him); then, a few metres from Kwan, his
// welcome. Nothing while another conversation or an InfoLink plays.
function WelcomeTick(UCHBKwan k, ScriptedPawn ga)
{
	local DeusExPlayer P;
	local Conversation con;

	P = Plr();
	if (P == None || bCue)
		return;
	// the welcome was heard (or cut short) but the blast never came (a game loaded in between): now
	if (GetF('UC_HBKwanWelcome_Played'))
	{
		if (!Talking())
			Breach();
		return;
	}
	KwanApproach(k, P);
	if (k == None || Talking() || InfoBusy())
		return;
	if (!GetF('UC_HBGuardPhoto_Played') && ga != None && photoTries < 8 && Within(k, 450) && OffTheLift())
	{
		if (!Queued('UC_HBGuardPhoto'))
		{
			QueueBark(ga, 'UC_HBGuardPhoto', 3);
			photoTries++;
		}
		return;
	}
	if (barkCon != None)
		return;
	con = ConOf(k, 'UC_HBKwanWelcome');
	if (con != None && Within(k, 260) && P.StartConversation(k, IM_Other, con, False, False))
	{
		bKwanComing = False;
		k.SetOrders('Standing', '', True);
		Log("UCHarbourline: Kwan's welcome");
	}
}

// Two seconds after JC is out of the dock lift, in the hall, Kwan walks up to him (Gabby, 16 Oct);
// a few steps off he stops and the welcome starts (WelcomeTick, within 260).
function KwanApproach(UCHBKwan k, DeusExPlayer P)
{
	if (k == None || P == None || GetF('UC_HBKwanWelcome_Played'))
		return;
	if (!AtDock() || !OffTheLift())
	{
		offLiftAt = 0;
		return;
	}
	if (offLiftAt == 0)
		offLiftAt = Level.TimeSeconds;
	if (Level.TimeSeconds - offLiftAt < 2.0 || Talking())
		return;
	if (VSize((k.Location - P.Location) * vect(1,1,0)) > 220)
	{
		if (!bKwanComing || !k.IsInState('GoingTo'))
		{
			bKwanComing = True;
			k.SetOrders('GoingTo', '', True);      // no tag: towards the player
			Log("UCHarbourline: Kwan walks up to JC");
		}
	}
	else if (k.IsInState('GoingTo'))
		k.SetOrders('Standing', '', True);
}

// The welcome's cue, just before Kwan's last line (UC_HBKwanWelcome triggers this scene's Tag,
// UCHBBreachCue): the blast cuts the line on "bro-", about when his voice gets there (0.9 of it; 2.4
// seconds while he has no voice of his own: such a line would wait for a click). JC clicking on before
// that ends the talk: the blast comes at once (CueTick).
function Trigger(Actor Other, Pawn EventInstigator)
{
	if (bCue || GetF('UC_HB_BreachStarted'))
		return;
	bCue = True;
	cueT = CutSeconds();
	Log("UCHarbourline: Kwan's welcome reaches the blast's cue," @ cueT @ "s to the cut");
}

// How long Kwan's cut line plays before "bro-" (the same text as in KwanTalks: the voice is found by it).
function float CutSeconds()
{
	local Sound snd;
	local string text;

	text = "Ready and fueled. And I have a man who knows the area around the airstrip where your bro-";
	snd = class'UCVoiceBank'.static.Resolve(Self, "VictorKwan", text);
	if (snd == None)
		snd = class'UCVoice'.static.Find(text, class'UCVoice'.static.Profile(Kwan(), "VictorKwan"));
	if (snd != None)
		return class'UCInfoVoice'.static.GameSeconds(Self, GetSoundDuration(snd) * 0.9);
	return 2.4;
}

function CueTick(float dt)
{
	local DeusExPlayer P;

	cueT -= dt;
	if (cueT > 0 && WelcomePlaying())
		return;
	bCue = False;
	P = Plr();
	if (P != None && WelcomePlaying())
		P.conPlay.TerminateConversation();
	Breach();
}

// The Luminous Path blows the garage gate (plan 4.10). The squad has waited behind the closed doors,
// hidden: it is told now (RevealPath), in the same moment the gate and the bay's shutter go; the other
// doors follow (BreachSteps). The gate post guard dies in the blast. Kwan runs for cover (KwanTick, as
// soon as the welcome's window has closed) shouting (+0.3 s, priority 11: the first line after the blast,
// before the Path's cries; at 0.8 s and priority 9 it came after the leader's "The doctor was right", 7-8
// seconds late: photo tests 15 Oct). The goals of the doc come once that window has closed (BreachGoals:
// they would pop up over it).
function Breach()
{
	local DeusExPlayer P;
	local ScriptedPawn gg;
	local vector loc;

	P = Plr();
	if (P == None || GetF('UC_HB_BreachStarted'))
		return;
	SetF('UC_HB_BreachStarted', True);
	bCue = False;
	RevealPath();
	QueueBark(Kwan(), 'UC_HBKwanBreach', 11, 0.3, True);
	EntryBarks();
	BreakDoor('UCHBGarageGate');
	BreakDoor('UCHBShutter');
	loc = GateSpot();
	Spawn(class'ExplosionLarge',,, loc);
	Spawn(class'ExplosionLight',,, loc);
	P.PlaySound(Sound'DeusExSounds.Generic.LargeExplosion1', SLOT_None, 2.0,, 4096);
	P.ShakeView(1.0, 900, 36);
	gg = GuardPawn("UCHBGateGuard0");
	if (gg != None)
		gg.TakeDamage(400, None, gg.Location, vect(0,0,0), 'Exploded');
	breachT = 0;
	breachStep = 0;
	bBreachRun = True;
	Log("UCHarbourline: the Luminous Path blows the garage gate (UC_HB_BreachStarted)");
}

function AddGoal(name goalName, string text)
{
	if (Plr() != None && Plr().FindGoal(goalName) == None)
		GoalNew(goalName, text);
}

// The attack's goals (the doc's wording), once no conversation window is up (the welcome's, cut by the blast,
// closes after it): FightTick, at the latest BreachOver. The game keeps them in a saved game (AddGoal: not twice).
function BreachGoals()
{
	if (bGoalsSet || CinematicTalk())
		return;
	bGoalsSet = True;
	GoalDone('UCHBMeetKwan');
	AddGoal('UCHBRepel', "Repel the attack.");
	AddGoal('UCHBDefuse', "Defuse the charges on the containers.");
	AddGoal('UCHBLeader', "Kill or capture the squad leader.");
}

// Every fighter of the Luminous Path (Alliance UCHBPath: UCHBPathFighter, UCHBPathLeader) is told the
// attack has begun (Trigger: they answer with ActivateBreach). They have waited hidden, behind doors.
function RevealPath()
{
	local ScriptedPawn sp;
	local int n;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.Health > 0 && (sp.Alliance == 'UCHBPath' || sp.IsA('UCHBPathFighter') || sp.IsA('UCHBPathLeader')))
		{
			sp.Trigger(Self, Plr());
			n++;
		}
	Log("UCHarbourline: the Path squad attacks:" @ n);
}

// The blast's later doors (the trailer, the back room, the maintenance room: fighters wait behind
// them). Kwan's shout as he runs for cover is queued by Breach.
function BreachSteps(float dt)
{
	breachT += dt;
	if (breachStep == 0 && breachT >= 0.3)
	{
		BreakDoor('UCYardTrailer');
		breachStep = 1;
	}
	if (breachStep == 1 && breachT >= 0.6)
	{
		BreakDoor('UCYardBackroom');
		breachStep = 2;
	}
	if (breachStep == 2 && breachT >= 0.8)
		breachStep = 3;
	if (breachStep == 3 && breachT >= 0.9)
	{
		BreakDoor('UCYardMaintenance');
		breachStep = 4;
		bBreachRun = False;
	}
}

// After the blast, every 0.25 s while JC is in the garage: the fight (FightTick: the fighters' targets,
// the retreat, the barks, its end, BreachOver: UC_HB_BreachOver, which also opens the service stair,
// ExitLock), then what comes after it (AfterTick).
// A game saved in the blast's first second (bBreachRun is the scene's, not saved) comes back with the
// trailer's, the back room's and the maintenance room's doors still shut: they go now (BreakDoor leaves a door
// already gone alone). Not on the debug jump after the attack (DebugAftermath).
function BreachTick()
{
	if (!bBreachRun && breachStep < 4 && !GetF('UC_HB_BreachOver'))
	{
		breachStep = 4;
		BreakDoor('UCYardTrailer');
		BreakDoor('UCYardBackroom');
		BreakDoor('UCYardMaintenance');
	}
	if (GetF('UC_HB_BreachOver'))
		AfterTick();
	else
		FightTick();
}

// The freight lift doesn't run from the blast to the end of the fight (the charges count down and the fight
// goes on only while JC is down here: up on the roof everything would wait for him).
function UseLift(DeusExPlayer P, bool bToRoof)
{
	if (GetF('UC_HB_BreachStarted') && !GetF('UC_HB_BreachOver'))
	{
		if (P != None && !bLiftBusy)
			P.ClientMessage("The freight lift doesn't respond.");
		return;
	}
	Super.UseLift(P, bToRoof);
}

// D2 (Gabby): the service stair up to the butcher's shop and Wan Chai Street is shut from JC's arrival
// until the attack is over: its door locked and not pickable, its level change off. Saved with the map.
function ExitLock(bool bLock)
{
	local DeusExMover door;
	local Teleporter t;

	foreach AllActors(class'DeusExMover', door, 'UCShopBackDoor')
		if (door.bLocked != bLock)
		{
			door.bLocked = bLock;
			door.bPickable = False;
			Log("UCHarbourline: the service stair door, locked" @ bLock);
		}
	foreach AllActors(class'Teleporter', t, 'UCShopUp')
		if (t.bEnabled == bLock)
			t.bEnabled = !bLock;
}

// The charges (UCHBCharge, plan 5.3-5.4): the HUD's countdown shows the one that blows first ("Charge -
// container N", red under 10 seconds), gone when none is armed, made again after a load. The game has one
// timer window (DeusExHUD.timer): if one of its own is up, the charges' beeps say the rest. A charge armed,
// defused or blown is news once (not again after a load): OnCharge* (phase 5's barks).
function ChargeTick()
{
	local UCHBCharge c, soonest;
	local DeusExRootWindow root;
	local UCHBChargeTimer win;
	local int bit;

	foreach AllActors(class'UCHBCharge', c)
	{
		bit = 1 << c.container;
		if (c.bArmed && (armedBits & bit) == 0)
		{
			armedBits = armedBits | bit;
			if (bChargesSeen)
				OnChargeArmed(c);
		}
		if (c.bDefused && (defusedBits & bit) == 0)
		{
			defusedBits = defusedBits | bit;
			if (bChargesSeen)
				OnChargeDefused(c);
		}
		if (c.bBlown && (blownBits & bit) == 0)
		{
			blownBits = blownBits | bit;
			if (bChargesSeen)
				OnChargeBlew(c);
		}
		if (c.IsArmed() && (soonest == None || c.fuseLeft < soonest.fuseLeft))
			soonest = c;
	}
	bChargesSeen = True;
	root = DeusExRootWindow(Plr().rootWindow);
	if (root == None || root.hud == None)
		return;
	win = UCHBChargeTimer(root.hud.timer);
	if (soonest == None)
	{
		if (win != None)
			win.Destroy();
		return;
	}
	if (root.hud.timer == None)
	{
		win = UCHBChargeTimer(root.hud.NewChild(class'UCHBChargeTimer'));
		root.hud.timer = win;
		if (win != None)
			win.AskParentForReconfigure();
	}
	if (win == None)
		return;
	win.Keep(Self);
	win.message = "Charge - container" @ soonest.container;
	win.time = FMax(0, soonest.fuseLeft);
	win.bCritical = soonest.fuseLeft < 10;
}

// The charge on container n (2, 4 or 6): what a planter arms (UCHBCharge.Arm, phase 5).
function UCHBCharge ChargeOn(int n)
{
	local UCHBCharge c;

	foreach AllActors(class'UCHBCharge', c)
		if (c.container == n)
			return c;
	return None;
}

// News of the charges (seen live, not again after a load). The barks that follow a charge's time
// (Kwan's "If one of those opens...", the planters' "Thirty seconds!") are PlantBarks'.
function OnChargeArmed(UCHBCharge c)
{
	Log("UCHarbourline: the charge on container" @ c.container @ "is armed");
}

function OnChargeDefused(UCHBCharge c)
{
	Log("UCHarbourline: JC defused the charge on container" @ c.container);
}

function OnChargeBlew(UCHBCharge c)
{
	Log("UCHarbourline: container" @ c.container @ "blew");
	KwanBark('UC_HBKwanBlew', 0.5);
}

// --- the barks of the garage: one at a time ----------------------------------------------------------
// A line said in passing (Bark, radius 1600) waits its turn here: one at a time, 3 seconds from the start
// of one to the start of the next (and a second after the last one ended), the most important first
// (Kwan 9, the Path's entry 5, the squad leader 6, the others 3-4; the same priority in the order they
// came), never over a conversation or an InfoLink. It is dropped when it has waited maxWait seconds (4 by
// default, 10 for Kwan's: the moment has gone) or its speaker is down; one the game refuses (the speaker
// is reeling from a hit) is tried again until then.
// delay: not before so many seconds. bMoving: who says it keeps doing what he does (Bark).
function QueueBark(ScriptedPawn sp, name conName, int prio, optional float delay, optional bool bMoving, optional float maxWait)
{
	local int i;

	if (sp == None || sp.Health <= 0 || conName == '')
		return;
	for (i = 0; i < qN; i++)
		if (qCon[i] == conName && qWho[i] == sp)
			return;
	if (qN >= ArrayCount(qCon))
		return;
	if (maxWait <= 0)
	{
		maxWait = 4.0;
		if (prio >= 9)
			maxWait = 10.0;
	}
	qWho[qN] = sp;
	qCon[qN] = conName;
	qPrio[qN] = prio;
	qReady[qN] = Level.TimeSeconds + delay;
	qUntil[qN] = qReady[qN] + maxWait;
	qTries[qN] = 0;
	qMoving[qN] = 0;
	if (bMoving)
		qMoving[qN] = 1;
	qN++;
}

function bool Queued(name conName)
{
	local int i;

	for (i = 0; i < qN; i++)
		if (qCon[i] == conName)
			return True;
	return False;
}

function DropBark(int i)
{
	for (i = i; i < qN - 1; i++)
	{
		qWho[i] = qWho[i + 1];
		qCon[i] = qCon[i + 1];
		qPrio[i] = qPrio[i + 1];
		qReady[i] = qReady[i + 1];
		qUntil[i] = qUntil[i + 1];
		qTries[i] = qTries[i + 1];
		qMoving[i] = qMoving[i + 1];
	}
	if (qN > 0)
	{
		qN--;
		qWho[qN] = None;
		qCon[qN] = '';
	}
}

function UnqueueBark(name conName)
{
	local int i;

	for (i = qN - 1; i >= 0; i--)
		if (qCon[i] == conName)
			DropBark(i);
}

function BarkQueueTick()
{
	local int i, best;
	local float now;

	now = Level.TimeSeconds;
	for (i = qN - 1; i >= 0; i--)
	{
		if ((qWho[i] == None || qWho[i].bDeleteMe || qWho[i].Health <= 0) && now <= qUntil[i] && HandOver(i))
			continue;
		if (qWho[i] == None || qWho[i].bDeleteMe || qWho[i].Health <= 0 || now > qUntil[i] || Played(qCon[i])
			|| (barkCon != None && barkCon.conName == qCon[i]))
		{
			if (qWho[i] != None && now > qUntil[i])
				Log("UCHarbourline: bark dropped (its moment has gone)" @ qCon[i]);
			DropBark(i);
		}
	}
	if (qN == 0 || barkCon != None || Talking() || InfoBusy() || now < lastBarkEnd + 1.0 || now < lastBarkStart + 3.0)
		return;
	best = -1;
	for (i = 0; i < qN; i++)
		if (qReady[i] <= now && (best < 0 || qPrio[i] > qPrio[best]))
			best = i;
	if (best < 0)
		return;
	if (!BarkFits(qCon[best]))
	{
		Log("UCHarbourline: bark dropped (no longer true)" @ qCon[best]);
		DropBark(best);
		return;
	}
	if (Bark(qWho[best], qCon[best], 1600, qMoving[best] != 0))
	{
		Log("UCHarbourline: bark" @ qCon[best]);
		lastBarkStart = now;
		DropBark(best);
		return;
	}
	if (qTries[best] == 0)
		Log("UCHarbourline: bark refused" @ qCon[best] @ "(tried again): JC" @ Plr().GetStateName() @ Plr().Physics
			@ Plr().CanStartConversation() @ "speaker" @ qWho[best].Name @ qWho[best].GetStateName() @ qWho[best].Physics
			@ qWho[best].bCanConverse @ qWho[best].bInterruptState);
	if (qTries[best] < 250)
		qTries[best]++;
	qReady[best] = now + 0.5;
}

// What a bark says is still true when its turn comes (checked again just before it plays: the queue can
// hold it a few seconds): Kwan's "The containers, Denton!" while a charge counts down and JC is far from all
// that do and not at any container's door (one he has just defused: photo test 15 Oct, charge 6 armed 604
// units from JC at charge 4); his "They're going for number four" while its planter is still on his way to it; "If one of those
// opens..." and "Thirty seconds!" while a charge counts down; the guards' "How many of ours? - Three." only if
// three of Kwan's men are down.
function bool BarkFits(name conName)
{
	local UCHBCharge c, c4;
	local UCHBPathFighter f;
	local bool bArmed;

	switch (conName)
	{
		case 'UC_HBKwanContainers':
			foreach AllActors(class'UCHBCharge', c)
			{
				if (VSize(c.Location - Plr().Location) <= 300)
					return False;
				if (c.IsArmed())
				{
					bArmed = True;
					if (VSize(c.Location - Plr().Location) <= 600)
						return False;
				}
			}
			return bArmed;
		case 'UC_HBKwanFour':
			c4 = ChargeOn(4);
			if (c4 == None || c4.bDefused || c4.bBlown)
				return False;
			foreach AllActors(class'UCHBPathFighter', f)
				if (f.plantContainer == 4 && UCHBPathLeader(f) == None && f.Health > 0 && f.bActivated && !f.bPlanted
					&& !f.bRetreating && VSize(f.Location - c4.Location) < 500)
					return True;
			return False;
		case 'UC_HBKwanOpens':
			return ChargeArmed();
		case 'UC_HBPathThirty':
			foreach AllActors(class'UCHBCharge', c)
				if (c.IsArmed() && c.fuseLeft <= 31 && c.fuseLeft > 2)
					return True;
			return False;
		case 'UC_HBGuardsCount':
			return DeadGuards() == 3;
	}
	return True;
}

// A line of the Path's fighters (not the leader's) whose speaker is down or gone: another fighter of the
// squad still in the garage says it (the one nearest to JC). False: nobody is left to say it.
function bool HandOver(int i)
{
	local UCHBPathFighter f, best;
	local float d, bestD;

	if (Left(string(qCon[i]), 9) != "UC_HBPath" || Plr() == None)
		return False;
	foreach AllActors(class'UCHBPathFighter', f)
		if (UCHBPathLeader(f) == None && f != qWho[i] && f.bActivated && f.Health > 0 && !f.bDeleteMe)
		{
			d = VSize(f.Location - Plr().Location);
			if (best == None || d < bestD)
			{
				best = f;
				bestD = d;
			}
		}
	if (best == None || (!HasCon(best, qCon[i]) && !MakePathBark(best, qCon[i])))
		return False;
	qWho[i] = best;
	return True;
}

// --- the fight (phase 5) ------------------------------------------------------------------------------
function UCHBPathLeader Leader()
{
	local UCHBPathLeader L;

	foreach AllActors(class'UCHBPathLeader', L)
		if (L.Health > 0 && !L.bDeleteMe)
			return L;
	return None;
}

// The squad leader is in the fight (came in, has not given up).
function bool LeaderFights(UCHBPathLeader L)
{
	return L != None && L.bActivated && !L.bSurrendered && L.Health > 0;
}

// A conversation has played (the game's <name>_Played, set when it ends): the barks are said once.
function bool Played(name conName)
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None || P.rootWindow == None || P.FlagBase == None)
		return False;
	return P.FlagBase.GetBool(P.rootWindow.StringToName(string(conName) $ "_Played"));
}

// A charge counts down.
function bool ChargeArmed()
{
	local UCHBCharge c;

	foreach AllActors(class'UCHBCharge', c)
		if (c.IsArmed())
			return True;
	return False;
}

// The fight, every 0.25 s while JC is in the garage (plan 5.6): the fighters' targets and the spotted
// barks (FighterTick), the squad's retreat (CallRetreat), the barks of the charges (PlantBarks), the ones
// who have fallen back removed unseen (LeaversTick), the end (BreachOver).
// The squad falls back when its leader is out (given up, knocked out or dead: a planter not done yet still
// arms his charge first) or when no planter is left on his way and two fighters or fewer are still fighting;
// the leader never does. The fight is over when nobody of the Path is left in the garage (PathInHall) and no
// charge counts down. A fight that never ends (somebody stuck) is ended by SafetyTimeout.
function FightTick()
{
	local UCHBPathFighter f;
	local UCHBPathLeader L;
	local DeusExPlayer P;
	local int active, pending;
	local bool bOut;

	P = Plr();
	if (P == None)
		return;
	breachAge += 0.25;
	BreachGoals();
	GuardsHold(True);
	L = Leader();
	bOut = GetF('UC_HB_LeaderCaptured') || GetF('UC_HB_LeaderKilled') || (L != None && L.bSurrendered);
	if (bOut)
		GoalDone('UCHBLeader');         // killed or taken: that goal is done at once
	foreach AllActors(class'UCHBPathFighter', f)
	{
		if (f.Health <= 0 || f.bDeleteMe || !f.bActivated)
			continue;
		if (UCHBKwan(f.Enemy) != None)          // Kwan can't be hurt (D7): never anybody's target
		{
			f.SetEnemy(None, 0, True);
			f.FollowOrders();
		}
		if (f.bRetreating || UCHBPathLeader(f) != None)
			continue;
		active++;
		if (f.plantContainer != 0 && !f.bPlanted && !f.bGaveUp)
			pending++;
		FighterTick(f, P);
	}
	if (LeaderFights(L))
		FighterTick(L, P);
	if (breachAge >= 6 && (bOut || (pending == 0 && active <= 2)))
		CallRetreat(bOut);
	SafetyTimeout(L);
	PlantBarks(L);
	LeaversTick();
	if (breachAge >= 5 && !PathInHall() && !ChargeArmed())
		BreachOver();
}

// Two of Kwan's men always come through the fight (the doc's lines after it; the gate post died in the
// blast): when only two of A, B, C and the other gate post are left standing, they can't fall any more (photo
// tests 15 Oct: in a fight as played all five died and nobody was left in the garage to talk). bHold False:
// back to normal, the fight is over. Their exchange "How many of ours?" - "Three. Kwan says the report will
// say two." is said only if three of the five are down (DeadGuards, GuardPair).
function GuardsHold(bool bHold)
{
	local ScriptedPawn sp;
	local int i, n;

	if (bHold)
	{
		for (i = 0; i < 4; i++)
			if (GuardAt(i) != None)
				n++;
		if (n > 2)
			return;
	}
	for (i = 0; i < 4; i++)
	{
		sp = GuardAt(i);
		if (sp != None && sp.bInvincible != bHold)
		{
			sp.bInvincible = bHold;
			if (bHold)
				Log("UCHarbourline:" @ sp.BindName @ "comes through the fight (two of Kwan's men left)");
		}
	}
}

// One fighter: badly hurt (35% of his health or less) he falls back, the first saying "The Path does not
// forget." (a planter still on his way goes on: JC has to stop him); the first three times one of them
// turns on JC, 6 seconds apart, a "spotted" bark in the doc's order; idle (done with his way in and his
// charge, nobody to fight), a guard he can see, else JC.
function FighterTick(UCHBPathFighter f, DeusExPlayer P)
{
	local UCTransitGuard g, best;
	local float d, bestD;

	if (UCHBPathLeader(f) == None)
	{
		if (f.fullHealth > 0 && f.Health <= f.fullHealth * 0.35 && (f.plantContainer == 0 || f.bPlanted || f.bGaveUp))
		{
			PathBark(f, 'UC_HBPathForget', 4, 0, 8);
			f.Retreat(CanalExitSpot());
			return;
		}
		if (!f.bSpottedJC && f.Enemy == P && f.LineOfSightTo(P))
		{
			f.bSpottedJC = True;
			if (Level.TimeSeconds >= spotNext && SpotBark(f))
				spotNext = Level.TimeSeconds + 6.0;
		}
	}
	if (f.Orders != 'Standing' || !f.IsInState('Standing'))
		return;
	foreach AllActors(class'UCTransitGuard', g)
		if (g.Health > 0 && g.bInWorld && !g.bHidden && f.LineOfSightTo(g))
		{
			d = VSize(g.Location - f.Location);
			if (best == None || d < bestD)
			{
				best = g;
				bestD = d;
			}
		}
	if (best != None && f.SetEnemy(best, 0, True))
		f.HandleEnemy();
	else if (f.SetEnemy(P, 0, True))
		f.HandleEnemy();
}

// The next of the three "spotted" barks (said once each, in order).
function bool SpotBark(UCHBPathFighter f)
{
	if (!Played('UC_HBPathSpot1') && !Queued('UC_HBPathSpot1'))
		return PathBark(f, 'UC_HBPathSpot1', 4, 0, 4);
	if (!Played('UC_HBPathSpot2') && !Queued('UC_HBPathSpot2'))
		return PathBark(f, 'UC_HBPathSpot2', 4, 0, 4);
	if (!Played('UC_HBPathSpot3') && !Queued('UC_HBPathSpot3'))
		return PathBark(f, 'UC_HBPathSpot3', 4, 0, 4);
	return False;
}

// The squad falls back to the canal: every fighter still in the fight (not the leader, who never does). A
// planter who has not armed his charge yet (on his way in, to his container, kneeling at it) finishes first
// (Gabby's default): FightTick calls this again and he goes once it is armed. bAll (the safety timeout):
// everybody at once. Its two barks once: "The sensors heard us...", then "Fall back to the canal!".
function CallRetreat(bool bLeaderOut, optional bool bAll)
{
	local UCHBPathFighter f, first, second;

	foreach AllActors(class'UCHBPathFighter', f)
		if (f.Health > 0 && f.bActivated && !f.bRetreating && UCHBPathLeader(f) == None
			&& (bAll || f.plantContainer == 0 || f.bPlanted || f.bGaveUp))
		{
			f.Retreat(CanalExitSpot());
			if (first == None)
				first = f;
			else if (second == None)
				second = f;
		}
	if (bRetreatCalled || first == None)
		return;
	bRetreatCalled = True;
	Log("UCHarbourline: the Path falls back to the canal (leader out" @ bLeaderOut $ ")");
	if (second == None)
		second = first;
	PathBark(first, 'UC_HBPathSensors', 5, 0, 10);
	PathBark(second, 'UC_HBPathCanal', 5, 0.1, 12);
}

// The fight's safety net (review 15 Oct: a pawn stuck where nobody reaches him would keep the way out shut,
// Kwan in cover and the debrief away for good): 150 seconds into the fight with no charge counting down, the
// whole squad falls back, planters too; a squad leader still fighting whom JC has not seen for a minute slips
// away (removed out of JC's sight and far from him; no flag: neither killed nor taken).
function SafetyTimeout(UCHBPathLeader L)
{
	local DeusExPlayer P;

	P = Plr();
	if (!LeaderFights(L) || SeenByJC(L))
		leaderUnseenT = 0;
	else
		leaderUnseenT += 0.25;
	if (breachAge <= 150 || ChargeArmed())
		return;
	if (!bTimeoutCalled)
	{
		bTimeoutCalled = True;
		Log("UCHarbourline: the fight's safety timeout at" @ int(breachAge) @ "s: the squad falls back");
	}
	CallRetreat(GetF('UC_HB_LeaderCaptured') || GetF('UC_HB_LeaderKilled'), True);
	if (LeaderFights(L) && leaderUnseenT >= 60 && !SeenByJC(L) && VSize(L.Location - P.Location) > 800)
	{
		if (P.conPlay != None && P.conPlay.invokeActor == L)
			P.AbortConversation();
		bLeaderSlipped = True;
		Log("UCHarbourline: the squad leader slipped away unseen (safety timeout)");
		L.Destroy();
	}
}

// Somebody of the Path still in the fight: the leader still fighting, wherever he is; a fighter who is
// not falling back; one falling back who is still inside the garage (30 seconds at most).
function bool PathInHall()
{
	local UCHBPathFighter f;

	foreach AllActors(class'UCHBPathFighter', f)
	{
		if (f.Health <= 0 || f.bDeleteMe || !f.bActivated)
			continue;
		if (UCHBPathLeader(f) != None)
		{
			if (!UCHBPathLeader(f).bSurrendered)
				return True;
			continue;
		}
		if (!f.bRetreating || (!InLane(f.Location) && f.retreatT < 30))
			return True;
	}
	return False;
}

// The barks of the planting and of the charges (plan 5.7): the first planter to kneel ("Charges on the
// cold containers, move!", the leader's if he still fights); the leader's "Number four!" when the planter
// of container 4 kneels; Kwan's "They're going for number four" when that planter is within 500 of it;
// "Thirty seconds!" by a planter when a charge has 30 seconds left; Kwan's "If one of those opens..." 8
// seconds after a charge is armed, and "The containers, Denton!" when one counts down and JC is more than
// 600 from every one that does (and not within 300 of any charge: at a container's door).
function PlantBarks(UCHBPathLeader L)
{
	local UCHBPathFighter f, p4, thirty;
	local UCHBCharge c, c4;
	local DeusExPlayer P;
	local bool bOpens, bThirty, bArmed, bNear;
	local int thirtyOn;

	P = Plr();
	foreach AllActors(class'UCHBCharge', c)
	{
		if (c.container == 4)
			c4 = c;
		if (VSize(c.Location - P.Location) <= 300)
			bNear = True;
		if (!c.IsArmed())
			continue;
		if (c.armedFor >= 3)
			bArmed = True;
		if (c.armedFor >= 8)
			bOpens = True;
		if (c.fuseLeft <= 30 && !bThirty)
		{
			bThirty = True;
			thirtyOn = c.container;
		}
		if (VSize(c.Location - P.Location) <= 600)
			bNear = True;
	}
	foreach AllActors(class'UCHBPathFighter', f)
	{
		if (f.Health <= 0 || !f.bActivated || f.plantContainer == 0 || UCHBPathLeader(f) != None)
			continue;
		if (f.plantContainer == 4)
			p4 = f;
		if (bThirty && !f.bRetreating && (thirty == None || f.plantContainer == thirtyOn))
			thirty = f;
		if (f.bPlanting && !Played('UC_HBLeaderCharges') && !Played('UC_HBPathCharges')
			&& !Queued('UC_HBLeaderCharges') && !Queued('UC_HBPathCharges'))
		{
			if (LeaderFights(L))
				PathBark(L, 'UC_HBLeaderCharges', 7, 0, 8);
			else
				PathBark(f, 'UC_HBPathCharges', 4, 0, 5);
		}
	}
	if (p4 != None && p4.bPlanting && LeaderFights(L))
		PathBark(L, 'UC_HBLeaderFour', 10, 0, 12);
	if (p4 != None && !p4.bPlanted && !p4.bRetreating && c4 != None && VSize(p4.Location - c4.Location) < 500)
		KwanBark('UC_HBKwanFour', 0, 3);
	if (thirty != None)
		PathBark(thirty, 'UC_HBPathThirty', 4, 0, 4);
	if (bOpens)
		KwanBark('UC_HBKwanOpens', 0);
	if (bArmed && !bNear)
		KwanBark('UC_HBKwanContainers', 0, 3);
}

// The Path's entry barks, right after the blast (+0.5, +2.5, +4.5 s; in turn with Kwan's shout): a fighter
// coming through the gate, one from the bay's shutter, the squad leader.
function EntryBarks()
{
	local UCHBPathFighter f1, f2;
	local UCHBPathLeader L;

	f1 = NearestFighter(GateSpot(), None);
	f2 = NearestFighter(ShutterSpot(), f1);
	// the same priority as the leader's line, queued first: Kwan's shout, then these two, then
	// "The doctor was right" (ties go to the earliest in the queue)
	PathBark(f1, 'UC_HBPathBurn', 10, 0.5, 15);
	PathBark(f2, 'UC_HBPathForPath', 10, 2.5, 15);
	L = Leader();
	if (L != None && L.bActivated)
		PathBark(L, 'UC_HBLeaderDoctor', 10, 4.5, 18);
}

// The fighter nearest to a place (rather one who plants nothing), not the leader.
function UCHBPathFighter NearestFighter(vector spot, UCHBPathFighter notThis)
{
	local UCHBPathFighter f, best;
	local float d, bestD;

	foreach AllActors(class'UCHBPathFighter', f)
		if (f != notThis && f.Health > 0 && f.bActivated && UCHBPathLeader(f) == None)
		{
			d = VSize(f.Location - spot);
			if (f.plantContainer != 0)
				d += 2000;
			if (best == None || d < bestD)
			{
				best = f;
				bestD = d;
			}
		}
	return best;
}

// Kwan's barks from cover (his talks are attached by KwanTalks). maxWait: dropped after so many seconds
// in the queue (10 by default; 3 for the ones about where JC or a planter is right now: BarkFits checks
// them again before they play).
function KwanBark(name conName, float delay, optional float maxWait)
{
	local UCHBKwan k;

	k = Kwan();
	if (k == None || Played(conName) || Queued(conName) || !HasCon(k, conName))
		return;
	if (maxWait <= 0)
		maxWait = 10;
	QueueBark(k, conName, 9, delay, True, maxWait);
}

// A bark of the Path (once): attached to who says it when needed, then queued. False: it can't be.
function bool PathBark(ScriptedPawn sp, name conName, int prio, optional float delay, optional float maxWait)
{
	if (sp == None || sp.Health <= 0 || Played(conName) || Queued(conName))
		return False;
	if (!HasCon(sp, conName) && !MakePathBark(sp, conName))
		return False;
	QueueBark(sp, conName, prio, delay, True, maxWait);
	return True;
}

// The Path's barks: the doc's lines, the speakers written out (the voice tools read them: "UCHBPath" for
// the fighters, "UCHBPathLeader"). Said by an enemy of JC: the game would refuse such a line
// (CanConverseWithPlayer) unless bCanBeInterrupted; several fighters share the binding, so the one who
// says it is bound as the speaker (ownerRefCount > 1: ConPlayBase, BindActorEvents).
function bool MakePathBark(ScriptedPawn sp, name conName)
{
	local UCCon c;

	c = new(Level) class'UCCon';
	switch (conName)
	{
		case 'UC_HBPathBurn':
			c.Begin('UC_HBPathBurn', "UCHBPath", True);
			c.Line("UCHBPath", "JCDenton", "Burn the poison! All of it!");
			break;
		case 'UC_HBPathForPath':
			c.Begin('UC_HBPathForPath', "UCHBPath", True);
			c.Line("UCHBPath", "JCDenton", "For the Luminous Path!");
			break;
		case 'UC_HBPathSpot1':
			c.Begin('UC_HBPathSpot1', "UCHBPath", True);
			c.Line("UCHBPath", "JCDenton", "An American! UNATCO!");
			break;
		case 'UC_HBPathSpot2':
			c.Begin('UC_HBPathSpot2', "UCHBPath", True);
			c.Line("UCHBPath", "JCDenton", "It's the other Denton. The one who obeys.");
			break;
		case 'UC_HBPathSpot3':
			c.Begin('UC_HBPathSpot3', "UCHBPath", True);
			c.Line("UCHBPath", "JCDenton", "The wrong brother. Take him!");
			break;
		case 'UC_HBPathCharges':
			c.Begin('UC_HBPathCharges', "UCHBPath", True);
			c.Line("UCHBPath", "JCDenton", "Charges on the cold containers, move!");
			break;
		case 'UC_HBPathThirty':
			c.Begin('UC_HBPathThirty', "UCHBPath", True);
			c.Line("UCHBPath", "JCDenton", "Thirty seconds! Get clear!");
			break;
		case 'UC_HBPathSensors':
			c.Begin('UC_HBPathSensors', "UCHBPath", True);
			c.Line("UCHBPath", "JCDenton", "The sensors heard us, the police are coming!");
			break;
		case 'UC_HBPathCanal':
			c.Begin('UC_HBPathCanal', "UCHBPath", True);
			c.Line("UCHBPath", "JCDenton", "Fall back to the canal!");
			break;
		case 'UC_HBPathForget':
			c.Begin('UC_HBPathForget', "UCHBPath", True);
			c.Line("UCHBPath", "JCDenton", "The Path does not forget.");
			break;
		case 'UC_HBLeaderDoctor':
			c.Begin('UC_HBLeaderDoctor', "UCHBPathLeader", True);
			c.Line("UCHBPathLeader", "JCDenton", "The doctor was right, it's in here!");
			break;
		case 'UC_HBLeaderCharges':
			c.Begin('UC_HBLeaderCharges', "UCHBPathLeader", True);
			c.Line("UCHBPathLeader", "JCDenton", "Charges on the cold containers, move!");
			break;
		case 'UC_HBLeaderFour':
			c.Begin('UC_HBLeaderFour', "UCHBPathLeader", True);
			c.Line("UCHBPathLeader", "JCDenton", "Number four! The doctor said number four!");
			break;
		default:
			return False;
	}
	c.Passive();
	c.NoFrob();
	c.con.bCanBeInterrupted = True;
	c.con.ownerRefCount = 2;
	c.Done();
	c.AttachTo(sp);
	return True;
}

// The fighters who fell back go once JC can't see them: round the lane's bend (or, stuck on the way, after
// 40 seconds and far from JC).
function LeaversTick()
{
	local UCHBPathFighter f;
	local DeusExPlayer P;

	P = Plr();
	foreach AllActors(class'UCHBPathFighter', f)
		if (f.bRetreating && f.Health > 0 && !f.bDeleteMe && UCHBPathLeader(f) == None && !SeenByJC(f)
			&& (PastBend(f.Location) || (f.retreatT > 40 && VSize(f.Location - P.Location) > 1200)))
		{
			Log("UCHarbourline: removed unseen (fell back to the canal):" @ f.Name);
			f.Destroy();
		}
}

// --- after the fight (phase 6) --------------------------------------------------------------------------
// The fight is over (plan 6.1): its goals done (not the charges' if a container blew: that one was failed,
// it stays open; not the leader's if he slipped away, SafetyTimeout), the way out open (ExitLock),
// UC_HB_AllDefused when no container blew (a charge never armed counts as saved).
function BreachOver()
{
	if (GetF('UC_HB_BreachOver'))
		return;
	SetF('UC_HB_BreachOver', True);
	SetF('UC_HB_AllDefused', !GetF('UC_HB_ContainerBlew'));
	bGoalsSet = False;
	BreachGoals();
	GoalDone('UCHBRepel');
	if (!GetF('UC_HB_ContainerBlew'))
		GoalDone('UCHBDefuse');
	if (GetF('UC_HB_LeaderKilled') || GetF('UC_HB_LeaderCaptured') || GetF('UC_HB_LeaderKO'))
		GoalDone('UCHBLeader');
	ExitLock(False);
	GuardsHold(False);
	// what belongs to a fight still going on is not said after it
	UnqueueBark('UC_HBKwanOpens');
	UnqueueBark('UC_HBKwanFour');
	UnqueueBark('UC_HBKwanContainers');
	UnqueueBark('UC_HBPathCharges');
	UnqueueBark('UC_HBLeaderCharges');
	UnqueueBark('UC_HBLeaderFour');
	UnqueueBark('UC_HBPathThirty');
	Log("UCHarbourline: the attack is over (UC_HB_BreachOver): a container blew" @ GetF('UC_HB_ContainerBlew')
		@ "leader killed" @ GetF('UC_HB_LeaderKilled') @ "taken" @ GetF('UC_HB_LeaderCaptured'));
	AfterStart();
}

// Once per scene after the fight (a load too): the sirens; the squad's men who never came in go (hidden
// all along: nobody ever saw them; not a taken leader, PlaceCaptive). Kwan leaves cover (KwanTick), a
// prisoner is walked to the custody spot (LeaderTick).
function AfterStart()
{
	local UCHBPathFighter f;

	bAfterDone = True;
	Sirens();
	foreach AllActors(class'UCHBPathFighter', f)
		if (!f.bActivated && f.bHidden && f.Health > 0 && !(UCHBPathLeader(f) != None && GetF('UC_HB_LeaderCaptured')))
		{
			Log("UCHarbourline: removed unseen (never came in):" @ f.Name);
			f.Destroy();
		}
	garageNext = Level.TimeSeconds + 4.0;
	GuardsRegroup();
}

// After the fight Kwan's men who are left go back to the containers by Kwan and face him, in the order B, C,
// A, the gate post: the first two to B's and C's places side by side (their exchange, "How many of ours?"),
// the others to A's place and the gate. One sent already (a load) keeps his way.
function GuardsRegroup()
{
	local UCTransitGuard g;
	local int i, k;

	for (i = 0; i < 4; i++)
	{
		g = UCTransitGuard(GuardAt(PairOrder(i)));
		if (g == None)
			continue;
		if (g.Orders != 'HBWalkTo')
			g.StandGuardAt(GuardPost(k), KwanAfterSpot());
		k++;
	}
}

// Kwan's men sent to their places after the fight (orders HBWalkTo) whom the game's own search took away: Revision's
// Seeking ends in Guarding, then Wandering, and never goes back to the orders (photo test 15 Oct: the gate post
// wandering by the containers, so the last two never stood together for "How many of ours?"). Back to their
// orders once nobody is left for them to fight.
function GuardsKeep()
{
	local ScriptedPawn sp;
	local int i;

	for (i = 0; i < 4; i++)
	{
		sp = GuardAt(i);
		if (sp != None && sp.Orders == 'HBWalkTo' && sp.Enemy == None && (sp.IsInState('Wandering') || sp.IsInState('Guarding')))
		{
			Log("UCHarbourline:" @ sp.BindName @ "back to his place (from" @ sp.GetStateName() $ ")");
			sp.FollowOrders();
		}
	}
}

// The squad leader is in the cold room and gone: the man who took him there comes back to his place by the
// containers (GuardsRegroup's: with two of Kwan's men left he is one of the two of "How many of ours?").
function EscortBack()
{
	local UCTransitGuard g;
	local int i, k;

	for (i = 0; i < 4; i++)
	{
		g = UCTransitGuard(GuardAt(PairOrder(i)));
		if (g == None)
			continue;
		if (g.Orders == 'HBWalkTo' && VSize(g.hbSpot - ColdGuardSpot()) <= 1)
		{
			g.StandGuardAt(GuardPost(k), KwanAfterSpot());
			Log("UCHarbourline:" @ g.BindName @ "comes back from the cold room");
		}
		k++;
	}
}

function vector GuardPost(int k)
{
	switch (k)
	{
		case 0:
			return vect(-30020, -160, 48);      // B's place by container 2
		case 1:
			return vect(-30160, -150, 48);      // C's place, the aisle of containers 2 and 3
		case 2:
			return vect(-30020, 180, 48);       // A's place
	}
	return vect(-29240, 392, 48);               // the gate post's
}

// The police's sirens out in the lane (plan 5.8): the map's sound actors with Tag UCHBSiren, silent until
// now.
function Sirens()
{
	local Actor A;
	local Sound s;

	s = Sound(DynamicLoadObject("Ambient.Ambient.EuropeanSiren", class'Sound', True));
	if (s == None)
		return;
	foreach AllActors(class'Actor', A, 'UCHBSiren')
		if (A.AmbientSound != s)
		{
			A.AmbientSound = s;
			Log("UCHarbourline: the sirens in the lane");
		}
}

// After the fight, every 0.25 s while JC is in the garage.
function AfterTick()
{
	if (!bAfterDone)
		AfterStart();
	GuardsKeep();
	DebugAftermath();
	DebriefTick(Kwan());
	LeaderTick();
	LeaversTick();
	GarageBarks();
	AlexReportTick();
}

// The debug jump to after the attack (UCDbgHarbourAfter, its flag UC_HB_DebugAfter) comes into a garage
// the blast never touched: its doors go quietly (no fragments, no flash).
function DebugAftermath()
{
	local DeusExMover door;

	if (!GetF('UC_HB_DebugAfter'))
		return;
	SetF('UC_HB_DebugAfter', False);
	foreach AllActors(class'DeusExMover', door)
		if (!door.bDestroyed && (door.Tag == 'UCHBGarageGate' || door.Tag == 'UCHBShutter' || door.Tag == 'UCYardTrailer'
			|| door.Tag == 'UCYardBackroom' || door.Tag == 'UCYardMaintenance'))
		{
			door.NumFragments = 0;
			door.bDrawExplosion = False;
			door.BlowItUp(None);
			Log("UCHarbourline: debug arrival after the attack, door" @ door.Tag @ "gone");
		}
}

// Kwan's debrief (plan 6.2) when JC comes a few metres from him, out of cover, in sight (or a click).
function DebriefTick(UCHBKwan k)
{
	local Conversation con;

	if (k == None || k.Orders != 'HBDebrief' || GetF('UC_HBKwanAfter_Played') || Talking() || InfoBusy() || barkCon != None)
		return;
	con = ConOf(k, 'UC_HBKwanAfter');
	if (con != None && Within(k, 260) && Plr().StartConversation(k, IM_Other, con, False, False))
		Log("UCHarbourline: Kwan's debrief");
}

// The squad leader after the fight (plans 6.3-6.4). Taken: walked to the custody spot by Kwan, where JC
// can talk to him (UC_HBLeaderTalk); handed over (UC_HB_LeaderToKwan) he goes into the cold room with one
// of Kwan's men, let go (UC_HB_LeaderFreed) out by the lane; either way he is removed only where JC can't
// see him. Knocked out (D6): he comes round where he fell (LeaderSwap) and is walked to the custody spot
// too (his orders: the out-of-view rule lets him move). The talk waits for Kwan's debrief (LeaderTalks). The
// debug jump's taken leader (never came in): put by Kwan (PlaceCaptive).
function LeaderTick()
{
	local UCHBPathLeader L;

	L = Leader();
	if (L == None)
	{
		if (GetF('UC_HB_LeaderKO') && !GetF('UC_HB_LeaderToKwan') && !GetF('UC_HB_LeaderFreed'))
			LeaderSwap();
		if (GetF('UC_HB_LeaderToKwan') || GetF('UC_HB_LeaderFreed'))
			EscortBack();
		return;
	}
	if (!L.bActivated)
	{
		if (GetF('UC_HB_LeaderCaptured') && !GetF('UC_HB_LeaderToKwan') && !GetF('UC_HB_LeaderFreed'))
			PlaceCaptive(L);
		return;
	}
	if (!L.bSurrendered)
		return;
	if (!Talking() && !HasCon(L, 'UC_HBLeaderTalk'))
		LeaderTalks(L);
	if (Talking())
		return;
	if (GetF('UC_HB_LeaderToKwan'))
		ColdRoomTick(L);
	else if (GetF('UC_HB_LeaderFreed'))
		FreedTick(L);
	else
		CustodyTick(L);
}

// Taken (16 Oct 2026, Gabby): one of Kwan's men (Escort's: the gate post, else A, C, B) comes for him where he
// stands, then walks him a step behind to the cold room's door; the leader stands in front of it, hands
// behind his back, the guard by the door (ColdGuardSpot: Escort, EscortBack find him there). Nobody left to
// do it: the leader walks there alone.
function CustodyTick(UCHBPathLeader L)
{
	local UCTransitGuard g;
	local vector d;

	g = escortGuard;
	if (g == None || g.bDeleteMe || g.Health <= 0)
	{
		g = PickEscort();
		escortGuard = g;
		if (g == None)
		{
			if (L.Orders != 'HBLed' || L.ledMode != 1)
			{
				L.LedTo(1, CustodySpot());
				Log("UCHarbourline: the squad leader is walked to the cold room's door (nobody to take him)");
			}
			return;
		}
		bEscortSent = True;
		d = g.Location - L.Location;
		d.Z = 0;
		g.StandGuardAt(L.Location + Normal(d) * 70, L.Location);
		Log("UCHarbourline:" @ g.BindName @ "comes for the squad leader");
	}
	if (L.Orders != 'HBLed' || L.ledMode != 1)
	{
		if (VSize((g.Location - L.Location) * vect(1,1,0)) > 130)
			return;                 // his guard is on his way to him
		L.LedTo(1, CustodySpot());
		Log("UCHarbourline:" @ g.BindName @ "walks the squad leader to the cold room's door");
	}
	if (VSize((L.Location - CustodySpot()) * vect(1,1,0)) > 60)
	{
		d = CustodySpot() - L.Location;
		d.Z = 0;
		g.FollowTo(L.Location - Normal(d) * 64, L.Location);       // a step behind him
	}
	else
		g.FollowTo(ColdGuardSpot(), CustodySpot());
}

// The man who takes the squad leader (Escort's order: the gate post, else A, C, B).
function UCTransitGuard PickEscort()
{
	local UCTransitGuard g;
	local int i;

	for (i = 3; i >= 0; i--)
	{
		g = UCTransitGuard(GuardAt(PairOrder(i)));
		if (g != None && !g.bDeleteMe && g.Health > 0)
			return g;
	}
	return None;
}

// The talk with the taken squad leader (click; after the fight and after Kwan's debrief, UC_HBKwanAfter:
// Kwan stands by the custody spot for "We'll take care of it."): the doc's five lines, then two answers.
// Kwan's line is said to JC (no distance check between the two of them).
function LeaderTalks(UCHBPathLeader L)
{
	local UCCon c;

	c = new(Level) class'UCCon';
	c.Begin('UC_HBLeaderTalk', "UCHBPathLeader", False);
	c.Once();
	c.Require('UC_HB_BreachOver', True);
	if (Kwan() != None)
		c.Require('UC_HBKwanAfter_Played', True);
	c.Require('UC_HB_LeaderToKwan', False);
	c.Require('UC_HB_LeaderFreed', False);
	c.Line("UCHBPathLeader", "JCDenton", "You stopped us tonight. You won't stop what's in those crates.");
	c.Line("JCDenton", "UCHBPathLeader", "Who told you about the shipment?");
	c.Line("UCHBPathLeader", "JCDenton", "The doctor. He sees what you refuse to see.");
	c.Line("JCDenton", "UCHBPathLeader", "Where's the doctor?");
	c.Line("UCHBPathLeader", "JCDenton", "Where your brother went to die. Or to live. That's up to you, Denton.");
	c.Choices();
	c.Answer("Hand him over to Kwan.", "Kwan");
	c.Answer("Let him go.", "Free");
	c.Label("Kwan");
	c.Line("JCDenton", "VictorKwan", "Hand him over to Kwan.");
	c.Line("VictorKwan", "JCDenton", "We'll take care of it.");
	c.SetFlag('UC_HB_LeaderToKwan', True);
	c.EndHere();
	c.Label("Free");
	c.Line("JCDenton", "VictorKwan", "Let him go.");
	c.Line("UCHBPathLeader", "JCDenton", "The Path will remember this night.");
	c.SetFlag('UC_HB_LeaderFreed', True);
	c.Done();
	c.AttachTo(L);
}

// Handed over: into the cold room (its door opened as soon as he is handed over and kept open, opened again
// if JC shuts it, until he is inside: a pawn that bumps a shut door stalls; closed behind him once JC is not
// by it); one of Kwan's men goes with him to the room (Escort) and, once he is gone, back to the others
// (EscortBack). Removed behind the closed door, unseen (or, if he could not get there, unseen and far from JC
// after a minute).
function ColdRoomTick(UCHBPathLeader L)
{
	local DeusExMover door;
	local DeusExPlayer P;
	local bool bInside, bFallback;

	P = Plr();
	if (L.Orders != 'HBLed' || L.ledMode != 2)
	{
		L.LedTo(2, ColdRoomSpot());
		Log("UCHarbourline: the squad leader is handed over to Kwan (the cold room)");
	}
	Escort();
	bInside = VSize((L.Location - ColdRoomSpot()) * vect(1,1,0)) < 100;
	bFallback = L.ledT > 60 && VSize(L.Location - P.Location) > 900;
	foreach AllActors(class'DeusExMover', door, 'UCHBColdDoor')
		break;
	if (door != None && !door.bDestroyed)
	{
		if (!bInside && door.KeyNum == 0)
			OpenDoor('UCHBColdDoor', True);
		if (bInside && door.KeyNum != 0 && !door.bInterpolating && VSize(P.Location - ColdRoomSpot()) > 260)
			OpenDoor('UCHBColdDoor', False);
		if ((!bInside || door.KeyNum != 0 || door.bInterpolating) && !bFallback)
			return;
	}
	else if (!bInside && !bFallback)
		return;
	if (SeenByJC(L))
		return;
	Log("UCHarbourline: the squad leader removed unseen (the cold room)");
	L.Destroy();
	EscortBack();
}

// One of Kwan's men (the gate post, else A, C, B: the last of them by their places after the fight, GuardsRegroup)
// walks to the cold room with the leader and stays there until the leader is gone (EscortBack).
function Escort()
{
	local UCTransitGuard g;
	local int i;

	if (bEscortSent)
		return;
	bEscortSent = True;
	for (i = 3; i >= 0; i--)
	{
		g = UCTransitGuard(GuardAt(PairOrder(i)));
		if (g == None)
			continue;
		if (g.Orders != 'HBWalkTo' || VSize(g.hbSpot - ColdGuardSpot()) > 1)
		{
			g.StandGuardAt(ColdGuardSpot(), ColdRoomSpot());
			Log("UCHarbourline:" @ g.BindName @ "takes the squad leader to the cold room");
		}
		return;
	}
}

// Let go: out through the gate and down the lane; removed round its bend (or, if he could not get there,
// after 45 seconds and far from JC), unseen.
function FreedTick(UCHBPathLeader L)
{
	local DeusExPlayer P;

	P = Plr();
	if (L.Orders != 'HBLed' || L.ledMode != 3)
	{
		L.LedTo(3, CanalExitSpot());
		Log("UCHarbourline: the squad leader is let go (the lane)");
	}
	if (!SeenByJC(L) && (PastBend(L.Location) || (L.ledT > 45 && VSize(L.Location - P.Location) > 1000)))
	{
		Log("UCHarbourline: the squad leader removed unseen (let go)");
		L.Destroy();
		EscortBack();               // the man who walked him to the door goes back to the others
	}
}

// D6 (Gabby): a knock-out is a capture. After the fight his unconscious body (the carcass that keeps his
// binding) is swapped, while JC is not looking at it, for the leader alive at the same spot; then he is
// walked by his orders to the custody spot by Kwan, where JC can talk to him after Kwan's debrief. Not while JC carries the body. A body
// killed after the knock-out (or gone: blown to pieces) means he is dead.
function LeaderSwap()
{
	local DeusExCarcass carc, body;
	local POVCorpse held;
	local UCHBPathLeader L;
	local DeusExPlayer P;
	local vector loc;
	local rotator r;

	P = Plr();
	foreach AllActors(class'DeusExCarcass', carc)
		// his body: Revision names it after him (flagName), the original game by the CarcassName he gave it
		if ((carc.GetPropertyText("flagName") ~= "UCHBPathLeader" || carc.CarcassName == 'UCHBPathLeader') && !carc.bDeleteMe)
		{
			body = carc;
			break;
		}
	if (body == None)
	{
		held = POVCorpse(P.inHand);
		if (held != None && (held.GetPropertyText("flagName") ~= "UCHBPathLeader" || held.CarcassName == 'UCHBPathLeader'))
		{
			if (!held.bNotDead)
				LeaderLost("killed after the knock-out");
			return;
		}
		LeaderLost("his body is gone");
		return;
	}
	if (!body.bNotDead)
	{
		LeaderLost("killed after the knock-out");
		return;
	}
	if (SeenByJC(body) || VSize(body.Location - P.Location) < 160)
		return;
	loc = body.Location;
	loc.Z += class'UCHBPathLeader'.default.CollisionHeight - body.CollisionHeight + 4;
	r.Yaw = body.Rotation.Yaw;
	L = Spawn(class'UCHBPathLeader',,, loc, r);
	if (L == None)
		L = Spawn(class'UCHBPathLeader',,, loc + vect(0,0,24), r);
	if (L == None)
		return;
	body.bHidden = True;            // kept, out of the game (UCFateWatch: a body that goes is a death)
	body.SetCollision(False, False, False);
	body.bCollideWorld = False;
	body.SetPhysics(PHYS_None);
	body.SetPropertyText("flagName", "");
	body.CarcassName = '';
	L.Tag = body.Tag;
	body.Tag = '';
	L.WakeCaptive();                // standing where he fell: CustodyTick sends a guard for him
	SetF('UC_HB_LeaderKO', False);
	SetF('UC_HB_LeaderCaptured', True);
	Log("UCHarbourline: the knocked-out squad leader comes round (D6), his body swapped unseen");
}

function LeaderLost(string why)
{
	SetF('UC_HB_LeaderKilled', True);
	SetF('UC_HB_LeaderCaptured', False);
	SetF('UC_HB_LeaderKO', False);
	Log("UCHarbourline: the squad leader is dead," @ why @ "(UC_HB_LeaderKilled)");
}

// The debug jump's taken squad leader (UCDbgHarbourAfter: UC_HB_LeaderCaptured, he never came in): moved
// while still hidden to the custody spot, shown there once JC is not looking.
function PlaceCaptive(UCHBPathLeader L)
{
	if (L.Alliance != 'UCHBCaptive')
		L.Captive();            // nobody's enemy already while he waits, hidden, to be shown
	if (VSize((L.Location - CustodySpot()) * vect(1,1,0)) > 32)
		L.SetLocation(CustodySpot() + vect(0,0,4));
	if (SeenByJC(L))
		return;
	L.WakeCaptive();
	L.LedTo(1, CustodySpot());
	Log("UCHarbourline: debug arrival, the taken squad leader kneels by Kwan");
}

// The garage's guards, in the fallback order of their lines: A, B, C, the gate post.
function string GuardBind(int g)
{
	switch (g)
	{
		case 0:
			return "UCHBGuardA";
		case 1:
			return "UCHBGuardB";
		case 2:
			return "UCHBGuardC";
	}
	return "UCHBGateGuard1";
}

function ScriptedPawn GuardAt(int g)
{
	return GuardPawn(GuardBind(g));
}

// The order for the two of the exchange: B, C, then A, the gate post.
function int PairOrder(int i)
{
	switch (i)
	{
		case 0:
			return 1;
		case 1:
			return 2;
		case 2:
			return 0;
	}
	return 3;
}

function DropCon(Actor A, name conName)
{
	local ConListItem item, prev;

	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
	{
		if (item.con != None && item.con.conName == conName)
		{
			if (prev == None)
				A.ConListItems = item.next;
			else
				prev.next = item.next;
			return;
		}
		prev = item;
	}
}

// The garage's lines after the fight (plan 6.5), said by guard g (0 A, 1 B, 2 C, 3 the gate post; the
// speakers written out: the voice tools read them). The exchange: g asks, o answers.
function bool MakeGuardBark(ScriptedPawn sp, int g, name conName, optional int o)
{
	local UCCon c;
	local string toName, fromName;

	c = new(Level) class'UCCon';
	toName = GuardBind(o);
	fromName = GuardBind(g);
	switch (conName)
	{
		case 'UC_HBGuardBodies':
			c.Begin('UC_HBGuardBodies', fromName, True);
			switch (g)
			{
				case 0:
					c.Line("UCHBGuardA", "JCDenton", "Move the Path bodies into the cold room before the police get here.");
					break;
				case 1:
					c.Line("UCHBGuardB", "JCDenton", "Move the Path bodies into the cold room before the police get here.");
					break;
				case 2:
					c.Line("UCHBGuardC", "JCDenton", "Move the Path bodies into the cold room before the police get here.");
					break;
				default:
					c.Line("UCHBGateGuard1", "JCDenton", "Move the Path bodies into the cold room before the police get here.");
			}
			break;
		case 'UC_HBGuardsCount':
			c.Begin('UC_HBGuardsCount', fromName, True);
			switch (g)
			{
				case 0:
					c.Line("UCHBGuardA", toName, "How many of ours?");
					break;
				case 1:
					c.Line("UCHBGuardB", toName, "How many of ours?");
					break;
				case 2:
					c.Line("UCHBGuardC", toName, "How many of ours?");
					break;
				default:
					c.Line("UCHBGateGuard1", toName, "How many of ours?");
			}
			switch (o)
			{
				case 0:
					c.Line("UCHBGuardA", fromName, "Three. Kwan says the report will say two.");
					break;
				case 1:
					c.Line("UCHBGuardB", fromName, "Three. Kwan says the report will say two.");
					break;
				case 2:
					c.Line("UCHBGuardC", fromName, "Three. Kwan says the report will say two.");
					break;
				default:
					c.Line("UCHBGateGuard1", fromName, "Three. Kwan says the report will say two.");
			}
			break;
		case 'UC_HBGuardMoved':
			c.Begin('UC_HBGuardMoved', fromName, True);
			switch (g)
			{
				case 0:
					c.Line("UCHBGuardA", "JCDenton", "Did you see how he moved? UNATCO people aren't human.");
					break;
				case 1:
					c.Line("UCHBGuardB", "JCDenton", "Did you see how he moved? UNATCO people aren't human.");
					break;
				case 2:
					c.Line("UCHBGuardC", "JCDenton", "Did you see how he moved? UNATCO people aren't human.");
					break;
				default:
					c.Line("UCHBGateGuard1", "JCDenton", "Did you see how he moved? UNATCO people aren't human.");
			}
			break;
		case 'UC_HBGuardLook':
			c.Begin('UC_HBGuardLook', fromName, True);
			switch (g)
			{
				case 0:
					c.Line("UCHBGuardA", "JCDenton", "Ten years here and I've never looked inside a container. I'm not starting tonight.");
					break;
				case 1:
					c.Line("UCHBGuardB", "JCDenton", "Ten years here and I've never looked inside a container. I'm not starting tonight.");
					break;
				case 2:
					c.Line("UCHBGuardC", "JCDenton", "Ten years here and I've never looked inside a container. I'm not starting tonight.");
					break;
				default:
					c.Line("UCHBGateGuard1", "JCDenton", "Ten years here and I've never looked inside a container. I'm not starting tonight.");
			}
			break;
		case 'UC_HBGuardGloves':
			c.Begin('UC_HBGuardGloves', fromName, True);
			switch (g)
			{
				case 0:
					c.Line("UCHBGuardA", "JCDenton", "Don't touch that liquid! Wait for the gloves!");
					break;
				case 1:
					c.Line("UCHBGuardB", "JCDenton", "Don't touch that liquid! Wait for the gloves!");
					break;
				case 2:
					c.Line("UCHBGuardC", "JCDenton", "Don't touch that liquid! Wait for the gloves!");
					break;
				default:
					c.Line("UCHBGateGuard1", "JCDenton", "Don't touch that liquid! Wait for the gloves!");
			}
			break;
		default:
			return False;
	}
	c.Passive();
	c.NoFrob();
	c.Done();
	c.AttachTo(sp);
	return True;
}

// After the fight (plan 6.5): Kwan's men talk as JC walks past (within 300, in sight of who speaks), one
// line every 6 seconds at most, each once: A on the bodies, the exchange of B and C (only if three of
// Kwan's men are down), the gate post on how JC moved, C on the containers, and (a container blew) the
// guard nearest to it on the liquid. A speaker who died hands his line to the first living one of A, B, C,
// the gate post. Not while JC stands by the taken squad leader whose talk is due (LeaderTalkNear).
function GarageBarks()
{
	if (Level.TimeSeconds < garageNext || qN > 0 || barkCon != None || Talking() || InfoBusy() || LeaderTalkNear())
		return;
	if (GuardLine('UC_HBGuardBodies', 0))
		return;
	if (GuardPair())
		return;
	if (GuardLine('UC_HBGuardMoved', 3))
		return;
	if (GuardLine('UC_HBGuardLook', 2))
		return;
	if (GetF('UC_HB_ContainerBlew'))
		GuardGloves();
}

// JC is within 400 of the taken squad leader whose talk is due (after Kwan's debrief): a line said in passing
// would take his click on him (the game starts no talk over another: photo test hk6fT5, 15 Oct, the click refused
// while the guards' lines followed one another for half a minute).
// JC has walked out of the dock lift (more than 200 from its button): the guard's "Is that him?"
// is said as he comes in, not on the lift's threshold.
function bool OffTheLift()
{
	local UCTransitButton b;

	b = LiftButton(True);
	return b == None || Plr() == None || VSize((Plr().Location - b.Location) * vect(1,1,0)) > 200;
}

function bool LeaderTalkNear()
{
	local UCHBPathLeader L;

	L = Leader();
	return L != None && L.bSurrendered && Plr() != None && (Kwan() == None || GetF('UC_HBKwanAfter_Played'))
		&& !Played('UC_HBLeaderTalk') && !GetF('UC_HB_LeaderToKwan') && !GetF('UC_HB_LeaderFreed')
		&& VSize(L.Location - Plr().Location) < 250 && SeenByJC(L);
}

function bool GuardLine(name conName, int pref)
{
	local ScriptedPawn sp;
	local int i, g;

	if (Played(conName) || Queued(conName))
		return False;
	g = -1;
	sp = GuardAt(pref);
	if (sp != None)
		g = pref;
	for (i = 0; i < 4 && g < 0; i++)
	{
		sp = GuardAt(i);
		if (sp != None)
			g = i;
	}
	if (g < 0 || !Within(sp, 300))
		return False;
	DropCon(sp, conName);
	if (!MakeGuardBark(sp, g, conName))
		return False;
	QueueBark(sp, conName, 3, 0, False, 4);
	garageNext = Level.TimeSeconds + 6.0;
	return True;
}

// Kwan's men down (dead or knocked out): of the garage's five (A, B, C and the two gate posts), the ones not
// standing any more.
function int DeadGuards()
{
	local int i, n;

	n = 5;
	for (i = 0; i < 4; i++)
		if (GuardAt(i) != None)
			n--;
	if (GuardPawn("UCHBGateGuard0") != None)
		n--;
	return n;
}

// The exchange: two living guards near each other (the game starts a talk between two only within 300),
// B and C if they can. Only if three of Kwan's men are down ("Three. Kwan says the report will say two."):
// otherwise it is not said.
function bool GuardPair()
{
	local ScriptedPawn a, b, sp;
	local int i, j, ia, ib;

	if (Played('UC_HBGuardsCount') || Queued('UC_HBGuardsCount') || DeadGuards() != 3)
		return False;
	ia = -1;
	ib = -1;
	for (i = 0; i < 4 && ib < 0; i++)
	{
		a = GuardAt(PairOrder(i));
		if (a == None)
			continue;
		for (j = i + 1; j < 4; j++)
		{
			sp = GuardAt(PairOrder(j));
			if (sp != None && VSize(sp.Location - a.Location) < 280 && (Within(a, 300) || Within(sp, 300)))
			{
				ia = PairOrder(i);
				ib = PairOrder(j);
				b = sp;
				break;
			}
		}
	}
	if (ib < 0)
		return False;
	a = GuardAt(ia);
	DropCon(a, 'UC_HBGuardsCount');
	if (!MakeGuardBark(a, ia, 'UC_HBGuardsCount', ib))
		return False;
	QueueBark(a, 'UC_HBGuardsCount', 3, 0, False, 4);
	garageNext = Level.TimeSeconds + 6.0;
	return True;
}

function bool GuardGloves()
{
	local UCHBCharge c, blown;
	local ScriptedPawn sp, best;
	local int i, g;
	local float d, bestD;

	if (Played('UC_HBGuardGloves') || Queued('UC_HBGuardGloves'))
		return False;
	foreach AllActors(class'UCHBCharge', c)
		if (c.bBlown)
		{
			blown = c;
			break;
		}
	if (blown == None)
		return False;
	g = -1;
	for (i = 0; i < 4; i++)
	{
		sp = GuardAt(i);
		if (sp == None)
			continue;
		d = VSize(sp.Location - blown.Location);
		if (best == None || d < bestD)
		{
			best = sp;
			bestD = d;
			g = i;
		}
	}
	if (best == None || !Within(best, 300))
		return False;
	DropCon(best, 'UC_HBGuardGloves');
	if (!MakeGuardBark(best, g, 'UC_HBGuardGloves'))
		return False;
	QueueBark(best, 'UC_HBGuardGloves', 3, 0, False, 4);
	garageNext = Level.TimeSeconds + 6.0;
	return True;
}

// The van: Harbourline's (the Coalition's) vehicle for JC. Gabby's D2: Mission 6 stays open, the van ends
// nothing; Alex's second call (UCSceneHBAlexCall 2, UC_HB_AlexReport) plays when JC comes within 450 of it
// after the fight and after Kwan's debrief (the call sends the airstrip and names Lo: Kwan tells JC first).
function Actor TheVan()
{
	local Actor A;
	local UCTransitButton b;

	A = FirstTag('UCHBVan');
	if (A != None)
		return A;
	A = FirstTag('UCTransportVan');
	if (A != None)
		return A;
	b = LiftButton(True);
	if (b == None)
		return None;
	foreach AllActors(class'Actor', A)
		if (A.IsA('Van') && VSize(A.Location - b.Location) < 4000)
			return A;
	return None;
}

function AlexReportTick()
{
	local UCSceneHBAlexCall alex;
	local Actor van;

	if (bAlexReport || GetF('UC_HB_AlexReport') || Talking() || InfoBusy())
		return;
	if (Kwan() != None && !GetF('UC_HBKwanAfter_Played'))
		return;
	van = TheVan();
	if (van == None || VSize(Plr().Location - van.Location) > 450)
		return;
	foreach AllActors(class'UCSceneHBAlexCall', alex)
		return;
	bAlexReport = True;
	alex = Spawn(class'UCSceneHBAlexCall');
	if (alex != None)
		alex.which = 2;
	Log("UCHarbourline: Alex's call 2 (the report, by the van)");
}

// --- the sequence ----------------------------------------------------------------
state Playing
{
Begin:
	CueTag();
	if (Plr() == None || Plr().FlagBase == None)
	{
		Sleep(0.5);
		Goto('Begin');
	}
	Log("UCHarbourline: begin (landing seen" @ GetF('UC_HB_LandingSeen') $ ")");
	Friendly();
	RoofTalks();
	Plr().FlagBase.SetName('MusicPackageTrack', 'HongKong_Music');
	Plr().UpdateDynamicMusic(5);
	class'UCSceneHongKong'.static.TongGoal(Plr());
	// a game of the old flow that had already landed here: no second landing, no second title
	if (!GetF('UC_HB_LandingSeen') && (GetF('UC_RooftopIntroduced') || GetF('UC_EvaRooftop_Played')))
	{
		SetF('UC_HB_LandingSeen', True);
		SetF('UC_HB_TitleShown', True);
	}
	// only the landing where the platforms wait is open: the other door stays shut
	MovePlatform(False, 0, 0.05);
	MovePlatform(True, 0, 0.05);
	OpenDoor('UCRoofLiftDoor', !AtDock());
	OpenDoor('UCDockLiftDoor', AtDock());
	ExitLock(!GetF('UC_HB_BreachOver'));
	if (!GetF('UC_HB_LandingSeen') && !AtDock())
		GotoState('Landing');
	else
		ReleaseBlack();
	SetF('UC_RooftopIntroduced', True);     // read by the Market lift and the old Helibase (UCHKWorld, UCCampaign)
	Recover();
Loop:
	if (Plr() == None)
	{
		Sleep(0.5);
		Goto('Loop');
	}
	BarkTick();
	FrobTalks();
	KeepOnceFlags();
	if (!Talking())
		SmokerTalk();
	if (!bLiftBusy)
	{
		if (AtDock())
			DockTick();
		else
			RoofTick();
	}
	BarkQueueTick();
	Sleep(0.25);
	Goto('Loop');
}

state Landing
{
Begin:
	StartBlack();
	SetF('UC_HB_LandingSeen', True);        // the landing is never played twice (and no game is saved in it)
	SetF('UC_RooftopIntroduced', True);     // read by the Market lift and the old Helibase (UCHKWorld, UCCampaign)
	Sleep(0.2);
	LandStart();
Fly:
	if (landPhase == 1 || landPhase == 2)
	{
		Sleep(0.1);
		Goto('Fly');
	}
	// Reveal JC for Eva's talk; if it can't start, release him and let EvaTick retry.
	if (!CockpitTalk())
		Goto('Out');
Talk:
	if (landPhase == 4)
	{
		Sleep(0.1);
		Goto('Talk');
	}
	Sleep(0.5);                             // a moment of black: JC gets out of the helicopter
Out:
	LandEnd();
	GotoState('Playing', 'Loop');
}
defaultproperties
{
}
