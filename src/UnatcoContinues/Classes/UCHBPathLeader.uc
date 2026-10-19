//=============================================================================
// UCHBPathLeader - the squad leader of the Luminous Path in the attack on the garage of Harbourline Tower
// (Mission 6, 06_HongKong_WanChai_Rooftop; plan 5.2). The Gang Leader's body (TriadLumPath2: his
// ponytail, a touch taller) on the squad's fighter (UCHBPathFighter: hidden behind the gate until the
// blast, then in, then he fights). BindName "UCHBPathLeader".
//  - He never falls back (Retreat does nothing).
//  - At 40% of his health or less (still alive) he gives up (Surrender, state HBSurrendered): his weapon
//    drops, he stands with his hands behind his back (PlayCaptive: UCHandsBehind, made in the map editor's
//    Animation Studio on GM_Suit; Gabby 16 Oct: always standing, no kneeling), nobody's enemy any more
//    (Harbourline's men stop shooting at him); he can still be killed. UC_HB_LeaderCaptured.
//  - Killed: UC_HB_LeaderKilled. Knocked out (D6, Gabby): a capture. UC_HB_LeaderCaptured and
//    UC_HB_LeaderKO; after the fight UCSceneHarbourline swaps his unconscious body for him, alive and
//    kneeling, while JC is not looking (WakeCaptive). Once he has been handed over or let go, his death
//    changes nothing.
//  - After the fight the scene walks him (HBLed): taken (he gave up, or came round after a knock-out), one
//    of Kwan's men comes for him and walks him, a step behind, to the custody spot in front of the cold
//    room's door, where he stands (hands behind his back, walking too: UCWalkCaptive); after Kwan's debrief
//    the talk UC_HBLeaderTalk, then into the cold room (handed over) or out by the lane to the canal (let
//    go, walking freely). The scene removes him only where JC can't see him.
// Like the fighters, his moment is his Orders (saved with him).
//=============================================================================
class UCHBPathLeader extends UCHBPathFighter;

var bool bSurrendered;      // he gave up, or came round after a knock-out: a prisoner
var bool bWoke;             // he came round after a knock-out (D6)
var int ledMode;            // where he is walked: 1 the custody spot, 2 the cold room, 3 out to the canal
var vector ledSpot;
var float ledT;             // seconds on his way (the scene's fallback for a way he can't finish)

function SetFlag(name flagName, bool value)
{
	local DeusExPlayer P;

	P = DeusExPlayer(GetPlayerPawn());
	if (P != None && P.FlagBase != None)
		P.FlagBase.SetBool(flagName, value,, 99);
}

function bool GetFlag(name flagName)
{
	local DeusExPlayer P;

	P = DeusExPlayer(GetPlayerPawn());
	return P != None && P.FlagBase != None && P.FlagBase.GetBool(flagName);
}

// He never falls back.
function Retreat(vector spot)
{
}

// Badly hurt (40% of his health when the attack began, or less): he gives up.
function Tick(float deltaTime)
{
	Super.Tick(deltaTime);
	if (bActivated && !bSurrendered && Health > 0 && fullHealth > 0 && Health <= fullHealth * 0.4
		&& !IsInState('Dying'))
		Surrender();
}

// Nobody's enemy: his own side's alliance goes (the guards are enemies of UCHBPath, not of a prisoner),
// whoever was shooting at him stops.
function Captive()
{
	local ScriptedPawn sp;

	SetEnemy(None, 0, True);
	SetAlliance('UCHBCaptive');
	ChangeAlly('Player', 0, True);
	ChangeAlly('Harbourline', 0, True);
	ChangeAlly('UCHBPath', 0, True);
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp != Self && sp.Enemy == Self)
		{
			sp.SetEnemy(None, 0, True);
			sp.FollowOrders();
		}
}

