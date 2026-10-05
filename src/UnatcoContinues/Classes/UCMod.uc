//=============================================================================
// UCMod - gestore della route UNATCO (vedi docs\ROUTE_DESIGN.md).
// Osserva i flag vanilla di Mission 04 e imposta i nostri flag UNATCORoute_*.
//
// Dopo M04PlayerLikesUNATCO (JC sceglie l'UNATCO):
//   'Ton        Paul resta seduto nell'appartamento; JC esce normalmente
//               (niente raid, niente MIB). Nuovo goal: Jock a Battery Park.
//   Hell's Kitchen  qualche pattuglia UNATCO amica, porte INF, metro aperta.
//   Metro di Hell's Kitchen  Anna Navarre sorveglia l'uscita (se e' morta: un soldato);
//               il cancello e' aperto per il personale UNATCO.
//   Battery Park    Jock aspetta con l'elicottero; "pronto" -> decollo -> Hong Kong.
//=============================================================================
class UCMod extends Actor
	transient;   // come MissionScript: i puntatori a Player/flags non vanno salvati ne' ripuliti al cambio mappa

var DeusExPlayer Player;
var FlagBase flags;
var string localURL;
var bool bEvidenceSeen;
var bool bCommitted;
var bool bInit;
var int pendingArrival;   // 1 = portami vicino a Paul (salto di debug)
var int arrivalTicks;
var int tickCount;
var bool bHeliChecked;
var bool bTransmitterLocked;
var bool bSubGateChecked;
var bool bStreetSetup;
var bool bBPSetup;
var bool bSignalHooked;
var bool bHotelSetup;
var bool bJockConv;
var bool bHKSetup;
var bool bHello;          // messaggio "mod caricata" gia' dato in questa mappa
var bool bLiftGuardGone;  // la guardia dell'ascensore delle versioni precedenti e' stata tolta
var bool bSimonsScene;
var bool bHKWorld;
var bool bGuntherScene;
var bool bHotelQuestCons;   // conversazioni della faccenda di JoJo gia' tolte in questa mappa
var bool bTraveler;       // UCTraveler gia' controllato in questa mappa
var bool bRouteWalls;     // muri 'UCWall*' della route gia' alzati in questa mappa
var bool bSignChecked;    // scritta dell'eliporto gia' controllata in questa mappa
var bool bVanillaShown;   // oggetti "UCVanilla*" gia' mostrati (gioco normale) in questa mappa
var float lastBarkTime;
var float lastBlockMsgTime;
var name barked[96];      // PNG che hanno gia' detto la loro battuta (nomi, non puntatori)
var int numBarked;
var int barkIndex;

// Rilascia i puntatori prima della pulizia del livello (evita il crash al cambio mappa).
event Destroyed()
{
	Player = None;
	flags = None;
	Super.Destroyed();
}

// Il motore lo chiama prima di cambiare mappa (come per MissionScript).
function PreTravel()
{
	SetTimer(0, False);
	Release();
}

function PostBeginPlay()
{
	local UCMod other;

	Super.PostBeginPlay();

	// un solo gestore per mappa (il mutator e "summon" possono crearne piu' di uno)
	foreach AllActors(class'UCMod', other)
		if (other != Self && !other.bDeleteMe)
		{
			Destroy();
			return;
		}

	// UCMutator viene salvato dentro la mappa e ricrea UCMod quando la mappa viene
	// ricaricata dal salvataggio (tornandoci): se manca (partita senza il mutator
	// nell'URL) lo mettiamo noi.
	if (!HasMutatorAnchor())
		Spawn(class'UCMutator');

	SetTimer(0.5, True);
	Spawn(class'UCDialogueDirector'); // camere e musica nelle conversazioni della mod
	Spawn(class'UCVoiceDriver');   // voci registrate nelle conversazioni della mod
	Log("UnatcoContinues: gestore route avviato.");
}

// Messaggi di servizio a schermo: non durante la presentazione per il video (UCTour).
function Dbg(string s)
{
	if (!flags.GetBool('UC_Tour'))
		Player.ClientMessage(s);
}

// Presentazione per il video: finche' il flag UC_Tour e' acceso c'e' un UCTour per mappa.
function EnsureTour()
{
	local UCTour tour;

	foreach AllActors(class'UCTour', tour)
		return;
	Spawn(class'UCTour');
}

// JC porta con se' UCTraveler: fa ripartire la mod nelle mappe raggiunte con le
// uscite normali (che perdono il mutator dell'URL).
function EnsureTraveler()
{
	local UCTraveler t;

	bTraveler = True;
	if (Player.FindInventoryType(class'UCTraveler') != None)
		return;
	t = Spawn(class'UCTraveler', Player);
	if (t == None)
	{
		bTraveler = False;   // riprova al prossimo giro
		return;
	}
	t.GiveTo(Player);
	t.SetBase(Player);
	Log("UnatcoContinues: UCTraveler dato a JC");
}

function bool HasMutatorAnchor()
{
	local UCMutator m;

	foreach AllActors(class'UCMutator', m)
		return True;
	return False;
}

// Prende il giocatore e la flagbase SOLO per la durata di un tick: i puntatori
// vengono azzerati a fine Timer(), cosi' non esistono mai durante il cambio mappa
// (altrimenti il motore va in crash in CleanupDestroyed).
function bool Acquire()
{
	Player = DeusExPlayer(GetPlayerPawn());
	if (Player == None)
		return False;

	flags = Player.FlagBase;
	if (flags == None)
	{
		Player = None;
		return False;
	}
	return True;
}

function Release()
{
	Player = None;
	flags = None;
}

// Inizializzazione per mappa (una volta sola, con Player/flags acquisiti).
function InitRoute()
{
	local DeusExLevelInfo info;

	bInit = True;

	foreach AllActors(class'DeusExLevelInfo', info)
		localURL = Caps(info.mapName);

	// la route gia' scelta in un salvataggio resta attiva
	bCommitted = flags.GetBool('UNATCORouteCommitted');
	bEvidenceSeen = flags.GetBool('UNATCORoute_EvidenceFound');

	// JC ha lasciato il 'Ton: anche Paul se ne va (lo si scoprira' piu' avanti nella storia)
	// (irreversibile: non viene mai azzerato; PaulDenton_Dead resta falso)
	if (bCommitted && localURL != "04_NYC_HOTEL" && !flags.GetBool('PaulLeftTonHotel'))
	{
		flags.SetBool('PaulLeftTonHotel', True,, 99);
		flags.SetBool('PaulEscapedTon', True,, 99);
		flags.SetBool('PaulLocationUnknown', True,, 99);
	}

	// salto di debug: UCDebug.Jump lascia qui il punto di arrivo desiderato
	pendingArrival = flags.GetInt('UC_DbgArrival');
	if (pendingArrival > 0)
	{
		flags.SetInt('UC_DbgArrival', 0,, 99);
		arrivalTicks = 6;   // aspetta ~3 s che la mappa sia pronta
		// presentazione per il video, punti fissi: subito, o si vedrebbe JC spostarsi di colpo
		if (flags.GetBool('UC_Tour') && pendingArrival >= 6)
			arrivalTicks = 0;
	}

	Log("UnatcoContinues: mappa" @ localURL @ "- route attiva:" @ bCommitted);
}

function Timer()
{
	if (!Acquire())
		return;
	if (Player.conPlay == None)
		RestoreBarkBindings();

	if (!bInit)
		InitRoute();
	if (!bHello)
	{
		bHello = True;
		Dbg("UNATCO Continues: mod caricata.");
	}
	if (flags.GetBool('UC_Tour'))
		EnsureTour();
	if (!bTraveler)
		EnsureTraveler();
	if (!bSignChecked && bInit && localURL == "06_HONGKONG_HELIBASE")
	{
		bSignChecked = True;
		if (!bCommitted)
			SwapHelibaseSign(False);
	}
	if (!bVanillaShown && bInit)
	{
		bVanillaShown = True;
		if (!bCommitted)
			ShowVanillaOnly();
	}

	// ogni ~4 s: ricorda finestra / schermo intero per il prossimo avvio
	tickCount++;
	if (tickCount % 8 == 2)
		RememberWindowMode();

	// Battery Park: Jock deve esserci (in Revision l'elicottero di inizio missione riparte)
	if (bCommitted && !bHeliChecked && localURL == "04_NYC_BATTERYPARK" && !flags.GetBool('UNATCORoute_DepartedNYC'))
	{
		bHeliChecked = True;
		EnsureHeli();
	}

	if (pendingArrival > 0)
	{
		arrivalTicks--;
		if (arrivalTicks <= 0)
		{
			DoArrival(pendingArrival);
			pendingArrival = 0;
		}
	}

	if (Left(localURL, 3) == "03_" || Left(localURL, 3) == "04_")
		KnowledgeTick();

	// Prova trovata a NSF HQ: l'infolink DL_GotUplinkCode e' gia' partito.
	// (Se la partita non e' sulla route vanilla di Paul i flag restano falsi.)
	if (!bEvidenceSeen && flags.GetBool('DL_GotUplinkCode_Played'))
	{
		bEvidenceSeen = True;
		flags.SetBool('UNATCORoute_EvidenceFound', True,, 99);
		Dbg("[UC] Prova NSF trovata.");
	}

	// Il goal vanilla SendSignal deve poter essere chiuso da entrambe le scelte.
	if (!flags.GetBool('UC_SendSignalText') && Player.FindGoal('SendSignal') != None)
	{
		Player.GoalAdd('SendSignal', "Investigate the NSF transmitter and decide whether to send Paul's distress signal.", True);
		flags.SetBool('UC_SendSignalText', True,, 99);
	}

	// NSF HQ: al trasmettitore JC sceglie se mandare il segnale (scelta tagliata nel gioco
	// originale). Per dire di no JC torna da Paul e glielo dice di persona (niente rifiuto
	// via radio): da li' la route e' scelta e il trasmettitore e' spento.
	if (localURL == "04_NYC_NSFHQ" && !flags.GetBool('NSFSignalSent'))
	{
		if (bCommitted)
		{
			if (!bTransmitterLocked)
				LockTransmitter();
		}
		else if (!bSignalHooked)
			RestoreSignalChain();
	}

	// La conversazione originale M04PlayerLikesUNATCO richiede M04MeetGateGuard_Played.
	// La leghiamo invece alla NOSTRA condizione (prova trovata, segnale non inviato).
	if (!bCommitted)
		GateGuardGate();

	// Biforcazione: Paul rifiutato (conversazione originale M04PlayerLikesUNATCO),
	// segnale NSF NON inviato, Paul vivo, prova trovata.
	if (!bCommitted
		&& flags.GetBool('M04PlayerLikesUNATCO_Played')
		&& flags.GetBool('UNATCORoute_EvidenceFound')
		&& !flags.GetBool('NSFSignalSent')
		&& !flags.GetBool('PaulDenton_Dead'))
	{
		CommitRoute();
	}

	// Blocca la catena vanilla del raid finche' la route UNATCO e' attiva.
	if (bCommitted)
	{
		BlockVanillaRaid();
		RouteTick();
	}

	Release();
}

// Al 'Ton: M04MeetGateGuard_Played = (prova trovata E segnale non inviato).
// Nelle altre mappe rimette il valore vero (la guardia al cancello resta vanilla).
function GateGuardGate()
{
	local bool want, have;

	have = flags.GetBool('M04MeetGateGuard_Played');

	if (localURL == "04_NYC_HOTEL")
	{
		want = flags.GetBool('UNATCORoute_EvidenceFound') && !flags.GetBool('NSFSignalSent');
		if (want == have)
			return;
		if (!flags.GetBool('UC_GG_Saved'))
		{
			flags.SetBool('UC_GG_Saved', True,, 99);
			flags.SetBool('UC_GG_Real', have,, 99);
		}
		flags.SetBool('M04MeetGateGuard_Played', want,, 6);
		Log("UnatcoContinues: M04MeetGateGuard_Played ->" @ want);
	}
	else if (flags.GetBool('UC_GG_Saved'))
	{
		flags.SetBool('M04MeetGateGuard_Played', flags.GetBool('UC_GG_Real'),, 6);
		flags.SetBool('UC_GG_Saved', False,, 99);
	}
}

