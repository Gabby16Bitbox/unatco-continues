//=============================================================================
// UCHKStory - Hong Kong, Missione 1 "THE HUNT" (pezzi HK-3..HK-8 di
// docs\HONGKONG_M1_PIANO.md): dall'arrivo al mercato fino a "Tong will speak with you".
// Regola: si riusa la logica originale (flag vanilla Have_Evidence, MaxChenConvinced,
// QuickConvinced, QuickLetPlayerIn: tregua, tastierini 1997...), si sostituiscono
// solo le conversazioni. Maggie e il messaggero non sono essenziali: ogni
// informazione necessaria arriva anche da un'altra strada.
//  - mercato: messaggero Red Arrow (facoltativo) -> Max Chen al Lucky Money;
//  - Lucky Money: accenno (due uomini governativi con un Red Arrow); quel Red Arrow poi
//    porta JC da Max, che lo ha mandato a chiamare (niente biglietto d'ingresso); Max Chen;
//  - Queen's Tower: Maggie Chow riscritta; Dragon's Tooth; ologramma di Simons
//    riscritto (registrazione Simons/Maggie); poi JC chiama Simons;
//  - compound: Gordon Quick; dopo la tregua "Tong will speak with you" (codice 1997).
// UCCampaign lo crea nelle mappe 06 dopo la partenza da New York.
// Nessun puntatore a giocatore/flag tenuto fra un tick e l'altro.
//=============================================================================
class UCHKStory extends Actor
	transient;

var string mapName;
var bool bSetup;
var bool bSimonsCall;
var bool bHoloSpot;      // holoSpot gia' preso
var vector holoSpot;     // dove era JC alla fine della registrazione (con la spada presa)
var bool bTongScene;
var bool bOffscreenCall;
var float foreshadowTime;
var int escortWp;         // prossimo punto del percorso dell'accompagnatore (0 = da calcolare)
var float escortStuck;    // da quanti secondi non arriva al punto
var bool bEscortWaiting;  // fermo ad aspettare JC rimasto indietro

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0.5, True);
}

function DeusExPlayer Plr()
{
	return DeusExPlayer(GetPlayerPawn());
}

function bool GetF(name f)
{
	local DeusExPlayer P;

	P = Plr();
	return P != None && P.FlagBase != None && P.FlagBase.GetBool(f);
}

function SetF(name f, bool v)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None && P.FlagBase != None)
		P.FlagBase.SetBool(f, v,, 99);
}

function bool HasCon(Actor A, name conName)
{
	local ConListItem item;

	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
			return True;
	return False;
}

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

function ScriptedPawn FindPawn(name className, optional name skipTag)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA(className) && (skipTag == '' || sp.Tag != skipTag) && sp.bInWorld && sp.Health > 0)
			return sp;
	return None;
}

function ScriptedPawn Tagged(name tagName)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp, tagName)
		return sp;
	return None;
}

function ScriptedPawn Place(class<ScriptedPawn> cls, name tagName, string bindName, vector spot, int yaw, optional string shownName)
{
	local ScriptedPawn sp;
	local rotator r;

	r.Yaw = yaw;
	sp = Spawn(cls,, tagName, spot, r);
	if (sp == None)
		sp = Spawn(cls,, tagName, spot + vect(0,0,24), r);
	if (sp == None)
		return None;
	sp.BindName = bindName;
	sp.ConBindEvents();
	sp.ChangeAlly('Player', 1.0, False);
	sp.SetOrders('Standing', '', True);
	if (shownName != "")
	{
		sp.FamiliarName = shownName;
		sp.UnfamiliarName = shownName;
	}
	return sp;
}

function Goal(name goalName, string text, bool bPrimary)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None && P.FindGoal(goalName) == None)
		P.GoalAdd(goalName, text, bPrimary);
}

function GoalDone(name goalName)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None && P.FindGoal(goalName) != None)
		P.GoalCompleted(goalName);
}

function Note(name flagName, string text)
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None || GetF(flagName))
		return;
	SetF(flagName, True);
	P.AddNote(text, False, True);
}

// ---------------------------------------------------------------------------
// Mappa per mappa (a ogni caricamento: le conversazioni aggiunte non vengono salvate)
// ---------------------------------------------------------------------------
function Setup()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None || P.FlagBase == None)
		return;
	// battute vanilla di Tong nella stanza della spada (lo sostituisce la chiamata a Simons)
	P.FlagBase.SetBool('DL_Tong_00B_Played', True,, 99);
	P.FlagBase.SetBool('DL_Tong_00_Played', True,, 99);
	SetupForMap();
}

