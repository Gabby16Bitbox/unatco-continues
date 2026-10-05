//=============================================================================
// UCSceneGuntherTon - Hell's Kitchen, davanti al 'Ton (route UNATCO, dopo Paul).
// Gunther e due Special Agents aspettano sul marciapiede, ai piedi della scalinata
// (non salgono incontro a JC). Il dialogo parte solo quando JC scende e gli passa
// vicino; poi i tre salgono ed entrano nell'hotel IN FILA INDIANA, sempre dalla
// stessa corsia della scalinata, a qualche secondo l'uno dall'altro (prima si
// compenetravano sui gradini).
// Il portone in cima alla scalinata si apre quando il primo arriva in cima e resta
// aperto (prima ognuno lo frobbava, l'anta girava loro addosso e restavano ~15 s a
// spingere e indietreggiare; provato con le foto automatiche, UCDbgGuntherStreet).
// Arrivati alla porta dell'hotel si fermano li', in vista, ed entrano (spariscono) solo
// quando JC non li guarda: dentro l'hotel JC li ritrova appena oltre l'ingresso
// (UCSceneGuntherSearch). Regola delle scene: nessuno sparisce sotto gli occhi di JC.
// Chi esce dalla finestra (o si allontana) evita la scena: Gunther entra lo stesso.
// I due agenti sono MIB presentati come "Special Agent" (niente MJ12 per ora).
// Dialogo: specifica "Dialoghi e varianti" del 4 ott 2026, con le correzioni di stile
// di docs\DIALOGHI_STILE.md. Gunther accetta che JC sia ancora con UNATCO ma non che
// abbia lasciato Paul libero; minaccia un rapporto a Manderley (flag
// GuntherReportedJCConduct: nota per un debriefing futuro, non toglie niente a JC).
//  - G01 (Anna viva, o morte non avvenuta sul 747): finisce su "Get out of the way.";
//    Gunther si avvia e, mentre cammina, JC: "Bring him in alive." / Gunther: "You had
//    your chance." (senza telecamera, si sente solo se JC e' vicino);
//  - G02 (Anna morta sul 747, UCScene.Anna747): piu' duro, sospetta ma non ha prove
//    contro JC ("I do not forget the airfield."); niente scambio durante la salita.
// Conoscenze: GuntherKnowsJCMetPaul lo mette la battuta in cui JC ammette di aver parlato
// con Paul; a fine dialogo la squadra trasmette il rapporto (UC_PaulContactReportSent),
// che Anna alla metro riceve senza aspettare la fine della perquisizione.
//=============================================================================
class UCSceneGuntherTon extends UCScene;

var float walkT;
var bool bIn0, bIn1, bIn2;
var int wp[3];          // tappa del percorso per Gunther, agente 2, agente 1 (0 = fermo, 6 = alla porta)
var bool bMet;          // il dialogo davanti all'hotel c'e' stato (non evitato dalla finestra)
var bool bAliveDone;    // scambio "Bring him in alive." gia' fatto (o saltato)

function ScriptedPawn Tagged(name tagName, optional string bindName)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp, tagName)
		if (bindName == "" || sp.BindName == bindName)
			return sp;
	return None;
}

function ScriptedPawn Gunther()
{
	return Tagged('UCGunther');
}

function ScriptedPawn Agent(int i)
{
	return Tagged('UCSpecialAgent', "UCSpecialAgent" $ i);
}

function ScriptedPawn Place(class<ScriptedPawn> cls, name tagName, string bindName, vector spot, int yaw)
{
	local ScriptedPawn sp;
	local rotator r;

	r.Yaw = yaw;
	sp = Spawn(cls,, tagName, spot, r);
	if (sp == None)
		sp = Spawn(cls,, tagName, spot + vect(0,0,20), r);
	if (sp == None)
		return None;
	sp.BindName = bindName;
	sp.ConBindEvents();
	sp.ChangeAlly('Player', 1.0, False);
	sp.SetOrders('Standing', '', True);
	if (sp.IsA('MIB'))
	{
		sp.FamiliarName = "Special Agent";
		sp.UnfamiliarName = "Special Agent";
		// stesso passo di Gunther (i MIB camminano molto piu' lenti)
		sp.GroundSpeed = 210;
		sp.WalkingSpeed = 0.35;
	}
	return sp;
}