// Battery Park: rimette al suo posto l'elicottero di Jock (la sua posizione vanilla).
function EnsureHeli()
{
	local BlackHelicopter heli;
	local vector spot;

	spot = vect(-1632.6, 516.7, 424.1);   // posizione originale nella mappa

	foreach AllActors(class'BlackHelicopter', heli)
		break;

	if (heli != None)
		Log("UnatcoContinues: elicottero trovato, stato" @ heli.GetStateName() @ "hidden" @ heli.bHidden @ "pos" @ int(heli.Location.X) $ "," $ int(heli.Location.Y) $ "," $ int(heli.Location.Z));
	else
	{
		heli = Spawn(class'BlackHelicopter',,, spot);
		if (heli != None)
		{
			heli.BindName = "Jock";
			heli.Event = 'HelicopterFlysOff';   // percorso vanilla del decollo
		}
		Log("UnatcoContinues: elicottero creato:" @ (heli != None));
	}

	if (heli == None)
		return;

	heli.EnterWorld();   // nelle mappe gli elicotteri partono "fuori dal mondo" (+20000 Z, nascosti)
	if (!heli.IsInState('Flying'))
		heli.GotoState('Flying');
	heli.bHidden = False;
	heli.SetLocation(spot);
	heli.Tag = 'UCTransport';   // il trigger vanilla MadeItToBP (JockTakesOff) non lo fa ripartire da solo
}

// Porta il giocatore vicino a Paul (prova varie posizioni libere).
function DoArrival(int where)
{
	local PaulDenton paul;
	local int i;
	local vector offs[6];

	if (where == 2)
	{
		ArriveNearHeli();
		return;
	}
	if (where == 4)
	{
		ArriveTransmitter();
		return;
	}
	// Hell's Kitchen: in cima alle scale della metro, verso la grata
	if (where == 6)
	{
		if (Player.SetLocation(vect(2292, -1138, -470)))
			Player.ClientSetRotation(rot(0, 0, 0));
		Dbg("[UC] In cima alle scale della metro.");
		return;
	}
	// 'Ton, appartamento di Paul: vicino all'ingresso, a qualche passo da lui (seduto in
	// fondo alla stanza), girato verso di lui
	if (where == 8)
	{
		if (Player.SetLocation(vect(290, -3290, 112)))
			Player.ClientSetRotation(rot(0, 46183, 0));
		Dbg("[UC] Nell'appartamento di Paul.");
		return;
	}
	// Lucky Money: nel centro commerciale, davanti all'ingresso del club, verso ovest
	if (where == 7)
	{
		if (Player.SetLocation(vect(-560, 0, -275)))
			Player.ClientSetRotation(rot(0, 32768, 0));
		Dbg("[UC] Davanti al Lucky Money.");
		return;
	}
	// eliporto di Hong Kong: davanti al passaggio verso gli ascensori, verso ovest
	if (where == 5)
	{
		if (Player.SetLocation(vect(-960, -128, 440)))
			Player.ClientSetRotation(rot(0, 32768, 0));
		Dbg("[UC] Davanti al passaggio degli ascensori.");
		Spawn(class'UCDbgMovers');   // stato dei mover del passaggio nel log
		return;
	}
	if (where != 1)
		return;

	foreach AllActors(class'PaulDenton', paul)
		break;

	if (paul == None)
	{
		Dbg("[UC] Paul non trovato in questa mappa.");
		return;
	}

	offs[0] = vect(-70, 0, 10);
	offs[1] = vect(70, 0, 10);
	offs[2] = vect(0, -70, 10);
	offs[3] = vect(0, 70, 10);
	offs[4] = vect(-120, 0, 10);
	offs[5] = vect(120, 0, 10);

	for (i = 0; i < 6; i++)
	{
		if (Player.SetLocation(paul.Location + offs[i]))
		{
			Dbg("[UC] Sei vicino a Paul.");
			if (flags.GetBool('UC_DbgAutoConv'))
			{
				flags.SetBool('UC_DbgAutoConv', False,, 99);
				Player.StartConversationByName('M04PlayerLikesUNATCO', paul, False, False);
			}
			return;
		}
	}
	Dbg("[UC] Nessuna posizione libera vicino a Paul.");
}

function ArriveNearHeli()
{
	local BlackHelicopter heli;
	local int i;
	local vector offs[4];

	foreach AllActors(class'BlackHelicopter', heli)
		break;
	if (heli == None)
	{
		Dbg("[UC] Elicottero non trovato.");
		return;
	}

	offs[0] = vect(950, 0, 0);
	offs[1] = vect(-950, 0, 0);
	offs[2] = vect(0, 950, 0);
	offs[3] = vect(0, -950, 0);
	for (i = 0; i < 4; i++)
		if (Player.SetLocation(heli.Location + offs[i]))
		{
			Dbg("[UC] Sei vicino all'elicottero di Jock.");
			return;
		}
	Dbg("[UC] Nessuna posizione libera vicino all'elicottero.");
}

// NSF HQ: davanti al computer del trasmettitore (Tag Computer4) sul tetto.
function ArriveTransmitter()
{
	local Actor comp;
	local int i;
	local vector offs[4];

	foreach AllActors(class'Actor', comp, 'Computer4')
		break;
	if (comp == None)
		return;
	offs[0] = vect(70, 0, 20);
	offs[1] = vect(-70, 0, 20);
	offs[2] = vect(0, 70, 20);
	offs[3] = vect(0, -70, 20);
	for (i = 0; i < 4; i++)
		if (Player.SetLocation(comp.Location + offs[i]))
		{
			Dbg("[UC] Davanti al computer del trasmettitore: usa Broadcast Message.");
			return;
		}
}

// JC ha scelto l'UNATCO (dialogo originale con Paul). Paul resta dov'e':
// e' JC quello che se ne va ("we go our separate ways").
function CommitRoute()
{
	bCommitted = True;

	flags.SetBool('UNATCORouteActive', True,, 99);
	flags.SetBool('UNATCORouteCommitted', True,, 99);
	flags.SetBool('JCDefectedFromUNATCO', False,, 99);
	flags.SetBool('NSFSignalSent', False,, 99);
	flags.SetBool('PaulRejectedByJC', True,, 99);

	Player.GoalCompleted('UCReturnToPaul');
	Log("UnatcoContinues: route UNATCO attivata.");
}

// Cose da fare ad ogni tick quando la route UNATCO e' attiva.
function RouteTick()
{
	if (!bRouteWalls)
	{
		bRouteWalls = True;
		RaiseRouteWalls();
	}

	// finita la conversazione con Paul: il goal vanilla del segnale si chiude
	if (!flags.GetBool('UC_PaulTalkClosed') && Player.conPlay == None)
	{
		flags.SetBool('UC_PaulTalkClosed', True,, 99);
		Player.GoalCompleted('SendSignal');
		// goal delle versioni precedenti (ritorno a Liberty Island con Gunther)
		if (Player.FindGoal('ReturnToUNATCO') != None)
			Player.GoalCompleted('ReturnToUNATCO');
		if (Player.FindGoal('FindHermann') != None)
			Player.GoalCompleted('FindHermann');
	}

	// Jock aspetta a Battery Park: dopo l'incontro con Gunther davanti al 'Ton, o se JC
	// lo evita (finestra), o comunque appena e' in un'altra mappa
	if (!flags.GetBool('UC_JockGoal') && Player.conPlay == None
		&& (flags.GetBool('GuntherTonEncounterPlayed') || flags.GetBool('GuntherTonSkipped')
			|| (localURL != "04_NYC_HOTEL" && localURL != "04_NYC_STREET")))
	{
		flags.SetBool('UC_JockGoal', True,, 99);
		Player.GoalAdd('MeetJockBatteryPark', "Resume your original assignment. Meet Jock in Battery Park and proceed to Hong Kong.", True);
	}

	// Gunther e gli Special Agents al 'Ton (scena facoltativa: chi esce dalla finestra puo' evitarli)
	if (localURL == "04_NYC_STREET" && !bGuntherScene && !flags.GetBool('GuntherTonEncounterPlayed') && !flags.GetBool('GuntherTonSkipped'))
	{
		bGuntherScene = True;
		Spawn(class'UCSceneGuntherTon');
	}
	// dentro l'hotel: la ricerca (anche se JC ha evitato l'incontro fuori) e, a ricerca
	// finita, gli approfondimenti di Gunther da riattaccare (non si salvano con la mappa)
	if (localURL == "04_NYC_HOTEL" && !bGuntherScene
		&& (flags.GetBool('GuntherTonEncounterPlayed') || flags.GetBool('GuntherTonSkipped')))
	{
		bGuntherScene = True;
		Spawn(class'UCSceneGuntherSearch');
	}
	// JC e' andato altrove: la perquisizione di Gunther si e' chiusa fuori scena
	if (localURL != "04_NYC_HOTEL" && localURL != "04_NYC_STREET" && !flags.GetBool('GuntherTonSearchComplete')
		&& (flags.GetBool('GuntherTonEncounterPlayed') || flags.GetBool('GuntherTonSkipped') || flags.GetBool('PaulLeftTonHotel')))
	{
		flags.SetBool('GuntherTonSearchStarted', True,, 99);
		flags.SetBool('GuntherTonSearchComplete', True,, 99);
		flags.SetBool('GuntherFailedToCapturePaul', True,, 99);
	}
	if (!flags.GetBool('JCBrokeWithUNATCO'))
		CheckAttackOnGunther();

	// NSF HQ: con la route UNATCO il segnale non si puo' piu' mandare
	if (localURL == "04_NYC_NSFHQ" && !bTransmitterLocked)
		LockTransmitter();

	// i soldati UNATCO restano amici (ogni ~3 s)
	if (tickCount % 6 == 1 && !flags.GetBool('JCBrokeWithUNATCO'))
		MakeUnatcoFriendly();

	// 'Ton: Paul resta nell'appartamento (finche' JC non lascia la mappa)
	if (localURL == "04_NYC_HOTEL" && !bHotelSetup)
		HotelSetup();
	// 'Ton: la faccenda di JoJo si chiude senza esito, Gilbert torna al bancone
	if (localURL == "04_NYC_HOTEL")
		CloseHotelQuest();

	// Hell's Kitchen: qualche pattuglia amica, porte chiuse, metro aperta
	if (localURL == "04_NYC_STREET")
	{
		if (!bStreetSetup)
			StreetSetup();
		if (!bSubGateChecked)
			OpenSubwayGate();
		else if (tickCount % 6 == 3)
			PlaceMetroPost(flags.GetBool('AnnaNavarre_Dead'));   // conversazioni da riattaccare se perse
		MetroReportTick();
		BlockedExitWarning();
	}

	// Battery Park: Jock aspetta all'elicottero (Anna resta alla metro di Hell's Kitchen)
	if (localURL == "04_NYC_BATTERYPARK" && !flags.GetBool('UNATCORoute_DepartedNYC'))
	{
		if (!bBPSetup)
			BatteryParkSetup();
		if (!flags.GetBool('UC_BP_Started'))
			flags.SetBool('UC_BP_Started', True,, 99);
		if (!bJockConv)
			AttachJockTalk();
		ParkPatrolTick();
		if (flags.GetBool('UC_JockGo') && !flags.GetBool('UC_Takeoff_Started'))
		{
			flags.SetBool('UC_Takeoff_Started', True,, 99);
			Spawn(class'UCSceneTakeoff');
		}
	}

	// Hong Kong: Jock lascia JC all'eliporto (route UNATCO: niente trappola MJ12)
	if (localURL == "06_HONGKONG_HELIBASE" && flags.GetBool('UNATCORoute_DepartedNYC'))
	{
		if (!bHKSetup)
			HelibaseSetup();
		if (!bLiftGuardGone && tickCount % 4 == 1)
			bLiftGuardGone = RemoveLiftGuard();
		if (flags.GetBool('UC_JockHK_Played') && !flags.GetBool('UC_HK_Started'))
		{
			flags.SetBool('UC_HK_Started', True,, 99);
			Spawn(class'UCSceneHongKong');
		}
		// "Mr. Simons will brief you on the assignment.": l'InfoLink di Simons parte qui,
		// appena finito il dialogo con l'ufficiale (chi lo salta lo riceve al mercato)
		if (flags.GetBool('UC_HKOfficer_Played') && !flags.GetBool('UC_HK_SimonsBriefing') && !bSimonsScene
			&& Player.conPlay == None)
		{
			bSimonsScene = True;
			Spawn(class'UCSceneSimonsBriefing');
		}
	}

	// Hong Kong (HK-2): fazioni e trigger di Wan Chai per un agente UNATCO in servizio
	if (Left(localURL, 3) == "06_" && localURL != "06_HONGKONG_HELIBASE" && localURL != "06_HONGKONG_STORAGE"
		&& flags.GetBool('UNATCORoute_DepartedNYC') && !bHKWorld)
	{
		bHKWorld = True;
		Spawn(class'UCHKWorld');
		Spawn(class'UCHKStory');   // HK-3..HK-8: messaggero, Max, Maggie, Gordon, Dragon's Tooth, tregua
	}

	// Hong Kong: JC chiama Simons al mercato, dopo il messaggero Red Arrow (o quando il
	// messaggero non c'e' / JC e' andato oltre: UCHKStory, UC_HK_MessengerDone); nelle
	// altre mappe subito, se non l'ha ancora fatto. All'eliporto no.
	if (Left(localURL, 3) == "06_" && localURL != "06_HONGKONG_HELIBASE" && flags.GetBool('UNATCORoute_DepartedNYC')
		&& !flags.GetBool('UC_HK_SimonsBriefing'))
	{
		if (flags.GetBool('UC_HK_Started'))
			flags.SetBool('UC_HK_SimonsDue', True,, 99);
		if (flags.GetBool('UC_HK_SimonsDue') && !bSimonsScene
			&& (localURL != "06_HONGKONG_WANCHAI_MARKET" || flags.GetBool('UC_HK_MessengerDone')))
		{
			bSimonsScene = True;
			Spawn(class'UCSceneSimonsBriefing');
		}
	}

	// Hong Kong: il briefing di Simons era partito ma JC ha cambiato mappa prima della fine:
	// versione breve di recupero (una volta che e' finito non si ripete piu')
	if (Left(localURL, 3) == "06_" && !bSimonsScene && flags.GetBool('UC_HK_SimonsOpen')
		&& !flags.GetBool('UC_HK_SimonsDone') && Player.conPlay == None)
	{
		bSimonsScene = True;
		Spawn(class'UCSceneSimonsBriefing');
	}

	// battute dei soldati vicini
	BarkTick();
}

