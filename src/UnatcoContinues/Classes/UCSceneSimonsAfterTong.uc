//=============================================================================
// UCSceneSimonsAfterTong - Hong Kong, fine della Missione 1 (HK-11).
// Dopo l'assalto al laboratorio di Tong i dati recuperati da JC vanno da soli al suo
// archivio UNATCO (TongEvidenceReportSent, nessuna battuta di JC) e Simons risponde
// con un InfoLink a senso unico: Tong scappato, il sito "sanitizzato", i file su
// VersaLife letti; JC va a VersaLife in via ufficiale. Nuovo goal REPORT TO VERSALIFE.
// Le domande di JC ("Then the records should be easy to disprove", Maggie, i dati
// cancellati) restano per il confronto di persona con Simons.
// Varianti (non nel copione): Tong morto; JC ha sparato alla squadra (solo
// l'avvertimento di Simons, senza risposta).
// La lanciano UCSceneTongLab (dopo il comandante) e UCHKStory (JC uscito durante
// l'assalto, operazione chiusa fuori scena).
// Copione: "INFOLINK FIX PASS", punto 4.
//=============================================================================
class UCSceneSimonsAfterTong extends UCScene;

var bool bTongDead;     // Tong morto prima della fuga
var bool bFired;        // JC ha sparato alla squadra (JCAttackedSpecialProjects)
var int n;
var float d;

function float CallLine(int i)
{
	switch (i)
	{
		case 0:
			if (bTongDead)
				return Say("WaltonSimons", "Denton. Tong is dead, and his facility and most of his local network have been compromised. Special Projects is sanitizing the site and preserving whatever intelligence is relevant.");
			return Say("WaltonSimons", "Denton. Tong escaped during the operation, but his facility and most of his local network have been compromised. Special Projects is sanitizing the site and preserving whatever intelligence is relevant.");
		case 1: return Say("WaltonSimons", "I've reviewed the material recovered from Tong's systems. Several files reference VersaLife, including Ambrosia shipping records and restricted research directories.") + 1.0;
		case 2: return Say("WaltonSimons", "You'll proceed to VersaLife under official authorization. Tong's people penetrated their network; determine what they accessed, recover any compromised research and verify the shipping records while you're there.");
		case 3: return Say("WaltonSimons", "If Tong manufactured the evidence, we'll know soon enough.") + 1.0;
		// JC ha sparato alla squadra: un avvertimento, niente risposta via radio
		case 4: if (!bFired) return 0; return Say("WaltonSimons", "I'm told you fired on Coalition personnel.");
		case 5: if (!bFired) return 0; return Say("WaltonSimons", "We'll discuss your judgment when you return.") + 1.0;
		case 6: return Say("WaltonSimons", "Report when you have something conclusive.");
	}
	return -1;
}

function float InfoLine(int i)
{
	return CallLine(i);
}

// I dati recuperati da JC vanno da soli al suo archivio UNATCO: Simons li ha letti.
function UploadEvidence()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	class'UCSceneTongLab'.static.AddFragment(P);
	SetF('TongEvidenceReportSent', True);
	Msg("Mission data uploaded to UNATCO.");
}

function NewAssignment()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	SetF('MJ12AssaultResolved', True);
	SetF('VersaLifeInvestigationAuthorized', True);
	SetF('SimonsVersaLifeConcern', True);
	if (P.FindGoal('UCSecureTong') != None)
		P.GoalCompleted('UCSecureTong');
	if (P.FindGoal('UCTongArchives') != None)
		P.GoalCompleted('UCTongArchives');
	if (P.FindGoal('UCReportVersaLife') == None)
		P.GoalAdd('UCReportVersaLife', "Walton Simons has authorized an official investigation into the data recovered from Tracer Tong. Report to VersaLife and determine whether its systems or personnel were compromised.", True);
	if (!GetF('UC_NoteVersaLifeCode'))
	{
		SetF('UC_NoteVersaLifeCode', True);
		P.AddNote("VersaLife (Wan Chai market, elevator north of the market): employee number 06288. Access authorized by Walton Simons.", False, True);
	}
}

state Playing
{
Begin:
	if (Talking())
	{
		Sleep(0.5);
		Goto('Begin');
	}
	Sleep(1.0);
	UploadEvidence();
	Sleep(2.0);
Wait:
	if (Talking())
	{
		Sleep(0.5);
		Goto('Wait');
	}
	// goal e flag subito: se JC cambia zona a meta' vale come ascoltato (UCScene.InfoStart)
	NewAssignment();
	SetF('UC_SimonsAfterTong', True);
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
