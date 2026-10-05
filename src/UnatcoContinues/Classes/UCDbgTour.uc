//=============================================================================
// UCDbgTour - presentazione per il video (UCTour): porta JC all'inizio di un capitolo.
// Cosi' com'e' parte dal primo passo (Paul al 'Ton); le sottoclassi UCDbgTour2..8 partono
// dagli altri capitoli, UCDbgTourNext / UCDbgTourAgain / UCDbgTourStop passano al passo
// successivo, ripetono, fermano; UCDbgTourHide toglie la scritta a schermo.
// In console: uctour, ucnext (anche PagSu), uchide (anche PagGiu'), ucagain, ucstop.
// I passi sono tredici: nove capitoli e quattro varianti (vedi UCTour.ChapterMap).
//   summon UnatcoContinues.UCDbgTour
// Ogni salto carica la mappa da zero (gli stati salvati della sessione vengono
// cancellati, come all'inizio di una partita nuova): i capitoli si possono rifare
// quante volte si vuole. I salvataggi veri di Gabby non vengono toccati.
//=============================================================================
class UCDbgTour extends UCDebug;

var int chapter;   // passo di partenza (1..13, vedi UCTour.ChapterMap)
var int mode;      // 0 = vai a "chapter", 1 = passo successivo, 2 = ripeti, 3 = ferma, 4 = togli la scritta

function Leave()
{
	Player = None;
	flags = None;
	Destroy();
}

function HideCaption()
{
	local DeusExRootWindow root;
	local UCCaptionWindow win;

	root = DeusExRootWindow(Player.rootWindow);
	if (root == None)
		return;
	win = class'UCTour'.static.FindCaption(root);
	if (win != None)
		win.Hide();
}

function Run()
{
	local int n;
	local UCTour tour;

	n = chapter;
	if (mode == 4)
	{
		foreach AllActors(class'UCTour', tour)
			tour.Dismiss();
		HideCaption();
		Leave();
		return;
	}
	if (mode == 3)
	{
		SetF('UC_Tour', False);
		Player.ClientMessage("[UC] Presentazione fermata.");
		Leave();
		return;
	}
	if (mode == 1 || mode == 2)
	{
		if (!flags.GetBool('UC_Tour'))
		{
			Player.ClientMessage("[UC] La presentazione non e' attiva: uctour per avviarla.");
			Leave();
			return;
		}
		n = flags.GetInt('UC_TourStep');
		if (mode == 1)
			n++;
	}
	if (n > class'UCTour'.static.LastChapter())
	{
		SetF('UC_Tour', False);
		Leave();
		return;
	}
	if (n < 1)
		n = 1;
	// un salto e' gia' partito da questa mappa: il tasto premuto due volte non salta un passo
	foreach AllActors(class'UCTour', tour)
	{
		if (tour.bLeaving && mode != 0)
		{
			Leave();
			return;
		}
		tour.bLeaving = True;
	}
	HideCaption();
	Go(n);
}

