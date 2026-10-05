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
// UCMod lo crea nelle mappe 06 dopo la partenza da New York.
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
	if (mapName == "06_HONGKONG_WANCHAI_MARKET")
		SetupMessenger();
	else if (mapName == "06_HONGKONG_WANCHAI_UNDERWORLD")
	{
		SetF('MaxChenMeetingAvailable', True);
		SetupMax();
		SetupForeshadow();
		SetupEscort();
	}
	else if (mapName == "06_HONGKONG_WANCHAI_STREET")
	{
		SetupMaggie();
		SetupHologram();
		if (Tagged('UCSwordHook') == None)
			Spawn(class'UCSwordHook',, 'Sword_Triggers');
	}
	else if (mapName == "06_HONGKONG_WANCHAI_COMPOUND")
		SetupGordon();
}

// --- mercato: messaggero Red Arrow (facoltativo, sacrificabile) --------------
function vector MessengerSpot()
{
	return vect(-690, -1280, 48);
}

function SetupMessenger()
{
	local ScriptedPawn m;
	local UCCon c;

	// nel corridoio dell'ascensore merci, contro il muro nord a ~230 dalle porte,
	// girato verso l'ascensore: JC lo vede appena esce e per forza gli passa accanto
	m = Tagged('UCMessenger');
	if (m == None && !GetF('UC_MessengerPlaced'))
	{
		m = Place(class'TriadRedArrow', 'UCMessenger', "UCMessenger", MessengerSpot(), 35700);
		SetF('UC_MessengerPlaced', True);
	}
	else if (m != None && !GetF('UC_Messenger_Played') && VSize(m.Location - MessengerSpot()) > 60)
	{
		// versioni precedenti: era all'angolo del mercato o attaccato alle porte
		m.SetLocation(MessengerSpot());
		m.SetRotation(rot(0, 35700, 0));
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
	c.Line("UCMessenger", "JCDenton", "Someone who knows why you're here. Max Chen wants to see you at the Lucky Money.");
	c.Line("JCDenton", "UCMessenger", "Why?");
	c.Line("UCMessenger", "JCDenton", "Ask him.");
	c.SetFlag('RedArrowMessengerContacted', True);
	c.SetFlag('MaxChenMeetingAvailable', True);
	c.Done();
	c.AttachTo(m);
}

// Il messaggero non si muove: parla quando JC gli passa accanto (entro ~180, fuori
// dall'ascensore, niente muri in mezzo). Quando ha parlato, o non c'e' piu', o JC e' andato oltre, puo' chiamare Simons.
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
	if (P.conPlay != None || P.Location.X < -890 || VSize(P.Location - m.Location) > 180 || !m.LineOfSightTo(P))
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
	local ScriptedPawn max;
	local UCCon c;

	max = FindPawn('MaxChen');
	if (max == None || HasCon(max, 'UC_MaxMeet'))
		return;
	RemoveCon(max, 'MeetMaxChen');
	RemoveCon(max, 'Show_Chen');

	c = new(Level) class'UCCon';
	c.Begin('UC_MaxAfter', "MaxChen", False);
	c.Require('MaxChenConvinced', True);
	c.Line("MaxChen", "JCDenton", "I have called Gordon Quick. The Red Arrow will keep the truce. He is expecting you at the compound.");
	c.Done();
	c.AttachTo(max);

	// con la prova (anche come primo incontro)
	c = new(Level) class'UCCon';
	c.Begin('UC_MaxEvidence', "MaxChen", False);
	c.Once();
	c.Radius(190);
	c.Require('Have_Evidence', True);
	c.Require('MaxChenConvinced', False);
	c.Line("MaxChen", "JCDenton", "Miss Chow had the Dragon's Tooth?");
	c.Line("JCDenton", "MaxChen", "Yes.");
	c.Line("MaxChen", "JCDenton", "Then Yuen Kong was right to suspect her. He went to Queen's Tower because he believed Miss Chow was arranging the attacks that kept the Red Arrow and the Luminous Path at war. He never came back.");
	c.Line("JCDenton", "MaxChen", "That's evidence of deception. Not murder.");
	c.Line("MaxChen", "JCDenton", "You are careful with words.");
	c.Line("JCDenton", "MaxChen", "Words are what you have until you get proof.");
	c.Line("MaxChen", "JCDenton", "Hmmm. Perhaps. But if Miss Chow had the sword, the reason for this war is gone. I will call Gordon Quick.");
	c.Line("JCDenton", "MaxChen", "Do it.");
	c.Line("MaxChen", "JCDenton", "There is something I do not understand. You work for UNATCO. Miss Chow works with your people. Yet you bring me evidence against her.");
	c.Line("JCDenton", "MaxChen", "I work for UNATCO. Not Maggie Chow.");
	c.Line("MaxChen", "JCDenton", "Is there a difference?");
	c.Line("JCDenton", "MaxChen", "There should be.");
	c.SetFlag('MeetMaxChen_Played', True);
	c.SetFlag('MadeChenAccusation', True);
	c.SetFlag('MaxChenConvinced', True);
	c.Done();
	c.AttachTo(max);

	c = new(Level) class'UCCon';
	c.Begin('UC_MaxMeet', "MaxChen", False);
	c.Once();
	c.Radius(190);
	c.Require('Have_Evidence', False);
	// E' Max che ha mandato a chiamare JC (messaggero al mercato, accompagnatore alla
	// porta): parla per primo e dice perche'. Voleva vederlo prima di Maggie Chow.
	c.Line("MaxChen", "JCDenton", "Mr. Denton. I wanted to see you before the others do.");
	c.Line("JCDenton", "MaxChen", "What others?");
	c.Line("MaxChen", "JCDenton", "A UNATCO agent arrives in Hong Kong looking for Tracer Tong. Many people will want to tell him where to look.");
	c.Line("JCDenton", "MaxChen", "And you?");
	c.Line("MaxChen", "JCDenton", "I will tell you where not to look. This is the headquarters of the Red Arrow Triad. Mr. Tong works with the Luminous Path.");
	c.Line("JCDenton", "MaxChen", "And Maggie Chow?");
	c.Line("MaxChen", "JCDenton", "Miss Chow has interests everywhere. The Red Arrow, VersaLife, the police... perhaps even UNATCO.");
	c.Line("JCDenton", "MaxChen", "She knows I'm coming.");
	c.Line("MaxChen", "JCDenton", "Yes. That is why I sent for you first.");
	c.SetFlag('MeetMaxChen_Played', True);
	c.SetFlag('KnowsAboutTriads', True);
	c.Done();
	c.AttachTo(max);
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
			c.Line("UCLMAgent1", "UCLMRedArrow", "The shipment was received. Chen accepted the money.");
			c.Line("UCLMRedArrow", "UCLMAgent1", "Max never asked for the shipment.");
			c.Line("UCLMAgent2", "UCLMRedArrow", "He accepted the money.");
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
	local ScriptedPawn maggie;
	local UCCon c;

	maggie = RealMaggie();
	if (maggie == None || HasCon(maggie, 'UC_MaggieMeet'))
		return;
	RemoveCon(maggie, 'MeetMaggie');
	RemoveCon(maggie, 'MeetMaggie2');
	RemoveCon(maggie, 'MaggieBarks');

	c = new(Level) class'UCCon';
	c.Begin('UC_MaggieAgain', "MaggieChow", False);
	c.Require('UC_MaggieMeet_Played', True);
	c.Line("MaggieChow", "JCDenton", "Find the Dragon's Tooth, Mr. Denton, and you may find the path to Tong with it.");
	c.Done();
	c.AttachTo(maggie);

	c = new(Level) class'UCCon';
	c.Begin('UC_MaggieMeet', "MaggieChow", False);
	c.Once();
	c.Radius(120);
	c.Line("MaggieChow", "JCDenton", "Mr. J. C. Denton... in the flesh. As dark and serious as his brother.");
	c.Line("JCDenton", "MaggieChow", "You knew him?");
	c.Line("MaggieChow", "JCDenton", "Everyone who dealt seriously with Tracer Tong knew Paul eventually. He spent a great deal of time in Hong Kong before UNATCO realized where his loyalties had shifted.");
	c.Line("JCDenton", "MaggieChow", "That's not what I asked.");
	c.Line("MaggieChow", "JCDenton", "Yes. I knew him.");
	// la sua versione dei fatti
	c.Line("MaggieChow", "JCDenton", "Paul came here looking for evidence that UNATCO was conspiring against him. Tong gave him exactly what he wanted to hear. That's what Tong does.");
	c.Line("MaggieChow", "JCDenton", "He finds intelligent people who already distrust authority and convinces them that only he understands the truth.");
	c.Line("JCDenton", "MaggieChow", "Paul didn't need much encouragement.");
	c.Line("MaggieChow", "JCDenton", "Perhaps not. But Tong gave him contacts, protection and a cause. Look at the result. Your brother abandoned his career, his friends and his own government.");
	c.Line("JCDenton", "MaggieChow", "What does that have to do with the Triads?");
	c.Line("MaggieChow", "JCDenton", "Everything. The Red Arrow and Luminous Path were once capable of doing business together. Since Tong became involved, every disagreement has become ideological.");
	c.Line("MaggieChow", "JCDenton", "Weapons disappear, shipments are attacked, people die, and Tong remains safely hidden while everyone else pays the price.");
	// il Dragon's Tooth (chi non ha incontrato Max ha il nome da Simons)
	c.IfFlag('MeetMaxChen_Played', True, "MaxMet");
	c.Line("JCDenton", "MaggieChow", "Simons says you have contacts with both sides.");
	c.Jump("Sword");
	c.Label("MaxMet");
	c.Line("JCDenton", "MaggieChow", "Max Chen says you have contacts with both sides.");
	c.Label("Sword");
	c.Line("MaggieChow", "JCDenton", "I try to keep this city from destroying itself. Unfortunately, the Luminous Path recently stole something that has made reconciliation almost impossible: a prototype weapon known as the Dragon's Tooth.");
	c.Line("JCDenton", "MaggieChow", "Why would they steal it?");
	c.Line("MaggieChow", "JCDenton", "Power. Prestige. Leverage against Red Arrow. Pick whichever motive you prefer; they're all true.");
	c.Line("JCDenton", "MaggieChow", "And you want it recovered.");
	c.Line("MaggieChow", "JCDenton", "I want the Triads talking again. If you find the weapon, you may find the path to Tong with it.");
	c.SetFlag('MeetMaggie_Played', True);
	c.SetFlag('KnowsAboutMaggie', True);
	c.SetFlag('KnowsAboutTriads', True);
	c.SetFlag('FoundMaggieChow', True);
	c.Trigger('MaggieWanders');
	c.Done();
	c.AttachTo(maggie);
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
	c.Line("WaltonSimons", "UCMaggieHolo", "Ms. Chow. Denton should be arriving shortly. He's still following UNATCO orders, which makes him useful.");
	c.Line("UCMaggieHolo", "WaltonSimons", "And if Paul changed his mind?");
	c.Line("WaltonSimons", "UCMaggieHolo", "He didn't. Paul made the mistake of confronting his brother before Denton had seen enough evidence to doubt the institution.");
	c.Line("UCMaggieHolo", "WaltonSimons", "You're very confident.");
	c.Line("WaltonSimons", "UCMaggieHolo", "Denton believes in procedure. Give him a procedure to follow.");
	c.Line("UCMaggieHolo", "WaltonSimons", "And Tong?");
	c.Line("WaltonSimons", "UCMaggieHolo", "If Denton gets close enough, we'll know where to look.");
	c.Line("JCDenton", "WaltonSimons", "Simons...");
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
	local ScriptedPawn gordon;
	local UCCon c;

	gordon = FindPawn('GordonQuick');
	if (gordon == None || HasCon(gordon, 'UC_GordonMeet'))
		return;
	RemoveCon(gordon, 'Gate_Guard2');
	RemoveCon(gordon, 'ConvinceQuick');
	RemoveCon(gordon, 'QuickAfterMaggie');
	RemoveCon(gordon, 'QuickFinalTalk');
	RemoveCon(gordon, 'QuickWaiting');
	RemoveCon(gordon, 'QuickWaiting_1_5');

	c = new(Level) class'UCCon';
	c.Begin('UC_GordonWait', "GordonQuick", False);
	c.Require('UC_GordonMeet_Played', True);
	c.Require('Have_Evidence', False);
	c.Line("GordonQuick", "JCDenton", "Ask Maggie Chow who killed Yuen Kong, Agent Denton.");
	c.Done();
	c.AttachTo(gordon);

	// dopo la tregua: il permesso
	c = new(Level) class'UCCon';
	c.Begin('UC_GordonFinal', "GordonQuick", False);
	c.Once();
	c.Radius(180);
	c.Require('MaxChenConvinced', True);
	c.Require('QuickLetPlayerIn', False);
	c.Line("GordonQuick", "JCDenton", "You stopped a war you could have used to weaken both Triads. I did not expect that from UNATCO.");
	c.Line("JCDenton", "GordonQuick", "Dead Triads don't tell me where Tong is.");
	c.Line("GordonQuick", "JCDenton", "Maybe that is all it is.");
	c.Line("JCDenton", "GordonQuick", "Does it matter?");
	c.Line("GordonQuick", "JCDenton", "To Tong, yes.");
	c.Line("GordonQuick", "JCDenton", "You have shown that you are willing to follow evidence even when it embarrasses your own contacts. Tong has agreed to speak with you.");
	c.Line("JCDenton", "GordonQuick", "I didn't ask to speak with him.");
	c.Line("GordonQuick", "JCDenton", "No. You came here to arrest him.");
	c.Line("GordonQuick", "JCDenton", "Nineteen ninety-seven. The door in our sparring room. Keep your weapon down until someone gives you a reason not to.");
	c.Line("JCDenton", "GordonQuick", "Good advice.");
	c.SetFlag('Gate_Guard2_Played', True);
	c.SetFlag('QuickConvinced', True);
	c.SetFlag('QuickLetPlayerIn', True);
	c.Done();
	c.AttachTo(gordon);

	// con la prova, prima della tregua
	c = new(Level) class'UCCon';
	c.Begin('UC_GordonEvidence', "GordonQuick", False);
	c.Once();
	c.Require('Have_Evidence', True);
	c.Require('MaxChenConvinced', False);
	c.Line("JCDenton", "GordonQuick", "Maggie Chow had the Dragon's Tooth.");
	c.Line("GordonQuick", "JCDenton", "Then you know who killed Yuen Kong.");
	c.Line("JCDenton", "GordonQuick", "I know who had his sword.");
	c.Line("GordonQuick", "JCDenton", "Show it to Max Chen. If he still wants war after that, nothing will stop it.");
	c.SetFlag('Gate_Guard2_Played', True);
	c.SetFlag('QuickConvinced', True);
	c.Done();
	c.AttachTo(gordon);

	// primo incontro al cancello: ostile a parole, non attacca
	c = new(Level) class'UCCon';
	c.Begin('UC_GordonMeet', "GordonQuick", False);
	c.Once();
	c.Radius(180);
	c.Require('MaxChenConvinced', False);
	c.Line("GordonQuick", "JCDenton", "Paul Denton trusted you.");
	c.Line("JCDenton", "GordonQuick", "Paul made a mistake.");
	c.Line("GordonQuick", "JCDenton", "Which one?");
	c.Line("JCDenton", "GordonQuick", "Choosing terrorists over UNATCO.");
	c.Line("GordonQuick", "JCDenton", "No. Trusting his brother.");
	c.Line("GordonQuick", "JCDenton", "Paul worked with us. He took risks for people here, and he earned our confidence. You arrive with a UNATCO badge and orders to find Tong. Don't expect the same treatment.");
	c.Line("JCDenton", "GordonQuick", "I don't need your trust. I need Tong.");
	c.Line("GordonQuick", "JCDenton", "Then you need information, and information has a price.");
	c.Line("JCDenton", "GordonQuick", "What's yours?");
	c.Line("GordonQuick", "JCDenton", "Ask Maggie Chow who killed Yuen Kong.");
	c.Line("JCDenton", "GordonQuick", "Why don't you tell me?");
	c.Line("GordonQuick", "JCDenton", "Because you wouldn't believe me.");
	c.SetFlag('Gate_Guard2_Played', True);
	c.SetFlag('KnowsAboutMaggie', True);
	c.SetFlag('KnowsAboutNanoSword', True);
	c.Done();
	c.AttachTo(gordon);
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
		Goal('UCMeetMaxChen', "Optional: Max Chen of the Red Arrow Triad wants to see you at the Lucky Money club.", False);
	if (GetF('MeetMaxChen_Played'))
		GoalDone('UCMeetMaxChen');

	// Maggie (o Gordon, se Maggie non c'e'): il Luminous Path protegge Tong
	if (GetF('UC_MaggieMeet_Played') || GetF('UC_GordonMeet_Played') || GetF('MaggieChow_Dead'))
	{
		Goal('UCInvestigateLumPath', "Investigate the Luminous Path. Gordon Quick will not let a UNATCO agent into their compound: you will have to earn his trust.", False);
		Goal('UCYuenKong', "Optional: investigate the death of Red Arrow leader Yuen Kong.", False);
	}
	if (GetF('UC_MaggieMeet_Played') || GetF('MaggieChow_Dead'))
		GoalDone('ContactMaggieChow');

	// il Dragon's Tooth era da Maggie
	if (GetF('Have_Evidence'))
	{
		GoalDone('UCYuenKong');
		if (!GetF('MaxChenConvinced'))
			Goal('UCShowMaxChen', "Show Max Chen what you found: the Dragon's Tooth was in Maggie Chow's apartment.", True);
	}
	// la tregua
	if (GetF('MaxChenConvinced'))
	{
		GoalDone('UCShowMaxChen');
		if (!GetF('QuickLetPlayerIn'))
			Goal('UCTellGordon', "Max Chen has declared a truce and called Gordon Quick. Go to the Luminous Path compound.", True);
	}
	if (GetF('QuickLetPlayerIn'))
	{
		GoalDone('UCTellGordon');
		GoalDone('UCInvestigateLumPath');
		Note('UC_NoteTongLab', "Tracer Tong's laboratory is beneath the Luminous Path compound. The door is in the sparring room: code 1997.");
	}
}