// La parte che non ha bisogno del giocatore (la usa anche UCHKCheck, la verifica senza gioco).
function SetupForMap()
{
	if (mapName == MessengerMap())
		SetupMessenger();
	if (mapName == "06_HONGKONG_WANCHAI_UNDERWORLD")
	{
		SetF('MaxChenMeetingAvailable', True);
		SetupMax();
		SetupForeshadow();
		SetupEscort();
	}
	else if (mapName == "06_HONGKONG_WANCHAI_STREET")
	{
		SetupSpecialProjectsDoor();
		SetupMaggie();
		SetupHologram();
		if (Tagged('UCSwordHook') == None)
			Spawn(class'UCSwordHook',, 'Sword_Triggers');
	}
	else if (mapName == "06_HONGKONG_WANCHAI_COMPOUND")
		SetupGordon();
}

// --- Street: la porta di Special Projects -------------------------------------
// The loading dock lies under the butcher's shop of Wan Chai Street (the roll-up grille DeusExMover36,
// south of Queen's Tower). Its service stair comes up behind an old brown door in the back room
// (UCStairsDoor): JC arrives in front of it (#UCSpecialProjects) and opening it takes him back down the
// stair (UCSpecialProjectsDoor -> 06_HongKong_WanChai_Rooftop#UCStreetDoor). The level change is that
// door: the grille is only the shop's front, opened from inside. Before the arrival on the rooftop the
// door is locked and the shop is the shut shop of the original game.
function SetupSpecialProjectsDoor()
{
	local DeusExMover M;
	local Teleporter T;
	local Trigger trig;
	local bool bOpen;

	bOpen = GetF('UCHongKongRooftopArrival');
	foreach AllActors(class'DeusExMover', M, 'UCStairsDoor')
	{
		M.bLocked = !bOpen;
		if (M.KeyNum != 0)
			M.InterpolateTo(0, 0.01);
	}
	foreach AllActors(class'Teleporter', T, 'UCSpecialProjectsDoor')
		T.bEnabled = False;             // only the door uses it (TickSpecialProjectsDoor)
	if (!bOpen)
		return;
	foreach AllActors(class'DeusExMover', M)
		if (VSize(M.BasePos - vect(-192, -2432, 64)) < 8)
			M.bLocked = False;          // the grille opens from inside
	// the original shop is out of bounds (the police hate whoever they see inside): JC belongs there now
	foreach AllActors(class'Trigger', trig, 'LOSHateTrigger')
		if (trig.Location.X > -450 && trig.Location.X < -120 && trig.Location.Y > -2600 && trig.Location.Y < -1930)
		{
			trig.SetCollision(False, False, False);
			trig.Destroy();
		}
}

function TickSpecialProjectsDoor()
{
	local DeusExMover M;
	local Teleporter T;
	local DeusExPlayer P;

	P = Plr();
	if (P == None || !GetF('UCHongKongRooftopArrival'))
		return;
	foreach AllActors(class'DeusExMover', M, 'UCStairsDoor')
		if ((M.KeyNum != 0 || M.bInterpolating) && VSize(P.Location - M.Location) < 200)
		{
			M.InterpolateTo(0, 0.01);
			foreach AllActors(class'Teleporter', T, 'UCSpecialProjectsDoor')
			{
				T.bEnabled = True;
				T.Touch(P);
			}
			return;
		}
}

// --- messaggero Red Arrow (facoltativo, sacrificabile) ----------------------
// Route UNATCO (JC came through the Special Projects dock): he waits in Wan Chai Street, in
// front of the butcher's grille JC comes out of. Older saves without the rooftop arrival: in the
// market corridor of the freight lift (06_HongKong_WanChai_Market#cargoup).
function string MessengerMap()
{
	if (GetF('UCHongKongRooftopArrival'))
		return "06_HONGKONG_WANCHAI_STREET";
	return "06_HONGKONG_WANCHAI_MARKET";
}

function vector MessengerSpot()
{
	if (mapName == "06_HONGKONG_WANCHAI_STREET")
		return vect(150, -2380, 48);
	return vect(-690, -1280, 48);
}

function int MessengerYaw()
{
	if (mapName == "06_HONGKONG_WANCHAI_STREET")
		return 34500;      // across the street, toward the grille
	return 35700;
}