// Sul marciapiede ai piedi della scalinata del 'Ton, girati verso l'hotel.
function SetupActors()
{
	local ScriptedPawn g;
	local UCCon c;

	g = Gunther();
	if (g == None)
		g = Place(class'GuntherHermann', 'UCGunther', "GuntherHermann", vect(1330, 897, -456), 32768);
	if (Agent(1) == None)
		Place(class'MIB', 'UCSpecialAgent', "UCSpecialAgent1", vect(1425, 828, -456), 30400);
	if (Agent(2) == None)
		Place(class'MIB', 'UCSpecialAgent', "UCSpecialAgent2", vect(1445, 975, -456), 35900);
	if (g == None || HasCon(g, 'UC_GuntherTon1'))
		return;

	// parte quando JC scende in strada e gli passa vicino
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherTon1', "GuntherHermann", False);
	c.Once();
	c.Radius(250);
	if (Anna747())
	{
		// G02: nessun saluto; la morte di Anna rende il tono piu' duro ma non e' una prova
		c.Line("GuntherHermann", "JCDenton", "Denton. Agent Navarre is dead. Your brother has betrayed UNATCO. And now I find you leaving his hotel.");
		c.Line("JCDenton", "GuntherHermann", "He asked me to join him. I refused.");
		c.SetFlag('GuntherKnowsJCMetPaul', True);
		c.Line("GuntherHermann", "JCDenton", "But you did not arrest him.");
		c.Line("JCDenton", "GuntherHermann", "I'm not stopping you.");
		c.Line("GuntherHermann", "JCDenton", "Manderley will hear about this. I do not forget the airfield.");
		c.Line("JCDenton", "GuntherHermann", "Bring Paul in alive.");
		c.Line("GuntherHermann", "JCDenton", "Get out of the way.");
	}
	else
	{
		// G01
		c.Line("GuntherHermann", "JCDenton", "Denton. You should be on your way to Hong Kong. Did you see Paul?");
		c.Line("JCDenton", "GuntherHermann", "I spoke to him.");
		c.SetFlag('GuntherKnowsJCMetPaul', True);
		c.Line("GuntherHermann", "JCDenton", "He is wanted by UNATCO. Why is he not in custody?");
		// JC risponde sulla lealta', non sull'arresto: Gunther se ne accorge e insiste
		c.Line("JCDenton", "GuntherHermann", "He tried to recruit me. I turned him down.");
		c.Line("GuntherHermann", "JCDenton", "And then you left him here.");
		c.Line("JCDenton", "GuntherHermann", "I'm not stopping you.");
		c.Line("GuntherHermann", "JCDenton", "Manderley will hear about this. Get out of the way.");
	}
	c.SetFlag('GuntherReportedJCConduct', True);
	c.SetFlag('SpecialAgentsSeenAtTon', True);
	c.SetFlag('UC_PaulContactReportSent', True);
	c.SetFlag('GuntherTonEncounterPlayed', True);
	c.Done();
	c.AttachTo(g);
}

function bool HasCon(Actor A, name conName)
{
	local ConListItem item;

	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
			return True;
	return False;
}

// Gunther si e' gia' avviato verso l'ingresso: JC gli chiede di prenderlo vivo, lui
// risponde senza fermarsi. Niente telecamera (scorre da sola); solo se JC e' vicino.
function bool AliveLine()
{
	local UCCon c;
	local DeusExPlayer P;

	P = Plr();
	if (P == None || Gunther() == None || P.conPlay != None)
		return False;
	if (VSize(P.Location - Gunther().Location) > 700)
		return True;   // JC si e' allontanato: niente scambio
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherTon2', "GuntherHermann", True);
	c.Once();
	c.Passive();
	c.Radius(1200);   // Gunther si allontana mentre parla: senza raggio il gioco la tronca
	c.Line("JCDenton", "GuntherHermann", "Bring him in alive.");
	c.Line("GuntherHermann", "JCDenton", "You had your chance.");
	c.Done();
	PlayConvMoving(c, Gunther());
	return True;
}

// --- l'ingresso in fila indiana -------------------------------------------------
// Corsia nord della scalinata (lungo i PathNode della mappa), il portico, la porta
// nord del doppio portone, fino alla porta dell'hotel.
function vector WalkPoint(int i)
{
	switch (i)
	{
		case 1: return vect(1232, 960, -456);   // ai piedi della scalinata
		case 2: return vect(1040, 960, -344);   // in cima
		case 3: return vect(828, 943, -344);    // portico
		case 4: return vect(656, 944, -344);    // oltre il portone
	}
	return vect(440, 897, -344);                // la porta dell'hotel
}

function name WalkTag(int i)
{
	switch (i)
	{
		case 1: return 'UCTonW1';
		case 2: return 'UCTonW2';
		case 3: return 'UCTonW3';
		case 4: return 'UCTonW4';
	}
	return 'UCTonDoor';
}

function ScriptedPawn Walker(int k)
{
	if (k == 0)
		return Gunther();
	if (k == 1)
		return Agent(2);
	return Agent(1);
}

function SetupWalk()
{
	local int i;

	for (i = 1; i <= 5; i++)
		Spawn(class'UCMark',, WalkTag(i), WalkPoint(i));
	wp[0] = 0;
	wp[1] = 0;
	wp[2] = 0;
	walkT = 0;
	if (Gunther() != None)
		Gunther().SetOrders('Standing', '', True);
}

