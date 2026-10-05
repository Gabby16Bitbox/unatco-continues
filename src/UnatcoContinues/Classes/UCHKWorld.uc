//=============================================================================
// UCHKWorld - Hong Kong sulla route UNATCO (pezzo HK-2, docs\HONGKONG_M1_PIANO.md).
// La stessa Wan Chai del gioco originale, ma JC e' un agente UNATCO in servizio:
//  - atteggiamento verso JC: Red Arrow, polizia, VersaLife/MJ12 (e Maggie) amici;
//    Luminous Path sospettosi (neutrali: cacciano JC a parole, non attaccano);
//  - spenti i trigger di trama che renderebbero ostili le guardie MJ12 di Maggie e il
//    Luminous Path; restano le zone vietate "di gioco" (piano di sopra della polizia,
//    banco del chiosco, appartamento privato nel compound...);
//  - niente incursione MJ12 al Lucky Money dopo la tregua (la prima vera azione MJ12
//    e' l'assalto al laboratorio di Tong);
//  - Alex non e' alla base di Tong (e' all'UNATCO);
//  - passaggi verso la mappa delle fogne (non esiste nel gioco) disattivati.
// La lancia UCMod nelle mappe 06 (non l'eliporto, gestito da UCMod, ne' Storage).
// Nessun puntatore a giocatore/flag tenuto fra un tick e l'altro.
//=============================================================================
class UCHKWorld extends Actor
	transient;

var string mapName;
var bool bSetup;
var bool bFirstVisit;      // prima visita di questa mappa: si applica a tutti
var name done[160];        // PNG gia' sistemati in questa visita
var int numDone;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(1.0, True);
}

function Timer()
{
	local DeusExLevelInfo info;
	local DeusExPlayer P;
	local FlagBase f;
	local name visited;

	P = DeusExPlayer(GetPlayerPawn());
	if (P == None || P.FlagBase == None || P.rootWindow == None)
		return;
	f = P.FlagBase;
	if (mapName == "")
		foreach AllActors(class'DeusExLevelInfo', info)
			mapName = Caps(info.mapName);
	if (!bSetup)
	{
		bSetup = True;
		visited = P.rootWindow.StringToName("UC_HKWorld_" $ mapName);
		bFirstVisit = !f.GetBool(visited);
		f.SetBool(visited, True,, 99);
		f.SetBool('MS_CommandosUnhidden', True,, 99);   // il gioco non manda i commando al Lucky Money
		Setup();
	}
	Attitudes();
}

// Atteggiamento voluto verso JC per l'alleanza del PNG (i nomi cambiano da mappa a mappa).
// 2 = non toccare.
function float Wanted(ScriptedPawn sp)
{
	local name a;

	a = sp.Alliance;
	if (a == 'RedArrow' || a == 'triad_red' || a == 'KillMJ12')
		return 1.0;
	if (a == 'Cops' || a == 'Cop')
		return 1.0;
	if (a == 'mj12' || a == 'MJ12bot' || a == 'Security' || a == 'Researcher' || a == 'Worker' || a == 'Maggie')
		return 1.0;
	if (a == 'LumPath' || a == 'triad_lum')
		return 0.0;
	return 2.0;
}

// JC lo ha fatto arrabbiare (o una zona vietata lo ha reso ostile)?
function bool HostileToPlayer(ScriptedPawn sp)
{
	return sp.GetAllianceType('Player') == ALLIANCE_Hostile;
}

function bool IsDone(name n)
{
	local int i;

	for (i = 0; i < numDone; i++)
		if (done[i] == n)
			return True;
	return False;
}

// Una volta per PNG e per visita. Alla prima visita della mappa vale per tutti; nelle
// visite dopo non si "perdona" chi JC ha fatto arrabbiare (atteggiamento negativo).
function Attitudes()
{
	local ScriptedPawn sp;
	local float want;

	foreach AllActors(class'ScriptedPawn', sp)
	{
		if (!sp.bInWorld || sp.Health <= 0 || numDone >= 160 || IsDone(sp.Name))
			continue;
		done[numDone] = sp.Name;
		numDone++;
		want = Wanted(sp);
		if (want > 1.5)
			continue;
		if (bFirstVisit || !HostileToPlayer(sp) || sp.Tag == 'MaggieTroop')
			sp.ChangeAlly('Player', want, False);
	}
}

// Un AllianceTrigger / OrdersTrigger senza Event non tocca piu' nessuno.
function int Disarm(name triggerTag, optional name onlyEvent)
{
	local Actor A;
	local int n;

	foreach AllActors(class'Actor', A, triggerTag)
		if ((A.IsA('AllianceTrigger') || A.IsA('OrdersTrigger')) && (onlyEvent == '' || A.Event == onlyEvent))
		{
			A.Event = '';
			n++;
		}
	return n;
}

function Setup()
{
	local Teleporter tp;
	local ScriptedPawn sp;
	local Actor A;
	local int n;

	// passaggi verso 06_HongKong_WanChai_Sewers (mappa inesistente)
	foreach AllActors(class'Teleporter', tp)
		if (InStr(Caps(tp.URL), "SEWERS") != -1)
			tp.bEnabled = False;

	if (mapName == "06_HONGKONG_WANCHAI_STREET")
	{
		// le guardie MJ12 di Maggie non diventano ostili (allarmi, laser, console, May Sung):
		// Maggie e May Sung reagiscono ancora come nel gioco originale
		foreach AllActors(class'Actor', A)
			if ((A.IsA('AllianceTrigger') || A.IsA('OrdersTrigger')) && A.Event == 'MaggieTroop')
			{
				A.Event = '';
				n++;
			}
	}
	else if (mapName == "06_HONGKONG_WANCHAI_COMPOUND")
	{
		// il Luminous Path caccia JC a parole ("Leave the compound now!") ma non lo attacca
		n = Disarm('LumpathPissed');
	}
	else if (mapName == "06_HONGKONG_WANCHAI_UNDERWORLD")
	{
		// niente incursione MJ12 dopo la tregua: via i commando e la fuga dei clienti
		foreach AllActors(class'ScriptedPawn', sp, 'RaidingCommando')
		{
			sp.Destroy();
			n++;
		}
		n += Disarm('RaidUnderway');
	}
	else if (mapName == "06_HONGKONG_TONGBASE")
	{
		// Alex Jacobson e' all'UNATCO, non con Tong
		foreach AllActors(class'ScriptedPawn', sp)
			if (sp.IsA('AlexJacobson') && sp.bInWorld)
			{
				sp.LeaveWorld();
				n++;
			}
	}
	Log("UnatcoContinues: Hong Kong" @ mapName @ "pronta per la route UNATCO (" $ n $ " modifiche, prima visita:" @ bFirstVisit $ ")");
}

defaultproperties
{
     bHidden=True
}
