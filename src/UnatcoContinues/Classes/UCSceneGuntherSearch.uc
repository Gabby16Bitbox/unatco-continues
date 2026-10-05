//=============================================================================
// UCSceneGuntherSearch - 'Ton, contenuto facoltativo: Gunther e i due Special Agents
// dentro l'hotel, dopo l'incontro davanti all'ingresso (o dopo che JC lo ha evitato
// uscendo dalla finestra). Paul e' gia' sparito (vedi UCMod.InitRoute).
// Copione: specifica "Dialoghi e varianti" del 4 ott 2026 (blocchi G03-G17), con le
// correzioni di stile di docs\DIALOGHI_STILE.md.
//  - G03 lobby: Gilbert protesta, Gunther tira dritto verso le scale, l'Agente 02 resta
//    nella lobby (si sente solo se JC e' li'; senza Gilbert si salta);
//  - l'Agente 02 si ferma davanti al bancone, da Gilbert, e i due si scambiano due
//    battute quando JC passa li' vicino (una volta; richiesta di Gabby del 4 ott 2026);
//  - Gunther e l'Agente 01 vanno DRITTI alla camera di Paul, in fila; le porte chiuse
//    davanti a loro si aprono (UCScene.OpenDoorsNear);
//  - G05: durante la salita, a chi lo ferma Gunther risponde solo "Not now, Denton."
//    (con una pausa prima di poterlo ripetere). Niente battute fra se' sulle scale;
//  - G06 camera vuota: "We came too late.", l'Agente 01 fa rapporto a Simons ed esce
//    davvero (si sente quando JC arriva);
//  - a ricerca finita gli approfondimenti partono SOLO se JC parla con Gunther, uno per
//    clic, in quest'ordine: G10 (rimprovero) oppure G07 se l'incontro fuori e' stato
//    saltato (Gunther non sa ancora che JC ha parlato con Paul: glielo chiede), G11,
//    G12, G13, G14 (oppure G16 se Anna e' morta sul 747 e JC ha gia' fatto rapporto a
//    Manderley), G15, poi la battuta di ripetizione G17.
// Conoscenze: Gunther rimprovera JC per Paul solo se JC gli ha detto di averlo visto
// (flag GuntherKnowsJCMetPaul, messo dalla battuta di JC, fuori o in G07).
// Rientrando a ricerca finita la scena non si rigioca: Gunther e' dove era rimasto e
// gli approfondimenti vengono solo riattaccati (le conversazioni non si salvano).
// Nessuna informazione necessaria per andare avanti esiste solo qui.
//=============================================================================
class UCSceneGuntherSearch extends UCScene;

var float t;
var float notNowT;         // pausa di "Not now, Denton."
var bool bLobbyDone;       // scambio con Gilbert gia' fatto (o saltato)
var bool bLobbyPost;       // l'Agente 02 e' al suo posto nella lobby
var int lobbyStage;        // 0 = va verso il corridoio davanti al bancone, 1 = ultimo tratto
var float lobbyT;

function ScriptedPawn Tagged(name tagName)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp, tagName)
		return sp;
	return None;
}

function ScriptedPawn Gunther()
{
	return Tagged('UCGuntherSearch');
}

// L'Agente 01: segue Gunther fino alla camera.
function ScriptedPawn Agent()
{
	return Tagged('UCSpecialAgentSearch');
}

// L'Agente 02: resta nella lobby.
function ScriptedPawn LobbyAgent()
{
	return Tagged('UCSpecialAgentLobby');
}

function ScriptedPawn Gilbert()
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA('GilbertRenton') && sp.bInWorld && sp.Health > 0)
			return sp;
	return None;
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
		sp.GroundSpeed = 210;
		sp.WalkingSpeed = 0.35;
	}
	return sp;
}