// Un passo del percorso per il k-esimo della fila. Ritorna True quando e' entrato.
function bool WalkStep(int k)
{
	local ScriptedPawn sp;
	local vector d;

	sp = Walker(k);
	if (sp == None || !sp.bInWorld || sp.Health <= 0)
		return True;
	// alla porta: fermo, entra appena JC non lo guarda
	if (wp[k] == 6)
	{
		if (SeenByJC(sp))
			return False;
		sp.LeaveWorld();
		return True;
	}
	// partono a distanza: ognuno quasi due secondi dopo quello davanti
	if (wp[k] == 0)
	{
		if (walkT >= k * 1.8)
		{
			wp[k] = 1;
			sp.SetOrders('GoingTo', WalkTag(1), True);
		}
		return False;
	}
	d = sp.Location - WalkPoint(wp[k]);
	if (VSize(d * vect(1,1,0)) < 70 && Abs(d.Z) < 90)
	{
		if (wp[k] >= 5)
		{
			wp[k] = 6;   // alla porta dell'hotel: si ferma, girato verso la porta
			sp.SetOrders('Standing', '', True);
			sp.DesiredRotation = rot(0, 32768, 0);
			return False;
		}
		wp[k]++;
		sp.SetOrders('GoingTo', WalkTag(wp[k]), True);
	}
	// incastrato: entra quando JC non lo vede
	if (walkT > 45 + k * 2 && !SeenByJC(sp))
	{
		sp.LeaveWorld();
		return True;
	}
	return False;
}

// Salvataggi di una versione precedente: Gunther era sul portico o correva verso JC.
function MoveToStart()
{
	local ScriptedPawn g;
	local DeusExPlayer P;

	g = Gunther();
	P = Plr();
	if (g == None || GetF('UC_GuntherTon1_Played'))
		return;
	g.SetOrders('Standing', '', True);
	if (Agent(1) != None)
		Agent(1).SetOrders('Standing', '', True);
	if (Agent(2) != None)
		Agent(2).SetOrders('Standing', '', True);
	if ((P != None && P.LineOfSightTo(g)) || VSize(g.Location - vect(1330, 897, -456)) < 80)
		return;
	g.SetLocation(vect(1330, 897, -456));
	g.SetRotation(rot(0, 32768, 0));
	if (Agent(1) != None)
		Agent(1).SetLocation(vect(1425, 828, -456));
	if (Agent(2) != None)
		Agent(2).SetLocation(vect(1445, 975, -456));
}

function bool PlayerFar()
{
	local DeusExPlayer P;
	local ScriptedPawn g;

	P = Plr();
	g = Gunther();
	return (P != None && g != None && VSize(P.Location - g.Location) > 1700);
}

function Cleanup()
{
	local UCMark mark;

	foreach AllActors(class'UCMark', mark)
		if (Left(string(mark.Tag), 5) == "UCTon" || mark.Tag == 'UCRearExit' || mark.Tag == 'UCGuntherMeet'
			|| mark.Tag == 'UCAgentMeet1' || mark.Tag == 'UCAgentMeet2')
			mark.Destroy();
}

state Playing
{
Begin:
	Sleep(0.2);
	SetupActors();
	MoveToStart();
	Cleanup();   // segni delle versioni precedenti (corsa incontro a JC)
WaitMeet:
	SetupActors();   // se il gioco ha rifatto la lista delle conversazioni, il dialogo si riattacca
	// JC si e' allontanato senza passare davanti a Gunther (es. dalla finestra)
	if (!GetF('UC_GuntherTon1_Played') && PlayerFar())
	{
		SetF('GuntherTonSkipped', True);
		Goto('Leave');
	}
	if (!GetF('UC_GuntherTon1_Played') || Talking())
	{
		Sleep(0.25);
		Goto('WaitMeet');
	}
	SetF('GuntherTonEncounterPlayed', True);
	SetF('GuntherTonSearchStarted', True);
	bMet = True;
	bAliveDone = Anna747();   // in G02 "Bring Paul in alive." e' gia' nel dialogo
Leave:
	SetupWalk();
Going:
	// il portone in cima alla scalinata si apre quando il primo arriva in cima
	OpenDoorsNear(Gunther(), 400);
	OpenDoorsNear(Agent(1), 400);
	OpenDoorsNear(Agent(2), 400);
	bIn0 = WalkStep(0);
	bIn1 = WalkStep(1);
	bIn2 = WalkStep(2);
	if (bMet && !bAliveDone && walkT >= 1.25)
		bAliveDone = AliveLine();
	KeepWalking(Gunther(), 'UC_GuntherTon2');   // risponde senza fermarsi
	if (!bIn0 || !bIn1 || !bIn2)
	{
		Sleep(0.25);
		walkT += 0.25;
		Goto('Going');
	}
	Cleanup();
	Destroy();
}

defaultproperties
{
}