// Dragon's Tooth: il rapporto di JC parte da solo (nessuna battuta) quando esce dalla
// stanza segreta di Queen's Tower, poi Simons risponde (UCSceneSimonsSword).
//  - registrazione vista: appena JC si allontana (400) da dove era quando l'ha vista
//    finire (o dalla teca, se ha preso la spada dopo);
//  - non vista: quando lascia l'appartamento (lontano dalla teca o sceso con
//    l'ascensore) o la mappa: fino ad allora puo' ancora vederla.
function SimonsCall()
{
	local UCSceneSimonsSword s;
	local DeusExPlayer P;
	local bool bHolo;

	P = Plr();
	if (bSimonsCall || GetF('UC_SimonsSwordCall') || !GetF('Have_Evidence') || P == None || P.conPlay != None)
		return;
	SetF('DragonToothEvidenceFound', True);
	bHolo = GetF('M06WaltonHolo_Played');
	if (mapName == "06_HONGKONG_WANCHAI_STREET")
	{
		if (bHolo)
		{
			if (!bHoloSpot)
			{
				bHoloSpot = True;
				holoSpot = P.Location;
			}
			if (VSize(P.Location - holoSpot) < 400)
				return;
		}
		else if (VSize((P.Location - vect(-1858, -159, 2052)) * vect(1,1,0)) < 1500 && Abs(P.Location.Z - 2052) < 600)
			return;
	}
	bSimonsCall = True;
	s = Spawn(class'UCSceneSimonsSword');
	if (s != None)
		s.bRecording = bHolo;
}

