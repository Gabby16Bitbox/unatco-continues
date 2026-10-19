//=============================================================================
// UCSceneBatteryPark - Battery Park on the UNATCO route: Jock is dead. Gabby's mission script
// (Gabby's mission doc "UNATCO Mod - Mission scripts", tab "Mission 5 - Battery Park"):
//  1. JC comes out of the subway kiosk: a second and a half later Jock's InfoLink starts; when it
//     ends (the line goes dead) JC hears the gunshot (nobody sees it: the pad is out of sight until
//     JC rounds the vine wall). JC running to the pad cuts the call: the shot comes at once, so Jock
//     never sounds alive near his own body. Goal: reach the helicopter. Two police officers on
//     the way (walking a short beat round their posts, Gabby 18 Oct: CopBeat) and a bum at the barrel
//     fire north of the pad (Gabby, 15 Oct: near Jock, not by the subway) say what they saw (once
//     each, the bum only after the shot); clicked again they brush JC off.
//  2. The pad: Jock's helicopter with the engine off and blood on the paving, two Men in Black shown
//     as "Special Agent" (route rule: never "Majestic 12" or "Man in Black" yet). The first one
//     talks when JC comes near: "The pilot has been neutralized."
//  3. Optional: Jock's body under a plastic tarp in the planting bed behind the vine wall,
//     south-west of the pad, out of sight of the pad and of the police, his blood under him.
//     Searching him gives his flask (it can be drunk); Paul's datacube lies beside him, JC reads it
//     and says nothing. The agent who shot him stands guard there, pistol in hand (Gabby, 15 Oct):
//     when JC comes round the wall he walks up to him and tries to send him away ("Nothing to see
//     here, Denton."); once JC has seen the body: "He was a terrorist, Denton. Go to work."
//  4. Only after the body: the agents greet JC with "You went behind the wall" (extra answer if
//     the cube was read). Nothing JC says changes anything.
//  5. After the first talk with the agents (either of the two): Alex's InfoLink, cut off by
//     Simons. Meanwhile a second UNATCO helicopter flies in over the bay to the clearing south of
//     the subway (Gabby, 15 Oct: cell B7 of the plan), where a flare burns (Gabby, 17 Oct: a fourth
//     Special Agent, placed there out of JC's sight, lights it when JC comes near and holds it up high;
//     clicked, he tells JC to move: UCBPFlareAgent). It holds high up in the
//     dark, heard more than seen, louder as JC comes near; when he does, it comes down and lands
//     in front of him (it waits in the air while JC stands under it). Asked, the agents say where
//     it is setting down. Eva speaks when JC clicks the helicopter ("at the door"): every answer
//     ends with the takeoff to Hong Kong, in silence.
// Never more than three answers in a conversation (Gabby, 15 Oct).
// Flags (UC_, expiration 99, read by Missions 6/7): UC_BP_JockCall (call started), UC_JockDead,
// UC_BP_MIBMet, UC_BP_JockBodyFound, UC_BP_PaulCubeRead, UC_BP_MIBConfronted,
// UC_BP_EvaCall, UC_BP_EvaLanded, UC_BP_EvaWallLine, UC_EvaGo; then UNATCORoute_DepartedNYC.
// UC_BP_ShooterPlaced: the agent by the body is there (placed after the shot, out of JC's sight).
// UC_BP_EvaDescent: Eva's helicopter has started down to the clearing (JC came near).
// UC_BP_FlareAgentPlaced: the agent with the flare (UCSpecialAgent4) is at the clearing.
// The scene is transient: after a reload it rebuilds its state from the flags. What it places
// (agents, police, bum, body, tarp, cube, Eva's helicopter) is saved with the map and looked up by
// Tag before placing. Positions: read from the map (BSP plan and line of sight), see the notes.
// Spawned by UCCampaign.RouteTick in 04_NYC_BATTERYPARK.
//=============================================================================
class UCSceneBatteryPark extends UCScene transient;

var int n;
var float d;
var float t;
var int infoMode;      // 1 Jock's call, 2 Alex and Simons
var int flight;        // Eva's helicopter: 0 none, 1 coming in, 2 going down, 3 landed, 4 lifting, 5 leaving,
                       // 6 holding high over the clearing until JC comes near
var float flightT;
var float outT;        // seconds JC has been in the level before Jock's call
var vector curVel;     // Eva's helicopter: its speed now, eased towards the wanted one (no jolts)
var float descentV;    // its speed going down (eased too)
var bool bDescentHeld; // JC is under it: it waits low in the air while its rotor wash moves him out
var float shooterT;    // seconds since the agent by the body last spoke to JC
var bool bShooterOn;   // the agent by the body is dealing with JC
var Conversation barkCon;   // a line said in passing, started by the scene (Bark)
var float flareT;      // seconds the agent with the flare has waited for JC before lighting it
var float flareWait;   // seconds the clearing has been in JC's sight, keeping the agent from being placed
var float beatT;       // the police beat (CopBeat), by officer: seconds since the last step,
var int beatLeg[3];    // the point he walks to or waits at,
var float beatWait[3]; // seconds left there,
var float beatBest[3]; // the closest he has got to it on the way, and since when (a blocked way)
var float beatStuck[3];
var byte beatOn[3];    // 1: on his way to it (else waiting there)   (no bool arrays in UnrealScript)
var byte beatHeld[3];  // 1: stopped for JC
var byte beatInit[3];

// --- places -----------------------------------------------------------------
function vector JockPad()   { return vect(-1632.6, 516.7, 424.1); }   // Jock's helicopter (vanilla)
// Eva's landing: the clearing south of the subway kiosk (Gabby, 15 Oct: cell B7 of the plan), on
// its west edge, the only part with the rotor's room all round (trees, crates, the Castle Clinton
// wall: the map's plan and SDK traces of 15 Oct). She comes from the bay due south, so she lands
// nose to the north with the tail in the gap between the two trees south of it (from the east the
// tail fin went into the crown of the nearer one). The sky lid of the map is at Z 1600.
function vector EvaSpot()   { return vect(-4000, -256, 408.5); }
function vector EvaHold()   { return vect(-4000, -256, 1350); }      // high above it, in the dark
function vector EvaFrom()   { return vect(-4570, -4300, 1100); }      // over the bay, south of it
function vector FlareSpot() { return vect(-3560, -256, 408.5); }      // the flare marking it, on JC's side,
                                                                         // outside the 420 where she waits for JC
// the agent holding the flare when the map has none placed (17 Oct): to the right of JC's way to the
// helicopter, leaving it room (Gabby, 17 Oct evening: "too much in front of it"), 440 from her spot (her landed
// body is 261), 90 from the trash bags south of him, facing the way JC comes from the pad. Normally he is
// an actor of the map (UCBPFlareAgent0 in the editor's Hierarchy, out of the world until Simons's call):
// then his own place is used.
function vector FlareAgentSpot(int i)
{
	switch (i)
	{
		case 0: return vect(-3600, -440, 408.5);
		case 1: return vect(-3640, -400, 408.5);
		case 2: return vect(-3560, -420, 408.5);
	}
	return vect(-3620, -470, 408.5);
}
function vector BodySpot()  { return vect(-1985, -1050, 360); }       // corner of the L vine wall
function vector BumSpot()   { return vect(-2235, 1140, 370); }        // barrel fire north of the pad
function vector ShooterPost() { return vect(-2290, -1000, 370); }     // inside the L, west of the body

// JC is behind the vine wall where Jock lies: inside the L (south of its long side, west of its
// short one: the map's height plan of 15 Oct) or close to the body from any side.
function bool InShooterZone()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None || P.Location.Z < 300)
		return False;
	if (P.Location.X < -1860 && P.Location.X > -2900 && P.Location.Y < -840 && P.Location.Y > -1750)
		return True;
	return VSize((P.Location - BodySpot()) * vect(1,1,0)) < 450;
}

// JC is out of the subway kiosk, on the park's ground (Gabby, 15 Oct: the call starts a second or
// two after he is out, not on the stairs). The kiosk is x < -3940, y 1400..1900 above Z 340; the
// platform, the corridor and the stairs are below Z 300.
function bool OutOfSubway()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return False;
	return P.Location.Z > 340 && (P.Location.X > -3940 || P.Location.Y > 1900 || P.Location.Y < 1400);
}

// JC is about to see the pad: rounding the south end of the vine wall (the first point it shows,
// from the map's line-of-sight study), or already looking at the helicopter or an agent.
function bool NearPad()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return False;
	if (P.Location.Z > 300 && P.Location.X > -2600 && P.Location.Y < 250)
		return True;
	// close to the pad from any side (a player who runs: Gabby, 15 Oct)
	if (P.Location.Z > 300 && VSize((P.Location - JockPad()) * vect(1,1,0)) < 1500)
		return True;
	return SeenByJC(JockHeli()) || SeenByJC(Agent(1)) || SeenByJC(Agent(2));
}

