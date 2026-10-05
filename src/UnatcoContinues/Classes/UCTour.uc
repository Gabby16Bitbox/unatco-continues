//=============================================================================
// UCTour - modalita' "presentazione" per il video di Gabby (NON fa parte della mod
// giocata: si accende solo con uctour / menu di debug, flag UC_Tour).
// Porta da una novita' all'altra e mette a schermo una riga breve che dice cosa sta
// succedendo ("If you leave the hotel, you find Gunther:"). Tredici passi: nove capitoli
// piu' quattro VARIANTI, cioe' la stessa scena rifatta con un passato diverso ("If Anna
// Navarre died on the 747, Gunther says this instead:").
// I dialoghi non vengono mai saltati ne' tagliati: scorrono interi, al loro ritmo.
//  - ogni passo comincia con un salto (UCDbgTour) in una mappa caricata da zero;
//  - al passo dopo si va SOLO quando lo decide Gabby: tasto PagSu (ucnext). Niente tagli
//    automatici. Se ci arriva da solo, giocando (un'uscita vera), va bene uguale;
//  - la scritta resta a schermo finche' Gabby non la toglie: tasto PagGiu' (uchide). La
//    sostituisce solo la scritta del momento successivo, quando arriva;
//  - UCMod crea questo attore in ogni mappa finche' il flag UC_Tour e' acceso.
// Stato nei flag (viaggiano con JC): UC_TourStep = capitolo, UC_TourCues = scritte gia'
// mostrate (un bit ciascuna). Nessun puntatore a giocatore/finestre fra un tick e l'altro.
//=============================================================================
class UCTour extends Actor
	transient;

var string mapName;
var bool bInit;
var bool bLeaving;       // un salto e' gia' partito (UCDbgTour): PagSu premuto due volte non ne salta uno
var float leaveT;
var float aliveT;        // da quanto esiste questo attore (cioe' da quanto JC e' nella mappa)
var float chapterT;      // secondi passati in questa mappa
var float captionT;      // da quanto e' a schermo la scritta
var string curTitle, curBody;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0.2, True);
}

function DeusExPlayer Plr()
{
	return DeusExPlayer(GetPlayerPawn());
}

static function int LastChapter()
{
	return 13;
}

static function string ChapterMap(int n)
{
	switch (n)
	{
		case 1: return "04_NYC_HOTEL";                      // Paul
		case 2: return "04_NYC_STREET";                     // Gunther davanti al 'Ton
		case 3: return "04_NYC_STREET";                     //   variante: Anna morta sul 747
		case 4: return "04_NYC_HOTEL";                      // la perquisizione
		case 5: return "04_NYC_STREET";                     // Anna alla metro (Lebedev ucciso da JC)
		case 6: return "04_NYC_STREET";                     //   variante: Lebedev ucciso da Anna
		case 7: return "04_NYC_STREET";                     //   variante: Anna morta, c'e' un soldato
		case 8: return "04_NYC_BATTERYPARK";                // Jock
		case 9: return "06_HONGKONG_HELIBASE";              // eliporto: Jock, ufficiale, Simons
		case 10: return "06_HONGKONG_HELIBASE";             //   variante: JC ha ascoltato Lebedev
		case 11: return "06_HONGKONG_WANCHAI_MARKET";       // messaggero
		case 12: return "06_HONGKONG_WANCHAI_UNDERWORLD";   // Lucky Money, Max Chen
		case 13: return "06_HONGKONG_TONGBASE";             // Tracer Tong e l'assalto
	}
	return "";
}

// Una variante e' la scena del passo prima rifatta con un passato diverso: ci si arriva
// solo con un taglio, mai camminando.
static function bool IsVariant(int n)
{
	return n == 3 || n == 6 || n == 7 || n == 10;
}

