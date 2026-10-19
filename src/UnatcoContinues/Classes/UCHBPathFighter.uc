//=============================================================================
// UCHBPathFighter - a fighter of the Luminous Path in the attack on the garage of Harbourline Tower
// (Mission 6, 06_HongKong_WanChai_Rooftop; plan 5.1). The squad waits behind the garage's closed doors,
// hidden and with no collision (the old raid's pattern, UCYardRaider, without its flags): nothing of it
// is seen until the blast (UCSceneHarbourline.Breach: RevealPath triggers every one, Trigger ->
// ActivateBreach). Then:
//  - HBEntry: after entryDelay (the doors behind him blow one after another) he runs in, by the
//    gallery if he has one, to his entry point. He sees and hears nothing on the way.
//  - a planter (plantContainer 2, 4 or 6) then runs to his container (HBPlant), still blind and deaf to
//    everything (JC has to stop him), kneels 4 seconds in front of its door and arms the charge on it
//    (UCHBCharge.Arm: UC_HB_Charge<N>Planted);
//  - then he fights (orders Standing: the scene gives him a target, a guard he can see or JC).
//  - HBRetreat: the squad falls back, or he is badly hurt (the scene, Retreat): he runs to the lane's
//    dead end "to the canal" and waits there; the scene removes him only when JC can't see him.
// His moment is his Orders (saved with him): after a hit, a stun, a load, the game's FollowOrders sends
// him back to it and the state goes on from where it was (entryStage, bPlanting, plantLeft).
// The scene's barks don't stop him: a first-person line said in the fight leaves his state alone
// (EnterConversationState). Kwan can't be hurt (D7): he is no target (FightTick, and Kwan is not
// detectable while in cover).
// The map sets per actor: the points, the container, the weapons (InitialInventory: a sword by default;
// the leader and one fighter carry a pistol and two clips), Orders Standing. Alliance UCHBPath, BindName
// "UCHBPath" (the barks' speaker).
//=============================================================================
class UCHBPathFighter extends TriadLumPath;

var() vector galleryPoint;  // a first stop on the way in ((0,0,0): none): the back room's gallery
var() vector entryPoint;    // where he comes into the hall ((0,0,0): where he waits)
var() int plantContainer;   // 0, or the container whose charge he arms (2, 4, 6): a planter
var() vector plantPoint;    // where he kneels to arm it (in front of the container's door)
var() name exitTag;         // an actor with this Tag marks where he falls back to (else the scene's canal exit)
var() float entryDelay;     // seconds after the blast before he moves

var bool bActivated;        // the attack has begun: he is seen and he fights
var int entryStage;         // 0 waiting for the doors, 1 to the gallery, 2 to the entry point, 3 in the hall
var bool bPlanting;         // kneeling at his container
var float plantLeft;        // seconds of kneeling left
var bool bPlanted;          // his charge is armed (or there was nothing to arm)
var bool bGaveUp;           // he could not reach his container: he fights instead
var bool bRetreating;       // falling back to the canal
var vector exitSpot;        // where he falls back to
var float retreatT;         // seconds since he began to fall back
var float fullHealth;       // his health when the attack began (the scene's "badly hurt": a share of it)
var bool bSpottedJC;        // he has had JC as his enemy (the scene's "spotted" barks)
var int steps;              // path steps on the current way (a cap: nobody runs in circles)
var int pulledBack;         // times the game's own fight took him from his orders (Tick: the log says the first)
var int doorSteps;          // his steps when a door stopped him (the game's OpeningDoor comes back to ContinueFromDoor:
                            // the way goes on with them, BeginState would start them again)

// The scene's blast (RevealPath triggers every fighter).
function Trigger(Actor Other, Pawn EventInstigator)
{
	ActivateBreach();
}

// Out of hiding, hostile to JC and to Harbourline, on his way in (orders HBEntry).
function ActivateBreach()
{
	if (bActivated || Health <= 0)
		return;
	bActivated = True;
	bHidden = False;
	SetCollision(True, True, True);
	bCollideWorld = True;
	fullHealth = Health;
	ChangeAlly('Player', -1.0, True);
	ChangeAlly('Harbourline', -1.0, True);
	entryStage = 0;
	SetOrders('HBEntry', '', True);
	Log("UCHBPath:" @ Name @ "comes in (container" @ plantContainer $ ")");
}