function bool InfoBusy()
{
	local DeusExRootWindow root;

	if (Plr() == None)
		return False;
	root = DeusExRootWindow(Plr().rootWindow);
	return Plr().dataLinkPlay != None || (root != None && root.hud != None && root.hud.infolink != None);
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

function vector FloorAt(vector spot, out vector normal)
{
	local vector hitLoc;

	if (Trace(hitLoc, normal, spot - vect(0,0,300), spot, False) == None)
	{
		normal = vect(0,0,1);
		return spot - vect(0,0,44);
	}
	return hitLoc;
}

// --- who and what -------------------------------------------------------------
function ScriptedPawn Tagged(name tagName, string bindName)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp, tagName)
		if (sp.BindName == bindName)
			return sp;
	return None;
}

function ScriptedPawn Agent(int i)
{
	return Tagged('UCSpecialAgent', "UCSpecialAgent" $ i);
}

function ScriptedPawn Cop(int i)
{
	return Tagged('UCBPCop', "UCBPCop" $ i);
}

function ScriptedPawn Bum()
{
	return Tagged('UCBPBum', "UCBPBum");
}

function BlackHelicopter EvaHeli()
{
	local BlackHelicopter h;

	foreach AllActors(class'BlackHelicopter', h, 'UCEvaHeli')
		return h;
	return None;
}

function BlackHelicopter JockHeli()
{
	local BlackHelicopter h;

	foreach AllActors(class'BlackHelicopter', h, 'UCTransport')
		return h;
	foreach AllActors(class'BlackHelicopter', h)
		if (h.Tag != 'UCEvaHeli')
			return h;
	return None;
}

function UCBPJockCarcass JockBody()
{
	local UCBPJockCarcass body;

	foreach AllActors(class'UCBPJockCarcass', body)
		return body;
	return None;
}

function ScriptedPawn PlaceNPC(class<ScriptedPawn> cls, name tagName, string bindName, vector spot, int yaw)
{
	local ScriptedPawn sp;
	local rotator r;

	r.Yaw = yaw;
	sp = Spawn(cls,, tagName, spot, r);
	if (sp == None)
		sp = Spawn(cls,, tagName, spot + vect(0,0,24), r);
	if (sp == None)
	{
		Log("UCBatteryPark: could not place" @ bindName @ "at" @ spot);
		return None;
	}
	sp.BindName = bindName;
	sp.ConBindEvents();
	// not permanent: shooting them makes them hostile, and for the agents that ends the loyal
	// route (UCCampaign.CheckAttackOnGunther watches Tag 'UCSpecialAgent'), as at the 'Ton
	sp.ChangeAlly('Player', 1.0, False);
	sp.SetOrders('Standing', '', True);
	return sp;
}

// An agent is gone (killed, knocked out) without the route break having fired (a single shot):
// the same consequences as UCCampaign.BreakWithUNATCO. The scene stops: no Eva for a deserter.
function AgentDown()
{
	local ScriptedPawn sp;

	SetF('JCBrokeWithUNATCO', True);
	SetF('UNATCORouteActive', False);
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA('UNATCOTroop') || sp.Tag == 'UCSpecialAgent' || sp.Tag == 'UCBPCop')
			sp.ChangeAlly('Player', -1.0, True);
	Msg("You have attacked UNATCO personnel.");
	Log("UCBatteryPark: a Special Agent is down: loyal route broken");
}

// Jock's helicopter: nobody in it. Engine and rotors off; it no longer answers as Jock (the
// game would bind his vanilla lines to it: "I'm not leaving until I know Paul's okay.").
function JockHeliStill()
{
	local BlackHelicopter h;

	h = JockHeli();
	if (h == None)
		return;
	if (h.BindName != "UCJockHeli")
		h.BindName = "UCJockHeli";
	h.ConListItems = None;
	if (h.IsInState('Flying'))
	{
		h.GotoState('');
		h.PlayAnim('Still');
	}
	h.AmbientSound = None;
	StillRotor(h);
}

// Its rotors at rest (Gabby, 15 Oct): the game's rotor is a blurred disc, made turning. The disc is
// hidden (black on its translucent faces) and two dark blades take its place: UCModels.UCM_JockRotor,
// made in the helicopter's own measures (tools\make_jock_rotor.py), at its place and turn.
function StillRotor(BlackHelicopter h)
{
	local UCMeshDeco blades;
	local Mesh m;

	if (h.MultiSkins[1] != Texture'DeusExItems.Skins.BlackMaskTex')
		h.MultiSkins[1] = Texture'DeusExItems.Skins.BlackMaskTex';
	foreach AllActors(class'UCMeshDeco', blades, 'UCBPRotor')
		return;
	m = Mesh(DynamicLoadObject("UCModels.UCM_JockRotor", class'Mesh', True));
	if (m == None)
		return;
	blades = Spawn(class'UCMeshDeco',, 'UCBPRotor', h.Location, h.Rotation);
	if (blades == None)
		return;
	blades.SetCollision(False, False, False);
	blades.Mesh = m;
	blades.DrawScale = h.DrawScale;
	blades.ItemName = "Rotor";
}

// Blood on the paving beside the helicopter, on JC's side. Decals vanish when nobody looks at
// them (DeusExDecal.Timer): permanent, and made again if missing.
function Blood()
{
	local BloodSplat s;
	local vector spot[4], floor, normal;
	local int i;
	local bool bHave;

	foreach AllActors(class'BloodSplat', s, 'UCBPBlood')
	{
		s.SetPropertyText("bPermanent", "True");   // Revision only (the original game's decals have no bPermanent)
		s.bImportant = True;
		bHave = True;
	}
	if (bHave)
		return;
	spot[0] = vect(-1805, 300, 380);
	spot[1] = vect(-1775, 268, 380);
	spot[2] = vect(-1840, 255, 380);
	spot[3] = vect(-1935, -985, 380);     // beside the tarp, where he was dragged in
	for (i = 0; i < 4; i++)
	{
		floor = FloorAt(spot[i], normal);
		s = Spawn(class'BloodSplat',, 'UCBPBlood', floor + normal, Rotator(normal));
		if (s != None)
		{
			s.SetPropertyText("bPermanent", "True");   // Revision only (the original game's decals have no bPermanent)
			s.bImportant = True;
		}
	}
}

// The body, the tarp over it and Paul's datacube beside it (south side: the lifted tarp goes north).
// Until the tarp is lifted the body and the cube pass every click to the tarp (UCBPJockCarcass /
// UCBPCube.Frob: the game picks the smallest object on the line of sight, the body under it) and
// the cube is hidden. A debug jump that reset the flags gets fresh props (the map kept the old).
function PlaceBody()
{
	local UCBPJockCarcass body;
	local UCBPTarp tarp;
	local UCBPCube cube;
	local BloodPool pool;
	local UCBPFlask flask;
	local vector floor, normal;
	local bool bFound;

	bFound = GetF('UC_BP_JockBodyFound');
	floor = FloorAt(BodySpot(), normal);
	// his blood under him, seen once the tarp is pulled aside (Gabby, 15 Oct)
	foreach AllActors(class'BloodPool', pool, 'UCBPBodyBlood')
		break;
	if (pool == None)
	{
		pool = Spawn(class'BloodPool',, 'UCBPBodyBlood', floor + normal, Rotator(normal));
		if (pool != None)
		{
			pool.SetPropertyText("bPermanent", "True");   // Revision only (the original game's decals have no bPermanent)
			pool.bImportant = True;
			pool.maxDrawScale *= 1.4;
		}
	}
	foreach AllActors(class'UCBPTarp', tarp)
		break;
	if (tarp != None && tarp.bLifted != bFound)
	{
		tarp.Destroy();
		tarp = None;
	}
	body = JockBody();
	// A body saved by an older version held the flask from the start, shown on top of him. Taken
	// from there it stayed listed on the body too, tied into JC's own inventory (Gabby, 15 Oct):
	// the body lets go of it. Still lying on him: it goes, the search makes a new one.
	if (body != None && body.Inventory != None && body.Inventory.Owner != body)
	{
		body.Inventory = None;
		body.bFlaskGiven = True;
	}
	if (body != None && !body.bFlaskGiven)
		foreach AllActors(class'UCBPFlask', flask)
			if (flask.Owner == body)
			{
				body.DeleteInventory(flask);
				flask.Destroy();
			}
	if (body != None && !bFound && body.bFlaskGiven)
	{
		body.Destroy();          // searched in an earlier run of a debug jump: the flask is back
		body = None;
	}
	if (body == None)
	{
		body = Spawn(class'UCBPJockCarcass',, 'UCBPJockBody', floor + vect(0,0,9), rot(0,0,0));
		if (body == None)
			Log("UCBatteryPark: could not place Jock's body at" @ floor);
	}
	if (body != None && body.BindName != "UCBPJockBody")
		body.BindName = "UCBPJockBody";
	if (tarp == None)
	{
		tarp = Spawn(class'UCBPTarp',, 'UCBPTarp', floor + vect(0,0,14), rot(0,0,32768));
		if (tarp != None && bFound)
			tarp.Lift();
	}
	foreach AllActors(class'UCBPCube', cube)
		break;
	if (cube == None)
	{
		cube = Spawn(class'UCBPCube',, 'UCBPCube', FloorAt(BodySpot() + vect(46,-34,0), normal) + vect(0,0,2));
		if (cube != None)
			cube.SetPhysics(PHYS_None);
	}
	if (cube != None && cube.bHidden == bFound)
		cube.bHidden = !bFound;
}

