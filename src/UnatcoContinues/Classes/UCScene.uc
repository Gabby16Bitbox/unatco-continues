//=============================================================================
// UCScene - base di tutte le scene (eventi scriptati) della route UNATCO.
//
// Una scena e' un'Actor con uno stato "Playing" scritto come sequenza
// (Sleep, Say, FireTag...). REGOLA: nessun puntatore a Player/flags/finestre
// deve restare in variabili membro: ogni helper li prende, li usa e li lascia
// (altrimenti il cambio mappa manda in crash il motore).
//=============================================================================
class UCScene extends Actor
	abstract
	transient;

var bool bHistoryOnly;   // Say() scrive solo nella cronologia (vedi InfoStart)
var name openedDoors[16];  // porte gia' aperte dai PNG della scena (OpenDoorsNear)
var int numOpened;

function DeusExPlayer Plr()
{
	return DeusExPlayer(GetPlayerPawn());
}

// Le porte chiuse davanti a un PNG della scena si aprono (una volta, e restano aperte):
// anche quelle a chiave, che un PNG non sa aprire e davanti alle quali si incastrava.
// Le porte dell'appartamento di Paul nella mappa non sono segnate come porte (bIsDoor):
// per l'IA dei PNG erano muri, e Gunther restava davanti alla porta (provato con le foto
// automatiche). Qui vale ogni mover "da aprire": non le finestre (vetro, non frobbabili)
// ne' i passaggi segreti (non frobbabili). Viene anche segnato come porta, cosi' l'IA
// del gioco lo gestisce da sola se si richiude. Aprire in anticipo (raggio ampio) serve
// anche quando passano in fila: ognuno frobbava la porta (apri/chiudi) e l'anta girava
// loro addosso, e restavano a spingere e indietreggiare davanti al portone del 'Ton.
function OpenDoorsNear(ScriptedPawn sp, float radius)
{
	local DeusExMover m;
	local int i;
	local bool bDone;

	if (sp == None || !sp.bInWorld)
		return;
	foreach sp.RadiusActors(class'DeusExMover', m, radius)
	{
		if (!m.bFrobbable || m.bDestroyed || m.NumKeys < 2 || m.FragmentClass == class'GlassFragment')
			continue;
		m.bIsDoor = True;
		if (m.KeyNum != 0 || m.bInterpolating || numOpened >= ArrayCount(openedDoors))
			continue;
		bDone = False;
		for (i = 0; i < numOpened; i++)
			if (openedDoors[i] == m.Name)
				bDone = True;
		if (bDone)
			continue;
		openedDoors[numOpened] = m.Name;
		numOpened++;
		m.bLocked = False;
		// come fanno i PNG (ScriptedPawn.FrobDoor): un PNG apre qualsiasi porta con Frob
		m.Frob(sp, None);
	}
}

// True se JC sta guardando l'attore: nel campo visivo (circa 60 gradi dal centro) e
// senza muri in mezzo. Regola delle scene: un PNG si sposta o sparisce SOLO quando
// JC non lo vede (si ferma prima in un punto visibile e sensato).
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

// Anna Navarre e' morta sul 747 (missione 3). AnnaNavarre_Dead da solo non basta:
// M03PlayerKilledAnna lo mette l'InfoLink di Alex (DL_AlexShocked) quando Anna muore
// li', ed e' il flag che il gioco originale usa per il sospetto di Manderley e di
// Gunther. Una morte avvenuta altrove non attiva le varianti "Anna morta sul 747".
function bool Anna747()
{
	return GetF('AnnaNavarre_Dead') && GetF('M03PlayerKilledAnna');
}

// True mentre il giocatore e' in una conversazione (aspettare che finisca).
function bool Talking()
{
	local DeusExPlayer P;

	P = Plr();
	return (P != None && P.conPlay != None);
}

function SetF(Name flagName, bool value)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None && P.FlagBase != None)
		P.FlagBase.SetBool(flagName, value,, 99);
}

