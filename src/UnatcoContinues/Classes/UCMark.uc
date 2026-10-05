//=============================================================================
// UCMark - segnaposto invisibile con un Tag, usato come destinazione per gli
// ordini dei PNG (es. SetOrders('RunningTo', 'UCJCMark')).
//=============================================================================
class UCMark extends Actor
	transient;

defaultproperties
{
     bHidden=True
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