function SetupMessenger()
{
	local ScriptedPawn m;
	local UCCon c;

	// Street: dall'altra parte della strada, girato verso la saracinesca: JC lo vede appena esce.
	// Mercato: nel corridoio dell'ascensore merci, contro il muro nord a ~230 dalle porte,
	// girato verso l'ascensore: JC lo vede appena esce e per forza gli passa accanto
	m = Tagged('UCMessenger');
	if (m == None && !GetF('UC_MessengerPlaced'))
	{
		m = Place(class'TriadRedArrow', 'UCMessenger', "UCMessenger", MessengerSpot(), MessengerYaw());
		SetF('UC_MessengerPlaced', True);
	}
	else if (m != None && !GetF('UC_Messenger_Played') && VSize(m.Location - MessengerSpot()) > 60)
	{
		// versioni precedenti: era all'angolo del mercato o attaccato alle porte
		m.SetLocation(MessengerSpot());
		m.SetRotation(rot(0, 1, 0) * MessengerYaw());
		m.SetOrders('Standing', '', True);
	}
	if (m == None || m.Health <= 0 || HasCon(m, 'UC_Messenger'))
		return;

	c = new(Level) class'UCCon';
	c.Begin('UC_MessengerAgain', "UCMessenger", False);
	c.Require('UC_Messenger_Played', True);
	c.Line("UCMessenger", "JCDenton", "The Lucky Money. Mr. Chen does not like to wait.");
	c.Done();
	c.AttachTo(m);

	c = new(Level) class'UCCon';
	c.Begin('UC_Messenger', "UCMessenger", False);
	c.Once();   // la fa partire TickMessenger: solo quando JC e' uscito dall'ascensore e si vedono
	c.Line("UCMessenger", "JCDenton", "Denton?");
	c.Line("JCDenton", "UCMessenger", "Who's asking?");
	c.Line("UCMessenger", "JCDenton", "Max Chen. He wants to see you before you speak to Miss Chow.");
	c.Line("JCDenton", "UCMessenger", "Why?");
	c.IfFlag('UCHongKongRooftopArrival',False,"OldMessage");
	c.Line("UCMessenger","JCDenton","Because Maggie Chow will tell you this was about Tong. Max thinks it was about the cargo.");
	c.Label("OldMessage");
	c.Line("UCMessenger", "JCDenton", "Ask him. The Lucky Money.");
	c.SetFlag('RedArrowMessengerContacted', True);
	c.SetFlag('MaxChenMeetingAvailable', True);
	c.SetFlag('UC_HK_MessengerDone', True);
	c.Done();
	c.AttachTo(m);
}

