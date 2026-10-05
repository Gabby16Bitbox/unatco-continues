//=============================================================================
// UCSceneRefuse - JC sceglie di NON mandare il segnale al trasmettitore NSF.
// Paul lo chiama via InfoLink; JC torna al 'Ton a dirglielo in faccia
// (li' parte la conversazione originale M04PlayerLikesUNATCO).
//=============================================================================
class UCSceneRefuse extends UCScene;

state Playing
{
Begin:
	SetF('UC_RefusedSignal', True);
	SetF('UNATCORoute_EvidenceFound', True);
	Sleep(2.0);
	InfoSound();
	Sleep(1.0);
	Sleep(Say("PaulDenton", "JC? The transmitter's live, but nothing's going out. What's wrong?"));
	Sleep(Say("JCDenton", "Nothing's wrong. I'm not sending it."));
	Sleep(Say("PaulDenton", "JC... you've seen what's down there."));
	Sleep(Say("JCDenton", "I've seen enough to know I'm not deciding this over a radio. I'm coming back. We'll talk face to face."));
	Sleep(1.0);
	Sleep(Say("PaulDenton", "...All right. I'll be here."));
	HideInfo();
	GoalDone('SendSignal');
	GoalNew('UCReturnToPaul', "Return to Paul at the 'Ton Hotel and tell him your decision.");
	Destroy();
}

defaultproperties
{
}
