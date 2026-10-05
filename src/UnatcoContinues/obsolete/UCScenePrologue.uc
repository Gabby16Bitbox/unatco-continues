//=============================================================================
// UCScenePrologue - MISSION 1 "SEPARATE WAYS" - PROLOGO ('Ton Hotel)
//
// Parte quando finisce la conversazione originale M04PlayerLikesUNATCO.
//  1. Paul scappa di corsa nel corridoio (verso l'uscita vanilla PaulExit).
//  2. JC resta fermo. Silenzio.
//  3. InfoLink di Alex.
//  4. Title card: DEUS EX / SEPARATE WAYS.  Nuovo obiettivo: tornare all'UNATCO.
//  5. Poi UNATCO e Men in Black entrano dal portone (UCSceneHotelRaid).
//
// NB: gli eventi vanilla SetPaulGoing / PaulLeaves NON si usano: appartengono
// al raid (PaulLeaves imposta M04RaidDone e da' 100 punti abilita').
//=============================================================================
class UCScenePrologue extends UCScene;

state Playing
{
Begin:
	// aspetta la fine della conversazione originale
	if (Talking())
	{
		Sleep(0.25);
		Goto('Begin');
	}
	Sleep(0.5);

	// 1. Paul scappa (UCPaulEscape: corre al portone e svanisce, o sparisce se lo perdi di vista)
	Spawn(class'UCPaulEscape');

	// 2. JC resta fermo. Silenzio.
	Sleep(6.0);

	// 3. Il communicator si accende
	InfoSound();
	Sleep(1.0);
	Sleep(Say("AlexJacobson", "JC. Manderley wants you back at headquarters."));
	Sleep(Say("JCDenton", "What's happened?"));
	Sleep(Say("AlexJacobson", "Your brother happened."));
	Sleep(1.5);
	Sleep(Say("AlexJacobson", "They've revoked his clearance. Every UNATCO unit in Manhattan has his picture."));
	Sleep(Say("JCDenton", "I'm on my way."));
	Sleep(Say("AlexJacobson", "JC..."));
	Sleep(Say("JCDenton", "What?"));
	Sleep(Say("AlexJacobson", "Just get back here before somebody decides you need a new picture too."));
	Sleep(Say("AlexJacobson", "Hermann and Navarre are at Battery Park. Take the subway; the troops on the street will let you through."));
	HideInfo();

	// 4. Title card + obiettivo
	Sleep(1.5);
	TitleCard("DEUS EX", "SEPARATE WAYS");
	GoalDone('SendSignal');
	GoalNew('ReturnToUNATCO', "Take the Hell's Kitchen subway to Battery Park. Agent Hermann will escort you back to UNATCO Headquarters.");
	SetF('UC_Prologue_Done', True);

	Destroy();
}

defaultproperties
{
}