// Il messaggero non si muove: parla quando JC gli passa accanto (entro ~200 nella Street;
// al mercato entro ~180 e fuori dall'ascensore; niente muri in mezzo). Quando ha parlato, o non c'e' piu', o JC e' andato oltre, puo' chiamare Simons.
function TickMessenger()
{
	local DeusExPlayer P;
	local ScriptedPawn m;
	local ConListItem item;

	P = Plr();
	if (P == None || GetF('UC_HK_MessengerDone'))
		return;
	m = Tagged('UCMessenger');
	if (GetF('UC_Messenger_Played') || m == None || m.Health <= 0 || !m.bInWorld
		|| (m != None && VSize(P.Location - m.Location) > 1500))
	{
		if (P.conPlay == None)
			SetF('UC_HK_MessengerDone', True);
		return;
	}
	if (P.conPlay != None || VSize(P.Location - m.Location) > 200 || !m.LineOfSightTo(P)
		|| (mapName == "06_HONGKONG_WANCHAI_MARKET" && (P.Location.X < -890 || VSize(P.Location - m.Location) > 180)))
		return;
	for (item = ConListItem(m.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == 'UC_Messenger')
		{
			P.StartConversation(m, IM_Other, item.con, False, False);
			return;
		}
}

// --- Lucky Money: Max Chen ---------------------------------------------------
function SetupMax()
{
    local ScriptedPawn npc;
    npc = FindPawn('MaxChen');
    if (npc == None || HasCon(npc, 'UC_MaxMeet'))
        return;
    RemoveCon(npc, 'MeetMaxChen');
    RemoveCon(npc, 'Show_Chen');
    class'UCHKDialogue'.static.MaxTalks(npc);
}

// Accenno: due uomini governativi parlano con un Red Arrow davanti al Lucky Money e se
// ne vanno quando JC si avvicina. Nessun combattimento.
function SetupForeshadow()
{
	if (GetF('UC_LMForeshadowDone') || Tagged('UCLMAgent') != None)
		return;
	Place(class'MIB', 'UCLMAgent', "UCLMAgent1", vect(-746.9, 141.2, -270), 49152, "Government Agent");
	Place(class'MIB', 'UCLMAgent', "UCLMAgent2", vect(-700, 190, -270), 45000, "Government Agent");
	Place(class'TriadRedArrow', 'UCLMRedArrow', "UCLMRedArrow", vect(-810, 160, -270), 0);
}

function TickForeshadow()
{
	local DeusExPlayer P;
	local ScriptedPawn a, ra;
	local UCCon c;
	local UCMark mark;

	if (GetF('UC_LMForeshadowDone'))
		return;
	P = Plr();
	a = Tagged('UCLMAgent');
	ra = Tagged('UCLMRedArrow');
	if (P == None || a == None)
		return;

	if (!GetF('UC_LMForeshadow_Played'))
	{
		if (P.conPlay == None && VSize(P.Location - a.Location) < 650 && P.LineOfSightTo(a) && ra != None)
		{
			c = new(Level) class'UCCon';
			c.Begin('UC_LMForeshadow', "UCLMAgent1", True);
			c.Once();
			c.Passive();
			c.Line("UCLMAgent1", "UCLMRedArrow", "The payment cleared.");
			c.Line("UCLMRedArrow", "UCLMAgent1", "Max didn't authorize the shipment.");
			c.Line("UCLMAgent2", "UCLMRedArrow", "He accepted the transfer.");
			c.Line("UCLMAgent1", "UCLMRedArrow", "We'll continue this later.");
			c.Done();
			c.AttachTo(a);
			P.StartConversation(a, IM_Other, c.con, False, False);
		}
		return;
	}
	if (P.conPlay != None)
		return;
	// se ne vanno: spariscono appena JC non li vede
	foreshadowTime += 0.5;
	foreach AllActors(class'UCMark', mark, 'UCLMAway')
		break;
	if (mark == None)
	{
		Spawn(class'UCMark',, 'UCLMAway', vect(-716, -123, -270));
		foreach AllActors(class'ScriptedPawn', a, 'UCLMAgent')
			a.SetOrders('GoingTo', 'UCLMAway', True);
	}
	foreach AllActors(class'ScriptedPawn', a, 'UCLMAgent')
		if (a.bInWorld && (!P.LineOfSightTo(a) || foreshadowTime > 25))
			a.LeaveWorld();
	foreach AllActors(class'ScriptedPawn', a, 'UCLMAgent')
		if (a.bInWorld)
			return;
	SetF('UC_LMForeshadowDone', True);
}

// --- Lucky Money: il Red Arrow dell'accenno porta JC da Max ----------------------
// Max ha mandato a chiamare JC, quindi alla porta nessuno gli chiede il biglietto e
// qualcuno lo accompagna: il Red Arrow che stava parlando con i due agenti governativi,
// in cima ai gradini dell'ingresso. Parla quando JC gli passa accanto (dopo l'accenno),
// poi fa strada: di corsa attraverso il club, al passo nella sala sul retro, apre le
// porte dell'ufficio di Max e si mette di lato. Se JC resta indietro lo aspetta.
// Niente di tutto questo e' obbligatorio: senza di lui si entra pagando, come prima.
function SetupEscort()
{
	local ScriptedPawn ra;
	local UCCon c;

	ra = Tagged('UCLMRedArrow');
	if (ra == None || ra.Health <= 0 || HasCon(ra, 'UC_MaxEscort'))
		return;

	// cliccandolo, dopo
	c = new(Level) class'UCCon';
	c.Begin('UC_MaxEscortAgain', "UCLMRedArrow", False);
	c.Require('UC_MaxEscort_Played', True);
	c.IfFlag('MeetMaxChen_Played', True, "Met");
	c.Line("UCLMRedArrow", "JCDenton", "Mr. Chen is waiting.");
	c.EndHere();
	c.Label("Met");
	c.Line("UCLMRedArrow", "JCDenton", "You have Mr. Chen's answer.");
	c.Done();
	c.AttachTo(ra);

	// davanti alle porte dell'ufficio (scorre da sola)
	c = new(Level) class'UCCon';
	c.Begin('UC_MaxEscortDoor', "UCLMRedArrow", True);
	c.Once();
	c.Passive();
	c.NoFrob();
	c.Radius(330);
	c.Require('UC_MaxEscortDone', True);
	c.Require('MeetMaxChen_Played', False);
	c.Line("UCLMRedArrow", "JCDenton", "Mr. Chen is inside.");
	c.Done();
	c.AttachTo(ra);

	// il saluto: lo fa partire TickEscort
	c = new(Level) class'UCCon';
	c.Begin('UC_MaxEscort', "UCLMRedArrow", False);
	c.Once();
	c.Require('MeetMaxChen_Played', False);
	c.IfFlag('UC_Messenger_Played', True, "Told");
	// JC non ha parlato col messaggero
	c.Line("UCLMRedArrow", "JCDenton", "Denton. Max Chen wants to see you.");
	c.Line("JCDenton", "UCLMRedArrow", "I didn't ask for a meeting.");
	c.Line("UCLMRedArrow", "JCDenton", "Mr. Chen did.");
	c.Jump("Agents");
	c.Label("Told");
	c.Line("UCLMRedArrow", "JCDenton", "Mr. Denton. Mr. Chen is expecting you.");
	c.Label("Agents");
	c.IfFlag('UC_LMForeshadow_Played', False, "Go");
	c.Line("JCDenton", "UCLMRedArrow", "Friends of yours?");
	c.Line("UCLMRedArrow", "JCDenton", "Not friends.");
	c.Label("Go");
	c.Line("UCLMRedArrow", "JCDenton", "This way.");
	c.SetFlag('PaidForLuckyMoney', True);            // nessuno chiede il biglietto, le porte si aprono
	c.SetFlag('KnowsAboutMaxChen', True);
	c.SetFlag('ClubTriadBackroomMeet_Played', True); // nella sala sul retro nessuno lo ferma: e' accompagnato
	c.SetFlag('MaxChenMeetingAvailable', True);
	c.Done();
	c.AttachTo(ra);
}

// Il percorso, lungo i PathNode della mappa (l'ultimo tratto e' dritto).
function int EscortLast()
{
	return 8;
}

function vector EscortPoint(int i)
{
	switch (i)
	{
		case 1: return vect(-885, -7, -369);      // ai piedi dei gradini dell'ingresso
		case 2: return vect(-1025, -253, -369);   // corridoio
		case 3: return vect(-1027, -694, -369);   // davanti alle porte del club
		case 4: return vect(-1024, -1008, -369);  // dentro
		case 5: return vect(-703, -1534, -369);   // lato est della sala (la scala e il buttafuori sono al centro)
		case 6: return vect(-832, -2016, -369);   // passaggio verso la sala sul retro
		case 7: return vect(-680, -2242, -369);   // sala sul retro
	}
	return vect(-600, -2305, -369);               // di lato alle porte dell'ufficio di Max
}

function name EscortTag(int i)
{
	switch (i)
	{
		case 1: return 'UCEscort1';
		case 2: return 'UCEscort2';
		case 3: return 'UCEscort3';
		case 4: return 'UCEscort4';
		case 5: return 'UCEscort5';
		case 6: return 'UCEscort6';
		case 7: return 'UCEscort7';
	}
	return 'UCEscort8';
}

// Verso il punto i: di corsa nel club, al passo nella sala sul retro.
function EscortGo(ScriptedPawn e, int i)
{
	local UCMark mark;

	foreach AllActors(class'UCMark', mark, EscortTag(i))
		break;
	if (mark == None)
		Spawn(class'UCMark',, EscortTag(i), EscortPoint(i));
	if (i <= 6)
		e.SetOrders('RunningTo', EscortTag(i), True);
	else
		e.SetOrders('GoingTo', EscortTag(i), True);
}

function vector ClubDoorSpot()
{
	return vect(-1024, -784, -369);
}

// Le porte del club ('Club_Doors') non si aprono a mano: le apre un trigger della mappa
// quando passa JC che ha pagato, e restano aperte dieci secondi. L'accompagnatore arriva
// prima di JC, e JC puo' arrivare mentre si richiudono (il trigger della mappa scatta
// solo entrando nel suo raggio): si aprono qui per tutti e due.
function ClubDoors(DeusExPlayer P, ScriptedPawn e)
{
	local Mover m;
	local bool bNear;

	if (!GetF('PaidForLuckyMoney'))
		return;
	bNear = VSize((P.Location - ClubDoorSpot()) * vect(1,1,0)) < 300 && Abs(P.Location.Z - ClubDoorSpot().Z) < 150;
	if (e != None && escortWp >= 3 && escortWp <= 4 && VSize((e.Location - ClubDoorSpot()) * vect(1,1,0)) < 420)
		bNear = True;
	if (!bNear)
		return;
	foreach AllActors(class'Mover', m, 'Club_Doors')
		if (m.KeyNum == 0 && !m.bInterpolating)
			m.Trigger(Self, P);
}

// Le porte dell'ufficio di Max: l'accompagnatore le apre quando ci arriva (e restano aperte).
function OfficeDoors(ScriptedPawn e)
{
	local DeusExMover m;

	foreach AllActors(class'DeusExMover', m, 'MaxChensOffice')
		if (m.KeyNum == 0 && !m.bInterpolating && !m.bDestroyed && VSize((m.Location - e.Location) * vect(1,1,0)) < 330)
		{
			m.bLocked = False;
			m.Frob(e, None);
		}
}

// JC sta guardando l'attore (stessa regola di UCScene.SeenByJC).
function bool SeenByJC(Actor A)
{
	local DeusExPlayer P;
	local vector d;

	P = Plr();
	if (P == None || A == None)
		return False;
	d = A.Location - (P.Location + vect(0,0,1) * P.BaseEyeHeight);
	if (VSize(d) > 4000)
		return False;
	if ((Normal(d) dot vector(P.ViewRotation)) < 0.5)
		return False;
	return P.LineOfSightTo(A);
}

function TickEscort()
{
	local DeusExPlayer P;
	local ScriptedPawn e, a;
	local ConListItem item;
	local vector d, target;
	local float dist;
	local int i;

	P = Plr();
	if (P == None)
		return;
	e = Tagged('UCLMRedArrow');
	if (e != None && (e.Health <= 0 || !e.bInWorld))
		e = None;
	ClubDoors(P, e);
	if (e == None || GetF('UC_MaxEscortDone'))
		return;
	SetupEscort();   // il gioco puo' rifare la lista delle conversazioni: si riattaccano

	// il saluto, quando JC gli passa accanto
	if (!GetF('UC_MaxEscort_Played'))
	{
		if (GetF('MeetMaxChen_Played') || P.conPlay != None)
			return;
		// prima l'accenno: i due agenti governativi (se ci sono) devono aver parlato
		a = Tagged('UCLMAgent');
		if (a != None && a.bInWorld && !GetF('UC_LMForeshadow_Played') && !GetF('UC_LMForeshadowDone'))
			return;
		if (VSize(P.Location - e.Location) > 260 || !e.LineOfSightTo(P))
			return;
		for (item = ConListItem(e.ConListItems); item != None; item = item.next)
			if (item.con != None && item.con.conName == 'UC_MaxEscort')
			{
				P.StartConversation(e, IM_Other, item.con, False, False);
				return;
			}
		return;
	}
	// finche' dura il saluto sta fermo; le altre conversazioni non lo fermano (nella sala
	// sul retro i Red Arrow seduti parlano fra loro di continuo: restava li' ad aspettare)
	if (P.conPlay != None && P.conPlay.con != None && P.conPlay.con.conName == 'UC_MaxEscort')
		return;

	// fa strada (anche dopo un caricamento: riparte dal punto piu' vicino)
	if (escortWp == 0)
	{
		escortWp = 1;
		for (i = 2; i <= EscortLast(); i++)
			if (VSize(e.Location - EscortPoint(i)) < VSize(e.Location - EscortPoint(escortWp)))
				escortWp = i;
		escortStuck = 0;
		bEscortWaiting = False;
		EscortGo(e, escortWp);
	}
	target = EscortPoint(escortWp);
	if (escortWp >= 6)
		OfficeDoors(e);

	// arrivato al punto
	d = e.Location - target;
	if (VSize(d * vect(1,1,0)) < 70 && Abs(d.Z) < 90)
	{
		if (escortWp >= EscortLast())
		{
			// di lato alle porte aperte, girato verso la sala: da qui JC va da solo
			e.SetOrders('Standing', '', True);
			e.SetHomeBase(e.Location, rot(0, 40000, 0));
			e.DesiredRotation = rot(0, 40000, 0);
			SetF('UC_MaxEscortDone', True);
			return;
		}
		escortWp++;
		escortStuck = 0;
		bEscortWaiting = False;
		EscortGo(e, escortWp);
		return;
	}

	// JC e' rimasto indietro: lo aspetta, girato verso di lui
	dist = VSize(P.Location - e.Location);
	if (bEscortWaiting)
	{
		if (dist < 350 || VSize(P.Location - target) < VSize(e.Location - target))
		{
			bEscortWaiting = False;
			escortStuck = 0;
			EscortGo(e, escortWp);
		}
		else
			e.DesiredRotation = rotator((P.Location - e.Location) * vect(1,1,0));
		return;
	}
	if (dist > 600 && VSize(P.Location - target) > VSize(e.Location - target))
	{
		bEscortWaiting = True;
		e.SetOrders('Standing', '', True);
		e.DesiredRotation = rotator((P.Location - e.Location) * vect(1,1,0));
		return;
	}

	// incastrato: va al punto quando JC non lo guarda
	escortStuck += 0.5;
	if (escortStuck > 20 && !SeenByJC(e))
	{
		escortStuck = 0;
		if (e.SetLocation(target))
			EscortGo(e, escortWp);
	}
}

// --- Queen's Tower: Maggie Chow ------------------------------------------------
function ScriptedPawn RealMaggie()
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA('MaggieChow') && sp.Tag != 'UCMaggieHolo' && sp.bInWorld && sp.Health > 0)
			return sp;
	return None;
}