// Sono entrati poco prima di JC: li si vede appena oltre l'ingresso, all'inizio del
// corridoio (JC arriva a (-377,162) girato verso il corridoio), in fila: Gunther,
// l'Agente 01, l'Agente 02.
function SetupActors()
{
	local ScriptedPawn a;

	if (Gunther() == None)
		Place(class'GuntherHermann', 'UCGuntherSearch', "GuntherHermann", vect(0, -300, -8), -16384);
	a = Agent();
	if (a == None)
		Place(class'MIB', 'UCSpecialAgentSearch', "UCSpecialAgent1", vect(0, -150, -8), -16384);
	else if (a.BindName != "UCSpecialAgent1")
	{
		// salvataggi della versione precedente: l'agente della camera era il 02
		a.BindName = "UCSpecialAgent1";
		a.ConBindEvents();
	}
	if (LobbyAgent() == None && !GetF('UC_GuntherLobbyAgent'))
	{
		SetF('UC_GuntherLobbyAgent', True);
		Place(class'MIB', 'UCSpecialAgentLobby', "UCSpecialAgent2", vect(0, -20, -8), -16384);
	}
}

function bool HasCon(Actor A, name conName)
{
	local ConListItem item;

	if (A == None)
		return False;
	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
			return True;
	return False;
}

// G05: chi ferma Gunther mentre sale ottiene solo questo (prima della fine della ricerca).
function AttachNotNow()
{
	local UCCon c;
	local ScriptedPawn g;

	g = Gunther();
	if (g == None || HasCon(g, 'UC_GuntherNotNow'))
		return;
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherNotNow', "GuntherHermann", True);
	c.Passive();
	c.Require('GuntherTonSearchComplete', False);
	c.Require('UC_GuntherNotNowCD', False);
	c.Line("GuntherHermann", "JCDenton", "Not now, Denton.");
	c.SetFlag('UC_GuntherNotNowCD', True);
	c.Done();
	c.AttachTo(g);
}

// La pausa di G05: per qualche secondo Gunther non lo ripete.
function NotNowTick(float dt)
{
	if (!GetF('UC_GuntherNotNowCD'))
		return;
	notNowT += dt;
	if (notNowT >= 6.0)
	{
		notNowT = 0;
		SetF('UC_GuntherNotNowCD', False);
	}
}

// G03, lo scambio con Gilbert: quando Gunther passa davanti al bancone e JC e' li'.
// Gunther non si ferma. Se Gilbert non c'e' (o JC non e' li' a sentire) si salta.
// Sulla route UNATCO Gilbert e' al bancone (UCMod.CloseHotelQuest); se e' ancora nel
// retro con Sandra (la faccenda di JoJo e' in corso) protesta da li'.
function TryLobby()
{
	local ScriptedPawn gil, g;

	g = Gunther();
	if (bLobbyDone || g == None)
		return;
	gil = Gilbert();
	if (gil == None || gil.GetAllianceType('Player') == ALLIANCE_Hostile || g.Location.Z > 40)
	{
		bLobbyDone = True;   // niente Gilbert, oppure Gunther e' gia' di sopra
		return;
	}
	// Gunther davanti al bancone (Gilbert li' dietro), oppure nel punto del corridoio
	// piu' vicino al retro; JC abbastanza vicino a Gilbert da sentirlo
	if (VSize(gil.Location - g.Location) > 300 && (VSize(gil.Location - g.Location) > 760 || g.Location.Y > -1380))
		return;
	if (Plr() == None || VSize(Plr().Location - gil.Location) > 1000)
		return;
	if (StartLobby())
		bLobbyDone = True;
}

