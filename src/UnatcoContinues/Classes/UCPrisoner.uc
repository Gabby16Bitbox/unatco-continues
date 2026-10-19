// Held in custody until the player's objection or the commander's execution.
class UCPrisoner extends ScientistMale;

state UCExit
{
    ignores SeePlayer, HearNoise;
    function BeginState()
    {
        StandUp();
        SetDistress(False);
        bStasis=False;
        SeekPawn=None;
    }
Begin:
    PlayWalking();
    MoveTo(vect(128,-1280,48),GetWalkingSpeed());
    MoveTo(vect(128,-1488,48),GetWalkingSpeed());
    MoveTo(vect(416,-1488,48),GetWalkingSpeed());
    MoveTo(class'UCServiceAccess'.static.Stage(0),GetWalkingSpeed());
Hold:
    Sleep(1);
    Goto('Hold');
}

defaultproperties
{
    bFearShot=False
    bFearIndirectInjury=False
    bFearCarcass=False
    bFearDistress=False
    bFearAlarm=False
    bFearWeapon=False
    bReactPresence=False
    bReactAlarm=False
    bReactShot=False
    bReactDistress=False
}