// The squad falls back, or he is badly hurt (UCSceneHarbourline): to the lane's dead end.
function Retreat(vector spot)
{
	local Actor A;

	if (Health <= 0 || bRetreating || !bActivated)
		return;
	bRetreating = True;
	bPlanting = False;
	exitSpot = spot;
	if (exitTag != '')
		foreach AllActors(class'Actor', A, exitTag)
		{
			exitSpot = A.Location;
			break;
		}
	retreatT = 0;
	SetEnemy(None, 0, True);
	SetOrders('HBRetreat', '', True);
	Log("UCHBPath:" @ Name @ "falls back to the canal");
}

// Done with his way in (and his charge): he fights; the scene gives him his target.
function Fight()
{
	SetOrders('Standing', '', True);
}

// After the way in: to his container, or to the fight.
function InHall()
{
	entryStage = 3;
	if (plantContainer != 0 && !bPlanted && !bGaveUp)
		SetOrders('HBPlant', '', True);
	else
		Fight();
}

function UCHBCharge MyCharge()
{
	local UCHBCharge c;

	if (plantContainer == 0)
		return None;
	foreach AllActors(class'UCHBCharge', c)
		if (c.container == plantContainer)
			return c;
	return None;
}

// What he faces while he kneels: the charge on the container's door.
function vector ChargeSpot()
{
	local UCHBCharge c;

	c = MyCharge();
	if (c != None)
		return c.Location;
	return plantPoint - vect(64, 0, 0);
}

// The 4 seconds are over: the charge is armed (by the map's fuse).
function ArmCharge()
{
	local UCHBCharge c;

	c = MyCharge();
	if (c != None && !c.bArmed && !c.bDefused && !c.bBlown)
		c.Arm();
	else
		Log("UCHBPath:" @ Name @ "has no charge to arm on container" @ plantContainer);
	bPlanted = True;
	bPlanting = False;
}

function bool Near(vector spot, float dist)
{
	return VSize((spot - Location) * vect(1,1,0)) < dist;
}

// Every tenth step of a way (in, to his container, out): where he is (the log of a way that takes long).
function StepLog(string way, vector goal)
{
	if (steps > 0 && steps % 10 == 0)
		Log("UCHBPath:" @ Name @ way @ "step" @ steps @ "at" @ Location @ "to" @ goal @ "state" @ GetStateName()
			@ "physics" @ Physics);
}

// The attack's own moments: on his way in, to his container, out to the canal; the leader given up or led.
function bool QuietOrders()
{
	return Orders == 'HBEntry' || Orders == 'HBPlant' || Orders == 'HBRetreat' || Orders == 'HBSurrendered'
		|| Orders == 'HBLed';
}

// In those moments nothing of the game's own keeps him from his orders: a hit taken where the quiet states
// don't answer for him (falling from the loading platform, a pain state: the game's ReactToInjury sends him
// to HandlingEnemy, then Attacking, and he stays there while anybody is left to fight) gives him back to them
// at once (photo test 15 Oct: the planter of container 2 never planted).
function Tick(float deltaTime)
{
	Super.Tick(deltaTime);
	if (bActivated && Health > 0 && QuietOrders() && (IsInState('Attacking') || IsInState('HandlingEnemy')
		|| IsInState('Seeking') || IsInState('Alerting') || IsInState('Fleeing') || IsInState('Wandering')))
	{
		if (pulledBack < 3)
			Log("UCHBPath:" @ Name @ "back to his orders" @ Orders @ "from" @ GetStateName());
		pulledBack++;
		SetEnemy(None, 0, True);
		FollowOrders();
	}
}

// The scene's retreat and surrender decide; the game's own fleeing would keep him in the hall.
function bool ShouldFlee()
{
	return False;
}