function Surrender()
{
	if (bSurrendered || Health <= 0)
		return;
	bSurrendered = True;
	DropWeapon();
	SetupWeapon(False);
	Captive();
	if (!GetFlag('UC_HB_LeaderToKwan') && !GetFlag('UC_HB_LeaderFreed'))
	{
		SetFlag('UC_HB_LeaderCaptured', True);
		SetFlag('UC_HB_LeaderKilled', False);
	}
	SetOrders('HBSurrendered', '', True);
	Log("UCHBPath: the squad leader gives up (UC_HB_LeaderCaptured), health" @ Health);
}

// D6: spawned by the scene where his unconscious body lay (or put in place by the debug jump): alive,
// unarmed, kneeling.
function WakeCaptive()
{
	local int i;

	bActivated = True;
	bHidden = False;
	SetCollision(True, True, True);
	bCollideWorld = True;
	SetWeapon(None);
	for (i = 0; i < 32 && Inventory != None; i++)
		Inventory.Destroy();
	fullHealth = Health;
	bSurrendered = True;
	bWoke = True;
	Captive();
	SetOrders('HBSurrendered', '', True);
}

// A prisoner: standing, hands behind his back. The animations were made in the map editor's Animation Studio
// (16 Oct 2026, Gabby: "always standing with the hands behind the back") on his model GM_Suit: UCHandsBehind
// (the game's BreatheLight with the arms behind) and UCWalkCaptive (its Walk, same arms); they are in the
// copy of his model in UCAnims.u (with every sequence of the game's), which he takes here. Without the
// package (an old install) he just stands.
function UseCaptiveModel()
{
	local Mesh M;

	if (Mesh == None || Mesh.Outer.Name == 'UCAnims')
		return;
	M = Mesh(DynamicLoadObject("UCAnims." $ Mesh.Name, class'Mesh', True));
	if (M != None)
		Mesh = M;
}

function PlayCaptive()
{
	UseCaptiveModel();
	if (HasAnim('UCHandsBehind'))
		LoopAnim('UCHandsBehind', 1.0, 0.3);
	else
		PlayWaiting();
}

// Walking as a prisoner: the game's walk at its own speed, the arms kept behind his back.
function PlayCaptiveWalk()
{
	local float r;

	UseCaptiveModel();
	PlayWalking();
	if (!HasAnim('UCWalkCaptive'))
		return;
	r = AnimRate;                   // UCWalkCaptive has Walk's frames and rate: the same speed
	LoopAnim('UCWalkCaptive',, 0.15);
	AnimRate = r;
}

// Walked somewhere by the scene (1 custody, 2 the cold room, 3 out to the canal).
function LedTo(int mode, vector spot)
{
	ledMode = mode;
	ledSpot = spot;
	ledT = 0;
	SetOrders('HBLed', '', True);
}

function Died(pawn Killer, name damageType, vector HitLocation)
{
	Super.Died(Killer, damageType, HitLocation);     // bStunned is set here: a knock-out
	if (GetFlag('UC_HB_LeaderToKwan') || GetFlag('UC_HB_LeaderFreed'))
		return;
	if (bStunned)
	{
		SetFlag('UC_HB_LeaderCaptured', True);
		SetFlag('UC_HB_LeaderKO', True);
		SetFlag('UC_HB_LeaderKilled', False);
		Log("UCHBPath: the squad leader is knocked out (D6: a capture, UC_HB_LeaderKO)");
	}
	else
	{
		SetFlag('UC_HB_LeaderKilled', True);
		SetFlag('UC_HB_LeaderCaptured', False);
		SetFlag('UC_HB_LeaderKO', False);
		Log("UCHBPath: the squad leader is dead (UC_HB_LeaderKilled)");
	}
}

// Standing where he gave up, hands behind his back, facing JC. Still killable.
state HBSurrendered extends HBQuiet
{
	ignores SeePlayer, HearNoise;

	function BeginState()
	{
		Super.BeginState();
		SetupWeapon(False);
	}

Begin:
	Acceleration = vect(0, 0, 0);
	if (GetPlayerPawn() != None)
		TurnToward(GetPlayerPawn());
	PlayCaptive();
Hold:
	Sleep(2.0);
	Goto('Hold');
ContinueFromDoor:
	Goto('Begin');
}

