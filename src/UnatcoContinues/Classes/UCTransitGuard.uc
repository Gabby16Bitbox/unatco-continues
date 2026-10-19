// Harbourline Tower's security (Mission 6, roof and garage): its own alliance, Harbourline (Kwan's
// too); Wan Chai civilians stay neutral. Used only in 06_HongKong_WanChai_Rooftop.
// Based on SecretService (suit and dark glasses): MJ12Troop is given random body variants by
// Revision at spawn, which put the suit skins on the jumpsuit body (stretched face on the chest).
// The skins are inherited, so they always match the mesh Revision uses for this class.
class UCTransitGuard extends SecretService;

var vector hbSpot, hbLook;  // HBWalkTo: where he goes and what he faces there
var int hbSteps;
var int hbDoorSteps;        // his steps when a door stopped him (the game's OpeningDoor comes back to ContinueFromDoor)
var int hbTries;            // times he stopped short of his place and set off again (3 at most)
var bool hbStanding;        // at his place (There/Wait): a new place sets him off again (FollowTo)

// The garage after the Luminous Path's attack (UCSceneHarbourline): one of Kwan's men walks to a place
// and stays there facing a point (he takes the squad leader to the cold room and minds its door). Orders
// HBWalkTo: saved with him; after a conversation or a load the game's FollowOrders sends him on.
function StandGuardAt(vector spot, vector look)
{
	hbSpot = spot;
	hbLook = look;
	hbTries = 0;
	SetOrders('HBWalkTo', '', True);
}

// A place that moves (16 Oct 2026, Gabby: he walks the squad leader to the cold room's door a step behind
// him): the new place without starting his orders over. On his way he takes it at his next step; standing
// at his place he sets off again.
function FollowTo(vector spot, vector look)
{
	hbLook = look;
	if (Orders != 'HBWalkTo')
	{
		StandGuardAt(spot, look);
		return;
	}
	if (VSize((spot - hbSpot) * vect(1,1,0)) < 24)
		return;
	hbSpot = spot;
	hbTries = 0;
	if (hbStanding && IsInState('HBWalkTo') && VSize((hbSpot - Location) * vect(1,1,0)) >= 48)
	{
		hbStanding = False;
		hbSteps = 0;
		GotoState('HBWalkTo', 'Walk');
	}
}

state HBWalkTo
{
	ignores HearNoise;

	function HitWall(vector HitNormal, actor Wall)
	{
		if (Physics == PHYS_Falling)
			return;
		Global.HitWall(HitNormal, Wall);
		hbDoorSteps = hbSteps;
		CheckOpenDoor(HitNormal, Wall);
	}
	function BeginState()
	{
		StandUp();
		bInterruptState = True;
		bStasis = False;
		SetupWeapon(False);
		SetDistress(False);
		hbSteps = 0;
		hbStanding = False;
	}
	function EndState()
	{
		bStasis = True;
		hbStanding = False;
	}

Begin:
	Acceleration = vect(0, 0, 0);
Walk:
	if (VSize((hbSpot - Location) * vect(1,1,0)) < 40 || hbSteps > 30)
		Goto('There');
	hbSteps++;
	PlayWalking();
	if (pointReachable(hbSpot))
	{
		MoveTo(hbSpot, GetWalkingSpeed());
		Goto('Walk');
	}
	MoveTarget = FindPathTo(hbSpot);
	if (MoveTarget != None)
		MoveToward(MoveTarget, GetWalkingSpeed());
	else
		MoveTo(hbSpot, GetWalkingSpeed());
	Goto('Walk');
There:
	Acceleration = vect(0, 0, 0);
	// stopped short of his place (his step cap: somebody or something in the way): a moment, then again
	if (VSize((hbSpot - Location) * vect(1,1,0)) >= 64 && hbTries < 3)
	{
		hbTries++;
		Log("UCTransitGuard:" @ BindName @ "stopped short of his place at" @ Location @ "steps" @ hbSteps @ "to" @ hbSpot);
		PlayWaiting();
		Sleep(3.0);
		hbSteps = 0;
		Goto('Walk');
	}
	hbStanding = True;
	TurnTo(hbLook);
	PlayWaiting();
Wait:
	Sleep(2.0);
	Goto('Wait');
// a door on his way (the game's OpeningDoor comes back here)
ContinueFromDoor:
	hbSteps = hbDoorSteps + 1;
	Goto('Walk');
}

defaultproperties
{
    Alliance=Harbourline
    FamiliarName="Harbourline Security"
    UnfamiliarName="Security Guard"
    InitialInventory(0)=(Inventory=Class'DeusEx.WeaponAssaultGun')
    InitialInventory(1)=(Inventory=Class'DeusEx.Ammo762mm',Count=12)
    InitialInventory(2)=(Inventory=Class'DeusEx.WeaponCombatKnife')
    bReactLoudNoise=False
    bReactShot=False
    bReactCarcass=False
    bReactAlarm=False
}