// A line he says in the fight (the scene's barks: first person) does not stop him.
function EnterConversationState(bool bFirstPerson, optional bool bAvoidState)
{
	if (bFirstPerson && bActivated)
		return;
	Super.EnterConversationState(bFirstPerson, bAvoidState);
}

// A bark of his still playing ends with him (it never put him in the conversation state).
function Died(pawn Killer, name damageType, vector HitLocation)
{
	local DeusExPlayer P;

	P = DeusExPlayer(GetPlayerPawn());
	if (P != None && P.conPlay != None && P.conPlay.invokeActor == Self)
		P.AbortConversation();
	Super.Died(Killer, damageType, HitLocation);
}

// Hit on the way (entry, plant, retreat): the hit plays, then he goes on with what he was doing.
function HurtOnTheWay(name damageType, EHitLocation hitPos)
{
	if (Health <= 0)
		return;
	SetNextState(GetStateName(), 'Begin');
	GotoDisabledState(damageType, hitPos);
}

// The states of the attack where he sees and hears nothing: they only move him (never entered itself).
state HBQuiet
{
	ignores SeePlayer, HearNoise;

	function bool CheckEnemyPresence(float deltaSeconds, bool bCheckPlayer, bool bCheckOther)
	{
		return False;
	}
	function bool CheckBeamPresence(float deltaSeconds)
	{
		return False;
	}
	function bool CheckCarcassPresence(float deltaSeconds)
	{
		return False;
	}
	function HandleEnemy()
	{
	}
	function HandleSighting(Pawn pawnSighted)
	{
	}
	function HandleActorSighting(Actor actorSighted)
	{
	}
	function ReactToInjury(Pawn instigatedBy, Name damageType, EHitLocation hitPos)
	{
		HurtOnTheWay(damageType, hitPos);
	}
	// a door on his way: the game opens it (OpeningDoor) and sends him back to his state's ContinueFromDoor
	// (every state of the attack has one: without it he would stand there for good)
	function HitWall(vector HitNormal, actor Wall)
	{
		if (Physics == PHYS_Falling)
			return;
		Global.HitWall(HitNormal, Wall);
		doorSteps = steps;
		CheckOpenDoor(HitNormal, Wall);
	}
	function BeginState()
	{
		StandUp();
		bInterruptState = True;
		bCanConverse = True;
		bStasis = False;
		SetEnemy(None, 0, True);
		SetDistress(False);
		steps = 0;
	}
	function EndState()
	{
		bStasis = True;
	}
}

// In through the blown doors (the gallery, then the entry point), weapon out, seeing nothing.
state HBEntry extends HBQuiet
{
	ignores SeePlayer, HearNoise;

	function BeginState()
	{
		Super.BeginState();
		SetupWeapon(True);
	}

Begin:
	Acceleration = vect(0, 0, 0);
	if (entryStage == 0)
	{
		Sleep(entryDelay);
		entryStage = 1;
	}
	if (entryStage == 1 && galleryPoint == vect(0, 0, 0))
		entryStage = 2;
	PlayRunning();
Gallery:
	if (entryStage != 1)
		Goto('Entry');
	if (Near(galleryPoint, 40) || steps > 30)
	{
		entryStage = 2;
		steps = 0;
		Goto('Entry');
	}
	steps++;
	StepLog("in (gallery)", galleryPoint);
	if (pointReachable(galleryPoint))
	{
		MoveTo(galleryPoint, MaxDesiredSpeed);
		Goto('Gallery');
	}
	MoveTarget = FindPathTo(galleryPoint);
	if (MoveTarget != None)
		MoveToward(MoveTarget, MaxDesiredSpeed);
	else
		MoveTo(galleryPoint, MaxDesiredSpeed);
	Goto('Gallery');
Entry:
	if (entryPoint == vect(0, 0, 0) || Near(entryPoint, 40) || steps > 30)
		Goto('Done');
	steps++;
	StepLog("in", entryPoint);
	if (pointReachable(entryPoint))
	{
		MoveTo(entryPoint, MaxDesiredSpeed);
		Goto('Entry');
	}
	MoveTarget = FindPathTo(entryPoint);
	if (MoveTarget != None)
		MoveToward(MoveTarget, MaxDesiredSpeed);
	else
		MoveTo(entryPoint, MaxDesiredSpeed);
	Goto('Entry');
Done:
	Acceleration = vect(0, 0, 0);
	InHall();
	Stop;
ContinueFromDoor:
	steps = doorSteps + 1;
	Goto('Begin');
}