// Cosa sa JC di Majestic 12 prima di Hong Kong (lo usa l'ufficiale dell'eliporto).
// Nel gioco originale Lebedev nomina Majestic 12 solo nella conversazione che segue la
// morte di Anna sul 747 (LebedevAnnaDead -> MeetLebedev2): quel flag dura una missione,
// quindi qui si copia in un flag nostro che resta.
//  - UC_HeardLebedevMJ12: sentito di sicuro (la mod era attiva sul 747);
//  - UC_MJ12NameKnown: JC conosce il nome ma non possiamo attribuirlo a Lebedev con
//    certezza (dedotto in missione 4: Anna morta sul 747 e Lebedev ascoltato).
// Senza nessuno dei due l'ufficiale riceve la domanda neutra.
function KnowledgeTick()
{
	if (flags.GetBool('UC_HeardLebedevMJ12'))
		return;
	if (flags.GetBool('LebedevAnnaDead_Played') && Player.conPlay == None)
	{
		flags.SetBool('UC_HeardLebedevMJ12', True,, 99);
		flags.SetBool('UC_MJ12NameKnown', True,, 99);
		return;
	}
	if (!flags.GetBool('UC_MJ12NameKnown') && flags.GetBool('AnnaNavarre_Dead')
		&& flags.GetBool('M03PlayerKilledAnna') && flags.GetBool('M03LebedevParentsClaim'))
		flags.SetBool('UC_MJ12NameKnown', True,, 99);
}

// Prima di partire per Hong Kong: zittisce le battute vanilla della route del
// fuggitivo (Jock dirottato, killswitch, Daedalus) e il titolo "Secret MJ12
// helicopter base". Scadenza 99: devono sopravvivere alla pulizia dei flag di M04.
static function PrepareHongKongFlags(FlagBase f)
{
	if (f == None)
		return;
	f.SetBool('DL_Jock_01_Played', True,, 99);
	f.SetBool('DL_Jock_02_Played', True,, 99);
	f.SetBool('DL_Jock_03_Played', True,, 99);
	f.SetBool('DL_Jock_Fired_Played', True,, 99);
	f.SetBool('DL_Jock_04_Played', True,, 99);
	f.SetBool('DL_Jock_05_Played', True,, 99);
	f.SetBool('DL_Daedalus_02_Played', True,, 99);
	f.SetBool('DL_Tong_00B_Played', True,, 99);   // Tong nella stanza della spada: lo sostituisce Simons
	f.SetBool('DL_Tong_00_Played', True,, 99);
	f.SetBool('M06_HONGKONG_HELIBASE_StartupText', True,, 99);
}

// Toglie dalla lista del PNG una conversazione vanilla.
function RemoveCon(Actor A, name conName)
{
	local ConListItem item, prev;

	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
	{
		if (item.con != None && item.con.conName == conName)
		{
			if (prev == None)
				A.ConListItems = item.next;
			else
				prev.next = item.next;
			return;
		}
		prev = item;
	}
}

// ---------------------------------------------------------------------------
// HONG KONG, ELIPORTO: nel gioco originale e' una trappola MJ12 per il fuggitivo.
// Qui JC e' un agente UNATCO in servizio: niente allarme ne' squadra d'assalto,
// la base lo lascia passare, le porte blindate verso l'ascensore sono aperte.
// Jock gli parla prima di ripartire (UCSceneHongKong lo fa decollare).
// ---------------------------------------------------------------------------
function HelibaseSetup()
{
	local BlackHelicopter heli;
	local UCCon c;

	bHKSetup = True;
	OpenHelibase();

	if (flags.GetBool('UC_JockHK_Played'))
		return;
	foreach AllActors(class'BlackHelicopter', heli, 'chopper')
		break;
	if (heli == None || HasCon(heli, 'UC_JockHK'))
		return;

	heli.ConListItems = None;   // via le battute vanilla di Jock "intrappolato"
	heli.BindName = "Jock";

	c = new(Level) class'UCCon';
	c.Begin('UC_JockHK', "Jock", False);
	c.Once();
	c.Radius(640);   // JC arriva a ~540 dal centro dell'elicottero: parte subito
	c.WideShot();    // l'inquadratura alta di FixedShot sbatteva nel tetto dell'hangar e finiva dentro l'elicottero
	c.Line("Jock", "JCDenton", "Looks like they cleared us.");
	c.Line("JCDenton", "Jock", "Who?");
	c.Line("Jock", "JCDenton", "Hong Kong operations.");
	c.Line("JCDenton", "Jock", "You've been here before.");
	c.Line("Jock", "JCDenton", "I've landed here before.");
	c.Line("JCDenton", "Jock", "There's a difference?");
	c.Line("Jock", "JCDenton", "In this business? Usually.");
	c.Done();
	c.AttachTo(heli);
	// inquadratura fissa per questo dialogo (l'hangar e' troppo basso per quelle calcolate)
	if (FindJockCam() == None)
		Spawn(class'UCJockCam');
	Log("UnatcoContinues: eliporto di Hong Kong pronto per la route UNATCO");
}

function UCJockCam FindJockCam()
{
	local UCJockCam j;

	foreach AllActors(class'UCJockCam', j)
		return j;
	return None;
}

// L'eliporto amico, senza bisogno del giocatore (lo usa anche UCHKCheck).
function OpenHelibase()
{
	local Dispatcher disp;
	local DataLinkTrigger dl;
	local ScriptedPawn sp;
	local SecurityCamera cam;
	local AutoTurret tur;
	local DeusExMover m;

	foreach AllActors(class'Dispatcher', disp, 'AssaultForceDisp')
	{
		disp.Tag = 'UCDisabled';    // se non si puo' distruggere, almeno non riceve piu' l'evento
		disp.Destroy();
	}
	foreach AllActors(class'DataLinkTrigger', dl)
		if (dl.datalinkTag == 'DL_Jock_01')
		{
			dl.SetCollision(False, False, False);
			dl.Destroy();
		}

	foreach AllActors(class'ScriptedPawn', sp)
	{
		sp.ChangeAlly('Player', 1.0, True);
		RemoveCon(sp, 'TrooperBarks');   // "If it's really Denton, one of us is going to get a promotion"
	}
	foreach AllActors(class'SecurityCamera', cam)
	{
		cam.bNoAlarm = True;
		cam.Event = '';
	}
	foreach AllActors(class'AutoTurret', tur)
	{
		tur.bActive = False;
		tur.Tag = 'UCDisabled';
	}
	// nel gioco originale le porte blindate le abbatte Jock con i missili (resta la
	// macerie 'DoorWreckage'): qui sono aperte. Le porte della mappa non si possono
	// distruggere: si tolgono come fa il gioco quando si rompono (DeusExMover.BlowItUp),
	// spostate molto in alto e senza collisione, ma in silenzio.
	foreach AllActors(class'DeusExMover', m)
		if ((m.Tag == 'Blast_doors' || m.Tag == 'DoorWreckage') && !m.bDestroyed)
		{
			m.SetLocation(m.Location + vect(0,0,20000));
			m.SetCollision(False, False, False);
			m.bDestroyed = True;
		}

	ClearBlastDebris();
	SwapHelibaseSign(True);
	LockHelibaseDoors();
	LockHelipadLift();
	RestoreHelibaseLights();
	PlaceHelibaseStaff();
}

// Sopra la porta blindata restano le scintille (ElectricityEmitter 'LibElectric') e a
// terra il fumo (ParticleGenerator), e contro il muro sud sfondato il quadro elettrico
// storto (ControlPanel1, inclinato): nel gioco originale sono il danno dei missili di
// Jock. Qui la porta non e' stata colpita, quindi via (solo route UNATCO: lo chiama
// OpenHelibase).
function ClearBlastDebris()
{
	local Actor A;
	local int n;

	foreach AllActors(class'Actor', A)
	{
		if (A.IsA('ControlPanel'))
		{
			if (VSize((A.Location - vect(-1240, -128, 500)) * vect(1,1,0)) > 160 || Abs(A.Location.Z - 500) > 160)
				continue;
		}
		else if (!(A.IsA('ElectricityEmitter') || A.IsA('ParticleGenerator')))
			continue;
		else if (A.Tag != 'LibElectric' && VSize((A.Location - vect(-1240, -128, 500)) * vect(1,1,0)) > 160)
			continue;
		A.Tag = 'UCDisabled';
		A.SetCollision(False, False, False);
		A.bHidden = True;
		A.AmbientSound = None;
		A.LightType = LT_None;
		A.Destroy();
		if (!A.bDeleteMe)
			A.SetLocation(A.Location + vect(0,0,20000));   // bNoDelete: lontano e spento
		n++;
	}
	Log("UnatcoContinues: residui dell'esplosione tolti (" $ n $ ")");
}

// Sopra la porta blindata la scritta "LOCKDOWN" (HK_Helibase.Sn_HBLkdwn, nella geometria
// della mappa) diventa "ELEVATORS" (UnatcoContinues.UCSignElevators): la texture originale
// "si anima" sulla nuova e resta li'. Nel gioco normale si rimette com'era (la texture
// resta caricata anche cambiando partita).
function SwapHelibaseSign(bool bOn)
{
	local Texture orig, repl;

	orig = Texture(DynamicLoadObject("HK_Helibase.Sn_HBLkdwn", class'Texture', True));
	repl = Texture'UnatcoContinues.UCSignElevators';
	if (orig == None || repl == None)
		return;
	if (bOn)
	{
		// 1024x128 come la scritta HD di Revision: DrawScale 0.125 (scritto nel pacchetto
		// da tools\set_texture_prop.py durante build.ps1) la stende sulla superficie come
		// la 128x16 originale, come fa Revision per le sue texture HD.
		orig.AnimNext = repl;
		orig.AnimCurrent = repl;
		repl.AnimNext = repl;
		repl.AnimCurrent = repl;
	}
	else if (orig.AnimNext == repl)
	{
		orig.AnimNext = None;
		orig.AnimCurrent = None;
	}
}