function SetupMaggie()
{
    local ScriptedPawn npc;
    npc = RealMaggie();
    if (npc == None || HasCon(npc, 'UC_MaggieMeet'))
        return;
    RemoveCon(npc, 'MeetMaggie');
    RemoveCon(npc, 'MeetMaggie2');
    RemoveCon(npc, 'MaggieBarks');
    class'UCHKDialogue'.static.MaggieTalks(npc);
}

// L'ologramma vanilla di Simons (M06WaltonHolo) riscritto: una registrazione
// Simons/Maggie, sospetta solo perche' JC la trova li'. Stesso nome della
// conversazione vanilla: la fa partire il ConversationTrigger della mappa.
function SetupHologram()
{
	local ScriptedPawn walton, holo;
	local UCCon c;
	local int i;
	local vector offs[6];

	foreach AllActors(class'ScriptedPawn', walton)
		if (walton.IsA('WaltonSimons'))
			break;
	if (walton == None)
		return;

	holo = Tagged('UCMaggieHolo');
	if (holo == None && !GetF('M06WaltonHolo_Played'))
	{
		// Maggie nella registrazione: corpo generico con l'aspetto di Maggie (la vera
		// Maggie puo' essere morta o altrove), traslucida come l'ologramma di Simons
		offs[0] = vect(0, 70, 0);
		offs[1] = vect(70, 0, 0);
		offs[2] = vect(-70, 0, 0);
		offs[3] = vect(0, -70, 0);
		offs[4] = vect(55, 55, 10);
		offs[5] = vect(-55, -55, 10);
		for (i = 0; i < 6 && holo == None; i++)
			holo = Spawn(class'Female2',, 'UCMaggieHolo', walton.WorldPosition + offs[i], rotator(-offs[i]));
		if (holo != None)
		{
			holo.BindName = "UCMaggieHolo";
			holo.FamiliarName = "Maggie Chow";
			holo.UnfamiliarName = "Maggie Chow";
			holo.Mesh = class'MaggieChow'.Default.Mesh;
			for (i = 0; i < 8; i++)
				holo.MultiSkins[i] = class'MaggieChow'.Default.MultiSkins[i];
			holo.Style = walton.Style;
			holo.bInvincible = True;
			holo.SetCollision(False, False, False);
			holo.SetOrders('Standing', '', True);
			holo.ConBindEvents();
			holo.LeaveWorld();
		}
	}

	if (HasCon(walton, 'M06WaltonHolo') && HasCon(walton, 'UC_WaltonHoloMark'))
		return;
	RemoveCon(walton, 'M06WaltonHolo');

	c = new(Level) class'UCCon';
	c.Begin('UC_WaltonHoloMark', "WaltonSimons", True);   // solo segnaposto: non parte mai
	c.Require('AlwaysFalse', True);
	c.NoFrob();
	c.Done();
	c.AttachTo(walton);

	c = new(Level) class'UCCon';
	c.Begin('M06WaltonHolo', "WaltonSimons", True);
	c.Once();
	c.Passive();
	c.NoFrob();
    c.Line("WaltonSimons", "UCMaggieHolo", "Ms. Chow. Denton is arriving under UNATCO orders. Give him what he needs to continue the investigation.");
    c.Line("UCMaggieHolo", "WaltonSimons", "And if he questions my involvement?");
    c.Line("WaltonSimons", "UCMaggieHolo", "His assignment is Tong. Keep it there.");
    c.Line("UCMaggieHolo", "WaltonSimons", "The Red Arrow may approach him first.");
    c.Line("WaltonSimons", "UCMaggieHolo", "Then you should be ready with your account of the dispute.");
    c.Line("JCDenton", "WaltonSimons", "Simons.");
	c.SetFlag('SimonsConvoPlaying', False);
	c.SetFlag('UC_HoloSeen', True);
	c.Done();
	c.AttachTo(walton);
}