// Walked by the scene (LedTo): a prisoner's walk to the custody spot (the cold room's door) and into the cold
// room, there standing with his hands behind his back facing JC; let go (3) a free man's walk. A door on the
// way (the cold room's: the scene opens it for him) brings him back to ContinueFromDoor.
state HBLed extends HBQuiet
{
	ignores SeePlayer, HearNoise;

	function Tick(float deltaTime)
	{
		Global.Tick(deltaTime);
		ledT += deltaTime;
	}
	function BeginState()
	{
		Super.BeginState();
		SetupWeapon(False);
	}

Begin:
	Acceleration = vect(0, 0, 0);
Walk:
	if (Near(ledSpot, 40) || steps > 40)
		Goto('There');
	steps++;
	StepLog("led" @ ledMode, ledSpot);
	if (ledMode == 3)
		PlayWalking();
	else
		PlayCaptiveWalk();
	if (pointReachable(ledSpot))
	{
		MoveTo(ledSpot, GetWalkingSpeed());
		Goto('Walk');
	}
	MoveTarget = FindPathTo(ledSpot);
	if (MoveTarget != None)
		MoveToward(MoveTarget, GetWalkingSpeed());
	else
		MoveTo(ledSpot, GetWalkingSpeed());
	Goto('Walk');
There:
	Acceleration = vect(0, 0, 0);
	Log("UCHBPath: the squad leader stops (led" @ ledMode $ ") at" @ Location @ "steps" @ steps @ "to" @ ledSpot);
	if (ledMode == 3)
		Goto('Stand');
	if (ledMode == 1 && GetPlayerPawn() != None)
		TurnToward(GetPlayerPawn());
	PlayCaptive();
	Goto('Hold');
Stand:
	PlayWaiting();
Hold:
	Sleep(2.0);
	Goto('Hold');
ContinueFromDoor:
	steps = doorSteps + 1;
	Goto('Walk');
}

//#if vanilla
//// the original game's bodies do not keep who they were (Revision's flagName): his says it in CarcassName,
//// which also stays with the body JC carries and drops (UCSceneHarbourline.LeaderSwap finds it)
//function Carcass SpawnCarcass()
//{
//	local Carcass c;
//
//	c = Super.SpawnCarcass();
//	if (DeusExCarcass(c) != None)
//		DeusExCarcass(c).CarcassName = 'UCHBPathLeader';
//	return c;
//}
//#endif

defaultproperties
{
     BindName="UCHBPathLeader"
     FamiliarName="Path Squad Leader"
     UnfamiliarName="Path Squad Leader"
     InitialInventory(0)=(Inventory=Class'DeusEx.WeaponPistol')
     InitialInventory(1)=(Inventory=Class'DeusEx.Ammo10mm',Count=2)
     InitialInventory(2)=(Inventory=Class'DeusEx.WeaponSword')
     CarcassType=Class'DeusEx.TriadLumPath2Carcass'
     BaseEyeHeight=40.000000
     DrawScale=1.050000
     MultiSkins(0)=Texture'DeusExCharacters.Skins.TriadLumPath2Tex0'
     MultiSkins(1)=Texture'DeusExCharacters.Skins.PantsTex10'
     MultiSkins(2)=Texture'DeusExCharacters.Skins.TriadLumPath2Tex0'
     MultiSkins(3)=Texture'DeusExCharacters.Skins.TriadLumPathTex1'
     MultiSkins(4)=Texture'DeusExCharacters.Skins.TriadLumPathTex1'
     MultiSkins(5)=Texture'DeusExItems.Skins.GrayMaskTex'
     MultiSkins(6)=Texture'DeusExItems.Skins.BlackMaskTex'
     MultiSkins(7)=Texture'DeusExCharacters.Skins.PonytailTex1'
     CollisionRadius=16.799999
     CollisionHeight=48.830002
}
