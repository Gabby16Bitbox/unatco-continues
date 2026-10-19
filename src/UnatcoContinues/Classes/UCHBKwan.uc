//=============================================================================
// UCHBKwan - Victor Kwan, Harbourline's head of security (Mission 6, the garage of Harbourline Tower in
// 06_HongKong_WanChai_Rooftop; plan 4.4). A soldier of the Character Creator (UCCustomSoldier: the map
// gives him his suit, his glasses, his body and his pistol) with three moments:
//  - his map orders (Standing): he waits for JC by the containers; his welcome is a conversation of the
//    scene (UC_HBKwanWelcome, UCSceneHarbourline), cut short by the Luminous Path's blast;
//  - HBCover (the attack, TakeCover): he runs to the aisle between containers 2 and 3, out of the gate's
//    line of fire, and stays down there with his pistol out. He sees and hears nothing that would make
//    him leave or fight: his men fight, he shouts the orders (the scene's barks);
//  - HBDebrief (after it, Debrief): he walks to his place by the containers and waits for JC there.
// His moment is his Orders (saved with him): after a conversation, a load, anything that interrupts him,
// the game's FollowOrders sends him back to it.
// D7 (Gabby): he can't be killed from his welcome to the end of the mission. He is only met at his
// welcome, so he is bInvincible from the start (the scene makes sure of it): nothing hurts him, not even
// the charges' blasts, he does not flinch, and he never turns on JC.
//=============================================================================
class UCHBKwan extends UCCustomSoldier;

var vector coverSpot;       // where he takes cover during the attack
var vector coverLook;       // what he faces from there
var vector afterSpot;       // where he waits for JC after the attack
var int steps;              // path steps on his way there (a cap: he never runs in circles)
var int doorSteps;          // his steps when a door stopped him (the game's OpeningDoor comes back to ContinueFromDoor)

// The attack has begun: to cover (UCSceneHarbourline.KwanTick).
function TakeCover(vector spot, vector look)
{
	coverSpot = spot;
	coverLook = look;
	SetOrders('HBCover', '', True);
}

// The attack is over: to his place for the debrief (phase 6).
function Debrief(vector spot)
{
	afterSpot = spot;
	SetOrders('HBDebrief', '', True);
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, name damageType)
{
	if (bInvincible)
		return;
	Super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
}

function bool SetEnemy(Pawn newEnemy, optional float newSeenTime, optional bool bForce)
{
	if (bInvincible && DeusExPlayer(newEnemy) != None)
		return False;
	return Super.SetEnemy(newEnemy, newSeenTime, bForce);
}

// What he shouts from cover (the scene's barks: first person) leaves him down there.
function EnterConversationState(bool bFirstPerson, optional bool bAvoidState)
{
	if (bFirstPerson && Orders == 'HBCover' && IsInState('HBCover'))
		return;
	Super.EnterConversationState(bFirstPerson, bAvoidState);
}

state HBCover
{
	ignores SeePlayer, HearNoise, Bump;

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
	}
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
		bStasis = False;
		SetEnemy(None, 0, True);
		SetDistress(False);
		BlockReactions(True);
		SetupWeapon(True);
		steps = 0;
		bDetectable = False;        // the Path's fighters don't see him: he can't be hurt (D7), no target
	}
	function EndState()
	{
		ResetReactions();
		bStasis = True;
		bDetectable = True;
	}

Begin:
	Acceleration = vect(0, 0, 0);
	if (VSize((coverSpot - Location) * vect(1,1,0)) < 48)
		Goto('Down');
	PlayRunning();
Run:
	if (VSize((coverSpot - Location) * vect(1,1,0)) < 48 || steps > 30)
		Goto('Down');
	steps++;
	if (pointReachable(coverSpot))
	{
		MoveTo(coverSpot, MaxDesiredSpeed);
		Goto('Down');
	}
	MoveTarget = FindPathTo(coverSpot);
	if (MoveTarget != None)
	{
		if (ShouldPlayWalk(MoveTarget.Location))
			PlayRunning();
		MoveToward(MoveTarget, MaxDesiredSpeed);
		Goto('Run');
	}
	MoveTo(coverSpot, MaxDesiredSpeed);
Down:
	Acceleration = vect(0, 0, 0);
	TurnTo(coverLook);
	TweenToCrouchShoot(0.35);
	FinishAnim();
Hold:
	Acceleration = vect(0, 0, 0);
	Sleep(2.0);
	Goto('Hold');
// a door on his way (the game's OpeningDoor comes back here)
ContinueFromDoor:
	steps = doorSteps + 1;
	Goto('Begin');
}

state HBDebrief
{
	ignores HearNoise;

	function bool CheckEnemyPresence(float deltaSeconds, bool bCheckPlayer, bool bCheckOther)
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
	function ReactToInjury(Pawn instigatedBy, Name damageType, EHitLocation hitPos)
	{
	}
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
		bStasis = False;
		SetEnemy(None, 0, True);
		SetDistress(False);
		BlockReactions(True);
		SetupWeapon(False);
		steps = 0;
	}
	function EndState()
	{
		ResetReactions();
		bStasis = True;
	}

Begin:
	Acceleration = vect(0, 0, 0);
	if (VSize((afterSpot - Location) * vect(1,1,0)) < 48)
		Goto('Wait');
Walk:
	if (VSize((afterSpot - Location) * vect(1,1,0)) < 48 || steps > 30)
		Goto('Wait');
	steps++;
	PlayWalking();
	if (pointReachable(afterSpot))
	{
		MoveTo(afterSpot, GetWalkingSpeed());
		Goto('Wait');
	}
	MoveTarget = FindPathTo(afterSpot);
	if (MoveTarget != None)
	{
		MoveToward(MoveTarget, GetWalkingSpeed());
		Goto('Walk');
	}
	MoveTo(afterSpot, GetWalkingSpeed());
Wait:
	Acceleration = vect(0, 0, 0);
	PlayWaiting();
Look:
	if (GetPlayerPawn() != None)
		TurnToward(GetPlayerPawn());
	Sleep(3.0);
	Goto('Look');
// a door on his way (the game's OpeningDoor comes back here)
ContinueFromDoor:
	steps = doorSteps + 1;
	Goto('Begin');
}

defaultproperties
{
     bInvincible=True
     Alliance=Harbourline
     BindName="VictorKwan"
     FamiliarName="Victor Kwan"
     UnfamiliarName="Victor Kwan"
     bReactLoudNoise=False
     bReactShot=False
     bReactCarcass=False
     bReactAlarm=False
     bReactDistress=False
     bReactProjectiles=False
     bFearProjectiles=False
}