// An older version left Jock's flask in JC's inventory without an owner (the search took it twice,
// see UCBPJockCarcass): it could not be used, and clicking it in the inventory crashed the game
// (Gabby, 15 Oct). A save with it gets it handed over properly.
function RepairFlask()
{
	local DeusExPlayer P;
	local Inventory item;
	local int n;

	P = Plr();
	if (P == None)
		return;
	for (item = P.Inventory; item != None && n < 200; item = item.Inventory)
	{
		n++;
		if (UCBPFlask(item) != None && item.Owner != P)
		{
			item.SetOwner(P);
			item.Instigator = P;
			item.BecomeItem();
			item.GotoState('Idle2');
			Log("UCBatteryPark: Jock's flask handed over to JC again (it had no owner)");
		}
	}
}

function Setup()
{
	local ScriptedPawn sp;
	local BlackHelicopter h;

	JockHeliStill();
	if (GetF('UC_JockDead'))
		Blood();
	PlaceBody();
	RepairFlask();
	// The cast is placed once (then saved with the map): somebody killed stays dead. A debug
	// jump clears UC_BP_CastPlaced and puts back who is missing.
	if (!GetF('UC_BP_CastPlaced'))
		PlaceCast();
	MoveBum();
	PlaceShooter();
	sp = Agent(1);
	if (sp != None && sp.FamiliarName != "Special Agent")
	{
		sp.FamiliarName = "Special Agent";
		sp.UnfamiliarName = "Special Agent";
	}
	sp = Agent(2);
	if (sp != None && sp.FamiliarName != "Special Agent")
	{
		sp.FamiliarName = "Special Agent";
		sp.UnfamiliarName = "Special Agent";
	}
	// a debug jump reset the story but the map kept Eva's helicopter
	h = EvaHeli();
	if (h != None && !GetF('UC_BP_EvaCall'))
		h.Destroy();
	if (GetF('UC_BP_EvaCall') && !GetF('UC_EvaGo'))
		MarkLZ();
}

function PlaceCast()
{
	// the agents stand off the helicopter's south-west side, facing the way JC comes
	if (Agent(1) == None)
		PlaceNPC(class'MIB', 'UCSpecialAgent', "UCSpecialAgent1", vect(-1900, 300, 380), 39000);
	if (Agent(2) == None)
		PlaceNPC(class'MIB', 'UCSpecialAgent', "UCSpecialAgent2", vect(-1795, 205, 380), 38000);
	// police: one south of the end of the vine wall where JC turns towards the pad (off the
	// patrol's path node), one at the plaza's south-west mouth (the perimeter "tape")
	if (Cop(1) == None)
		PlaceNPC(class'Cop', 'UCBPCop', "UCBPCop1", vect(-2620, -200, 370), 0);
	if (Cop(2) == None)
		PlaceNPC(class'Cop', 'UCBPCop', "UCBPCop2", vect(-2150, -210, 370), 8192);
	// the bum at the barrel fire north of the pad, facing it (Gabby, 15 Oct: near Jock)
	if (Bum() == None)
		PlaceNPC(class'BumMale2', 'UCBPBum', "UCBPBum", BumSpot(), 25780);
	if (Agent(1) != None && Agent(2) != None && Cop(1) != None && Cop(2) != None && Bum() != None)
		SetF('UC_BP_CastPlaced', True);
}

// --- conversations ----------------------------------------------------------------
// After the first talk, if JC clicks one of them again before the body (and before Eva lands):
// "Stand by", then "There is nothing here for you". On both agents (same conversation names, so
// "Stand by" is heard once whoever JC clicks). Conversation owner = the agent clicked.
function AgainTalks(ScriptedPawn mib, string owner)
{
	local UCCon c;

	c = new(Level) class'UCCon';
	c.Begin('UC_BPAgentsAgain2', owner, False);
	c.Require('UC_BPAgentsAgain1_Played', True);
	c.Require('UC_BP_JockBodyFound', False);
	c.Require('UC_BP_EvaLanded', False);
	c.Line("UCSpecialAgent1", "JCDenton", "There is nothing here for you.");
	c.Done();
	c.AttachTo(mib);

	c = new(Level) class'UCCon';
	c.Begin('UC_BPAgentsAgain1', owner, False);
	c.Once();
	c.Require('UC_BP_MIBMet', True);
	c.Require('UC_BP_JockBodyFound', False);
	c.Require('UC_BP_EvaLanded', False);
	c.Line("UCSpecialAgent2", "JCDenton", "Stand by, Agent Denton.");
	c.Done();
	c.AttachTo(mib);

	// after Simons's call, until Eva has landed: where the new pilot sets down, if JC asks
	// (Gabby, 15 Oct). Attached last: tried first.
	c = new(Level) class'UCCon';
	c.Begin('UC_BPAgentsPilot', owner, False);
	c.Require('UC_BP_EvaCall', True);
	c.Require('UC_BP_EvaLanded', False);
	c.Line(owner, "JCDenton", "Your transport is inbound, Agent Denton.");
	c.Choices();
	c.Answer("Where is it setting down?", "Where");
	c.Answer("Understood.", "Ok");
	c.Label("Where");
	c.Line("JCDenton", owner, "Where is it setting down?");
	c.Line(owner, "JCDenton", "The clearing south of the subway entrance. Follow the flare.");
	c.EndHere();
	c.Label("Ok");
	c.Line("JCDenton", owner, "Understood.");
	c.Done();
	c.AttachTo(mib);
}

function AgentTwoTalks()
{
	local ScriptedPawn mib;

	mib = Agent(2);
	if (mib == None || Agent(1) == None || HasCon(mib, 'UC_BPAgentsAgain1'))
		return;
	mib.ConListItems = None;
	AgainTalks(mib, "UCSpecialAgent2");
}

// The agents' talks, in reverse priority (each one goes to the head of the list): the game
// plays the first one whose conditions hold.
function AgentTalks()
{
	local ScriptedPawn mib;
	local UCCon c;

	AgentTwoTalks();
	mib = Agent(1);
	if (mib == None || Agent(2) == None || HasCon(mib, 'UC_BPAgentsWall'))
		return;
	mib.ConListItems = None;

	AgainTalks(mib, "UCSpecialAgent1");

	// phase 2: the first talk, when JC comes near
	c = new(Level) class'UCCon';
	c.Begin('UC_BPAgents1', "UCSpecialAgent1", False);
	c.Once();
	c.Radius(260);
	c.Require('UC_JockDead', True);
	c.Require('UC_BP_MIBMet', False);
	c.SetFlag('UC_BP_MIBMet', True);
	c.Line("UCSpecialAgent1", "JCDenton", "Agent Denton. The pilot has been neutralized.");
	c.Choices();
	c.Answer("Neutralized. Is he alive?", "Alive");
	c.Answer("On whose orders?", "Orders");
	c.Answer("I'll wait.", "Wait");
	c.Label("Alive");
	c.Line("JCDenton", "UCSpecialAgent1", "Neutralized. Is he alive?");
	c.Line("UCSpecialAgent1", "JCDenton", "...");
	c.EndHere();
	c.Label("Orders");
	c.Line("JCDenton", "UCSpecialAgent2", "On whose orders?");
	c.Line("UCSpecialAgent2", "JCDenton", "Yours are to stand by. Your transport has been reassigned.");
	c.EndHere();
	c.Label("Wait");
	c.Line("JCDenton", "UCSpecialAgent1", "I'll wait.");
	c.Line("UCSpecialAgent1", "JCDenton", "Correct.");
	c.Done();
	c.AttachTo(mib);

	// phase 4: after the body (also as the first talk, if JC found him first)
	c = new(Level) class'UCCon';
	c.Begin('UC_BPAgentsWall', "UCSpecialAgent1", False);
	c.Once();
	c.Radius(260);
	c.Require('UC_BP_JockBodyFound', True);
	c.SetFlag('UC_BP_MIBMet', True);
	c.SetFlag('UC_BP_MIBConfronted', True);
	c.Line("UCSpecialAgent1", "JCDenton", "You went behind the wall, Agent Denton.");
	// three answers: the third is Paul's datacube's once JC has read it
	c.Choices();
	c.Answer("He was one of ours. You shot him and hid him behind a wall.", "Ours");
	c.Answer("Who gave the order? Manderley? Simons?", "Order");
	c.Answer("He was a pilot, not a terrorist.", "Pilot", 'UC_BP_PaulCubeRead', False);
	c.Answer("He flew Paul out. You could have arrested him.", "Arrest", 'UC_BP_PaulCubeRead', True);
	c.Label("Ours");
	c.Line("JCDenton", "UCSpecialAgent1", "He was one of ours. You shot him and hid him behind a wall.");
	c.Line("UCSpecialAgent1", "JCDenton", "Pilot Flanagan assisted a fugitive. The matter is closed.");
	c.Jump("Close");
	c.Label("Order");
	c.Line("JCDenton", "UCSpecialAgent1", "Who gave the order? Manderley? Simons?");
	c.Line("UCSpecialAgent1", "JCDenton", "The order was given. That is sufficient.");
	c.Jump("Close");
	c.Label("Pilot");
	c.Line("JCDenton", "UCSpecialAgent2", "He was a pilot, not a terrorist.");
	c.Line("UCSpecialAgent2", "JCDenton", "He chose a side. You chose another. We noted both.");
	c.Jump("Close");
	c.Label("Arrest");
	c.Line("JCDenton", "UCSpecialAgent1", "He flew Paul out. You could have arrested him.");
	c.Line("UCSpecialAgent1", "JCDenton", "Arrests generate records, Agent Denton.");
	c.Label("Close");
	c.Line("UCSpecialAgent1", "JCDenton", "Your loyalty has been noted. Do not give us reason to note anything else.");
	c.Done();
	c.AttachTo(mib);
}