// L'Agente 02 va al suo posto nella lobby e ci resta: davanti al bancone, dal lato dei
// clienti, girato verso Gilbert (dove nel gioco originale sta un soldato durante il raid).
// Ci arriva in due tratti: prima un punto del corridoio dove passa anche Gunther (che i
// PNG sanno raggiungere), poi l'ultimo pezzo dritto fino al bancone; se quel pezzo non
// gli riesce, dopo qualche secondo si ferma dov'e' (e' comunque a due passi da Gilbert).
function LobbyAgentTick(float dt)
{
	local ScriptedPawn a, gil;
	local rotator r;

	a = LobbyAgent();
	if (a == None || bLobbyPost || !a.bInWorld)
		return;
	if (lobbyStage == 0)
	{
		if (!Near(a, 'UCGSLobby', 60))
			return;
		lobbyStage = 1;
		lobbyT = 0;
		WalkTo(a, 'UCGSLobby2', vect(-418, -1269, -72));
		return;
	}
	lobbyT += dt;
	if (!Near(a, 'UCGSLobby2', 35) && lobbyT < 5.0)
		return;
	bLobbyPost = True;
	r = rot(0, 32768, 0);
	gil = Gilbert();
	if (gil != None)
		r = rotator((gil.Location - a.Location) * vect(1,1,0));
	a.SetOrders('Standing', '', True);
	a.DesiredRotation = r;
	a.SetHomeBase(a.Location, r);
	SetF('UC_LobbyAgentPosted', True);
}

// Due battute fra Gilbert e l'agente rimasto da lui. Partono da sole quando JC e' vicino
// al bancone (come i battibecchi "sentiti" del gioco originale), una volta sola, e solo
// quando l'agente e' al suo posto. Niente informazioni nuove: Gilbert vuole sapere per
// quanto ne avranno, l'agente risponde come rispondono i Men in Black del gioco
// ("Stay calm, please." e "Do not interfere with this operation." sono loro battute
// originali). La lista delle conversazioni non si salva: si riattacca a ogni caricamento.
function AttachLobbyChat()
{
	local UCCon c;
	local ScriptedPawn gil;

	gil = Gilbert();
	if (gil == None || LobbyAgent() == None || HasCon(gil, 'UC_LobbyChat'))
		return;
	c = new(Level) class'UCCon';
	c.Begin('UC_LobbyChat', "GilbertRenton", True);
	c.Once();
	c.Passive();
	c.NoFrob();
	c.Radius(380);
	c.Require('UC_LobbyAgentPosted', True);
	c.Line("GilbertRenton", "UCSpecialAgent2", "How long are you people going to be here?");
	c.Line("UCSpecialAgent2", "GilbertRenton", "Until the operation is concluded.");
	c.Line("GilbertRenton", "UCSpecialAgent2", "I've got guests upstairs. I don't want any trouble.");
	c.Line("UCSpecialAgent2", "GilbertRenton", "Stay calm, please. Do not interfere with this operation.");
	c.Done();
	c.AttachTo(gil);
}

function WalkTo(ScriptedPawn sp, name markTag, vector spot)
{
	local UCMark mark;

	if (sp == None)
		return;
	foreach AllActors(class'UCMark', mark, markTag)
		mark.Destroy();
	Spawn(class'UCMark',, markTag, spot);
	sp.SetOrders('GoingTo', markTag, True);
}

function bool Near(ScriptedPawn sp, name markTag, float dist)
{
	local UCMark mark;

	if (sp == None)
		return True;
	foreach AllActors(class'UCMark', mark, markTag)
		return VSize((sp.Location - mark.Location) * vect(1,1,0)) < dist && Abs(sp.Location.Z - mark.Location.Z) < 120;
	return True;
}

// Incastrato o troppo lento: arriva al posto quando JC non lo vede.
function Unstick(ScriptedPawn sp, name markTag)
{
	local UCMark mark;
	local DeusExPlayer P;

	P = Plr();
	if (sp == None || (P != None && P.LineOfSightTo(sp)))
		return;
	foreach AllActors(class'UCMark', mark, markTag)
		if (P == None || !FastTrace(mark.Location, P.Location + vect(0,0,1) * P.BaseEyeHeight))
			sp.SetLocation(mark.Location);
}

function float JCDist()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None || Gunther() == None)
		return 100000;
	return VSize(P.Location - Gunther().Location);
}

function bool NearRoom(float dist)
{
	return Near(Gunther(), 'UCGSRoom', dist);
}

