//=============================================================================
// UCSceneSimonsBriefing - Hong Kong: InfoLink di Walton Simons (specifica "Dialoghi e
// varianti", blocchi I01 e I02). Parla solo Simons: ordini e basta, JC non risponde via
// radio. Parte all'eliporto appena finito il dialogo con l'ufficiale ("Mr. Simons will
// brief you on the assignment."); chi salta l'ufficiale lo riceve al mercato, dopo il
// messaggero. L'ufficiale ha gia' presentato Special Projects: Simons non spiega MJ12.
// Goal: LOCATE TRACER TONG (primario), CONTACT MAGGIE CHOW (secondario).
// Obiettivi e flag UC_HK_SimonsBriefing subito all'inizio, non alla fine dell'audio: il
// cambio di incarico non dipende dall'aver ascoltato tutto (testo nella cronologia,
// UCScene.InfoStart). Se pero' JC cambia mappa prima della fine (UC_HK_SimonsOpen senza
// UC_HK_SimonsDone), nella mappa successiva arriva una volta la versione breve I02; a
// consegna conclusa non si ripete piu' e gli obiettivi non vengono duplicati.
// Il rapporto di Gunther (GuntherReportedJCConduct) non viene citato qui: resta una nota
// per un debriefing futuro.
//=============================================================================
class UCSceneSimonsBriefing extends UCScene;

var int n;
var float d;
var bool bRecovery;   // versione breve dopo un briefing interrotto (I02)

function float SimonsLine(int i)
{
    if (bRecovery)
    {
        if (i == 0)
            return Say("WaltonSimons", "Start with the Red Arrow. Your objective remains Tracer Tong.");
        return -1;
    }
    switch (i)
    {
        case 0: return Say("WaltonSimons", "Denton. Tong's network intersects with both Triads, but most of the commercial traffic passes through Wan Chai. Special Projects has been monitoring several contacts in the district.");
        case 1: return Say("WaltonSimons", "Start with the Red Arrow. Establish who is moving material for Tong and identify a route into the Luminous Path.");
        case 2: return Say("WaltonSimons", "Your objective remains Tracer Tong.");
    }
    return -1;
}

function float InfoLine(int i)
{
	return SimonsLine(i);
}

function MaggieGoal()
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None && P.FindGoal('UCMeetMaxChen') == None)
		P.GoalAdd('UCMeetMaxChen', "Contact Max Chen at the Lucky Money. Special Projects believes the Red Arrow can identify Tong's local network.", False);
}

state Playing
{
Begin:
	// niente InfoLink sopra a una conversazione
	if (Talking())
	{
		Sleep(0.5);
		Goto('Begin');
	}
	Sleep(1.0);
	class'UCSceneHongKong'.static.TongGoal(Plr());
	// Max is an optional personal lead from the messenger after the cargo raid.
	bRecovery = GetF('UC_HK_SimonsOpen') && !GetF('UC_HK_SimonsDone');
	SetF('UC_HK_SimonsBriefing', True);
	SetF('UC_HK_SimonsOpen', True);
	InfoStart("WaltonSimons");
	Sleep(1.5);
	n = 0;
Next:
	d = SimonsLine(n);
	if (d >= 0)
	{
		Sleep(d);
		n++;
		Goto('Next');
	}
	HideInfo();
	SetF('UC_HK_SimonsDone', True);
	Destroy();
}

defaultproperties
{
}
