//=============================================================================
// UCSignalHook - si mette al posto degli attori vanilla con Tag 'SendingSignal'
// (quelli che il computer del trasmettitore NSF fa scattare con "Broadcast
// Message"): invece di mandare subito il segnale apre la scelta UCSignalMenu.
// Gli attori vanilla vengono rinominati 'UCSendingSignal' (vedi UCSignalSend).
//=============================================================================
class UCSignalHook extends Actor
	transient;

function Trigger(Actor Other, Pawn EventInstigator)
{
	local DeusExPlayer P;
	local DeusExRootWindow root;

	P = DeusExPlayer(GetPlayerPawn());
	if (P == None)
		return;
	root = DeusExRootWindow(P.rootWindow);
	if (root != None)
		root.InvokeMenu(class'UCSignalMenu');
}

defaultproperties
{
     bHidden=True
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