function bool GetF(Name flagName)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None && P.FlagBase != None)
		return P.FlagBase.GetBool(flagName);
	return False;
}

function string DisplayName(string bindName)
{
	switch (bindName)
	{
		case "AlexJacobson":   return "Alex Jacobson";
		case "AnnaNavarre":    return "Anna Navarre";
		case "GuntherHermann": return "Gunther Hermann";
		case "JCDenton":       return "JC Denton";
		case "JosephManderley":return "Joseph Manderley";
		case "PaulDenton":     return "Paul Denton";
		case "WaltonSimons":   return "Walton Simons";
	}
	return bindName;
}

// Mostra una battuta nella finestra InfoLink. Ritorna per quanti secondi tenerla.
function float Say(string bindName, string text)
{
	local DeusExPlayer P;
	local DeusExRootWindow root;
	local HUDInfoLinkDisplay win;
	local Sound snd;

	P = Plr();
	if (P == None)
		return 0;
	if (bHistoryOnly)
	{
		AddInfoHistory(P, bindName, text);
		return 0;
	}

	root = DeusExRootWindow(P.rootWindow);
	if (root == None || root.hud == None)
		return 0;

	win = root.hud.infolink;
	if (win == None)
		win = root.hud.CreateInfoLinkWindow();
	if (win == None)
		return 0;

	win.SetSpeaker(bindName, DisplayName(bindName));
	win.ShowPortrait();
	win.ClearScreen();
	win.DisplayText(text);

	// voce registrata (se c'e'): la battuta dura quanto l'audio
	snd = class'UCVoice'.static.Find(text, bindName, bindName != "JCDenton");
	if (snd != None)
	{
		P.PlaySound(snd, SLOT_Talk, 1.0);
		Log("UCVoice: InfoLink playback" @ snd @ "speaker=" $ bindName);
		return GetSoundDuration(snd) + 0.5;
	}
	return 2.0 + Len(text) * 0.045;
}

function HideInfo()
{
	local DeusExPlayer P;
	local DeusExRootWindow root;

	P = Plr();
	if (P == None)
		return;
	root = DeusExRootWindow(P.rootWindow);
	if (root != None && root.hud != None)
		root.hud.DestroyInfoLinkWindow();
}

function GoalNew(Name goalName, string text)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None)
		P.GoalAdd(goalName, text, True);
}

function GoalDone(Name goalName)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None)
		P.GoalCompleted(goalName);
}

function Msg(string text)
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None)
		P.ClientMessage(text);
}

// Fa scattare tutti gli attori della mappa con quel Tag. Ritorna quanti sono.
function int FireTag(Name tagName)
{
	local Actor A;
	local int n;

	foreach AllActors(class'Actor', A, tagName)
	{
		A.Trigger(Self, Plr());
		n++;
	}
	Log("UnatcoContinues: FireTag" @ tagName @ "->" @ n);
	return n;
}

// Scrive nel log chi ha quel Tag (per capire cosa fanno gli eventi vanilla).
function DumpTag(Name tagName)
{
	local Actor A;

	foreach AllActors(class'Actor', A, tagName)
		Log("UnatcoContinues: tag" @ tagName @ ":" @ string(A.Class) @ "@" @ int(A.Location.X) $ "," $ int(A.Location.Y) $ "," $ int(A.Location.Z) @ "event:" @ A.Event);
}

// Avvia una conversazione costruita con UCCon con il personaggio npc.
// La modalita' nativa include telecamere, blocco input e musica di conversazione.
// bForcePlay e' riservato al finale/intro: salta tutti questi sistemi.
function bool PlayConv(UCCon c, Actor npc)
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None || npc == None || c == None)
		return False;
	// StartConversation checks ConListItems even when passed an explicit con.
	c.AttachTo(npc);
	return P.StartConversation(npc, IM_Other, c.con, False, False);
}