// Muri della route UNATCO messi con l'editor: mover con Tag che inizia per "UCWall".
// Nella mappa sono invisibili e senza collisione (nel gioco normale non esistono);
// sulla route UNATCO diventano muri veri: visibili, solidi, non apribili.
function RaiseRouteWalls()
{
	local Mover m;
	local DeusExMover dm;
	local int n;

	if (!bCommitted)
		return;
	// qualunque mover (anche quello base dell'editor), non solo DeusExMover
	foreach AllActors(class'Mover', m)
	{
		if (Left(Caps(string(m.Tag)), 6) != "UCWALL")
			continue;
		m.bHidden = False;
		// le lastre di luce del soffitto (UCWallLuce*) solo da vedere: con la collisione
		// (sottilissime) diventavano un muro invisibile nell'atrio degli ascensori
		if (Left(Caps(string(m.Tag)), 10) == "UCWALLLUCE")
		{
			m.SetCollision(False, False, False);
			n++;
			continue;
		}
		m.SetCollision(True, True, True);
		m.bCollideWorld = False;
		dm = DeusExMover(m);
		if (dm != None)
		{
			dm.bFrobbable = False;
			dm.bBreakable = False;
			dm.bPickable = False;
			dm.bLocked = True;
			dm.bHighlight = False;
		}
		n++;
	}
	if (n > 0)
		Log("UnatcoContinues: muri della route UNATCO alzati (" $ n $ ")");
	HideVanillaOnly();
}

// L'inverso: oggetti con Tag che inizia per "UCVanilla" (es. macerie trasformate in
// mover con l'editor) esistono solo nel gioco normale. Nella mappa sono NASCOSTI e
// senza collisione (un mover gia' visibile non si riesce a togliere dalla vista a gioco
// in corso): li mostra ShowVanillaOnly nel gioco normale. Qui, sulla route UNATCO, si
// tengono comunque spenti e lontani.
// Gioco normale (route non scelta): gli oggetti "UCVanilla*" tornano visibili e solidi,
// con lo stesso meccanismo che mostra i muri UCWall sulla route UNATCO.
function ShowVanillaOnly()
{
	local Actor A;
	local int n;

	foreach AllActors(class'Actor', A)
	{
		if (Left(Caps(string(A.Tag)), 9) != "UCVANILLA")
			continue;
		A.bHidden = False;
		A.SetCollision(True, True, True);
		n++;
	}
	if (n > 0)
		Log("UnatcoContinues: oggetti del gioco normale mostrati (" $ n $ ")");
}

function HideVanillaOnly()
{
	local Actor A;
	local int n;

	foreach AllActors(class'Actor', A)
	{
		if (Left(Caps(string(A.Tag)), 9) != "UCVANILLA")
			continue;
		// come DeusExMover.BlowItUp: PRIMA si sposta (con la collisione ancora accesa il
		// motore aggiorna dove disegna il mover), POI si spegne la collisione. Al contrario
		// il mover restava disegnato al suo posto, nero.
		if (A.IsA('Mover'))
			A.SetLocation(A.Location + vect(0,0,20000));
		A.bHidden = True;
		A.SetCollision(False, False, False);
		A.Tag = 'UCHiddenVanilla';   // non piu' "UCVanilla...": non va rielaborato
		n++;
	}
	if (n > 0)
		Log("UnatcoContinues: oggetti solo del gioco normale nascosti (" $ n $ ")");
}

// Eliporto: tutte le porte chiuse con serratura INF tranne quelle dell'ascensore.
// Il pavimento dell'hangar (Z 384) va dall'elicottero all'ascensore senza porte:
// quelle della mappa stanno ai piani sotto (caserme) e sopra (sale di controllo).
function LockHelibaseDoors()
{
	local DeusExMover m;
	local int n;

	foreach AllActors(class'DeusExMover', m)
		if (m.bFrobbable && m.KeyNum == 0 && m.Tag != 'elevator_door')
		{
			m.bLocked = True;
			m.bPickable = False;
			m.bBreakable = False;
			n++;
		}
	Log("UnatcoContinues: porte dell'eliporto chiuse (" $ n $ ")");
}

// Il pulsante della piattaforma (3 Switch1, Event 'Helipad_Lifter' -> Dispatcher1: alza la
// piattaforma di sinistra e apre il suo tetto) sulla route UNATCO non funziona piu': il tetto
// sopra Jock lo apre la scena (UCSceneHongKong, 'hangar_open') e il pulsante, che non lo
// sa, ripartirebbe da "chiuso". Se la piattaforma era gia' su (vecchio salvataggio) si
// riabbassa una volta, con il suo tetto, prima di spegnere i pulsanti.
function LockHelipadLift()
{
	local Switch1 sw;
	local DeusExMover lift;
	local Dispatcher disp;
	local int n;

	foreach AllActors(class'Switch1', sw)
		if (sw.Event == 'Helipad_Lifter')
		{
			sw.Event = '';
			sw.bHighlight = False;
			n++;
		}
	if (n == 0)
		return;   // gia' fatto (salvataggio ricaricato)
	foreach AllActors(class'DeusExMover', lift, 'Helipad')
		break;
	if (lift != None && lift.KeyNum != 0)
		foreach AllActors(class'Dispatcher', disp, 'Helipad_Lifter')
			disp.Trigger(None, None);
	Log("UnatcoContinues: pulsanti della piattaforma dell'eliporto spenti (" $ n $ ")");
}

// Atrio degli ascensori: le luci del soffitto sul lato nord tremolano (LT_Flicker), danno
// dell'esplosione. Sulla route UNATCO tornano fisse. Le due strisce di luce rovinate del
// soffitto le coprono i mover 'UCWallLuce*' della mappa (RaiseRouteWalls).
function RestoreHelibaseLights()
{
	local Light L;
	local int n;

	foreach AllActors(class'Light', L)
		if (L.LightType == LT_Flicker && L.Location.X > -1720 && L.Location.X < -1380
			&& L.Location.Y > -260 && L.Location.Y < 20 && L.Location.Z > 580 && L.Location.Z < 640)
		{
			L.LightType = LT_Steady;
			n++;
		}
	if (n > 0)
		Log("UnatcoContinues: luci dell'atrio degli ascensori riaccese (" $ n $ ")");
}

function ScriptedPawn FindTagged(name tagName)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp, tagName)
		return sp;
	return None;
}

// Un MJ12 aggiunto dalla mod: amico di JC, fermo al suo posto, battute dette proprio da lui.
function ScriptedPawn SpawnStaff(name tagName, string bindName, vector spot, rotator r)
{
	local MJ12Troop t;

	t = Spawn(class'MJ12Troop',, tagName, spot, r);
	if (t == None)
		t = Spawn(class'MJ12Troop',, tagName, spot + vect(0,0,24), r);
	if (t == None)
		return None;
	t.BindName = bindName;
	// Custom dialogue and native idle/combat barks use the same fixed actor.
	t.BarkBindName = class'UCVoice'.static.Profile(t, bindName);
	t.ConBindEvents();
	t.ChangeAlly('Player', 1.0, True);
	t.SetOrders('Standing', '', True);
	return t;
}

// L'ufficiale accoglie JC e lo manda all'ascensore (UCSceneHongKong lo fa correre da
// JC appena finito il dialogo con Jock). E' l'unico MJ12 aggiunto: la guardia davanti
// all'ascensore delle versioni precedenti e' stata tolta (RemoveLiftGuard).
function PlaceHelibaseStaff()
{
	local ScriptedPawn officer;
	local UCCon c;

	officer = FindTagged('UCHKOfficer');
	if (officer == None)
	{
		officer = SpawnStaff('UCHKOfficer', "UCHKOfficer", vect(1876, 477, 433), rot(0, -16384, 0));
		if (officer != None)
		{
			officer.FamiliarName = "MJ12 Officer";
			officer.UnfamiliarName = "MJ12 Officer";
			Spawn(class'UCMark',, 'UCHKOfficerPost', officer.Location);
		}
	}
	RemoveLiftGuard();

	if (officer != None && !HasCon(officer, 'UC_HKOfficer'))
	{
		c = new(Level) class'UCCon';
		c.Begin('UC_HKOfficerAgain', "UCHKOfficer", False);
		c.Require('UC_HKOfficer_Played', True);
		c.Line("UCHKOfficer", "JCDenton", "The lift at the far end of the hangar, Agent Denton. It will take you down to the market.");
		c.Done();
		c.AttachTo(officer);

		// H01-H05: una sola conversazione, il pezzo centrale dipende da cosa JC sa gia' di
		// Majestic 12 (KnowledgeTick). Niente Page, niente piano, nessuna confessione.
		c = new(Level) class'UCCon';
		c.Begin('UC_HKOfficer', "UCHKOfficer", False);
		c.Once();
		c.Radius(220);
		c.Line("UCHKOfficer", "JCDenton", "Agent Denton. Welcome to Hong Kong.");
		c.Line("JCDenton", "UCHKOfficer", "Who's in charge here?");
		c.Line("UCHKOfficer", "JCDenton", "Special Projects handles this facility.");
		c.IfFlag('UC_HeardLebedevMJ12', True, "H02");
		c.IfFlag('UC_MJ12NameKnown', True, "H03");
		// H04: conoscenza non accertata (variante prudente)
		c.Line("JCDenton", "UCHKOfficer", "MJ12. What is that?");
		c.Line("UCHKOfficer", "JCDenton", "Special Projects. This facility operates under Coalition authority.");
		c.Jump("H05");
		// H02: JC ha ascoltato Lebedev
		c.Label("H02");
		c.Line("JCDenton", "UCHKOfficer", "MJ12. Lebedev mentioned Majestic 12.");
		c.Line("UCHKOfficer", "JCDenton", "This facility operates under Coalition authority. Further details are classified.");
		c.Jump("H05");
		// H03: JC conosce il nome, ma non lo attribuiamo a Lebedev
		c.Label("H03");
		c.Line("JCDenton", "UCHKOfficer", "MJ12. Majestic 12?");
		c.Line("UCHKOfficer", "JCDenton", "Special Projects. This facility operates under Coalition authority.");
		// H05: chiusura comune
		c.Label("H05");
		c.Line("JCDenton", "UCHKOfficer", "Part of UNATCO?");
		c.Line("UCHKOfficer", "JCDenton", "Your clearance covers the transit level. Mr. Simons will brief you on the assignment.");
		c.Done();
		c.AttachTo(officer);
	}
}

// La guardia MJ12 davanti all'ascensore ('UCHKGuard') non c'e' piu': nei salvataggi dove
// era gia' stata creata sparisce, ma solo quando JC non la vede. Ritorna True se non c'e'.
function bool RemoveLiftGuard()
{
	local ScriptedPawn guard;

	guard = FindTagged('UCHKGuard');
	if (guard == None)
		return True;
	if (Player != None && Player.LineOfSightTo(guard))
		return False;
	guard.Destroy();
	return True;
}

// Il segnale si manda (o no) col computer del trasmettitore, come nel gioco originale:
// "Broadcast Message" lo invia; chi non lo invia torna da Paul e ottiene il dialogo
// M04PlayerLikesUNATCO. Le versioni precedenti della mod rinominavano la catena vanilla
// ('SendingSignal' -> 'UCSendingSignal') per aprire un menu: nei salvataggi vecchi va
// rimessa com'era.
function RestoreSignalChain()
{
	local Actor A;
	local int n;

	bSignalHooked = True;
	foreach AllActors(class'Actor', A, 'UCSendingSignal')
	{
		A.Tag = 'SendingSignal';
		n++;
	}
	if (n > 0)
		Log("UnatcoContinues: catena del trasmettitore ripristinata (" $ n $ " attori)");
}

// Spegne la catena vanilla del trasmettitore NSF (computer "Broadcast Message"):
//   computer -> evento SendingSignal -> DL_PaulGoodJob (si ripete) + FlagTrigger
//   -> SentSignalCorrectly -> NSFSignalSent=True (+300 punti).
// Anche gli InfoLink di Paul su NSF HQ non devono piu' partire.
function LockTransmitter()
{
	local DataLinkTrigger dl;
	local Actor A;
	local int n;

	bTransmitterLocked = True;

	foreach AllActors(class'DataLinkTrigger', dl)
		if (dl.datalinkTag == 'DL_PaulGoodJob' || dl.datalinkTag == 'DL_PaulNSFHQ' || dl.datalinkTag == 'DL_GotUplinkCode')
		{
			dl.Tag = 'UCDisabled';
			dl.SetCollision(False, False, False);
			n++;
		}

	foreach AllActors(class'Actor', A, 'SendingSignal')
	{
		A.Tag = 'UCDisabled';
		n++;
	}
	foreach AllActors(class'Actor', A, 'SentSignalCorrectly')
	{
		A.Tag = 'UCDisabled';
		n++;
	}
	foreach AllActors(class'Actor', A, 'UCSendingSignal')
	{
		A.Tag = 'UCDisabled';
		n++;
	}

	Log("UnatcoContinues: trasmettitore NSF disattivato (" $ n $ " attori)");
}

