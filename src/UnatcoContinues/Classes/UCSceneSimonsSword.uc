//=============================================================================
// UCSceneSimonsSword - Hong Kong: JC ha trovato il Dragon's Tooth da Maggie Chow.
// Uscito dalla stanza segreta il suo rapporto parte da solo (ChowEvidenceReportSent,
// nessuna battuta di JC: la lancia UCHKStory.SimonsCall) e Simons risponde con un
// InfoLink a senso unico. Due versioni:
//  - ha visto la registrazione Simons/Maggie (SimonsMaggieRecordingSeen): Maggie e'
//    un asset della Coalizione, la relazione e' in parte classificata; Simons non
//    conferma ne' smentisce la registrazione;
//  - non l'ha vista: gli asset a volte nascondono le cose.
// Le domande di JC (Yuen Kong, la registrazione) restano per il confronto di persona.
// Copione: "INFOLINK FIX PASS", punto 2.
//=============================================================================
class UCSceneSimonsSword extends UCScene;

var bool bRecording;   // JC ha visto la registrazione nella stanza della spada
var int n;
var float d;

function float RecordingLine(int i)
{
	switch (i)
	{
		case 0: return Say("WaltonSimons", "Denton. I received your report from Queen's Tower. Secure the Dragon's Tooth.");
		case 1: return Say("WaltonSimons", "Maggie Chow is a Coalition intelligence asset. Her relationship with Special Projects predates your assignment, and portions of that relationship are classified. Intelligence assets are not required to tell you everything they know.") + 1.0;
		case 2: return Say("WaltonSimons", "Whatever else you found, don't let it distract you from the objective. Chow's activities can be reviewed after Tong is in custody.");
		case 3: return Say("WaltonSimons", "Locate Tracer Tong.");
	}
	return -1;
}

function float NoRecordingLine(int i)
{
	switch (i)
	{
		case 0: return Say("WaltonSimons", "Denton. I received your report on the Dragon's Tooth. Secure the weapon and continue your investigation.");
		case 1: return Say("WaltonSimons", "Maggie Chow is a Coalition intelligence asset. Assets sometimes withhold information when they believe it protects their position. That doesn't make everything they've provided useless.");
		case 2: return Say("WaltonSimons", "Don't lose sight of the assignment. Resolve the Triad situation and locate Tracer Tong. We'll review Chow afterward.");
	}
	return -1;
}

function float CallLine(int i)
{
	if (bRecording)
		return RecordingLine(i);
	return NoRecordingLine(i);
}

function float InfoLine(int i)
{
	return CallLine(i);
}

state Playing
{
Begin:
	if (Talking())
	{
		Sleep(0.5);
		Goto('Begin');
	}
	// il rapporto di JC parte da solo (niente voce)
	SetF('DragonToothEvidenceFound', True);
	SetF('SimonsMaggieRecordingSeen', bRecording);
	SetF('ChowEvidenceReportSent', True);
	Msg("Mission report transmitted: Queen's Tower.");
	Sleep(3.0);
Wait:
	if (Talking())
	{
		Sleep(0.5);
		Goto('Wait');
	}
	// fatto subito: se JC cambia zona a meta' non si ripete (UCScene.InfoStart)
	SetF('UC_SimonsSwordCall', True);
	InfoStart("WaltonSimons");
	Sleep(1.0);
	n = 0;
Next:
	d = CallLine(n);
	if (d >= 0)
	{
		if (d > 0)
			Sleep(d);
		n++;
		Goto('Next');
	}
	HideInfo();
	Destroy();
}

defaultproperties
{
}