// What the bum and the police saw, once each. Started by the scene, not by distance alone: JC
// usually walks past them while Jock is still talking (nothing plays over an InfoLink), so each
// one speaks up as soon as the line is free, while JC is still within earshot and in sight. The
// bum speaks only after the shot (Gabby, 15 Oct); the police lines do not depend on it.
function WitnessTalks()
{
	local ScriptedPawn sp;
	local UCCon c;

	sp = Bum();
	if (sp != None && !HasCon(sp, 'UC_BPBum'))
	{
		// clicked again, or before the shot (each one to the head of the list: the news goes first)
		c = new(Level) class'UCCon';
		c.Begin('UC_BPBumMore', "UCBPBum", True);
		c.Passive();
		c.Require('UC_BPBum_Played', True);
		c.Line("UCBPBum", "JCDenton", "Told you what I heard. I ain't seen nothing else.");
		c.Done();
		c.AttachTo(sp);
		c = new(Level) class'UCCon';
		c.Begin('UC_BPBumBefore', "UCBPBum", True);
		c.Passive();
		c.Require('UC_JockDead', False);
		c.Line("UCBPBum", "JCDenton", "Cold night, friend. Cops everywhere tonight.");
		c.Done();
		c.AttachTo(sp);
		c = new(Level) class'UCCon';
		c.Begin('UC_BPBum', "UCBPBum", True);
		c.Passive();
		c.Once();
		c.Require('UC_JockDead', True);
		c.Line("UCBPBum", "JCDenton", "Heard a shot by the chopper. Then them suits dragged somebody off south, behind the wall. I ain't seen nothing, friend.");
		c.Done();
		c.AttachTo(sp);
	}
	sp = Cop(1);
	if (sp != None && !HasCon(sp, 'UC_BPCop1'))
	{
		c = new(Level) class'UCCon';
		c.Begin('UC_BPCop1More', "UCBPCop1", True);
		c.Passive();
		c.Require('UC_BPCop1_Played', True);
		c.Line("UCBPCop1", "JCDenton", "Talk to the suits, Agent. It's their show.");
		c.Done();
		c.AttachTo(sp);
		c = new(Level) class'UCCon';
		c.Begin('UC_BPCop1', "UCBPCop1", True);
		c.Passive();
		c.Once();
		c.Line("UCBPCop1", "JCDenton", "Feds took over. We're just holding the tape.");
		c.Done();
		c.AttachTo(sp);
	}
	sp = Cop(2);
	if (sp != None && !HasCon(sp, 'UC_BPCop2'))
	{
		c = new(Level) class'UCCon';
		c.Begin('UC_BPCop2More', "UCBPCop2", True);
		c.Passive();
		c.Require('UC_BPCop2_Played', True);
		c.Line("UCBPCop2", "JCDenton", "Keep moving, sir. Nothing for you here.");
		c.Done();
		c.AttachTo(sp);
		c = new(Level) class'UCCon';
		c.Begin('UC_BPCop2', "UCBPCop2", True);
		c.Passive();
		c.Once();
		c.Line("UCBPCop2", "JCDenton", "Since when do feds wear sunglasses at night?");
		c.Done();
		c.AttachTo(sp);
	}
}

function bool Within(ScriptedPawn sp, float dist)
{
	local DeusExPlayer P;

	P = Plr();
	return sp != None && P != None && sp.Health > 0 && VSize(sp.Location - P.Location) < dist && P.LineOfSightTo(sp);
}

function WitnessTick()
{
	if (Talking() || InfoBusy())
		return;
	if (GetF('UC_JockDead') && !GetF('UC_BPBum_Played') && Within(Bum(), 800))
		Bark(Bum(), 'UC_BPBum', 1000);
	else if (!GetF('UC_BPCop1_Played') && Within(Cop(1), 450))
		Bark(Cop(1), 'UC_BPCop1', 650);
	else if (!GetF('UC_BPCop2_Played') && Within(Cop(2), 450))
		Bark(Cop(2), 'UC_BPCop2', 650);
}