// METRO DI HELL'S KITCHEN (specifica "Dialoghi e varianti", blocchi A01-A13 e T01).
// La grata (SubGate) nel gioco originale si apre col tastierino SubKeypad (codice 6282),
// che lo script vanilla attiva solo nella route ribelle. Nella route UNATCO la stazione
// e' presidiata e la linea e' aperta al personale UNATCO: la grata e' gia' aperta, il
// passaggio non dipende da nessuna battuta (chi ignora il posto di guardia passa lo
// stesso). A sorvegliare l'uscita c'e' Anna Navarre; se Anna e' morta non viene ricreata:
// al suo posto un soldato.
function OpenSubwayGate()
{
	bSubGateChecked = True;
	OpenSubwayGateOnly();
	PlaceMetroPost(flags.GetBool('AnnaNavarre_Dead'));
}

function OpenSubwayGateOnly()
{
	local DeusExMover m;
	local Actor pad;

	foreach AllActors(class'DeusExMover', m, 'SubGate')
		if (m.KeyNum == 0 && !m.bInterpolating)
			m.Trigger(None, Player);
	// il tastierino resta spento come nel gioco originale (riaccenderlo richiuderebbe la grata)
	foreach AllActors(class'Actor', pad, 'SubKeypad')
		pad.SetCollision(False);
}

// Flag "creato una volta" dei PNG del posto alla metro (senza giocatore, nei controlli
// automatici, non ci sono flag: allora si crea e basta).
function bool OnceFlag(name flagName)
{
	if (flags == None)
		return False;
	if (flags.GetBool(flagName))
		return True;
	flags.SetBool(flagName, True,, 99);
	return False;
}

// Il rapporto della squadra di Gunther ("JC ha parlato con Paul") arriva ad Anna appena
// trasmesso, senza aspettare la fine della perquisizione, ma mai a meta' di un dialogo:
// la variante con cui Anna apre resta quella scelta all'inizio della conversazione.
function MetroReportTick()
{
	if (!flags.GetBool('UC_PaulContactReportSent') || flags.GetBool('UC_AnnaPaulReportReceived') || Player.conPlay != None)
		return;
	flags.SetBool('UC_AnnaPaulReportReceived', True,, 99);
	flags.SetBool('UC_AnnaKnowsJCMetPaul', True,, 99);
}

function PlaceMetroPost(bool bAnnaDead)
{
	local ScriptedPawn sp, anna, guard;
	local AnnaNavarre a;
	local UNATCOTroop t;
	local vector spot;
	local rotator r;

	spot = vect(2515.1, -1187.8, -583.0);   // sul pianerottolo davanti alla grata
	r = rot(0, 21744, 0);                   // verso chi scende le scale

	foreach AllActors(class'ScriptedPawn', sp, 'UCAnnaMetro')
		anna = sp;
	foreach AllActors(class'ScriptedPawn', sp, 'UCGateTrooper')
		guard = sp;

	if (!bAnnaDead)
	{
		// Anna viva: e' lei al posto di guardia (una volta sola: se non c'e' piu' non torna)
		if (anna == None && !OnceFlag('UC_AnnaMetroSpawned'))
		{
			// il soldato delle versioni precedenti le lascia il posto
			if (guard != None && guard.bInWorld)
				guard.LeaveWorld();
			a = Spawn(class'AnnaNavarre',, 'UCAnnaMetro', spot, r);
			if (a == None)
				a = Spawn(class'AnnaNavarre',, 'UCAnnaMetro', spot + vect(0,0,23), r);
			if (a != None)
			{
				a.ConBindEvents();
				a.ChangeAlly('Player', 1.0, True);
				a.SetOrders('Standing', '', True);
				anna = a;
			}
		}
		if (anna != None && anna.Health > 0 && anna.bInWorld)
			AttachAnnaMetro(anna);
		return;
	}

	// Anna morta: nessuna Anna (se era stata creata e poi uccisa resta dov'e' caduta);
	// al posto di guardia un soldato
	if (guard == None && !OnceFlag('UC_GateGuardSpawned'))
	{
		t = Spawn(class'UNATCOTroop',, 'UCGateTrooper', spot, r);
		if (t == None)
			t = Spawn(class'UNATCOTroop',, 'UCGateTrooper', spot + vect(0,0,23), r);
		if (t != None)
		{
			t.BindName = "UCGateGuard";
			t.BarkBindName = class'UCVoice'.static.Profile(t, "UCGateGuard");
			t.ConBindEvents();
			t.ChangeAlly('Player', 1.0, True);
			t.SetOrders('Standing', '', True);
			guard = t;
		}
	}
	if (guard != None && guard.Health > 0)
	{
		if (!guard.bInWorld)
			guard.EnterWorld();
		AttachMetroTrooper(guard);
	}
}

// T01: il soldato al posto di Anna. Non sa chi ha ucciso Anna e non commenta il 747.
function AttachMetroTrooper(ScriptedPawn guard)
{
	local UCCon c;

	if (HasCon(guard, 'UC_GateGuard'))
		return;

	c = new(Level) class'UCCon';
	c.Begin('UC_GateGuardAgain', "UCGateGuard", True);
	c.Passive();
	c.Require('UC_GateGuard_Played', True);
	c.Line("UCGateGuard", "JCDenton", "The line is open to UNATCO personnel. Go ahead.");
	c.Done();
	c.AttachTo(guard);

	c = new(Level) class'UCCon';
	c.Begin('UC_GateGuard', "UCGateGuard", False);
	c.Once();
	c.Radius(200);
	c.Line("UCGateGuard", "JCDenton", "Agent Denton. We're checking the stations for your brother.");
	c.Line("JCDenton", "UCGateGuard", "I'm heading for Battery Park.");
	c.Line("UCGateGuard", "JCDenton", "The line is open to UNATCO personnel. Go ahead.");
	c.Done();
	c.AttachTo(guard);
}

// Un'apertura di Anna: si attacca solo quella giusta per i fatti che Anna conosce.
//   lebedev: 1 = ucciso da JC, 2 = ucciso da Anna, 0 = altro esito o esito non attribuibile
//   bReport: Anna ha ricevuto il rapporto "JC ha parlato con Paul"
function UCCon AnnaOpening(name conName, int lebedev, bool bReport)
{
	local UCCon c;

	c = new(Level) class'UCCon';
	c.Begin(conName, "AnnaNavarre", False);
	c.Once();
	c.Radius(200);
	c.Require('UC_AnnaMetroOpened', False);
	c.Require('UC_AnnaPaulReportReceived', bReport);
	c.Require('PlayerKilledLebedev', lebedev == 1);
	if (lebedev != 1)
		c.Require('AnnaKilledLebedev', lebedev == 2);
	return c;
}

function AnnaOpeningDone(UCCon c, ScriptedPawn anna)
{
	c.SetFlag('UC_AnnaMetroOpened', True);
	c.Done();
	c.AttachTo(anna);
}

// Anna alla metro. AttachTo mette in testa alla lista: si attacca dall'ultima alla prima.
// Una sola apertura (A01-A06) risolve l'incontro; gli approfondimenti (A10-A12) partono
// solo se JC le parla di nuovo, uno per clic; poi resta la battuta di ripetizione (A13).
// Anna valuta l'affidabilita' professionale di JC; non ripete la minaccia di Gunther.
function AttachAnnaMetro(ScriptedPawn anna)
{
	local UCCon c;

	if (HasCon(anna, 'UC_AnnaA13'))
		return;

	// A13: battuta di ripetizione
	c = new(Level) class'UCCon';
	c.Begin('UC_AnnaA13', "AnnaNavarre", True);
	c.Passive();
	c.Require('UC_AnnaMetroOpened', True);
	c.Line("AnnaNavarre", "JCDenton", "Your assignment is in Hong Kong, Agent Denton.");
	c.Done();
	c.AttachTo(anna);

	// A12: JC critica Gunther (solo se lo ha incontrato e Anna sa dell'incontro con Paul)
	c = new(Level) class'UCCon';
	c.Begin('UC_AnnaA12', "AnnaNavarre", False);
	c.Once();
	c.Require('UC_AnnaMetroOpened', True);
	c.Require('GuntherTonEncounterPlayed', True);
	c.Require('UC_AnnaKnowsJCMetPaul', True);
	c.Line("JCDenton", "AnnaNavarre", "Gunther is taking this personally.");
	c.Line("AnnaNavarre", "JCDenton", "Paul knew our agents and our operations. He has put all of us at risk. Agent Hermann has reason to be angry.");
	c.Line("JCDenton", "AnnaNavarre", "Anger won't help him bring Paul in.");
	c.Line("AnnaNavarre", "JCDenton", "Neither did your visit, apparently.");
	c.Done();
	c.AttachTo(anna);

	// A11: le informazioni di Paul (qui Anna puo' venire a sapere dell'incontro da JC)
	c = new(Level) class'UCCon';
	c.Begin('UC_AnnaA11', "AnnaNavarre", False);
	c.Once();
	c.Require('UC_AnnaMetroOpened', True);
	c.Line("JCDenton", "AnnaNavarre", "Paul showed me records that were worth checking.");
	c.SetFlag('UC_AnnaKnowsJCMetPaul', True);
	c.Line("AnnaNavarre", "JCDenton", "And you checked them. Have they changed your orders?");
	c.Line("JCDenton", "AnnaNavarre", "No. They raised questions.");
	c.Line("AnnaNavarre", "JCDenton", "Then put them in your report. Manderley can read it while you complete your assignment.");
	c.Done();
	c.AttachTo(anna);

	// A10: perche' Anna e' alla metro
	c = new(Level) class'UCCon';
	c.Begin('UC_AnnaA10', "AnnaNavarre", False);
	c.Once();
	c.Require('UC_AnnaMetroOpened', True);
	c.Line("JCDenton", "AnnaNavarre", "Why are you down here?");
	c.Line("AnnaNavarre", "JCDenton", "Paul knows our checkpoints. We are watching the routes out of the district, not just the hotel.");
	c.Line("JCDenton", "AnnaNavarre", "You expect him to come through here?");
	c.Line("AnnaNavarre", "JCDenton", "I expect him to look for an exit we have neglected. This will not be one of them.");
	c.Done();
	c.AttachTo(anna);

	// A06: esito di Lebedev non attribuibile, senza rapporto
	c = AnnaOpening('UC_AnnaA06', 0, False);
	c.Line("AnnaNavarre", "JCDenton", "Agent Denton. You have orders for Hong Kong.");
	c.Line("JCDenton", "AnnaNavarre", "I'm on my way to Battery Park.");
	c.Line("AnnaNavarre", "JCDenton", "Then keep moving. The line is open to UNATCO personnel.");
	AnnaOpeningDone(c, anna);

	// A05: esito di Lebedev non attribuibile, con rapporto
	c = AnnaOpening('UC_AnnaA05', 0, True);
	c.Line("AnnaNavarre", "JCDenton", "Agent Hermann reports that you spoke to Paul and left him at the hotel.");
	c.Line("JCDenton", "AnnaNavarre", "He asked me to join him. I refused.");
	c.Line("AnnaNavarre", "JCDenton", "Then stop delaying your assignment. Agent Hermann will handle Paul. You have orders for Hong Kong.");
	c.Line("JCDenton", "AnnaNavarre", "Is the line to Battery Park open?");
	c.Line("AnnaNavarre", "JCDenton", "For UNATCO personnel. Go.");
	AnnaOpeningDone(c, anna);

	// A04: Lebedev ucciso da Anna, senza rapporto (nessun elogio a JC)
	c = AnnaOpening('UC_AnnaA04', 2, False);
	c.Line("AnnaNavarre", "JCDenton", "Agent Denton. Why are you still in New York?");
	c.Line("JCDenton", "AnnaNavarre", "I'm heading for Battery Park. Jock is taking me to Hong Kong.");
	c.Line("AnnaNavarre", "JCDenton", "At the airfield, I had to finish your assignment. Do not expect me to follow you to Hong Kong and do it again.");
	c.Line("JCDenton", "AnnaNavarre", "I know my orders.");
	c.Line("AnnaNavarre", "JCDenton", "Then carry them out. The line is open.");
	AnnaOpeningDone(c, anna);

	// A03: Lebedev ucciso da Anna, con rapporto
	c = AnnaOpening('UC_AnnaA03', 2, True);
	c.Line("AnnaNavarre", "JCDenton", "Agent Hermann says you spoke to Paul and left him at the hotel. I had to deal with Lebedev myself. Now Agent Hermann has to deal with your brother.");
	c.Line("JCDenton", "AnnaNavarre", "I refused to join Paul. My assignment is Tong.");
	c.Line("AnnaNavarre", "JCDenton", "Then complete it. This time, do not wait for someone else to act.");
	c.Line("JCDenton", "AnnaNavarre", "Is the line to Battery Park open?");
	c.Line("AnnaNavarre", "JCDenton", "For UNATCO personnel. Get to your helicopter.");
	AnnaOpeningDone(c, anna);

	// A02: Lebedev ucciso da JC, senza rapporto
	c = AnnaOpening('UC_AnnaA02', 1, False);
	c.Line("AnnaNavarre", "JCDenton", "Agent Denton. Have your orders for Hong Kong changed?");
	c.Line("JCDenton", "AnnaNavarre", "No. I'm heading for Battery Park.");
	c.Line("AnnaNavarre", "JCDenton", "You performed well at the airfield. I expect the same when you find Tong.");
	c.Line("JCDenton", "AnnaNavarre", "Is the line open?");
	c.Line("AnnaNavarre", "JCDenton", "For UNATCO personnel. Get moving.");
	AnnaOpeningDone(c, anna);

	// A01: Lebedev ucciso da JC, con rapporto (valutazione professionale, non un complimento)
	c = AnnaOpening('UC_AnnaA01', 1, True);
	c.Line("AnnaNavarre", "JCDenton", "Agent Denton. Agent Hermann reports that you spoke to Paul at the hotel. You were more decisive with Lebedev.");
	c.Line("JCDenton", "AnnaNavarre", "Paul asked me to join him. I refused.");
	c.Line("AnnaNavarre", "JCDenton", "That was expected. Arresting him would have been useful.");
	c.Line("JCDenton", "AnnaNavarre", "My orders are to find Tong. Gunther is handling Paul.");
	c.Line("AnnaNavarre", "JCDenton", "Then complete your assignment. Do not leave another agent to finish that one for you.");
	c.Line("JCDenton", "AnnaNavarre", "Is the line to Battery Park open?");
	c.Line("AnnaNavarre", "JCDenton", "For UNATCO personnel. Get to your helicopter.");
	AnnaOpeningDone(c, anna);
}