// La registrazione compare insieme all'ologramma di Simons e sparisce con lui.
function TickHologram()
{
	local ScriptedPawn walton, holo;

	holo = Tagged('UCMaggieHolo');
	if (holo == None)
		return;
	foreach AllActors(class'ScriptedPawn', walton)
		if (walton.IsA('WaltonSimons'))
			break;
	if (walton != None && walton.bInWorld && !holo.bInWorld && !GetF('M06WaltonHolo_Played'))
	{
		holo.EnterWorld();
		holo.SetCollision(False, False, False);
		holo.Style = walton.Style;
	}
	else if (holo.bInWorld && (walton == None || !walton.bInWorld) && GetF('M06WaltonHolo_Played'))
		holo.LeaveWorld();
}

// --- compound: Gordon Quick ----------------------------------------------------
function SetupGordon()
{
    local ScriptedPawn npc;
    npc = FindPawn('GordonQuick');
    if (npc == None || HasCon(npc, 'UC_GordonMeet'))
        return;
    RemoveCon(npc, 'Gate_Guard2');
    RemoveCon(npc, 'ConvinceQuick');
    RemoveCon(npc, 'QuickAfterMaggie');
    RemoveCon(npc, 'QuickFinalTalk');
    RemoveCon(npc, 'QuickWaiting');
    RemoveCon(npc, 'QuickWaiting_1_5');
    class'UCHKDialogue'.static.GordonTalks(npc);
}