// A line said in passing (the bum, the police, the agent by the body). The game cuts a
// first-person talk as soon as JC is 300 units from who started it, unless it was started by
// radius (DeusExPlayer.CheckActiveConversationRadius): so it starts as one, with a wide radius, only
// while it plays (BarkTick); left on, the game would start it by itself, also through walls. The
// conversation is passed directly, so its flags are not checked: that is the caller's job.
function bool Bark(ScriptedPawn sp, name conName, int radius)
{
	local ConListItem item;

	if (sp == None || Plr() == None || barkCon != None)
		return False;
	for (item = ConListItem(sp.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
		{
			item.con.bInvokeRadius = True;
			item.con.radiusDistance = radius;
			if (Plr().StartConversation(sp, IM_Radius, item.con, False, False))
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
	if (barkCon == None)
		return;
	if (Plr() != None && Plr().conPlay != None && Plr().conPlay.con == barkCon)
		return;
	barkCon.bInvokeRadius = False;
	barkCon = None;
}

// The bum's place moved (Gabby, 15 Oct): one placed by an older version, still by the subway, is
// moved to the fire while JC is far from both places and does not see him.
function MoveBum()
{
	local ScriptedPawn sp;
	local DeusExPlayer P;
	local rotator r;

	sp = Bum();
	P = Plr();
	if (sp == None || P == None || sp.Health <= 0 || VSize((sp.Location - BumSpot()) * vect(1,1,0)) < 300)
		return;
	if (VSize(P.Location - sp.Location) < 900 || VSize(P.Location - BumSpot()) < 900 || SeenByJC(sp))
		return;
	r.Yaw = 25780;
	if (sp.SetLocation(BumSpot()))
	{
		sp.SetRotation(r);
		sp.SetOrders('Standing', '', True);
	}
}

// --- the police on their beat ------------------------------------------------------
// The two officers do not stand still (Gabby, 18 Oct 2026): each walks a short beat round his post,
// three points, a few seconds at each looking out, then on to the next (the game's GoingTo, towards a
// UCMark moved to the point). Officer 1 on the path at the south end of the vine wall, officer 2 at
// the plaza's south-west mouth. The points keep the L vine wall between them and Jock's body (out of
// sight of the police) and keep them off the pad, the agents and Eva's clearing. An officer JC walks
// up to stops and turns to him (easy to click) and goes on when JC moves away. Talking, alarmed,
// fighting or hostile: left to the game.
function vector BeatSpot(int i, int k, out int yaw)
{
	if (i == 1)
	{
		if (k == 0) { yaw = 0;     return vect(-2620, -220, 370); }   // his post, facing the pad
		if (k == 1) { yaw = 32768; return vect(-3080, -300, 370); }   // west along the path, to the clearing
		yaw = 16384;               return vect(-2830, -420, 370);     // by the benches, looking into the park
	}
	if (k == 0) { yaw = 8192;  return vect(-2150, -210, 370); }       // his post, the plaza's mouth
	if (k == 1) { yaw = 0;     return vect(-1880, -400, 370); }       // the plaza's south side
	yaw = 16384;               return vect(-1650, -60, 370);          // east of the agents, facing the helicopter
}

function UCMark BeatMark(int i)
{
	local UCMark m;
	local name t;

	t = 'UCBPCopGo1';
	if (i == 2)
		t = 'UCBPCopGo2';
	foreach AllActors(class'UCMark', m, t)
		return m;
	return Spawn(class'UCMark',, t);
}

function BeatGo(ScriptedPawn sp, int i)
{
	local UCMark m;
	local vector spot, normal;
	local int yaw;

	m = BeatMark(i);
	if (m == None)
		return;
	spot = BeatSpot(i, beatLeg[i], yaw);
	m.SetLocation(FloorAt(spot + vect(0,0,60), normal) + vect(0,0,1) * sp.CollisionHeight);
	beatBest[i] = 99999;
	beatStuck[i] = 0;
	beatOn[i] = 1;
	sp.SetOrders('GoingTo', m.Tag, True);
}

function BeatFace(ScriptedPawn sp, int yaw)
{
	local rotator r;

	r.Yaw = yaw;
	sp.DesiredRotation = r;
}

// there (or as close as the way lets him): he stops and looks out for a few seconds
function BeatArrive(ScriptedPawn sp, int i)
{
	local int yaw;

	BeatSpot(i, beatLeg[i], yaw);
	beatOn[i] = 0;
	beatWait[i] = 4 + FRand() * 5;
	if (sp.IsInState('GoingTo'))
		sp.SetOrders('Standing', '', True);
	BeatFace(sp, yaw);
}

function CopBeat(float dt)
{
	local DeusExPlayer P;
	local ScriptedPawn sp;
	local vector spot;
	local float dist, best, jc;
	local int i, k, yaw;

	P = Plr();
	if (P == None || !GetF('UC_BP_CastPlaced'))
		return;
	for (i = 1; i <= 2; i++)
	{
		sp = Cop(i);
		if (sp == None || sp.Health <= 0 || !sp.bInWorld || sp.GetAllianceType('Player') == ALLIANCE_Hostile)
			continue;
		if (!sp.IsInState('GoingTo') && !sp.IsInState('Standing'))
			continue;
		if (beatInit[i] == 0)
		{
			// from the nearest point (a reload, or his post the first time), not all at once
			beatInit[i] = 1;
			best = 99999;
			for (k = 0; k < 3; k++)
			{
				dist = VSize((sp.Location - BeatSpot(i, k, yaw)) * vect(1,1,0));
				if (dist < best)
				{
					best = dist;
					beatLeg[i] = k;
				}
			}
			beatOn[i] = 0;
			beatWait[i] = 1 + FRand() * 4 + 3 * (i - 1);
			if (best > 90)
				BeatGo(sp, i);
			continue;
		}
		spot = BeatSpot(i, beatLeg[i], yaw);
		dist = VSize((sp.Location - spot) * vect(1,1,0));
		jc = VSize((P.Location - sp.Location) * vect(1,1,0));
		if (jc < 200 && Abs(P.Location.Z - sp.Location.Z) < 120 && P.LineOfSightTo(sp))
			beatHeld[i] = 1;
		else if (jc > 360)
			beatHeld[i] = 0;
		if (beatHeld[i] == 1)
		{
			if (sp.IsInState('GoingTo'))
				sp.SetOrders('Standing', '', True);
			BeatFace(sp, rotator(P.Location - sp.Location).Yaw);
			continue;
		}
		if (sp.IsInState('GoingTo'))
		{
			if (dist < 60)
				BeatArrive(sp, i);
			else if (dist < beatBest[i] - 10)
			{
				beatBest[i] = dist;
				beatStuck[i] = 0;
			}
			else
			{
				beatStuck[i] += dt;
				if (beatStuck[i] > 6)      // the way is blocked: he stops where he is
					BeatArrive(sp, i);
			}
			continue;
		}
		// standing: there, held up by JC, or back from a talk
		if (beatOn[i] == 1)
		{
			if (dist < 90)
				BeatArrive(sp, i);
			else
				BeatGo(sp, i);
			continue;
		}
		beatWait[i] -= dt;
		if (beatWait[i] <= 0)
		{
			beatLeg[i] = (beatLeg[i] + 1) % 3;
			BeatGo(sp, i);
		}
	}
}

// --- the agent who shot Jock ------------------------------------------------------
// Placed after the shot by the body, while JC is far from the spot and cannot see it.
function PlaceShooter()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None || GetF('UC_BP_ShooterPlaced') || !GetF('UC_JockDead'))
		return;
	if (Agent(3) == None)
	{
		if (VSize(P.Location - ShooterPost()) < 1200 || FastTrace(ShooterPost() + vect(0,0,40), P.Location + vect(0,0,1) * P.BaseEyeHeight))
			return;
		PlaceNPC(class'UCBPShooter', 'UCSpecialAgent', "UCSpecialAgent3", ShooterPost(), 0);
	}
	if (Agent(3) != None)
		SetF('UC_BP_ShooterPlaced', True);
}

// Short lines (Gabby, 15 Oct), said as he walks up to JC (ShooterTick) or when JC clicks him. Each
// one goes to the head of the list: the last attached is tried first.
function ShooterTalks()
{
	local ScriptedPawn sp;
	local UCCon c;

	sp = Agent(3);
	if (sp == None || HasCon(sp, 'UC_BPShooterStop'))
		return;
	sp.ConListItems = None;

	c = new(Level) class'UCCon';
	c.Begin('UC_BPShooterMore', "UCSpecialAgent3", True);
	c.Passive();
	c.Require('UC_BPShooterBack_Played', True);
	c.Require('UC_BP_JockBodyFound', False);
	c.Line("UCSpecialAgent3", "JCDenton", "Move along, Agent.");
	c.Done();
	c.AttachTo(sp);

	c = new(Level) class'UCCon';
	c.Begin('UC_BPShooterBack', "UCSpecialAgent3", True);
	c.Passive();
	c.Once();
	c.Require('UC_BPShooterStop_Played', True);
	c.Require('UC_BP_JockBodyFound', False);
	c.Line("UCSpecialAgent3", "JCDenton", "Your mission is at the helicopter, Agent. Get back to it.");
	c.Done();
	c.AttachTo(sp);

	c = new(Level) class'UCCon';
	c.Begin('UC_BPShooterStop', "UCSpecialAgent3", True);
	c.Passive();
	c.Once();
	c.Require('UC_BP_JockBodyFound', False);
	c.Line("UCSpecialAgent3", "JCDenton", "Nothing to see here, Denton.");
	c.Done();
	c.AttachTo(sp);

	c = new(Level) class'UCCon';
	c.Begin('UC_BPShooterBodyMore', "UCSpecialAgent3", True);
	c.Passive();
	c.Require('UC_BPShooterBody_Played', True);
	c.Line("UCSpecialAgent3", "JCDenton", "Go to work, Agent Denton.");
	c.Done();
	c.AttachTo(sp);

	c = new(Level) class'UCCon';
	c.Begin('UC_BPShooterBody', "UCSpecialAgent3", True);
	c.Passive();
	c.Once();
	c.Require('UC_BP_JockBodyFound', True);
	c.Line("UCSpecialAgent3", "JCDenton", "He was a terrorist, Denton. Go to work.");
	c.Done();
	c.AttachTo(sp);
}

// He waits by the body. When JC comes round the vine wall and he sees him, he walks up to him,
// pistol in hand, stops a few steps off and tries to send him away: "Nothing to see here", then,
// if JC goes on to the body, "Get back to it". Once the body has been found, one last line. When
// JC leaves he goes back to his place.
function ShooterTick()
{
	local ScriptedPawn sp;
	local DeusExPlayer P;

	sp = Agent(3);
	P = Plr();
	if (sp == None || P == None || sp.Health <= 0 || sp.GetPawnAllianceType(P) == ALLIANCE_Hostile)
		return;
	if (!InShooterZone())
	{
		if (bShooterOn)
		{
			bShooterOn = False;
			ShooterHome(sp);
		}
		else if (sp.IsInState('GoingTo') && sp.OrderTag == 'UCBPShooterPost' && VSize((sp.Location - ShooterPost()) * vect(1,1,0)) < 80)
			sp.SetOrders('Standing', '', True);
		return;
	}
	if (!bShooterOn && !P.LineOfSightTo(sp))
		return;
	bShooterOn = True;
	shooterT += 0.25;
	if (Talking() || InfoBusy())
		return;              // in a talk the game holds him still, facing JC
	if (VSize((sp.Location - P.Location) * vect(1,1,0)) > 200)
	{
		if (!sp.IsInState('GoingTo') || sp.OrderActor != P)
			sp.SetOrders('GoingTo', '', True);        // no tag: towards the player
	}
	else if (sp.IsInState('GoingTo'))
		sp.SetOrders('Standing', '', True);
	if (GetF('UC_BP_JockBodyFound'))
	{
		if (!GetF('UC_BPShooterBody_Played'))
			Bark(sp, 'UC_BPShooterBody', 1000);
	}
	else if (!GetF('UC_BPShooterStop_Played'))
	{
		if (Bark(sp, 'UC_BPShooterStop', 1000))
			shooterT = 0;
	}
	else if (!GetF('UC_BPShooterBack_Played') && shooterT > 6 && VSize((P.Location - BodySpot()) * vect(1,1,0)) < 500)
		Bark(sp, 'UC_BPShooterBack', 1000);
}

function ShooterHome(ScriptedPawn sp)
{
	local UCMark mark;

	foreach AllActors(class'UCMark', mark, 'UCBPShooterPost')
		break;
	if (mark == None)
		mark = Spawn(class'UCMark',, 'UCBPShooterPost', ShooterPost());
	if (mark != None)
		sp.SetOrders('GoingTo', 'UCBPShooterPost', True);
	else
		sp.SetOrders('Standing', '', True);
}

// Eva, at the helicopter door: JC clicks the helicopter (no radius: passing by on the way to the
// body must not start the takeoff). Every answer ends with the takeoff (UC_EvaGo).
function EvaTalks()
{
	local BlackHelicopter h;
	local UCCon c;

	h = EvaHeli();
	if (h == None || flight != 3 || HasCon(h, 'UC_BPEva'))
		return;
	h.BindName = "Eva";
	h.FamiliarName = "Eva";
	h.UnfamiliarName = "Eva";
	h.ConListItems = None;
	c = new(Level) class'UCCon';
	c.Begin('UC_BPEva', "Eva", False);
	c.Once();
	c.FixedShot();
	c.Line("Eva", "JCDenton", "Strand. I'm your pilot now.");
	// three answers: the second is about Jock's body once JC has found it
	c.Choices();
	c.Answer("You knew Jock?", "Knew");
	c.Answer("That was fast.", "Fast", 'UC_BP_JockBodyFound', False);
	c.Answer("They left him behind a wall.", "Wall", 'UC_BP_JockBodyFound', True);
	c.Answer("[Get in without a word]", "Silent");
	c.Label("Knew");
	c.Line("JCDenton", "Eva", "You knew Jock?");
	c.Line("Eva", "JCDenton", "I know his file. Get in.");
	c.SetFlag('UC_EvaGo', True);
	c.EndHere();
	c.Label("Fast");
	c.Line("JCDenton", "Eva", "That was fast.");
	c.Line("Eva", "JCDenton", "I was told to be ready. Get in.");
	c.SetFlag('UC_EvaGo', True);
	c.EndHere();
	c.Label("Wall");
	c.Line("JCDenton", "Eva", "They left him behind a wall.");
	c.Line("Eva", "JCDenton", "... Then don't give them a reason to do the same with you.");
	c.SetFlag('UC_BP_EvaWallLine', True);
	c.SetFlag('UC_EvaGo', True);
	c.EndHere();
	c.Label("Silent");
	c.SetFlag('UC_EvaGo', True);
	c.Done();
	c.AttachTo(h);
}

// --- InfoLinks (one-way: only the caller speaks) -----------------------------------------
function float JockLine(int i)
{
	switch (i)
	{
		case 0: return Say("Jock", "JC! Thank God. Listen, I'm at the pad, there's cops all over the chopper--");
		case 1: return Say("Jock", "They pulled me out of the cockpit. Said it's routine. It's not routine, JC, they've got guys in suits with them--");
		case 2: return Say("Jock", "[muffled] Hey, I'm talking to an agent, you can't-- [muffled] What are you doing with that--");
	}
	return -1;
}

function float AlexLine(int i)
{
	switch (i)
	{
		case 0: return Say("AlexJacobson", "JC... I just heard about Jock. I don't-- He was--");
		case 1: return Say("WaltonSimons", "Agent Jacobson, clear this channel.");
		case 2: return Say("AlexJacobson", "...Yes, sir.");
		case 3: return Say("WaltonSimons", "Agent Denton. A replacement pilot is inbound. Hong Kong hasn't moved. Neither has your target.");
	}
	return -1;
}

function float InfoLine(int i)
{
	if (infoMode == 1)
		return JockLine(i);
	if (infoMode == 2)
		return AlexLine(i);
	return -1;
}

// After the shot (also when a reload cut the call: it counts as heard).
function JockShot()
{
	local DeusExPlayer P;

	SetF('UC_JockDead', True);
	P = Plr();
	if (P == None)
		return;
	// "Meet Jock" closes with the call; the doc's new objective takes its place
	CloseGoal('MeetJockBatteryPark');
	if (P.FindGoal('UCBPReachHeli') == None)
		P.GoalAdd('UCBPReachHeli', "Reach Jock's helicopter.", True);
}

// completes a goal once (completing it again would repeat the message on the HUD)
function CloseGoal(name goalName)
{
	local DeusExPlayer P;
	local DeusExGoal g;

	P = Plr();
	if (P == None)
		return;
	g = P.FindGoal(goalName);
	if (g != None && !g.bCompleted)
		P.GoalCompleted(goalName);
}

function ReachGoalDone()
{
	CloseGoal('UCBPReachHeli');
}

// once the replacement helicopter is on the ground
function BoardGoal()
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None && P.FindGoal('UCBPBoardHeli') == None)
		P.GoalAdd('UCBPBoardHeli', "A replacement pilot is coming in at the flare south of the subway entrance. Board the helicopter and proceed to Hong Kong.", True);
}

