// The second wave uses the same physical path as the first.
class UCSPTech extends MJ12Troop;

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
    if (OrderTag != '') SetOrders('GoingTo', OrderTag, True);
    else SetOrders('Standing', '', True);
}