function bool StartLobby()
{
	local UCCon c;
	local ScriptedPawn gil;
	local string to;

	gil = Gilbert();
	if (gil == None || Plr() == None || Plr().conPlay != None)
		return False;
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherLobby', "GilbertRenton", True);
	c.Once();
	c.Passive();
	c.Radius(1100);   // si sente da tutta la lobby (vedi UCScene.PlayConvMoving)
	// Il gioco non fa partire uno scambio fra due PNG a piu' di 300 unita' l'uno dall'altro
	// (Conversation.CheckActorDistances). Gilbert al bancone e Gunther che gli passa
	// davanti si parlano davvero (Gilbert si gira verso di lui); l'Agente 02 e' in coda
	// alla fila, e se Gilbert e' ancora nel retro sono tutti lontani: allora le battute sono
	// "rivolte" a JC, che e' escluso dal controllo (in prima persona non cambia quello che
	// si vede).
	to = "JCDenton";
	if (VSize(gil.Location - Gunther().Location) < 290)
		to = "GuntherHermann";
	c.Line("GilbertRenton", to, "What's going on? You can't just come in here.");
	if (to != "JCDenton")
		to = "GilbertRenton";
	c.Line("GuntherHermann", to, "UNATCO. We are looking for Paul Denton. Stay downstairs.");
	if (LobbyAgent() != None && LobbyAgent().bInWorld)
		c.Line("UCSpecialAgent2", "JCDenton", "Keep the stairs clear.");
	c.Done();
	return PlayConv(c, gil);
}

// G06, la camera vuota: si sente se JC e' abbastanza vicino. Nessuno deduce l'ora
// della fuga dagli oggetti nella stanza.
function bool StartRoom()
{
	local UCCon c;

	if (Gunther() == None || Plr() == None || Plr().conPlay != None)
		return False;
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherRoom', "GuntherHermann", True);
	c.Once();
	c.Passive();
	c.Radius(900);   // JC la sente dalla porta dell'appartamento (parte entro 800)
	if (Agent() == None || !Agent().bInWorld)
	{
		// l'agente non c'e' piu' (salvataggi vecchi, o tolto di mezzo): Gunther da solo
		c.Line("GuntherHermann", "JCDenton", "Unglaublich! He was here. We came too late.");
		c.Done();
		return PlayConv(c, Gunther());
	}
	c.Line("UCSpecialAgent1", "GuntherHermann", "Bedroom clear. No sign of the subject.");
	c.Line("GuntherHermann", "UCSpecialAgent1", "Unglaublich! He was here. We came too late.");
	c.Line("UCSpecialAgent1", "GuntherHermann", "I'll report to Mr. Simons.");
	c.Line("GuntherHermann", "UCSpecialAgent1", "Tell him we need men at the subway exits. Then check the alley.");
	c.SetFlag('SimonsConnectionHinted', True);
	c.Done();
	return PlayConv(c, Gunther());
}