// The landing zone from Simons's call on (Gabby, 17 Oct: a Special Agent lights the flare and holds it up
// high, arm straight, open palm; clicked he says to move, not to waste time). He is placed by the clearing
// while JC can't see it (after 30 s in sight: the old flare on the ground instead), and lights it when JC
// comes near and sees him (or after 25 s). A game saved with the old flare on the ground keeps it.
function MarkLZ()
{
	local Flare f;
	local UCBPFlareAgent a;
	local DeusExPlayer P;

	foreach AllActors(class'Flare', f, 'UCBPEvaFlare')
		return;
	P = Plr();
	a = UCBPFlareAgent(Agent(4));
	if (a != None && !a.bInWorld)
	{
		// the agent of the map (placed in the editor, out of the world until now): in at his place once JC
		// can't see it (never in front of him)
		if (SpotSeen(a.WorldPosition) || SpotSeen(a.WorldPosition + vect(0,0,1) * a.BaseEyeHeight))
			return;
		a.ChangeAlly('Player', 1.0, False);
		a.EnterWorld();
		a.SetOrders('Standing', '', True);
		SetF('UC_BP_FlareAgentPlaced', True);
		Log("UCBatteryPark: the agent with the flare (the map's) comes in at" @ a.Location);
	}
	if (a == None)
	{
		if (GetF('UC_BP_FlareAgentPlaced'))
			return;                        // he is gone: Playing's AgentDown
		a = PlaceFlareAgent();
		if (a == None)
		{
			flareWait += 0.25;
			if (flareWait > 30)
				LightLZ();
			return;
		}
	}
	FlareTracks();
	if (!HasCon(a, 'UC_BPFlareAgent1'))
		FlareAgentTalks(a);
	if (a.bLighting || a.bHolding)
		return;
	if (!a.UseFlareModel())
	{
		LightLZ();                         // no UCAnims.u: the flare on the ground, as before
		return;
	}
	flareT += 0.25;
	if (flareT > 25 || (P != None && VSize(P.Location - a.Location) < 2400 && SeenByJC(a))
		|| (P != None && VSize((P.Location - EvaSpot()) * vect(1,1,0)) < 1900))
	{
		a.LightUp();
		Log("UCBatteryPark: the agent at the clearing lights the flare");
	}
}

// the clearing (with a margin round the spot) as JC sees it: placing the agent waits until he can't
function bool SpotSeen(vector spot)
{
	local DeusExPlayer P;
	local vector eye, d;

	P = Plr();
	if (P == None)
		return False;
	eye = P.Location + vect(0,0,1) * P.BaseEyeHeight;
	d = spot - eye;
	if (VSize(d) > 5000)
		return False;
	if ((Normal(d) dot vector(P.ViewRotation)) < 0.3)
		return False;
	return FastTrace(spot, eye) || FastTrace(spot + vect(0,0,48), eye);
}

function UCBPFlareAgent PlaceFlareAgent()
{
	local vector spot, normal;
	local ScriptedPawn sp;
	local int i;

	for (i = 0; i < 4; i++)
	{
		spot = FloorAt(FlareAgentSpot(i), normal) + vect(0,0,1) * (class'UCBPFlareAgent'.default.CollisionHeight + 2);
		if (SpotSeen(spot))
			return None;
		sp = PlaceNPC(class'UCBPFlareAgent', 'UCSpecialAgent', "UCSpecialAgent4", spot, 4150);
		if (sp != None)
		{
			SetF('UC_BP_FlareAgentPlaced', True);
			Log("UCBatteryPark: the agent with the flare is at" @ sp.Location);
			return UCBPFlareAgent(sp);
		}
	}
	return None;
}

// the hand's track of the flare animations (UCHeldFlare: the real flare on his hand), once per map
function FlareTracks()
{
	local UCTrackFlareLight l;
	local UCTrackFlareHold h;

	foreach AllActors(class'UCTrackFlareLight', l)
		break;
	if (l == None)
		Spawn(class'UCTrackFlareLight',,, EvaSpot());
	foreach AllActors(class'UCTrackFlareHold', h)
		break;
	if (h == None)
		Spawn(class'UCTrackFlareHold',,, EvaSpot());
}