// Le scritte del capitolo n (i = 0, 1, 2...). trig: "" = subito, "flag:Nome" = quando il
// flag diventa vero, "con:Nome" = mentre va quella conversazione, "t:secondi".
// Una riga sola, corta: e' una presentazione veloce, non una spiegazione.
function bool Cue(int n, int i, out string trig, out string title, out string body)
{
	title = "";
	trig = "";
	switch (n * 10 + i)
	{
		case 10: body = "If you go back to Paul without sending the NSF signal, this dialogue happens:"; return True;
		case 11: trig = "flag:UNATCORouteCommitted"; body = "JC stays with UNATCO. From here the story is new."; return True;

		case 20: body = "If you leave the hotel, you find Gunther:"; return True;
		case 21: trig = "flag:GuntherTonEncounterPlayed"; body = "They go in to search Paul's room."; return True;

		case 30: body = "If Anna Navarre died on the 747, Gunther says this instead:"; return True;

		case 40: body = "If you go back inside, you can follow the search:"; return True;
		case 41: trig = "con:UC_GuntherRoom"; body = "Paul is already gone."; return True;
		case 42: trig = "flag:GuntherTonSearchComplete"; body = "Afterwards you can question Gunther."; return True;

		case 50: body = "At the subway, Anna Navarre is on guard. If you killed Lebedev:"; return True;
		case 60: body = "If Anna had to kill Lebedev herself, she says this instead:"; return True;
		case 70: body = "If Anna is dead, a trooper guards the gate:"; return True;

		case 80: body = "At Battery Park, Jock is waiting to take you to Hong Kong:"; return True;
		case 81: trig = "flag:UC_Takeoff_Started"; body = "Next stop: Hong Kong."; return True;

		case 90: body = "In Hong Kong the MJ12 helibase is not a trap any more:"; return True;
		case 91: trig = "flag:UC_JockHK_Played"; body = "An officer comes to welcome you:"; return True;
		case 92: trig = "flag:UC_HK_SimonsOpen"; body = "Then Simons gives you the mission:"; return True;

		case 100: body = "If you listened to Lebedev, JC asks about Majestic 12:"; return True;

		case 110: body = "In the Wan Chai market, a Red Arrow messenger stops you:"; return True;

		case 120: body = "At the Lucky Money, government agents are talking to the Red Arrow:"; return True;
		case 121: trig = "con:UC_MaxEscort"; body = "You are expected. He takes you to Max Chen:"; return True;
		case 122: trig = "con:UC_MaxMeet"; body = "Max Chen tells you why he sent for you:"; return True;

		case 130: body = "Later, Tracer Tong agrees to see you:"; return True;
		case 131: trig = "con:UC_TongEvidence"; body = "He shows you what Paul found:"; return True;
		case 132: trig = "flag:UC_TongAlarmRang"; body = "Then Special Projects arrives. You led them here:"; return True;
		case 133: trig = "flag:UC_SimonsAfterTong"; title = "UNATCO CONTINUES"; body = "To be continued."; return True;
	}
	return False;
}

function bool CueReady(DeusExPlayer P, string cond)
{
	local string kind, arg;
	local int p1;

	if (cond == "")
		return True;
	p1 = InStr(cond, ":");
	kind = Left(cond, p1);
	arg = Mid(cond, p1 + 1);
	if (kind == "flag")
		return P.rootWindow != None && P.FlagBase.GetBool(P.rootWindow.StringToName(arg));
	if (kind == "con")
		return P.conPlay != None && P.conPlay.con != None && string(P.conPlay.con.conName) ~= arg;
	if (kind == "t")
		return chapterT >= float(arg);
	return False;
}

function Say(string t, string b)
{
	curTitle = t;
	curBody = b;
	captionT = 0;
}

// PagGiu' (uchide, UCDbgTourHide): Gabby toglie la scritta quando vuole lui.
function Dismiss()
{
	curTitle = "";
	curBody = "";
}

// La prossima scritta non ancora mostrata la cui condizione e' vera (una alla volta:
// quella a schermo resta almeno tre secondi).
function Cues(DeusExPlayer P, int step)
{
	local int i, mask;
	local string trig, t, b;

	if ((curTitle != "" || curBody != "") && captionT < 3.0)
		return;
	mask = P.FlagBase.GetInt('UC_TourCues');
	for (i = 0; i < 6; i++)
	{
		if ((mask & (1 << i)) != 0 || !Cue(step, i, trig, t, b) || !CueReady(P, trig))
			continue;
		P.FlagBase.SetInt('UC_TourCues', mask | (1 << i),, 99);
		Say(t, b);
		return;
	}
}