// Gli approfondimenti (uno per clic, mai automatici). AttachTo mette in testa alla
// lista: si attaccano dall'ultimo al primo.
function AttachOptional()
{
	local UCCon c;
	local ScriptedPawn g;

	g = Gunther();
	if (g == None || HasCon(g, 'UC_GuntherG17'))
		return;

	// G17: battuta di ripetizione
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherG17', "GuntherHermann", True);
	c.Passive();
	c.Require('GuntherTonSearchComplete', True);
	c.Line("GuntherHermann", "JCDenton", "Go to Hong Kong, Denton.");
	c.Done();
	c.AttachTo(g);

	// G15: chiudere l'incontro
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherG15', "GuntherHermann", False);
	c.Once();
	c.Require('GuntherTonSearchComplete', True);
	c.Line("JCDenton", "GuntherHermann", "You still want this assignment?");
	c.Line("GuntherHermann", "JCDenton", "Yes. I warned them about Paul, and they waited. Again I am sent after he has gone.");
	c.Line("JCDenton", "GuntherHermann", "What now?");
	c.Line("GuntherHermann", "JCDenton", "Now I find him. You have your own orders.");
	c.Done();
	c.AttachTo(g);

	if (Anna747() && GetF('ManderleyDebriefing03_Played'))
	{
		// G16: Anna morta sul 747 (al posto di G14). Nessuna nuova prova contro JC.
		c = new(Level) class'UCCon';
		c.Begin('UC_GuntherG16', "GuntherHermann", False);
		c.Once();
		c.Require('GuntherTonSearchComplete', True);
		c.Line("GuntherHermann", "JCDenton", "You were sent into that aircraft. Agent Navarre did not come back. You still owe me an explanation.");
		c.Line("JCDenton", "GuntherHermann", "I gave Manderley my report.");
		c.Line("GuntherHermann", "JCDenton", "I will find out what happened, Denton. Do not think this is over.");
		c.Done();
		c.AttachTo(g);
	}
	else
	{
		// G14: le accuse di Paul
		c = new(Level) class'UCCon';
		c.Begin('UC_GuntherG14', "GuntherHermann", False);
		c.Once();
		c.Require('GuntherTonSearchComplete', True);
		c.Line("JCDenton", "GuntherHermann", "Paul thinks UNATCO has been compromised.");
		c.Line("GuntherHermann", "JCDenton", "He swore to serve the Coalition. Then he joined the NSF. That is what I know about your brother.");
		c.Line("JCDenton", "GuntherHermann", "You won't even look at what he found?");
		c.Line("GuntherHermann", "JCDenton", "He gave information to our enemies. I do not need his explanation for that.");
		c.Done();
		c.AttachTo(g);
	}

	// G13: la segnalazione
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherG13', "GuntherHermann", False);
	c.Once();
	c.Require('GuntherTonSearchComplete', True);
	c.Line("JCDenton", "GuntherHermann", "Who told you Paul was here?");
	c.Line("GuntherHermann", "JCDenton", "Command gave me the address.");
	c.Line("JCDenton", "GuntherHermann", "Did they say who saw him?");
	c.Line("GuntherHermann", "JCDenton", "No. The report was correct. They should have sent it sooner.");
	c.Done();
	c.AttachTo(g);

	// G12: chi sono i due agenti
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherG12', "GuntherHermann", False);
	c.Once();
	c.Require('GuntherTonSearchComplete', True);
	c.Line("JCDenton", "GuntherHermann", "Who are the men with you?");
	c.Line("GuntherHermann", "JCDenton", "Mr. Simons sent them. They are supposed to assist with the arrest.");
	c.Line("JCDenton", "GuntherHermann", "Are they UNATCO?");
	c.Line("GuntherHermann", "JCDenton", "They have clearance. That is all I was told.");
	c.SetFlag('SimonsConnectionHinted', True);
	c.Done();
	c.AttachTo(g);

	// G11: il possibile avvertimento (solo se Gunther sa dell'incontro con Paul)
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherG11', "GuntherHermann", False);
	c.Once();
	c.Require('GuntherTonSearchComplete', True);
	c.Require('GuntherKnowsJCMetPaul', True);
	c.Line("GuntherHermann", "JCDenton", "Did you warn him we were coming?");
	c.Line("JCDenton", "GuntherHermann", "I didn't know you were coming.");
	c.Line("GuntherHermann", "JCDenton", "He knows our methods. That will not save him.");
	c.Done();
	c.AttachTo(g);

	// G10: rimprovero dopo la ricerca (l'ultima parola e' di Gunther)
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherReproach', "GuntherHermann", False);
	c.Once();
	c.Require('GuntherTonSearchComplete', True);
	c.Require('GuntherKnowsJCMetPaul', True);
	c.Line("GuntherHermann", "JCDenton", "You spoke to him and walked away. Now we have to search the city.");
	c.Line("JCDenton", "GuntherHermann", "I didn't help him escape.");
	c.Line("GuntherHermann", "JCDenton", "You did nothing to stop him.");
	c.Done();
	c.AttachTo(g);

	// G07: primo incontro avvenuto dentro (esterno saltato): Gunther non sa ancora
	// niente, lo chiede. Dopo l'ammissione di JC parte il rapporto alla squadra.
	c = new(Level) class'UCCon';
	c.Begin('UC_GuntherG07', "GuntherHermann", False);
	c.Once();
	c.Require('GuntherTonSearchComplete', True);
	c.Require('GuntherKnowsJCMetPaul', False);
	c.Line("GuntherHermann", "JCDenton", "Denton. Were you here with Paul?");
	c.Line("JCDenton", "GuntherHermann", "I spoke to him. He wanted me to join him. I refused.");
	c.SetFlag('GuntherKnowsJCMetPaul', True);
	c.SetFlag('UC_PaulContactReportSent', True);
	c.Line("GuntherHermann", "JCDenton", "You left him free. Manderley will hear about this. Go to Hong Kong.");
	c.SetFlag('GuntherReportedJCConduct', True);
	c.Done();
	c.AttachTo(g);
}