// Il pulsante "Toggle Full-Screen" del menu cambia modalita' ma non la salva:
// al riavvio Revision ripartiva sempre a schermo intero. Qui si salva la modalita'
// attuale in StartupFullscreen (sezione [WinDrvLite.WindowsClientLite] di Revision.ini).
function RememberWindowMode()
{
	local string cur, full, saved;
	local bool bFull;

	cur = Player.ConsoleCommand("GetCurrentRes");
	full = Player.ConsoleCommand("get WindowsClientLite FullscreenViewportX") $ "x" $ Player.ConsoleCommand("get WindowsClientLite FullscreenViewportY");
	if (cur == "" || full == "x")
		return;

	bFull = (cur == full);
	saved = Player.ConsoleCommand("get WindowsClientLite StartupFullscreen");
	if (bool(saved) != bFull)
	{
		Player.ConsoleCommand("set WindowsClientLite StartupFullscreen " $ string(bFull));
		Log("UnatcoContinues: StartupFullscreen ->" @ bFull @ "(risoluzione" @ cur $ ")");
	}
}

// La conversazione con quel nome e' gia' nella lista del PNG? (la mappa viene
// salvata con le conversazioni aggiunte: non vanno duplicate a ogni visita)
function bool HasCon(Actor A, name conName)
{
	local ConListItem item;

	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
			return True;
	return False;
}

// ---------------------------------------------------------------------------
// 'TON HOTEL: Paul resta seduto nell'appartamento. Se JC gli riparla, poche
// battute asciutte. Quando JC torna dopo aver lasciato la mappa, Paul non c'e' piu'.
// ---------------------------------------------------------------------------
function HotelSetup()
{
	local PaulDenton paul;

	bHotelSetup = True;
	RestoreHotelWindow();

	foreach AllActors(class'PaulDenton', paul)
		break;
	if (paul == None)
		return;

	if (flags.GetBool('PaulLeftTonHotel'))
	{
		if (paul.bInWorld)
			paul.LeaveWorld();
		PaulEvidence();
		return;
	}
	AttachPaulTalk(paul);
}

// Quando JC sceglie l'UNATCO la faccenda dei Renton (Gilbert e Sandra che litigano nel
// retro per JoJo, la pistola da dare a Gilbert, l'arrivo di JoJo) si chiude senza esito:
// l'albergo sta per riempirsi di agenti e JC ha altro da fare. JoJo non arriva piu' e
// Gilbert torna al bancone, dove sta nelle altre missioni; cosi' e' li' quando Gunther
// attraversa la lobby (scambio G03). Se JoJo e' gia' in giro la si lascia finire.
// Le conversazioni della faccenda si tolgono a ogni caricamento (la lista delle
// conversazioni non si salva); Gilbert si sposta una volta sola, e mai sotto gli occhi
// di JC (regola delle scene).
function CloseHotelQuest()
{
	local ScriptedPawn sp, gil, sandra;
	local vector desk, eyes;
	local rotator r;

	foreach AllActors(class'ScriptedPawn', sp)
	{
		if (sp.IsA('JoJoFine') && sp.bInWorld && sp.Health > 0)
			return;   // JoJo e' qui: la scena originale va avanti da sola
		if (sp.IsA('GilbertRenton'))
			gil = sp;
		else if (sp.IsA('SandraRenton'))
			sandra = sp;
	}

	// JoJo non arriva piu' (lo script della missione lo fa entrare solo se questo flag manca)
	if (!flags.GetBool('MS_JoJoUnhidden'))
		flags.SetBool('MS_JoJoUnhidden', True,, 5);

	if (!bHotelQuestCons)
	{
		bHotelQuestCons = True;
		if (gil != None)
		{
			RemoveCon(gil, 'M03OverhearSquabble');
			RemoveCon(gil, 'InterruptFamilySquabble');
			RemoveCon(gil, 'GilbertWaitingForJoJoBarks');
		}
		if (sandra != None)
			RemoveCon(sandra, 'SandraWaitingForJoJoBarks');
	}

	if (flags.GetBool('UC_GilbertAtDesk'))
		return;
	if (gil == None || !gil.bInWorld || gil.Health <= 0 || gil.GetAllianceType('Player') == ALLIANCE_Hostile)
	{
		flags.SetBool('UC_GilbertAtDesk', True,, 99);   // niente Gilbert da spostare
		return;
	}
	desk = vect(-502, -1323, -76);   // il suo posto dietro il bancone (come in missione 2)
	r = rot(0, 208, 0);
	if (VSize(gil.Location - desk) < 60)
	{
		flags.SetBool('UC_GilbertAtDesk', True,, 99);
		return;
	}
	// solo quando JC non vede ne' lui ne' il bancone, e non durante una conversazione
	if (Player.conPlay != None || gil.IsInState('Conversation') || gil.IsInState('FirstPersonConversation'))
		return;
	eyes = Player.Location + vect(0,0,1) * Player.BaseEyeHeight;
	if (Player.LineOfSightTo(gil) || FastTrace(desk, eyes) || FastTrace(desk + vect(0,0,40), eyes))
		return;
	if (!gil.SetLocation(desk))
		return;
	gil.SetRotation(r);
	gil.DesiredRotation = r;
	gil.SetHomeBase(desk, r);
	gil.SetOrders('Standing', '', True);
	flags.SetBool('UC_GilbertAtDesk', True,, 99);
	Log("UnatcoContinues: faccenda di JoJo chiusa, Gilbert al bancone");
}

function AttachPaulTalk(PaulDenton paul)
{
	local UCCon c;

	if (HasCon(paul, 'UC_PaulAfter1'))
		return;

	// dopo le tre battute resta la prima (in coda: vale solo alla fine)
	c = new(Level) class'UCCon';
	c.Begin('UC_PaulAfter4', "PaulDenton", False);
	c.Require('UC_PaulAfter3_Played', True);
	c.Line("PaulDenton", "JCDenton", "There's nothing else I can tell you.");
	c.Done();
	c.AttachTo(paul);

	c = new(Level) class'UCCon';
	c.Begin('UC_PaulAfter3', "PaulDenton", False);
	c.Once();
	c.Require('UC_PaulAfter2_Played', True);
	c.Line("PaulDenton", "JCDenton", "Be careful in Hong Kong, JC.");
	c.Line("JCDenton", "PaulDenton", "You too.");
	c.Done();
	c.AttachTo(paul);

	c = new(Level) class'UCCon';
	c.Begin('UC_PaulAfter2', "PaulDenton", False);
	c.Once();
	c.Require('UC_PaulAfter1_Played', True);
	c.Line("PaulDenton", "JCDenton", "You should go. Jock won't wait forever.");
	c.Done();
	c.AttachTo(paul);

	c = new(Level) class'UCCon';
	c.Begin('UC_PaulAfter1', "PaulDenton", False);
	c.Once();
	c.Require('M04PlayerLikesUNATCO_Played', True);
	c.Line("PaulDenton", "JCDenton", "There's nothing else I can tell you.");
	c.Done();
	c.AttachTo(paul);
}

// Versioni precedenti della mod chiudevano la finestra della camera (raid): riaperta.
function RestoreHotelWindow()
{
	local Teleporter tp;
	local UCBlocker blk;

	foreach AllActors(class'UCBlocker', blk, 'UCWindowBlock')
		blk.Destroy();
	foreach AllActors(class'Teleporter', tp)
		if (InStr(tp.URL, "BedroomWindow") != -1)
			tp.bEnabled = True;
}

// ---------------------------------------------------------------------------
// HELL'S KITCHEN: qualche pattuglia UNATCO amica (soldati vanilla del dopo-segnale,
// nascosti in origine), porte chiuse INF (tranne l'hotel), uscite verso bar,
// Smuggler, fogne e NSF HQ chiuse: si va alla metro per Battery Park.
// ---------------------------------------------------------------------------
function bool IsPatrol(name n)
{
	return (n == 'UNATCOTroop19' || n == 'UNATCOTroop41' || n == 'UNATCOTroop11' || n == 'UNATCOTroop40');
}

function StreetSetup()
{
	local ScriptedPawn sp;
	local Teleporter tp;
	local Actor A;

	bStreetSetup = True;

	// versioni precedenti della mod: posti di blocco salvati nella mappa
	foreach AllActors(class'Actor', A, 'UCBarricade')
		A.Destroy();

	foreach AllActors(class'ScriptedPawn', sp)
	{
		// robot del vecchio posto di blocco (in origine sono tutti fuori dal mondo)
		if (sp.IsA('SecurityBot2') && sp.bInWorld)
		{
			sp.bInvincible = sp.Default.bInvincible;
			sp.LeaveWorld();
		}
		else if (sp.IsA('UNATCOTroop') && sp.Tag == 'UNATCOTroop')
		{
			if (IsPatrol(sp.Name))
			{
				if (!sp.bInWorld)
					sp.EnterWorld();
				sp.ChangeAlly('Player', 1.0, True);
			}
			else if (sp.bInWorld)
				sp.LeaveWorld();
		}
	}

	foreach AllActors(class'Teleporter', tp)
		if (InStr(tp.URL, "Bar") != -1 || InStr(tp.URL, "Smug") != -1 || InStr(tp.URL, "Underground") != -1 || InStr(tp.URL, "NSFHQ") != -1)
			tp.bEnabled = False;

	RemoveSally();
	LockStreetDoors();
	AttachGreeter();

	Log("UnatcoContinues: Hell's Kitchen pronta per la route UNATCO");
}

