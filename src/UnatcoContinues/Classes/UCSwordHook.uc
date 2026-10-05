//=============================================================================
// UCSwordHook - Queen's Tower: la teca del Dragon's Tooth si apre (evento vanilla
// 'Sword_Triggers', fine della sequenza dei bracci meccanici). Nel gioco originale
// qui partiva l'InfoLink di Tong (DL_Tong_00) che imposta Have_Evidence: sulla route
// UNATCO l'InfoLink e' zittito e i flag li imposta questo attore. La chiamata a
// Simons la fa UCHKStory.
//=============================================================================
class UCSwordHook extends Actor
	transient;

function Trigger(Actor Other, Pawn EventInstigator)
{
	local DeusExPlayer P;

	P = DeusExPlayer(GetPlayerPawn());
	if (P == None || P.FlagBase == None)
		return;
	P.FlagBase.SetBool('Have_Evidence', True,, 99);
	P.FlagBase.SetBool('NoticedMJ12ChowConnection', True,, 99);
	P.FlagBase.SetBool('UC_SwordFound', True,, 99);
	Log("UnatcoContinues: teca del Dragon's Tooth aperta");
}

defaultproperties
{
     bHidden=True
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
