//=============================================================================
// UCSignalSend - JC manda il segnale: parte la catena vanilla (infolink di Paul,
// controllo parabole, NSFSignalSent...). Route ribelle originale.
//=============================================================================
class UCSignalSend extends Actor
	transient;

function PostBeginPlay()
{
	local Actor A;

	Super.PostBeginPlay();
	foreach AllActors(class'Actor', A, 'UCSendingSignal')
		A.Trigger(Self, GetPlayerPawn());
	Destroy();
}

defaultproperties
{
     bHidden=True
}
