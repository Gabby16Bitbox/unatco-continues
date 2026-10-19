// Freight-lift control. Only a passenger inside the cabin can depart.
class UCTransitButton extends Button1;
var() bool bToRoof;
function Frob(Actor Frobber, Inventory frobWith)
{
    local UCSceneHKArrival flow;
    Super.Frob(Frobber, frobWith);
    foreach AllActors(class'UCSceneHKArrival', flow)
        flow.UseLift(DeusExPlayer(Frobber), bToRoof);
}
defaultproperties
{
    ItemName="Freight lift control"
    bInvincible=True
    bPushable=False
}
