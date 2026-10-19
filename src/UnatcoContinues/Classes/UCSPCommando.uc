// Service road -> loading yard -> rear storage door -> existing navigation.
// The scene observes the real crossing before enabling the assault.
class UCSPCommando extends MJ12Commando;

state UCEntry
{
    ignores SeePlayer, HearNoise;
    function BeginState()
    {
        StandUp();
        SetupWeapon(False);
        SetDistress(False);
        bStasis=False;
        SeekPawn=None;
    }
    function EndState()
    {
        bStasis=True;
    }
Begin:
    PlayWalking();
    if (Location.X>448)
    {
        MoveTo(vect(416,-1488,48),GetWalkingSpeed());
        Sleep(0.3);
        Goto('Begin');
    }
    if (Location.Y<-1320 || Abs(Location.X-128)>96)
    {
        MoveTo(vect(128,-1280,48),GetWalkingSpeed());
        Sleep(0.3);
        Goto('Begin');
    }
    if (Location.Y<-1030)
    {
        MoveTo(vect(128,-1000,48),GetWalkingSpeed());
        Sleep(0.3);
        Goto('Begin');
    }
    if (OrderTag != '') SetOrders('RunningTo', OrderTag, True);
    else SetOrders('Standing', '', True);
}

// Existing laboratory navigation reaches storage; the new stairway is walked
// explicitly because a complete PATHS rebuild would alter Revision's graph.
state UCExit
{
    ignores SeePlayer, HearNoise;
    function BeginState()
    {
        StandUp();
        SetupWeapon(False);
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