// ---------------------------------------------------------------------------
// Obiettivi, note e chiamata a Simons (in qualunque mappa di Hong Kong)
// ---------------------------------------------------------------------------
function Goals()
{
    local DeusExPlayer P;
    P = Plr();
    if (P == None || P.conPlay != None)
        return;
    if (GetF('UC_Messenger_Played') || GetF('UC_MaxEscort_Played'))
        Goal('UCMeetMaxChen', "Contact Max Chen at the Lucky Money. Special Projects believes the Red Arrow can identify Tong's local network.", False);
    if (GetF('MeetMaxChen_Played'))
        GoalDone('UCMeetMaxChen');
    if (GetF('UC_MaxDealOffered') || GetF('UC_MaggieRWPlayed') || GetF('UC_GordonMeet_Played') || GetF('UC_ChowSwordVerified'))
    {
        Goal('UCInvestigateChow', "Check the claims about Maggie Chow, Yuen Kong and the Dragon's Tooth. Examine Queen's Tower and the police records.", False);
        Goal('UCYuenKong', "Compare the Queen's Tower transcript with the police report concerning Yuen Kong's death.", False);
        Goal('ContactMaggieChow', "Optional: question Maggie Chow at Queen's Tower about the Triad dispute. Verify her claims.", False);
    }
    if (GetF('UC_MaxDealOffered'))
        Goal('UCRecoverForMax', "Optional: Max Chen offers an introduction to Gordon Quick in exchange for the Dragon's Tooth and evidence on Yuen Kong. Delivery is your decision.", False);
    if (GetF('UC_MaggieRWPlayed'))
        Goal('UCRecoverForChow', "Optional: Maggie Chow claims the Luminous Path stole the weapon. Verify her claim before acting on it.", False);
    if (GetF('UC_MaggieRWPlayed') || GetF('MaggieChow_Dead'))
        GoalDone('ContactMaggieChow');
    if (GetF('UC_YuenCaseCorroborated'))
        GoalDone('UCYuenKong');
    if (GetF('UC_ChowSwordVerified'))
    {
        GoalDone('UCInvestigateChow');
        GoalDone('UCRecoverForChow');
        Goal('UCTellGordon', "Present your verified evidence to Gordon Quick at the compound. Delivering the weapon to Max is optional.", True);
    }
    if (GetF('UC_SwordGivenMax'))
        GoalDone('UCRecoverForMax');
    if (GetF('UC_LPMeetingGranted'))
    {
        GoalDone('UCTellGordon');
        Note('UC_NoteTongLab', "Tong has agreed to a guarded meeting. Sparring room door: 1997. Permission to speak is not permission to search the compound.");
    }
}

