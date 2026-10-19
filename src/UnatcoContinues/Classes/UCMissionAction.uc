// Native computer special-options and conversation triggers share these actions.
// Transient handlers are rebuilt on load; only the player's flags persist.
class UCMissionAction extends Actor transient;

var name operation;

function Trigger(Actor Other, Pawn EventInstigator)
{
    local UCInvestigation manager;
    local DeusExPlayer P;
    P = DeusExPlayer(EventInstigator);
    if (P == None)
        P = DeusExPlayer(GetPlayerPawn());
    if (P == None || P.FlagBase == None || !P.FlagBase.GetBool('UNATCORouteCommitted'))
        return;
    foreach AllActors(class'UCInvestigation', manager)
    {
        manager.Action(operation);
        return;
    }
}

defaultproperties
{
    bHidden=True
    bCollideActors=False
    bCollideWorld=False
}