// Come PlayConv, ma il PNG non entra nello stato di conversazione: continua a fare
// quello che stava facendo (camminare) mentre parla.
// NOTA sulle conversazioni "sentite" (prima persona, UCCon.Passive): il gioco le tronca
// appena JC e' a piu' di 300 unita' da chi le ha avviate, a meno che abbiano un raggio
// (DeusExPlayer.CheckActiveConversationRadius): dare sempre UCCon.Radius(...) largo.
// E non le fa partire se due PNG che si parlano sono a piu' di 300 unita' l'uno
// dall'altro (Conversation.CheckActorDistances): se sono lontani, le battute vanno
// "rivolte" a JCDenton, che e' escluso da quel controllo.
function bool PlayConvMoving(UCCon c, Actor npc)
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None || npc == None || c == None)
		return False;
	c.AttachTo(npc);
	return P.StartConversation(npc, IM_Other, c.con, True, False);
}

// Chi dice (o ascolta) una battuta viene messo dal gioco nello stato di conversazione
// fino alla fine dello scambio: sta fermo, girato verso l'interlocutore
// (ConPlayBase.AddConActor). Per chi deve tirare dritto mentre parla: se e' fermo dentro
// la conversazione indicata lo si rimette in cammino verso la sua meta. Va chiamata a
// ogni giro della scena finche' la conversazione dura.
function KeepWalking(ScriptedPawn sp, name conName)
{
	local DeusExPlayer P;

	P = Plr();
	if (sp == None || P == None || P.conPlay == None || P.conPlay.con == None || P.conPlay.con.conName != conName)
		return;
	if (sp.IsInState('FirstPersonConversation') && sp.OrderActor != None)
	{
		sp.bConversationEndedNormally = True;   // altrimenti uscire dallo stato annulla lo scambio
		sp.GotoState('GoingTo');
	}
}

// Suono "incoming transmission" dell'InfoLink.
function InfoSound()
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None)
		P.PlaySound(Sound'DeusExSounds.UserInterface.DataLinkStart', SLOT_None);
}

// --- InfoLink a senso unico ---------------------------------------------------
// Le battute dell'InfoLink, una per indice (0, 1, 2...; -1 = finito, 0 = saltata).
// Le scene con un InfoLink la ridefiniscono.
function float InfoLine(int i)
{
	return -1;
}

// Inizio di un InfoLink. Le scene sono transient: se JC cambia zona a meta', la scena
// sparisce. Come fa il gioco originale (DeusExPlayer.PreTravel ->
// DataLinkPlay.AbortAndSaveHistory) l'InfoLink vale allora come ascoltato: chi chiama
// segna il suo flag "fatto" e ne applica gli effetti PRIMA di InfoStart, e qui tutto il
// testo (InfoLine 0, 1, 2...) va subito nella cronologia delle conversazioni (Log).
// Cosi' non si ripete e si puo' rileggere.
function InfoStart(string ownerBind)
{
	local DeusExPlayer P;
	local ConHistory h;
	local DeusExLevelInfo info;
	local int i;

	InfoSound();
	P = Plr();
	if (P == None)
		return;
	h = P.CreateHistoryObject();
	if (h == None)
		return;
	h.conOwnerName = DisplayName(ownerBind);
	foreach AllActors(class'DeusExLevelInfo', info)
	{
		h.strLocation = info.MissionLocation;
		break;
	}
	h.strDescription = "";
	h.bInfoLink = True;
	h.firstEvent = None;
	h.lastEvent = None;
	h.next = P.conHistory;
	P.conHistory = h;
	bHistoryOnly = True;
	for (i = 0; i < 64; i++)
		if (InfoLine(i) < 0)
			break;
	bHistoryOnly = False;
}