// Lo stato della partita come se si fosse arrivati li' giocando, poi il salto.
function Go(int n)
{
	local string url;
	local int arrival;

	switch (n)
	{
		case 1:   // 'Ton: prova NSF trovata, segnale non inviato. JC e' nell'appartamento, a
			      // qualche passo da Paul: a parlargli ci va Gabby
			BaseMission04();
			EvidenceFound();
			SetF('PaulInjured2_Played', True);
			url = "04_NYC_Hotel";
			arrival = 8;
			break;
		case 2:   // fuori dal 'Ton: Gunther ai piedi della scalinata
		case 3:   //   variante: Anna e' morta sul 747
			AfterPaul();
			if (n == 3)
				AnnaDead();
			url = "04_NYC_Street#FromHotelFrontDoor";
			break;
		case 4:   // dentro l'hotel: la perquisizione
			AfterGunther();
			url = "04_NYC_Hotel#ToHotelFrontDoor";
			break;
		case 5:   // in cima alle scale della metro: Anna alla grata (Lebedev ucciso da JC)
		case 6:   //   variante: Lebedev ucciso da Anna
		case 7:   //   variante: Anna morta, alla grata c'e' un soldato
			AfterGunther();
			SetF('UC_GuntherTon1_Played', True);
			if (n == 6)
			{
				SetF('PlayerKilledLebedev', False);
				SetF('AnnaKilledLebedev', True);
			}
			if (n == 7)
				AnnaDead();
			url = "04_NYC_Street";
			arrival = 6;
			break;
		case 8:   // Battery Park, appena scesi dalla metro
			AfterGunther();
			SetF('UC_GuntherTon1_Played', True);
			url = "04_NYC_BatteryPark#ToBatteryPark";
			break;
		case 9:   // Hong Kong, appena atterrati con Jock
		case 10:  //   variante: solo l'ufficiale, con JC che ha ascoltato Lebedev
			AfterGunther();
			SetF('UC_BP_Started', True);
			SetF('UC_JockBP_Played', True);
			SetF('UC_JockGo', True);
			SetF('UC_Takeoff_Started', True);
			SetF('UNATCORoute_DepartedNYC', True);
			class'UCMod'.static.PrepareHongKongFlags(flags);
			if (n == 10)
			{
				SetF('UC_JockHK_Played', True);   // Jock ha gia' parlato: l'ufficiale arriva subito
				SimonsHeard();
				SetF('UC_HeardLebedevMJ12', True);
				SetF('UC_MJ12NameKnown', True);
			}
			url = "06_HongKong_Helibase";
			break;
		case 11:  // mercato di Wan Chai, usciti dall'ascensore: il messaggero (Simons gia' sentito)
			HongKongBase();
			SimonsHeard();
			url = "06_HongKong_WanChai_Market#cargoup";
			break;
		case 12:  // davanti al Lucky Money: agenti governativi, accompagnatore, Max Chen
			HongKongBase();
			SimonsHeard();
			SetF('UC_Messenger_Played', True);
			SetF('UC_HK_MessengerDone', True);
			url = "06_HongKong_WanChai_Underworld";
			arrival = 7;
			break;
		default:  // laboratorio di Tong: tregua fatta, Tong accetta di vedere JC; poi l'assalto
			TongLabState();
			url = "06_HongKong_TongBase#lab";
			break;
	}
	Equip();
	SetF('UC_Tour', True);
	flags.SetInt('UC_TourStep', n,, 99);
	flags.SetInt('UC_TourCues', 0,, 99);
	// mappa da zero: via gli stati salvati della sessione, e quella che si lascia non
	// viene salvata (come fa il gioco quando comincia una partita nuova)
	Player.DeleteSaveGameFiles();
	Player.bStartingNewGame = True;
	Jump(url, arrival);
}

// Nel video JC non deve girare a mani vuote: pistola carica (in mano), manganello,
// granate, medikit, una lattina, soia. Solo quello che non ha gia'; viaggia con lui.
function Equip()
{
	local Inventory pistol;

	GiveItem(class'WeaponPistol', 1, 0);
	GiveItem(class'Ammo10mm', 1, 30);
	GiveItem(class'WeaponBaton', 1, 0);
	GiveItem(class'WeaponLAM', 2, 0);
	GiveItem(class'MedKit', 3, 0);
	GiveItem(class'Sodacan', 1, 0);
	GiveItem(class'SoyFood', 2, 0);
	pistol = Player.FindInventoryType(class'WeaponPistol');
	if (pistol != None && Player.inHand == None)
		Player.PutInHand(pistol);
}

// Come se JC raccogliesse l'oggetto da terra (posto nell'inventario e nella cintura).
function GiveItem(class<Inventory> cls, int count, int ammo)
{
	local Inventory item;
	local int i;

	if (Player.FindInventoryType(cls) != None)
		return;
	for (i = 0; i < count; i++)
	{
		item = Spawn(cls,,, Player.Location);
		if (item == None)
			return;
		if (ammo > 0 && Ammo(item) != None)
			Ammo(item).AmmoAmount = ammo;
		Player.FrobTarget = item;
		if (Player.HandleItemPickup(item, True) && item != None && !item.bDeleteMe && item.Owner == Player)
			Player.FindInventorySlot(item);
		Player.FrobTarget = None;
		// non raccolto (inventario pieno): non resta per terra
		if (item != None && !item.bDeleteMe && item.Owner != Player)
			item.Destroy();
	}
}

// Anna Navarre e' morta sul 747 (JC l'ha uccisa per ascoltare Lebedev).
function AnnaDead()
{
	SetF('AnnaNavarre_Dead', True);
	SetF('M03PlayerKilledAnna', True);
	SetF('PlayerKilledLebedev', False);
}

// Dopo l'incontro con Gunther davanti al 'Ton (rapporto su JC gia' trasmesso).
function AfterGunther()
{
	AfterPaul();
	SetF('PaulLeftTonHotel', True);
	SetF('GuntherTonEncounterPlayed', True);
	SetF('GuntherKnowsJCMetPaul', True);
	SetF('GuntherReportedJCConduct', True);
	SetF('UC_PaulContactReportSent', True);
	SetF('UC_JockGoal', True);
}

function SimonsHeard()
{
	SetF('UC_HK_SimonsDue', True);
	SetF('UC_HK_SimonsBriefing', True);
	SetF('UC_HK_SimonsOpen', True);
	SetF('UC_HK_SimonsDone', True);
}

defaultproperties
{
     chapter=1
     bKeepTour=True
}