// Risposta InfoLink soltanto al rapporto inviato da JC dal terminale.
function SimonsCall()
{
    local UCSceneSimonsSword scene;
    if (bSimonsCall || GetF('UC_SimonsSwordCall') || !GetF('ChowEvidenceReportSent') || Plr() == None || Plr().conPlay != None)
        return;
    bSimonsCall = True;
    scene = Spawn(class'UCSceneSimonsSword');
    if (scene != None)
        scene.bRecording = GetF('SimonsMaggieRecordingSeen');
}

// Dopo l'ingresso autorizzato l'operazione puo proseguire fuori scena.
// La risposta di Simons richiede comunque un rapporto manuale dal terminale.
function AssaultOffscreen()
{
	local UCSceneSimonsAfterTong s;
	local DeusExPlayer P;

	P = Plr();
	if (bOffscreenCall || P == None || P.conPlay != None || !GetF('MJ12AssaultStarted') || GetF('MJ12AssaultResolved')
		|| (!GetF('UC_SPEntryCrossed') && !GetF('UC_LegacyAssault'))
		|| GetF('UC_SimonsAfterTong') || mapName == "06_HONGKONG_TONGBASE")
		return;
	SetF('MJ12AssaultResolvesOffscreen', True);
	if (!GetF('TracerTong_Dead'))
	{
		SetF('TongEscapedCompound', True);
		SetF('TongLocationUnknown', True);
	}
	SetF('UC_SweepComplete', True);
	SetF('UC_SPTeamRecordsRecovered', True);
	if (!GetF('UC_OffscreenResultsNoted'))
	{
		SetF('UC_OffscreenResultsNoted', True);
		P.AddNote("Special Projects operation continued after I left the base. Personnel and archive results are team reports, not my eyewitness account."
            $ " Submit the operation report from a secure terminal: the compound office, Wan Chai police station, Queen's Tower or Tong's archive.", False, True);
	}
	if (P.FindGoal('UCSubmitOperationReport') == None)
		P.GoalAdd('UCSubmitOperationReport', "Submit the Special Projects operation report from a secure terminal: Tong's archive, the compound office, Queen's Tower or the Wan Chai police station.", True);
	if (!GetF('UC_FinalReportRequested')) return;
	bOffscreenCall = True;
	s = Spawn(class'UCSceneSimonsAfterTong');
	if (s != None)
	{
		s.bTongDead = GetF('TracerTong_Dead');
		s.bFired = GetF('JCAttackedSpecialProjects');
	}
}

function Timer()
{
	local DeusExLevelInfo info;

	if (Plr() == None)
		return;
	if (mapName == "")
		foreach AllActors(class'DeusExLevelInfo', info)
			mapName = Caps(info.mapName);
	if (!bSetup)
	{
		bSetup = True;
		Setup();
	}
	if (mapName == MessengerMap())
		TickMessenger();
	else if (Left(mapName, 3) == "06_" && mapName != "06_HONGKONG_HELIBASE")
		SetF('UC_HK_MessengerDone', True);   // JC e' gia' altrove
	if (mapName == "06_HONGKONG_WANCHAI_UNDERWORLD")
	{
		TickForeshadow();
		TickEscort();
	}
	if (mapName == "06_HONGKONG_WANCHAI_STREET")
	{
		TickHologram();
		TickSpecialProjectsDoor();
	}
	Goals();
	SimonsCall();
	// laboratorio di Tong e assalto (HK-9/HK-10)
	if (mapName == "06_HONGKONG_TONGBASE" && !bTongScene)
	{
		bTongScene = True;
		Spawn(class'UCSceneTongLab');
	}
	AssaultOffscreen();
}

defaultproperties
{
     bHidden=True
}