// clicked: move, don't waste time (Gabby, 17 Oct); then a word. The last attached is tried first.
function FlareAgentTalks(ScriptedPawn sp)
{
	local UCCon c;

	c = new(Level) class'UCCon';
	c.Begin('UC_BPFlareAgent2', "UCSpecialAgent4", True);
	c.Require('UC_BPFlareAgent1_Played', True);
	c.Line("UCSpecialAgent4", "JCDenton", "Move, Agent.");
	c.Done();
	c.AttachTo(sp);

	c = new(Level) class'UCCon';
	c.Begin('UC_BPFlareAgent1', "UCSpecialAgent4", True);
	c.Once();
	c.Line("UCSpecialAgent4", "JCDenton", "The helicopter, Agent Denton. Move. Don't waste our time.");
	c.Done();
	c.AttachTo(sp);
}

// The landing zone marked by a burning flare (Gabby, 15 Oct), from Simons's call on. The game's
// flare burns for six minutes: this one (its smoke, sparks and light too) burns until JC leaves.
function LightLZ()
{
	local Flare f;
	//#if revision
	local FlareLight fl;
	//#endif
	local vector normal;

	foreach AllActors(class'Flare', f, 'UCBPEvaFlare')
		return;
	f = Spawn(class'Flare',, 'UCBPEvaFlare', FloorAt(FlareSpot(), normal) + vect(0,0,1) * class'Flare'.default.CollisionHeight);
	if (f == None)
	{
		Log("UCBatteryPark: the flare could not be placed");
		return;
	}
	f.SetPhysics(PHYS_None);
	f.LightFlare();
	f.LifeSpan = 0;
	if (f.gen != None)
		f.gen.LifeSpan = 0;
	//#if revision
	if (f.flaregen != None)
		f.flaregen.LifeSpan = 0;
	if (f.flamething != None)
		f.flamething.LifeSpan = 0;
	foreach AllActors(class'FlareLight', fl)
		if (fl.Owner == f)
			fl.LifeSpan = 0;
	//#endif
}

// --- Eva's helicopter ---------------------------------------------------------------
// Her helicopter is dark police blue from here on (Gabby, 15 Oct): the game's own body texture
// recoloured (UCTextures.UCEvaHeliTex). Also used on the Hong Kong roof (UCSceneHKArrival).
static function PaintEva(BlackHelicopter h)
{
	local Texture tex;

	if (h == None)
		return;
	tex = Texture(DynamicLoadObject("UnatcoContinues.UCEvaHeliTex", class'Texture', True));
	if (tex != None)
		h.MultiSkins[0] = tex;
}

function BlackHelicopter SpawnEvaHeli()
{
	local BlackHelicopter h;

	h = EvaHeli();
	if (h != None)
		return h;
	h = Spawn(class'BlackHelicopter',, 'UCEvaHeli', EvaFrom(), rot(0, 16384, 0));
	if (h == None)
	{
		Log("UCBatteryPark: Eva's helicopter could not be placed");
		return None;
	}
	if (!h.bInWorld)
		h.EnterWorld();
	h.bHidden = False;
	h.SetCollision(False, False, False);
	h.bCollideWorld = False;
	h.SetPhysics(PHYS_None);
	h.SetLocation(EvaFrom());
	h.Event = '';
	h.BindName = "UCEvaHeli";
	PaintEva(h);
	h.SoundRadius = 255;
	h.SoundVolume = 255;
	if (!h.IsInState('Flying'))
		h.GotoState('Flying');
	return h;
}

// where a helicopter already in the air goes on from (after a reload)
function ResumeFlight()
{
	local BlackHelicopter h;

	h = EvaHeli();
	if (h == None)
		h = SpawnEvaHeli();
	if (h == None)
		return;
	if (VSize((h.Location - EvaSpot()) * vect(1,1,0)) > 40)
		flight = 1;
	else if (GetF('UC_BP_EvaDescent'))
		Descend(h);
	else
		Hold(h);
}

// Over the clearing, high up: the rotor heard from afar, more than seen (Gabby, 15 Oct).
function Hold(BlackHelicopter h)
{
	flight = 6;
	h.SoundRadius = 160;
	h.SoundVolume = 160;
}

// JC is coming: down to the clearing, at full sound, before he gets there.
function Descend(BlackHelicopter h)
{
	flight = 2;
	SetF('UC_BP_EvaDescent', True);
	h.SoundRadius = 255;
	h.SoundVolume = 255;
}

function Face(BlackHelicopter h, vector dir)
{
	local rotator r;

	dir.Z = 0;
	if (VSize(dir) < 1)
		return;
	r = Rotator(dir);
	r.Pitch = 0;
	r.Roll = 0;
	h.SetRotation(r);
}

function Land(BlackHelicopter h)
{
	local DeusExPlayer P;
	local vector out;
	local float edge;

	curVel = vect(0,0,0);
	descentV = 0;
	h.SetLocation(EvaSpot());
	h.SetCollisionSize(261.23, 87.84);   // as Jock's in the map (the class default is a 461 disc)
	// JC still inside its collision (a reload, a wall that stopped the rotor wash): out to its edge first,
	// or he would walk through it and the crosshair (starting inside) would never take it
	P = Plr();
	if (P != None)
	{
		out = (P.Location - h.Location) * vect(1,1,0);
		edge = h.CollisionRadius + P.CollisionRadius + 4;
		if (VSize(out) < edge && Abs(P.Location.Z - h.Location.Z) < h.CollisionHeight + P.CollisionHeight)
		{
			if (VSize(out) < 1)
				out = vect(1,0,0);
			P.SetLocation(h.Location * vect(1,1,0) + Normal(out) * edge + vect(0,0,1) * P.Location.Z);
		}
	}
	h.SetCollision(True, True, True);
	class'UCHeliBlock'.static.Follow(h, True);   // the tail boom, out of the cylinder
	flight = 3;
	SetF('UC_BP_EvaLanded', True);
	BoardGoal();
	if (!IsInState('EvaArrives'))
		EvaTalks();                     // clickable at once (not a quarter of a second later)
	Log("UCBatteryPark: Eva's helicopter landed");
}

event Tick(float dt)
{
	local BlackHelicopter h;
	local DeusExPlayer P;
	local vector to, wantV;
	local float dist, speed, height, want, footprint;

	beatT += dt;
	if (beatT >= 0.25)
	{
		CopBeat(beatT);
		beatT = 0;
	}
	if (flight == 0 || flight == 3)
		return;
	h = EvaHeli();
	if (h == None)
	{
		flight = 0;
		return;
	}
	if (flight == 1)
	{
		// slowing down over the last few hundred units instead of stopping dead
		to = EvaHold() - h.Location;
		dist = VSize(to);
		if (dist < 30)
		{
			h.SetLocation(EvaHold());
			Hold(h);
			return;
		}
		speed = FMin(420, FMax(60, dist * 1.2));
		h.SetLocation(h.Location + Normal(to) * FMin(dist, speed * dt));
		Face(h, to);
		return;
	}
	if (flight == 6)
	{
		// it comes down once JC is near: he sees it land, and it is down before he gets there
		P = Plr();
		if (P != None && VSize((P.Location - EvaSpot()) * vect(1,1,0)) < 1700)
			Descend(h);
		return;
	}
	if (flight == 2)
	{
		// never down on top of JC. Under its body (its landed collision and his own), it comes down to
		// 150 over the clearing and waits there, and its rotor wash moves him out (MoveSmooth, walls stop
		// him); then it lands. (Gabby, 18 Oct: it used to wait wherever it was, low enough to look landed:
		// in the air it has no collision and no talk, so JC walked through it and could not click Eva.)
		P = Plr();
		dist = 99999;
		if (P != None)
			dist = VSize((P.Location - EvaSpot()) * vect(1,1,0));
		footprint = 261.23 + 8;
		if (P != None)
			footprint += P.CollisionRadius;
		if (dist < footprint)
			bDescentHeld = True;
		else if (dist > footprint + 10)
			bDescentHeld = False;
		height = h.Location.Z - EvaSpot().Z;
		if (bDescentHeld && height < 160 && P != None && !P.bHidden)
		{
			to = (P.Location - EvaSpot()) * vect(1,1,0);
			if (VSize(to) < 1)
				to = vect(1,0,0);
			P.MoveSmooth(Normal(to) * FMin(300 * dt, footprint + 12 - dist));
		}
		if (bDescentHeld && height < 150)
			want = 0;
		else
			want = FClamp(height * 0.7, 40, 280);
		descentV += FClamp(want - descentV, -250 * dt, 250 * dt);
		// The descent below deliberately stops one unit above the pad. At more
		// than 40 fps a frame's movement can be smaller than that gap, so using
		// only speed * dt never lands: Eva looks parked but stays non-colliding
		// and cannot be clicked. Include a small, frame-rate-independent tolerance.
		if (!bDescentHeld && height <= FMax(2.0, FMax(descentV, 40) * dt))
		{
			Land(h);
			return;
		}
		h.SetLocation(h.Location - vect(0,0,1) * FMin(descentV * dt, FMax(height - 1, 0)));
		return;
	}
	// the takeoff: up, turning towards the bay as it climbs, then away over the bay, level below the
	// map's sky lid (Z 1600: the cutscene can last longer at a low frame rate)
	flightT += dt;
	if (flight == 4)
	{
		wantV = vect(0,0,170);
		if (flightT > 3.5)
			flight = 5;
	}
	else
	{
		wantV = vect(300,-360,0);
		wantV.Z = FClamp((1350 - h.Location.Z) * 0.8, 0, 110);
	}
	// the speed eases towards the wanted one: no jolt when it lifts off or sets off
	curVel += (wantV - curVel) * FMin(1, dt * 2.5);
	h.SetLocation(h.Location + curVel * dt);
	TurnToward(h, vect(300,-360,0), 70 * dt);
}