// A planter: to his container, kneel, arm the charge. JC has to stop him: nothing else does.
state HBPlant extends HBQuiet
{
	ignores SeePlayer, HearNoise;

	function BeginState()
	{
		Super.BeginState();
		SetupWeapon(False);
	}

Begin:
	Acceleration = vect(0, 0, 0);
	if (bPlanted || plantContainer == 0)
		Goto('Over');
	if (bPlanting)
		Goto('Kneel');
	PlayRunning();
Run:
	if (Near(plantPoint, 40))
		Goto('Kneel');
	if (steps > 40)
	{
		bGaveUp = True;
		Log("UCHBPath:" @ Name @ "can't reach container" @ plantContainer);
		Goto('Over');
	}
	steps++;
	StepLog("to his container", plantPoint);
	if (pointReachable(plantPoint))
	{
		MoveTo(plantPoint, MaxDesiredSpeed);
		Goto('Run');
	}
	MoveTarget = FindPathTo(plantPoint);
	if (MoveTarget != None)
		MoveToward(MoveTarget, MaxDesiredSpeed);
	else
		MoveTo(plantPoint, MaxDesiredSpeed);
	Goto('Run');
Kneel:
	Acceleration = vect(0, 0, 0);
	if (!bPlanting)
	{
		bPlanting = True;
		plantLeft = 4.0;
		Log("UCHBPath:" @ Name @ "kneels at container" @ plantContainer);
	}
	TurnTo(ChargeSpot());
	TweenToCrouchShoot(0.3);        // crouched at the door (the cower animation of his body stands, hands on head)
	FinishAnim();
Plant:
	Sleep(0.25);
	plantLeft -= 0.25;
	if (plantLeft > 0)
		Goto('Plant');
	ArmCharge();
Over:
	Fight();
	Stop;
ContinueFromDoor:
	steps = doorSteps + 1;
	Goto('Begin');
}

// Falling back to the canal: running, seeing nothing; at the dead end he waits (the scene removes him
// once JC can't see him).
state HBRetreat extends HBQuiet
{
	ignores SeePlayer, HearNoise;

	function Tick(float deltaTime)
	{
		Global.Tick(deltaTime);
		retreatT += deltaTime;
	}
	function BeginState()
	{
		Super.BeginState();
		SetupWeapon(False);
	}

Begin:
	Acceleration = vect(0, 0, 0);
	PlayRunning();
Run:
	if (Near(exitSpot, 48) || steps > 60)
		Goto('There');
	steps++;
	StepLog("out", exitSpot);
	if (pointReachable(exitSpot))
	{
		MoveTo(exitSpot, MaxDesiredSpeed);
		Goto('Run');
	}
	MoveTarget = FindPathTo(exitSpot);
	if (MoveTarget != None)
		MoveToward(MoveTarget, MaxDesiredSpeed);
	else
		MoveTo(exitSpot, MaxDesiredSpeed);
	Goto('Run');
There:
	Acceleration = vect(0, 0, 0);
	PlayWaiting();
Wait:
	Sleep(1.0);
	Goto('Wait');
ContinueFromDoor:
	steps = doorSteps + 1;
	Goto('Begin');
}

defaultproperties
{
     entryDelay=1.000000
     Alliance=UCHBPath
     BindName="UCHBPath"
     FamiliarName="Luminous Path"
     UnfamiliarName="Luminous Path"
     InitialInventory(0)=(Inventory=Class'DeusEx.WeaponSword')
     InitialInventory(1)=(Inventory=None,Count=0)
     InitialInventory(2)=(Inventory=None,Count=0)
     bHidden=True
     bCollideActors=False
     bBlockActors=False
     bBlockPlayers=False
     bReactLoudNoise=False
     bReactShot=False
     bReactCarcass=False
     bReactAlarm=False
     bReactDistress=False
}