function AddInfoHistory(DeusExPlayer P, string bindName, string text)
{
	local ConHistoryEvent ev;

	if (P.conHistory == None || text == "")
		return;
	ev = P.CreateHistoryEvent();
	if (ev == None)
		return;
	ev.conSpeaker = DisplayName(bindName);
	ev.speech = text;
	ev.soundID = -1;
	ev.next = None;
	P.conHistory.AddEvent(ev);
}

// Testo grande a macchina da scrivere (come l'inizio missione di Deus Ex).
function TitleCard(string line1, optional string line2, optional string line3)
{
	local DeusExPlayer P;
	local DeusExRootWindow root;

	P = Plr();
	if (P == None)
		return;
	root = DeusExRootWindow(P.rootWindow);
	if (root == None || root.hud == None || root.hud.startDisplay == None)
		return;

	root.hud.startDisplay.message = "";
	root.hud.startDisplay.charIndex = 0;
	root.hud.startDisplay.AddMessage(line1);
	root.hud.startDisplay.AddMessage(line2);
	root.hud.startDisplay.AddMessage(line3);
	root.hud.startDisplay.StartMessage();
}

function BlackHelicopter FindHeli()
{
	local BlackHelicopter heli;

	foreach AllActors(class'BlackHelicopter', heli)
		return heli;
	return None;
}

function UCCam FindCam()
{
	local UCCam cam;

	foreach AllActors(class'UCCam', cam)
		if (cam.Owner == Self && !cam.bDeleteMe)
			return cam;
	return None;
}

// Cutscene: la telecamera diventa cam, il giocatore sparisce e non si muove.
function CutsceneStart(vector camPos, Actor lookAt)
{
	local DeusExPlayer P;
	local DeusExRootWindow root;
	local UCCam cam;

	P = Plr();
	if (P == None)
		return;

	cam = Spawn(class'UCCam', Self,, camPos);
	if (cam != None && lookAt != None)
		cam.SetShot(camPos, lookAt.Location + vect(0,0,20));

	P.Velocity = vect(0,0,0);
	P.Acceleration = vect(0,0,0);
	P.SetPhysics(PHYS_None);
	P.SetCollision(False, False, False);
	P.bHidden = True;
	P.ViewTarget = cam;
	P.bBehindView = True;
	if (cam != None)
		cam.ApplyView(P);

	root = DeusExRootWindow(P.rootWindow);
	if (root != None && root.hud != None)
		root.hud.Hide();
}

// La telecamera continua a guardare l'attore (chiamare ad ogni passo).
function CamLookAt(Actor lookAt)
{
	local UCCam cam;

	cam = FindCam();
	if (cam != None && lookAt != None)
		cam.SetShot(cam.shotPosition, lookAt.Location + vect(0,0,20));
}

// Rimette tutto come prima (da chiamare PRIMA di cambiare mappa).
function CutsceneEnd()
{
	local DeusExPlayer P;
	local DeusExRootWindow root;
	local UCCam cam;

	P = Plr();
	if (P != None)
	{
		P.ViewTarget = None;
		P.bBehindView = False;
		P.bHidden = False;
		P.SetCollision(True, True, True);
		P.SetPhysics(PHYS_Walking);
		root = DeusExRootWindow(P.rootWindow);
		if (root != None && root.hud != None)
			root.hud.Show();
	}
	cam = FindCam();
	if (cam != None)
		cam.Destroy();
}

// Cambia mappa portando il giocatore in un punto preciso (vedi UCMod.DoArrival).
function TravelTo(string mapName, int arrival)
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	P.FlagBase.SetInt('UC_DbgArrival', arrival,, 99);
	Level.Game.SendPlayer(P, mapName);
}

// Le sottoclassi ridefiniscono questo stato con la loro sequenza.
state Playing
{
Begin:
	Destroy();
}

// NB: lo stato iniziale va dato con InitialState: un GotoState() in PostBeginPlay
// verrebbe annullato dal motore (SetInitialState viene chiamato dopo).
defaultproperties
{
     bHidden=True
     InitialState=Playing
}