// Turns the helicopter towards a direction by at most that many degrees (no snap round).
function TurnToward(BlackHelicopter h, vector dir, float degrees)
{
	local rotator r;
	local int want, delta, stepU;

	dir.Z = 0;
	if (VSize(dir) < 1)
		return;
	want = Rotator(dir).Yaw & 65535;
	r = h.Rotation;
	delta = ((want - (r.Yaw & 65535) + 98304) & 65535) - 32768;
	stepU = Max(1, int(degrees * 65536 / 360));
	// slowing over the last ~20 degrees instead of stopping dead
	stepU = Max(1, Min(stepU, int(Abs(delta) * 6 * degrees / 70)));
	if (delta <= stepU && delta >= -stepU)
		r.Yaw = want;
	else if (delta > 0)
		r.Yaw += stepU;
	else
		r.Yaw -= stepU;
	r.Pitch = 0;
	r.Roll = 0;
	h.SetRotation(r);
}

// a camera beside Eva's helicopter with a clear view (as UCSceneTakeoff)
function vector CamSpot()
{
	local BlackHelicopter h;
	local vector base, cand;
	local vector offs[5];
	local int i;

	h = EvaHeli();
	if (h == None)
		return Location;
	base = h.Location;
	// the first two: clear of the tree crowns round Eva's clearing on every line to the helicopter,
	// from the ground to the top of the climb (FastTrace sees only the level, not trees: 15 Oct)
	offs[0] = vect(950, -350, 180);
	offs[1] = vect(700, -800, 200);
	offs[2] = vect(950, -650, 140);
	offs[3] = vect(-950, 650, 140);
	offs[4] = vect(0, -1100, 200);
	for (i = 0; i < 5; i++)
	{
		cand = base + offs[i];
		if (FastTrace(cand, base + vect(0,0,120)) && FastTrace(cand, base + vect(0,0,600)))
			return cand;
	}
	return base + vect(700, 0, 700);
}

// --- the sequence ---------------------------------------------------------------------
state Playing
{
Begin:
	if (Plr() == None || Plr().FlagBase == None)
	{
		Sleep(0.5);
		Goto('Begin');
	}
	Setup();
	if (GetF('UC_BP_JockCall') && !GetF('UC_JockDead'))
		JockShot();
	if (GetF('UC_BP_EvaCall') && !GetF('UC_BP_EvaLanded'))
		ResumeFlight();
	else if (GetF('UC_BP_EvaLanded') && EvaHeli() != None)
	{
		flight = 3;
		// Restore the complete landed state, not just the tail blockers. Older
		// saves can retain flight collision settings on the helicopter actor.
		if (!GetF('UC_EvaGo'))
			Land(EvaHeli());
	}
	if (GetF('UC_EvaGo'))
		GotoState('Takeoff');
Wait:
	// JC turned on UNATCO here (attacked the agents): no pilot comes for him
	if (GetF('JCBrokeWithUNATCO'))
	{
		Log("UCBatteryPark: JC broke with UNATCO, the sequence stops");
		Destroy();
		Stop;
	}
	if ((GetF('UC_BP_CastPlaced') && (Agent(1) == None || Agent(2) == None)) || (GetF('UC_BP_ShooterPlaced') && Agent(3) == None)
		|| (GetF('UC_BP_FlareAgentPlaced') && Agent(4) == None))
	{
		AgentDown();
		Destroy();
		Stop;
	}
	Setup();
	AgentTalks();
	WitnessTalks();
	ShooterTalks();
	BarkTick();
	WitnessTick();
	ShooterTick();
	EvaTalks();
	if (GetF('UC_BP_MIBMet'))
		ReachGoalDone();
	// Jock calls two seconds after JC gets off the train, still down in the station (Gabby, 18 Oct 2026; it
	// used to wait for him to come up: OutOfSubway)
	if (!GetF('UC_BP_JockCall') && !Talking() && !InfoBusy())
	{
		outT += 0.25;
		if (outT >= 2.0)
			GotoState('JockCall');
	}
	if (GetF('UC_BP_MIBMet') && !GetF('UC_BP_EvaCall') && !Talking() && !InfoBusy())
		GotoState('EvaArrives');
	if (GetF('UC_EvaGo') && !Talking())
		GotoState('Takeoff');
	Sleep(0.25);
	Goto('Wait');
}

// Phase 1: Jock calls a moment after JC is out of the subway. His last line ends, the line goes
// dead in static, and as soon as the call is over JC hears the gunshot, with its echo across the
// park (Gabby, 15 Oct). Only then the goal, and the bum's line about the shot (UC_JockDead).
// A player who runs can reach the pad before the call ends: the call is cut (static, shot) the
// moment JC comes close or is about to see the pad, also during the "incoming transmission".
state JockCall
{
Begin:
	SetF('UC_BP_JockCall', True);
	infoMode = 1;
	InfoStart("Jock");
	t = 0;
Open:
	if (NearPad())
		Goto('Shot');
	Sleep(0.25);
	t += 0.25;
	if (t < 1.5)
		Goto('Open');
	n = 0;
Next:
	d = JockLine(n);
	if (d < 0)
		Goto('Shot');
	t = 0;
Hold:
	if (NearPad())
		Goto('Shot');
	Sleep(0.25);
	t += 0.25;
	if (t < d)
		Goto('Hold');
	n++;
	Goto('Next');
Shot:
	Plr().PlaySound(Sound'DeusExSounds.Generic.Spark1', SLOT_Misc, 0.7);
	Sleep(0.5);
	HideInfo(True);                     // la chiamata e' interrotta: niente "end transmission"
	infoMode = 0;
	Sleep(0.3);
	Plr().PlaySound(Sound'DeusExSounds.Weapons.PistolFire', SLOT_Talk, 1.0,,, 0.85);
	Sleep(0.45);
	Plr().PlaySound(Sound'DeusExSounds.Weapons.PistolFire', SLOT_Misc, 0.35,,, 0.7);
	Sleep(0.5);
	JockShot();
	Log("UCBatteryPark: Jock's call over, gunshot heard");
	GotoState('Playing', 'Wait');
}

// Phase 5: Alex, cut off by Simons, while the replacement helicopter comes in from the bay.
state EvaArrives
{
Begin:
	Sleep(1.0);
	if (Talking() || InfoBusy())
		Goto('Begin');
	SetF('UC_BP_EvaCall', True);
	ReachGoalDone();
	if (SpawnEvaHeli() != None)
		flight = 1;
	infoMode = 2;
	InfoStart("AlexJacobson");
	Sleep(1.5);
	n = 0;
Next:
	d = AlexLine(n);
	if (d >= 0)
	{
		Sleep(d);
		n++;
		Goto('Next');
	}
	BoardGoal();                      // Simons's call says where the new pilot lands
	HideInfo();
	infoMode = 0;
	GotoState('Playing', 'Wait');
}

// Eva's answer said "Get in": JC is aboard (hidden), the camera watches the helicopter go.
state Takeoff
{
Begin:
	if (Talking())
	{
		Sleep(0.25);
		Goto('Begin');
	}
	if (EvaHeli() == None)
		SpawnEvaHeli();
	if (EvaHeli() != None && flight != 3)
		Land(EvaHeli());
	CloseGoal('UCBPBoardHeli');
	Sleep(0.3);
	CutsceneStart(CamSpot(), EvaHeli());
	Sleep(1.5);
	if (EvaHeli() != None)
	{
		EvaHeli().SetCollision(False, False, False);
		EvaHeli().SetPhysics(PHYS_None);
		class'UCHeliBlock'.static.Follow(EvaHeli(), False);
	}
	flightT = 0;
	flight = 4;
	t = 0;
Fly:
	CamLookAt(EvaHeli());
	Sleep(0.05);
	t += 0.05;
	if (t < 7.0)
		Goto('Fly');
	CutsceneEnd();
	SetF('UNATCORoute_DepartedNYC', True);
	if (Plr() != None)
		class'UCCampaign'.static.PrepareHongKongFlags(Plr().FlagBase);
	TravelTo("06_HongKong_WanChai_Rooftop", 0);
	Destroy();
}

// no talking with the agents, the cops... while Jock or Alex calls (Gabby, 18 Oct 2026: UCTalkHush)

defaultproperties
{
     bHushTalks=True
}