// Il soldato di pattuglia piu' vicino all'uscita dell'hotel riconosce JC:
// "Agent Denton." quando passa; se JC si ferma a parlargli, due parole.
function AttachGreeter()
{
	local ScriptedPawn sp, best;
	local Actor door;
	local vector spot;
	local float d, bestD;
	local UCCon c;

	spot = vect(1100, 900, -470);
	foreach AllActors(class'Actor', door, 'FromHotelFrontDoor')
		spot = door.Location;

	bestD = 100000;
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA('UNATCOTroop') && sp.bInWorld && (IsPatrol(sp.Name) || sp.BindName == "UCGreeter"))
		{
			d = VSize(sp.Location - spot);
			if (d < bestD)
			{
				bestD = d;
				best = sp;
			}
		}
	if (best == None || HasCon(best, 'UC_GreeterTalk'))
		return;

	best.BindName = "UCGreeter";   // battute dette proprio da lui

	c = new(Level) class'UCCon';
	c.Begin('UC_GreeterTalk', "UCGreeter", False);
	c.Once();
	c.Line("UCGreeter", "JCDenton", "Agent Denton.");
	c.Line("JCDenton", "UCGreeter", "What's going on?");
	c.Line("UCGreeter", "JCDenton", "Search operation. Orders from headquarters.");
	c.Line("JCDenton", "UCGreeter", "Looking for Paul?");
	c.Line("UCGreeter", "JCDenton", "Among others.");
	c.Done();
	c.AttachTo(best);

	// quando JC passa vicino (scorre da sola, JC puo' tirare dritto)
	c = new(Level) class'UCCon';
	c.Begin('UC_GreeterHello', "UCGreeter", True);
	c.Once();
	c.Passive();
	c.NoFrob();
	c.Radius(320);
	c.Require('UC_GreeterTalk_Played', False);
	c.Line("UCGreeter", "JCDenton", "Agent Denton.");
	c.Done();
	c.AttachTo(best);
}

// Vicino a un'uscita chiusa: JC non ha motivo di andare li'.
function BlockedExitWarning()
{
	local Teleporter tp;

	if (Level.TimeSeconds - lastBlockMsgTime < 6.0)
		return;
	foreach AllActors(class'Teleporter', tp)
		if (!tp.bEnabled && tp.URL != "" && VSize(tp.Location - Player.Location) < 260)
		{
			lastBlockMsgTime = Level.TimeSeconds;
			Player.ClientMessage("Jock is waiting in Battery Park. Take the subway.");
			return;
		}
}

// Porte di Hell's Kitchen: tutte chiuse con serratura e porta INF (tranne la grata
// della metro e le porte dell'ingresso dell'hotel); i vetri non si rompono.
// Cosi' non si passa dagli edifici.
function LockStreetDoors()
{
	local DeusExMover m;
	local Actor hotelDoor;
	local vector hotelSpot;
	local int n;

	// punto in cui JC esce dall'hotel (vestibolo): le sue porte devono restare apribili
	hotelSpot = vect(607.9, 897.7, -358.8);
	foreach AllActors(class'Actor', hotelDoor, 'FromHotelFrontDoor')
		hotelSpot = hotelDoor.Location;

	foreach AllActors(class'DeusExMover', m)
	{
		if (m.Tag == 'SubGate')
			continue;
		// porte dell'ingresso dell'hotel: aperte (e sbloccate anche se una versione
		// precedente della mod le aveva chiuse: la mappa viene salvata cosi')
		if (VSize(m.Location - hotelSpot) < 450)
		{
			m.bLocked = False;
			m.bPickable = m.Default.bPickable;
			m.bBreakable = m.Default.bBreakable;
			continue;
		}
		m.bBreakable = False;
		if (m.bFrobbable && m.KeyNum == 0)
		{
			m.bLocked = True;
			m.bPickable = False;
			n++;
		}
	}
	Log("UnatcoContinues: porte di Hell's Kitchen chiuse (" $ n $ ")");
}

// Sally (la ragazza di JoJo davanti alla metro) a questo punto della storia non c'e' piu'.
function RemoveSally()
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.BindName ~= "Sally" && sp.bInWorld)
			sp.LeaveWorld();
}

// ---------------------------------------------------------------------------
// BATTERY PARK: niente cattura vanilla. Navarre, soldati e robot amici; Gunther
// non c'e'; spenti i trigger che li rendevano ostili e l'uscita di fine missione
// vanilla. Le porte che non servono per arrivare all'elicottero sono chiuse.
// ---------------------------------------------------------------------------
function BatteryParkSetup()
{
	local ScriptedPawn sp;
	local Actor A;

	bBPSetup = True;

	foreach AllActors(class'ScriptedPawn', sp)
	{
		// Gunther e' al 'Ton, Anna alla metro di Hell's Kitchen: qui non ci sono
		if (sp.IsA('GuntherHermann') || sp.IsA('AnnaNavarre'))
		{
			if (sp.bInWorld)
				sp.LeaveWorld();
		}
		else if (sp.IsA('UNATCOTroop') || sp.IsA('Robot'))
			sp.ChangeAlly('Player', 1.0, True);
	}

	foreach AllActors(class'Actor', A, 'GuntherAttacksJC')
		A.Tag = 'UCDisabled';
	foreach AllActors(class'Actor', A, 'AnnaAttacksJC')
		A.Tag = 'UCDisabled';
	foreach AllActors(class'Actor', A, 'MadeItToBP')
		A.Tag = 'UCDisabled';
	foreach AllActors(class'Actor', A, 'Mission4Exit')
	{
		A.Tag = 'UCDisabled';
		A.SetCollision(False, False, False);
	}
	LockParkDoors();
	OpenParkRoute();
	ThinParkTroops();
	Log("UnatcoContinues: Battery Park pronta per la route UNATCO");
}

// Il gioco originale chiude il parco con tre posti di blocco (barriere RoadBlock + muri
// invisibili BlockPlayer) e un muro di paletti all'uscita della metro, per la cattura
// di JC. Sulla route UNATCO la strada verso l'elicottero di Jock e' aperta.
// I BlockPlayer sono statici: non si possono distruggere, si spegne la collisione.
function OpenParkRoute()
{
	local RoadBlock rb;
	local BlockPlayer bp;
	local vector c[5];
	local float r[5];
	local int i, n;

	c[0] = vect(-2680, 1700, 0);  r[0] = 200;   // posto di blocco a est (verso il forte e l'elicottero)
	c[1] = vect(-3150, 2190, 0);  r[1] = 200;   // posto di blocco a nord
	c[2] = vect(-4165, 720, 0);   r[2] = 140;   // posto di blocco a sud-ovest
	c[3] = vect(-4027, 1650, 0);  r[3] = 110;   // paletti in cima alle scale della metro
	c[4] = vect(-3830, 1820, 0);  r[4] = 150;   // fila di paletti verso il parco

	foreach AllActors(class'RoadBlock', rb)
	{
		rb.Destroy();
		n++;
	}
	foreach AllActors(class'BlockPlayer', bp)
		if (bp.bBlockPlayers && bp.CollisionRadius <= 60 && bp.Location.Z - bp.CollisionHeight <= 412)
			for (i = 0; i < 5; i++)
				if (VSize((bp.Location - c[i]) * vect(1,1,0)) < r[i])
				{
					bp.SetCollision(False, False, False);
					n++;
					break;
				}
	Log("UnatcoContinues: strada per l'elicottero aperta (" $ n $ " ostacoli)");
}

// Della squadra dell'imboscata vanilla restano solo due soldati di ronda (con le loro
// battute): via i robot e gli altri soldati. Si fa al caricamento, quando JC e' ancora
// sulla banchina della metro.
function ScriptedPawn ParkPatrol(name tagName, vector spot, ScriptedPawn other)
{
	local ScriptedPawn sp, best;
	local float d, bestD;

	foreach AllActors(class'ScriptedPawn', sp, tagName)
		return sp;
	bestD = 100000;
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA('UNATCOTroop') && sp.bInWorld && sp != other)
		{
			d = VSize((sp.Location - spot) * vect(1,1,0));
			if (d < bestD)
			{
				bestD = d;
				best = sp;
			}
		}
	if (best != None)
		best.Tag = tagName;
	return best;
}

function ThinParkTroops()
{
	local ScriptedPawn sp, keep1, keep2;
	local UCMark bpMark;
	local int n;

	keep1 = ParkPatrol('UCBPPatrol1', vect(-3550, 1450, 364), None);
	keep2 = ParkPatrol('UCBPPatrol2', vect(-2900, 400, 364), keep1);
	foreach AllActors(class'ScriptedPawn', sp)
	{
		if (!sp.bInWorld)
			continue;
		if (sp.IsA('Robot') || (sp.IsA('UNATCOTroop') && sp != keep1 && sp != keep2))
		{
			sp.LeaveWorld();
			n++;
		}
	}
	foreach AllActors(class'UCMark', bpMark)
		if (Left(string(bpMark.Tag), 7) == "UCBPPat")
			return;
	Spawn(class'UCMark',, 'UCBPPatA1', vect(-3550, 1450, 364));
	Spawn(class'UCMark',, 'UCBPPatA2', vect(-2950, 1750, 364));
	Spawn(class'UCMark',, 'UCBPPatB1', vect(-2900, 400, 364));
	Spawn(class'UCMark',, 'UCBPPatB2', vect(-2300, 300, 364));
	Log("UnatcoContinues: Battery Park, tolti" @ n @ "fra soldati e robot; 2 di ronda");
}

// I due soldati vanno avanti e indietro fra due punti del prato.
function ParkPatrolTick()
{
	PatrolStep('UCBPPatrol1', 'UCBPPatA1', 'UCBPPatA2');
	PatrolStep('UCBPPatrol2', 'UCBPPatB1', 'UCBPPatB2');
}

function PatrolStep(name trooperTag, name markA, name markB)
{
	local ScriptedPawn sp;
	local UCMark a, b;

	foreach AllActors(class'ScriptedPawn', sp, trooperTag)
		break;
	if (sp == None || !sp.bInWorld || sp.Health <= 0 || sp.IsInState('Conversation') || sp.GetAllianceType('Player') == ALLIANCE_Hostile)
		return;
	foreach AllActors(class'UCMark', a, markA)
		break;
	foreach AllActors(class'UCMark', b, markB)
		break;
	if (a == None || b == None)
		return;
	if (!sp.IsInState('GoingTo'))
		sp.SetOrders('GoingTo', markA, True);
	else if (sp.OrderTag == markA && VSize((sp.Location - a.Location) * vect(1,1,0)) < 90)
		sp.SetOrders('GoingTo', markB, True);
	else if (sp.OrderTag == markB && VSize((sp.Location - b.Location) * vect(1,1,0)) < 90)
		sp.SetOrders('GoingTo', markA, True);
}

// Distanza (in pianta) dal percorso metro -> scale -> parco -> elicottero.
static function float DistFromParkPath(vector p)
{
	local vector pts[5], a, b, ab, ap;
	local float best, d, k;
	local int i;

	pts[0] = vect(-5170, 3027, 0);   // banchina (arrivo dalla metro)
	pts[1] = vect(-5050, 2300, 0);   // scale verso sud
	pts[2] = vect(-5050, 1650, 0);
	pts[3] = vect(-4200, 1720, 0);   // scale verso il parco
	pts[4] = vect(-1632, 516, 0);    // elicottero
	p.Z = 0;
	best = 100000;
	for (i = 0; i < 4; i++)
	{
		a = pts[i];
		b = pts[i + 1];
		ab = b - a;
		ap = p - a;
		k = FClamp((ab dot ap) / (ab dot ab), 0.0, 1.0);
		d = VSize(p - (a + ab * k));
		if (d < best)
			best = d;
	}
	return best;
}

// Porte che non servono per arrivare all'elicottero: chiuse con serratura INF.
function LockParkDoors()
{
	local DeusExMover m;
	local int n;

	foreach AllActors(class'DeusExMover', m)
		if (m.bFrobbable && m.KeyNum == 0 && DistFromParkPath(m.Location) > 220)
		{
			m.bLocked = True;
			m.bPickable = False;
			m.bBreakable = False;
			n++;
		}
	Log("UnatcoContinues: porte di Battery Park chiuse (" $ n $ ")");
}