// "Then check the alley.": l'Agente 01 esce davvero, dall'ingresso.
function AgentLeaves()
{
	WalkTo(Agent(), 'UCGSExit', vect(-376, 100, -8));
}

function bool AgentGone()
{
	local DeusExPlayer P;
	local ScriptedPawn a;

	a = Agent();
	P = Plr();
	if (a == None || !a.bInWorld)
		return True;
	if (P != None && !SeenByJC(a) && (!P.LineOfSightTo(a) || VSize(a.Location - P.Location) > 900))
	{
		a.LeaveWorld();
		return True;
	}
	return False;
}

state Playing
{
Begin:
	Sleep(0.3);
	// ricerca gia' finita (JC rientra): niente replica, solo gli approfondimenti
	if (GetF('GuntherTonSearchComplete'))
	{
		AttachLobbyChat();
		Goto('After');
	}
	SetF('GuntherTonSearchStarted', True);
	SetupActors();
	AttachNotNow();
	AttachLobbyChat();
	Sleep(0.7);
Upstairs:
	// dritti alla camera di Paul, in fila: ognuno parte quando quello davanti e' avanti
	WalkTo(Gunther(), 'UCGSRoom', vect(-40, -3760, 118));
	Sleep(1.8);
	WalkTo(Agent(), 'UCGSRoomAgent', vect(-20, -3950, 118));
	Sleep(1.8);
	WalkTo(LobbyAgent(), 'UCGSLobby', vect(-358, -1301, -72));
	t = 0;
Walk:
	if (!NearRoom(110))
	{
		OpenDoorsNear(Gunther(), 200);
		OpenDoorsNear(Agent(), 200);
		if (!Talking())
			TryLobby();
		KeepWalking(Gunther(), 'UC_GuntherLobby');   // "Gunther continua verso le scale"
		LobbyAgentTick(0.25);
		NotNowTick(0.25);
		Sleep(0.25);
		t += 0.25;
		if (t > 140)
		{
			Unstick(Gunther(), 'UCGSRoom');
			Unstick(Agent(), 'UCGSRoomAgent');
		}
		Goto('Walk');
	}
	if (Gunther() != None)
		Gunther().SetOrders('Standing', '', True);
	if (Agent() != None)
		Agent().SetOrders('Standing', '', True);
WaitJC:
	// la camera vuota: si sente quando JC arriva
	if (JCDist() > 800)
	{
		LobbyAgentTick(0.5);
		NotNowTick(0.5);
		Sleep(0.5);
		Goto('WaitJC');
	}
Room:
	if (!StartRoom())
	{
		Sleep(0.25);
		Goto('Room');
	}
	Sleep(0.5);
WaitRoom:
	if (Talking())
	{
		Sleep(0.25);
		Goto('WaitRoom');
	}
	SetF('GuntherTonSearchComplete', True);
	SetF('GuntherFailedToCapturePaul', True);
	SetF('UC_GuntherNotNowCD', False);
	AgentLeaves();
After:
	// La scena resta finche' JC e' nell'hotel: il gioco puo' rifare la lista delle
	// conversazioni di un PNG, e allora gli approfondimenti vanno riattaccati (i due
	// Attach* controllano per nome: se ci sono gia' non fanno niente).
	AttachOptional();
	AttachLobbyChat();
	AgentGone();
	LobbyAgentTick(0.5);
	Sleep(0.5);
	Goto('After');
}

defaultproperties
{
}