static function UCCaptionWindow FindCaption(DeusExRootWindow root)
{
	local Window w;

	for (w = root.GetTopChild(); w != None; w = w.GetLowerSibling())
		if (UCCaptionWindow(w) != None)
			return UCCaptionWindow(w);
	return None;
}

// Mette (o toglie) la targhetta. Nei dialoghi col formato cinema sta nella fascia nera
// in alto; altrimenti in alto al centro, sotto il riquadro dei messaggi e dell'InfoLink.
function ShowCaption(DeusExPlayer P)
{
	local DeusExRootWindow root;
	local UCCaptionWindow win;
	local float y;

	root = DeusExRootWindow(P.rootWindow);
	if (root == None)
		return;
	win = FindCaption(root);
	if ((curTitle == "" && curBody == "") || root.WindowStackCount() > 0)
	{
		if (win != None)
			win.Hide();
		return;
	}
	if (win == None)
		win = UCCaptionWindow(root.NewChild(class'UCCaptionWindow'));
	if (win == None)
		return;
	win.SetCaption(curTitle, curBody, root.width * 0.7);
	if (P.conPlay != None && P.conPlay.conWinThird != None)
		y = FMax(2, (root.height * 0.104 - win.boxHeight) * 0.5);
	else
		y = root.height * 0.16;
	win.SetPos((root.width - win.boxWidth) * 0.5, y);
	win.SetSize(win.boxWidth, win.boxHeight);
	if (!win.IsVisible())
		win.fade = 0;   // ricompare: di nuovo in dissolvenza
	win.Show();
	win.Raise();
}

function Timer()
{
	local DeusExPlayer P;
	local DeusExLevelInfo info;
	local DeusExRootWindow root;
	local UCCaptionWindow win;
	local int step, n;

	P = Plr();
	if (P == None || P.FlagBase == None)
		return;
	if (!P.FlagBase.GetBool('UC_Tour'))
	{
		root = DeusExRootWindow(P.rootWindow);
		if (root != None)
		{
			win = FindCaption(root);
			if (win != None)
				win.Destroy();
		}
		Destroy();
		return;
	}
	if (mapName == "")
		foreach AllActors(class'DeusExLevelInfo', info)
			mapName = Caps(info.mapName);

	// due secondi dopo l'arrivo PagSu torna a funzionare (vedi UCDbgTour: UC_TourBusy);
	// lo stesso se un salto non e' partito entro 8 secondi
	aliveT += 0.2;
	if (bLeaving)
	{
		leaveT += 0.2;
		if (leaveT > 8.0)
		{
			bLeaving = False;
			leaveT = 0;
		}
	}
	if (aliveT >= 2.0 && !bLeaving && P.FlagBase.GetBool('UC_TourBusy'))
		P.FlagBase.SetBool('UC_TourBusy', False,, 99);

	step = P.FlagBase.GetInt('UC_TourStep');
	if (!bInit)
	{
		bInit = True;
		// la pistola in mano (vedi UCDbgTour.Equip), se JC ha le mani vuote
		if (P.inHand == None && P.FindInventoryType(class'WeaponPistol') != None)
			P.PutInHand(P.FindInventoryType(class'WeaponPistol'));
		// arrivato giocando (non con un salto) nella mappa di un capitolo piu' avanti: si
		// riprende da li' (le varianti si saltano: ci si arriva solo con un taglio)
		if (mapName != ChapterMap(step))
			for (n = step + 1; n <= LastChapter(); n++)
				if (!IsVariant(n) && mapName == ChapterMap(n))
				{
					step = n;
					P.FlagBase.SetInt('UC_TourStep', step,, 99);
					P.FlagBase.SetInt('UC_TourCues', 0,, 99);
					break;
				}
	}
	// fuori percorso (un'altra mappa): niente scritte finche' non ci torna
	if (step < 1 || mapName != ChapterMap(step))
	{
		curTitle = "";
		curBody = "";
		ShowCaption(P);
		return;
	}

	// in partenza per il passo dopo: niente scritte (se il salto non parte, dopo un po' si riprende)
	if (bLeaving)
	{
		curTitle = "";
		curBody = "";
		ShowCaption(P);
		return;
	}

	chapterT += 0.2;
	captionT += 0.2;
	Cues(P, step);
	ShowCaption(P);
}

defaultproperties
{
     bHidden=True
}