// Jock aspetta nell'elicottero (BindName "Jock"). La prima volta che JC si avvicina:
// "Where's Paul?". Poi la scelta: pronto (decollo) o un minuto (ci si torna e chiede "Ready?").
function AttachJockTalk()
{
	local BlackHelicopter heli;
	local UCCon c;

	bJockConv = True;
	foreach AllActors(class'BlackHelicopter', heli)
		break;
	if (heli == None || HasCon(heli, 'UC_JockBP'))
		return;

	c = new(Level) class'UCCon';
	JockReadyTalk(c);
	c.AttachTo(heli);

	// tornando dopo "Give me a minute" (una volta): Paul e l'informazione
	c = new(Level) class'UCCon';
	JockExtraTalk(c);
	c.AttachTo(heli);

	// in testa alla lista: prima di "Ready?" e delle battute vanilla di Jock
	c = new(Level) class'UCCon';
	JockParkTalk(c);
	c.AttachTo(heli);
}

// Prima volta all'elicottero (static: la controlla anche UCRouteCheckCommandlet).
static function JockParkTalk(UCCon c)
{
	c.Begin('UC_JockBP', "Jock", False);
	c.Once();
	c.Radius(620);   // l'elicottero e' largo: 620 dal centro = accanto alla fusoliera
	c.FixedShot();
	c.Line("Jock", "JCDenton", "Where's Paul?");
	c.Line("JCDenton", "Jock", "He's not coming.");
	c.Line("Jock", "JCDenton", "Couldn't convince him?");
	c.Line("JCDenton", "Jock", "He couldn't convince me.");
	c.Line("Jock", "JCDenton", "So what now?");
	c.Line("JCDenton", "Jock", "Hong Kong.");
	c.Line("Jock", "JCDenton", "You're still going after Tong.");
	c.Line("JCDenton", "Jock", "Those are my orders.");
	c.Line("Jock", "JCDenton", "Yeah.");
	c.Line("Jock", "JCDenton", "All right. Get in.");
	JockChoice(c);
	c.Done();
}

// Facoltativa, prima di salire (se JC ha chiesto un minuto): niente discussione.
static function JockExtraTalk(UCCon c)
{
	c.Begin('UC_JockBPExtra', "Jock", False);
	c.Once();
	c.Require('UC_JockBP_Played', True);
	c.Radius(560);
	c.FixedShot();
	c.Line("Jock", "JCDenton", "Paul put a lot on the line getting that information.");
	c.Line("JCDenton", "Jock", "That doesn't make him right.");
	c.Line("Jock", "JCDenton", "No.");
	c.Line("Jock", "JCDenton", "Guess it doesn't.");
	JockChoice(c);
	c.Done();
}

// JC torna all'elicottero dopo "Give me a minute".
static function JockReadyTalk(UCCon c)
{
	c.Begin('UC_JockBPReady', "Jock", False);
	c.Require('UC_JockBP_Played', True);
	c.Require('UC_JockBPExtra_Played', True);
	c.Radius(560);
	c.FixedShot();
	c.Line("Jock", "JCDenton", "Ready?");
	JockChoice(c);
	c.Done();
}

static function JockChoice(UCCon c)
{
	c.Choice("Let's go.", "Ready", "Give me a minute.", "Wait");
	c.Label("Ready");
	c.Line("JCDenton", "Jock", "Let's go.");
	c.SetFlag('UC_JockGo', True);
	c.EndHere();
	c.Label("Wait");
	c.Line("JCDenton", "Jock", "Give me a minute.");
	c.Line("Jock", "JCDenton", "Make it fast.");
}

// ---------------------------------------------------------------------------
// BATTUTE: quando JC passa vicino a un soldato, quello dice una battuta
// (una sola per PNG per visita).
// ---------------------------------------------------------------------------
function bool AlreadyBarked(name n)
{
	local int i;

	for (i = 0; i < numBarked; i++)
		if (barked[i] == n)
			return True;
	return False;
}

static function string OriginalBarkBinding(ConListItem first, string fallback)
{
	local ConListItem item;
	// The original conversation list survives in old saves even when the
	// temporary bark name was serialized on the NPC. Recover its actual name.
	for (item = first; item != None; item = item.next)
		if (item.con != None && Left(string(item.con.conName), 3) != "UC_"
			&& item.con.conOwnerName != "" && Left(item.con.conOwnerName, 6) != "UCBark")
			return item.con.conOwnerName;
	// Spawned barricade troops have no original list; use their class name.
	return fallback;
}

static function RestoreBarkBinding(Actor speaker)
{
	if (speaker != None && Left(speaker.BindName, 6) == "UCBark")
		speaker.BindName = OriginalBarkBinding(ConListItem(speaker.ConListItems), speaker.Default.BindName);
}

function RestoreBarkBindings()
{
	local ScriptedPawn sp;
	foreach AllActors(class'ScriptedPawn', sp)
		RestoreBarkBinding(sp);
}

function string BarkLine(ScriptedPawn sp)
{
	barkIndex++;
	if (localURL == "04_NYC_STREET")
	{
		if (barkIndex % 2 == 0)
			return "They've got every unit in Manhattan looking for your brother.";
		return "Didn't expect to see you here, Agent Denton.";
	}
	if (localURL == "04_NYC_BATTERYPARK")
	{
		if (barkIndex % 2 == 0)
			return "Your pilot's waiting past the fort, Agent Denton.";
		return "Heard you're shipping out to Hong Kong. Good luck.";   // battuta originale (M04TroopBarks)
	}
	return "";
}

function BarkTick()
{
	local ScriptedPawn sp;
	local string line;
	local UCCon c;

	if (Player.conPlay != None || Level.TimeSeconds - lastBarkTime < 5.0 || numBarked >= 96)
		return;

	foreach AllActors(class'ScriptedPawn', sp)
	{
		if (!sp.bInWorld || sp.bHidden || !sp.IsA('UNATCOTroop') || sp.BindName == "UCGreeter" || sp.BindName == "UCGateGuard")
			continue;
		if (VSize(sp.Location - Player.Location) > 240 || !Player.LineOfSightTo(sp) || AlreadyBarked(sp.Name))
			continue;

		line = BarkLine(sp);
		if (line == "")
			return;

		barked[numBarked] = sp.Name;
		numBarked++;
		lastBarkTime = Level.TimeSeconds;

		// nome di legame unico: la battuta e' detta proprio da questo PNG
		sp.BindName = "UCBark" $ numBarked;

		c = new(Level) class'UCCon';
		c.Begin('UC_Bark', sp.BindName, True);
		c.Passive();
		c.Line(sp.BindName, "JCDenton", line);
		c.Done();
		if (!Player.StartConversation(sp, IM_Other, c.con, False, False))
			Player.StartConversation(sp, IM_Other, c.con, False, True);
		return;
	}
}

// Se JC attacca Gunther o gli Special Agents la route lealista finisce (per ora:
// stato di fallimento, UNATCO ostile; Hong Kong da agente non va avanti).
function CheckAttackOnGunther()
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if ((sp.Tag == 'UCGunther' || sp.Tag == 'UCSpecialAgent' || sp.Tag == 'UCGuntherSearch' || sp.Tag == 'UCSpecialAgentSearch'
				|| sp.Tag == 'UCSpecialAgentLobby' || sp.Tag == 'UCAnnaMetro' || sp.Tag == 'UCGateTrooper')
			&& sp.bInWorld && sp.GetAllianceType('Player') == ALLIANCE_Hostile)
		{
			BreakWithUNATCO();
			return;
		}
}

function BreakWithUNATCO()
{
	local ScriptedPawn sp;

	flags.SetBool('JCBrokeWithUNATCO', True,, 99);
	flags.SetBool('UNATCORouteActive', False,, 99);
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA('UNATCOTroop') || sp.IsA('GuntherHermann') || sp.IsA('AnnaNavarre') || sp.Tag == 'UCSpecialAgent'
			|| sp.Tag == 'UCSpecialAgentSearch' || sp.Tag == 'UCSpecialAgentLobby')
			sp.ChangeAlly('Player', -1.0, True);
	Player.ClientMessage("You have attacked UNATCO personnel.");
	Log("UnatcoContinues: JC ha attaccato Gunther/Special Agents: route lealista interrotta");
}

// La camera di Paul dopo che se n'e' andato: sangue vicino alla sedia e gocce fino alla
// finestra della camera (porta della camera a x~0, y~-3605), un medkit usato caduto in
// camera, una lattina vicino alla sedia. La specifica "Dialoghi e varianti" sconsigliava
// il sangue (il killswitch non e' una ferita): Gabby lo vuole e resta (4 ott 2026). Vale
// pero' la regola dei dialoghi: nessuno deduce l'ora della fuga da sangue o medicine.
function vector FloorAt(vector spot, out vector normal)
{
	local vector hitLoc;

	if (Trace(hitLoc, normal, spot - vect(0,0,300), spot, False) == None)
	{
		normal = vect(0,0,1);
		return spot - vect(0,0,56);
	}
	return hitLoc;
}

function PaulEvidence()
{
	local Actor A;
	local vector floor, normal, trail[8];
	local BloodPool pool;
	local BloodSplat splat;
	local int i;
	local bool bHaveSplats;

	// oggetti (salvati con la mappa): una volta sola
	if (!flags.GetBool('UC_PaulEvidenceItems'))
	{
		flags.SetBool('UC_PaulEvidenceItems', True,, 99);
		// versione precedente (medkit attaccato alla sedia): tolta
		foreach AllActors(class'Actor', A, 'UCPaulEvidence')
			A.Destroy();
		Spawn(class'Sodacan',, 'UCPaulEvidence2', FloorAt(vect(215, -3615, 120), normal) + vect(0,0,8));
		// il medkit usato e' caduto in camera, lungo la strada verso la finestra
		Spawn(class'MedKit',, 'UCPaulEvidence2', FloorAt(vect(-70, -3760, 120), normal) + vect(0,0,10));
	}

	// la pozza sotto la sedia era troppo grande: niente pozza, solo le macchie piccole
	foreach AllActors(class'BloodPool', pool)
		if (pool.Tag == 'UCPaulEvidence2')
			pool.Destroy();
	// macchie di sangue (decalcomanie: si rifanno se mancano). Permanenti: una macchia
	// che nessuno vede si cancella da sola dopo ~20 s (DeusExDecal.Timer), e chi entra
	// dalla porta principale arriva in camera dopo.
	foreach AllActors(class'BloodSplat', splat)
		if (splat.Tag == 'UCPaulEvidence2')
		{
			splat.bPermanent = True;
			splat.bImportant = True;
			bHaveSplats = True;
		}
	if (bHaveSplats)
		return;
	// dalla sedia, intorno al muro, attraverso la porta della camera, fino alla finestra
	trail[0] = vect(150, -3590, 120);
	trail[1] = vect(95, -3580, 120);
	trail[2] = vect(40, -3588, 120);
	trail[3] = vect(5, -3640, 120);
	trail[4] = vect(-5, -3720, 120);
	trail[5] = vect(0, -3810, 120);
	trail[6] = vect(5, -3895, 120);
	trail[7] = vect(8, -3970, 120);
	for (i = 0; i < 8; i++)
	{
		floor = FloorAt(trail[i], normal);
		splat = Spawn(class'BloodSplat',, 'UCPaulEvidence2', floor + normal, Rotator(normal));
		if (splat != None)
		{
			splat.bPermanent = True;
			splat.bImportant = True;
		}
	}
}

function MakeUnatcoFriendly()
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA('UNATCOTroop'))
			sp.ChangeAlly('Player', 1.0, True);
}

// Flag vanilla che avviano raid / inseguimento: tenuti a FALSE.
function BlockVanillaRaid()
{
	if (flags.GetBool('TalkedToPaulAfterMessage_Played'))
		flags.SetBool('TalkedToPaulAfterMessage_Played', False,, 99);
	if (flags.GetBool('RaidBegin'))
		flags.SetBool('RaidBegin', False,, 99);
	if (flags.GetBool('AnnaBadMama'))
		flags.SetBool('AnnaBadMama', False,, 99);
	if (flags.GetBool('DL_SimonsPissed'))
		flags.SetBool('DL_SimonsPissed', False,, 99);
}

defaultproperties
{
     bHidden=True
}
