// InfoLink a senso unico in risposta al rapporto manuale dal terminale di Queen's Tower.
class UCSceneSimonsSword extends UCScene;

var bool bRecording;   // JC ha visto la registrazione nella stanza della spada
var int n;
var float d;

function float CallLine(int i)
{
    switch (i)
    {
        case 0: return Say("WaltonSimons", "Your report from Queen's Tower has been received. Chow's account will be reviewed.");
        case 1: return Say("WaltonSimons", "Secure the weapon if you can. Do not let either Triad decide how you conduct the investigation. Your objective remains Tong.");
    }
    return -1;
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
	SetF('DragonToothEvidenceFound', GetF('UC_ChowSwordVerified'));
	SetF('SimonsMaggieRecordingSeen', bRecording);
	// The player already submitted this report at the terminal.
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
	Sleep(1.5);
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