// JC ha lasciato la base di Tong durante l'assalto: l'operazione si chiude fuori scena
// e Simons lo chiama dove si trova. La storia non si blocca.
function AssaultOffscreen()
{
	local UCSceneSimonsAfterTong s;
	local DeusExPlayer P;

	P = Plr();
	if (bOffscreenCall || P == None || P.conPlay != None || !GetF('MJ12AssaultStarted') || GetF('MJ12AssaultResolved')
		|| GetF('UC_SimonsAfterTong') || mapName == "06_HONGKONG_TONGBASE")
		return;
	bOffscreenCall = True;
	SetF('MJ12AssaultResolvesOffscreen', True);
	SetF('TongEscapedCompound', True);
	SetF('TongLocationUnknown', True);
	class'UCSceneTongLab'.static.AddFragment(P);
	s = Spawn(class'UCSceneSimonsAfterTong');
	if (s != None)
		s.bFired = GetF('JCAttackedSpecialProjects');
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
	if (mapName == "06_HONGKONG_WANCHAI_MARKET")
		TickMessenger();
	else if (Left(mapName, 3) == "06_" && mapName != "06_HONGKONG_HELIBASE")
		SetF('UC_HK_MessengerDone', True);   // JC e' gia' altrove
	if (mapName == "06_HONGKONG_WANCHAI_UNDERWORLD")
	{
		TickForeshadow();
		TickEscort();
	}
	if (mapName == "06_HONGKONG_WANCHAI_STREET")
		TickHologram();
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
