// Actors are already waiting behind the service entrance; no visible spawning.
class UCYardRaider extends TriadLumPath;
var() vector entryPoint;
var() vector cargoPoint;
var() vector galleryPoint;
var vector retreatPoint;
var bool bActivated;

function TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, name damageType)
{
    local DeusExPlayer P;
    P=DeusExPlayer(EventInstigator);
    if (bActivated && P!=None && P.FlagBase!=None)
        P.FlagBase.SetBool('UCHongKongShipmentDefended',True,,99);
    Super.TakeDamage(Damage,EventInstigator,HitLocation,Momentum,damageType);
}

function ActivateRaid()
{
    if (bActivated || Health<=0) return;
    bActivated=True;
    retreatPoint=Location;
    bHidden=False;
    SetCollision(True,True,True);
    // enemies of JC (Gabby, 13 Oct: they looked like allies): they go for the case and shoot him too
    ChangeAlly('Player',-1.0,True);
    ChangeAlly('UCTransport',-1.0,True);
    GotoState('CargoEntry');
}
state CargoEntry
{
    ignores SeePlayer, HearNoise;
    function BeginState()
    {
        StandUp(); SetupWeapon(False); bStasis=False; SetDistress(False);
    }
Begin:
    PlayRunning();
    if (galleryPoint!=vect(0,0,0)) MoveTo(galleryPoint,GroundSpeed);
    MoveTo(entryPoint,GroundSpeed);
    MoveTo(cargoPoint,GroundSpeed);
    SetOrders('Standing','',True);
}
function RetreatFromCargo()
{
    if (Health<=0 || Enemy==DeusExPlayer(GetPlayerPawn())) return;
    SetEnemy(None,0,True);
    ChangeAlly('UCTransport',0.0,True);
    GotoState('CargoRetreat');
}
state CargoRetreat
{
    ignores SeePlayer, HearNoise;
Begin:
    PlayRunning();
    MoveTo(entryPoint,GroundSpeed);
    if (galleryPoint!=vect(0,0,0)) MoveTo(galleryPoint,GroundSpeed);
    MoveTo(retreatPoint,GroundSpeed);
    SetOrders('Standing','',True);
}
defaultproperties
{
    Alliance=UCCargoRaid
    FamiliarName="Luminous Path Raider"
    UnfamiliarName="Armed Raider"
    bHidden=True
    bCollideActors=False
    bBlockActors=False
    bBlockPlayers=False
    bReactLoudNoise=False
    bReactShot=False
    bReactCarcass=False
    bReactAlarm=False
}
