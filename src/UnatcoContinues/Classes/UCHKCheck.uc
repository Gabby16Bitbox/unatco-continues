//=============================================================================
// UCHKCheck - verifica senza gioco delle mappe di Hong Kong (tools\check-hongkong.ps1).
// Gira come ServerActor in un server di prova su una COPIA della mappa: lega le
// conversazioni vanilla ai PNG come fa il gioco, esegue UCHKWorld/UCHKStory e
// controlla il risultato (PNG originali trovati, conversazioni nostre attaccate e
// vanilla tolte, PNG nuovi creati davvero, trigger spenti, fazioni).
// Non puo' provare le conversazioni in se': serve un giocatore.
//=============================================================================
class UCHKCheck extends Actor
	transient;

var int checked, failed;
var string mapName;

function Check(bool ok, string description)
{
	checked++;
	if (!ok)
	{
		failed++;
		Log("UCHKCheck FAIL:" @ description);
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

// La prima conversazione con quel nome (quella che sceglie StartConversationByName).
function Conversation FirstCon(Actor A, name conName)
{
	local ConListItem item;

	if (A == None)
		return None;
	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
			return item.con;
	return None;
}

function ScriptedPawn FindClass(name className, optional name skipTag)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA(className) && (skipTag == '' || sp.Tag != skipTag))
			return sp;
	return None;
}

function int CountTag(name tagName)
{
	local ScriptedPawn sp;
	local int n;

	foreach AllActors(class'ScriptedPawn', sp, tagName)
		n++;
	return n;
}

function bool EventFired(name ev)
{
	local Dispatcher d;
	local Actor A;
	local int i;

	foreach AllActors(class'Dispatcher', d)
		for (i = 0; i < 8; i++)
			if (d.OutEvents[i] == ev)
				return True;
	foreach AllActors(class'Actor', A)
		if (A.Event == ev)
			return True;
	return False;
}

function Market()
{
	local ScriptedPawn m;
	local Teleporter tp;

	m = FindClass('TriadRedArrow');
	foreach AllActors(class'ScriptedPawn', m, 'UCMessenger')
		break;
	Check(m != None, "messaggero creato");
	if (m != None)
		Log("UCHKCheck messaggero a" @ m.Location);
	Check(HasCon(m, 'UC_Messenger') && HasCon(m, 'UC_MessengerAgain'), "conversazioni del messaggero");
	Check(FirstCon(m, 'UC_Messenger') != None && !FirstCon(m, 'UC_Messenger').bInvokeRadius, "il messaggero non parla attraverso i muri (niente raggio)");
	if (m != None)
	{
		// nel corridoio dell'ascensore merci, visibile da chi esce dalle porte (-912,-1344)
		Check(VSize(m.Location - vect(-912, -1344, 48)) < 300, "messaggero vicino all'uscita dell'ascensore");
		Check(m.Location.Z > 30 && m.Location.Z < 80, "messaggero sul pavimento del corridoio");
		Check(FastTrace(vect(-870, -1344, 60), m.Location + vect(0,0,30)), "dall'uscita dell'ascensore si vede il messaggero");
		Check(m.Orders == 'Standing', "il messaggero sta fermo");
	}
	foreach AllActors(class'Teleporter', tp)
		if (InStr(Caps(tp.URL), "SEWERS") != -1)
			Check(!tp.bEnabled, "passaggio verso le fogne inesistenti spento");
}

function Underworld()
{
	local ScriptedPawn max;
	local Actor A;

	max = FindClass('MaxChen');
	Check(max != None, "Max Chen trovato");
	Check(HasCon(max, 'UC_MaxMeet') && HasCon(max, 'UC_MaxEvidence') && HasCon(max, 'UC_MaxAfter'), "conversazioni nostre di Max");
	Check(!HasCon(max, 'MeetMaxChen') && !HasCon(max, 'Show_Chen'), "MeetMaxChen/Show_Chen vanilla tolte");
	Check(CountTag('RaidingCommando') == 0, "commando del raid tolti");
	Check(CountTag('UCLMAgent') == 2 && CountTag('UCLMRedArrow') == 1, "accenno: 2 agenti + 1 Red Arrow creati");
	Escort();
	foreach AllActors(class'Actor', A, 'RaidUnderway')
		if (A.IsA('AllianceTrigger') || A.IsA('OrdersTrigger'))
			Check(A.Event == '', "RaidUnderway spento:" @ A.Name);
}

// Il Red Arrow che porta JC da Max: conversazioni attaccate, percorso sul pavimento,
// porte del club e dell'ufficio dove il codice le cerca.
function Escort()
{
	local ScriptedPawn ra;
	local UCHKStory story;
	local Mover mo;
	local vector pt;
	local int i, clubDoors, officeDoors;

	foreach AllActors(class'ScriptedPawn', ra, 'UCLMRedArrow')
		break;
	foreach AllActors(class'UCHKStory', story)
		break;
	Check(HasCon(ra, 'UC_MaxEscort') && HasCon(ra, 'UC_MaxEscortAgain') && HasCon(ra, 'UC_MaxEscortDoor'), "conversazioni dell'accompagnatore");
	Check(story != None, "UCHKStory presente");
	if (story == None)
		return;
	for (i = 1; i <= story.EscortLast(); i++)
	{
		pt = story.EscortPoint(i);
		Check(FastTrace(pt + vect(0,0,30), pt) && !FastTrace(pt - vect(0,0,120), pt), "percorso dell'accompagnatore: punto" @ i @ "sul pavimento");
	}
	// l'ultimo tratto e' dritto (non e' un punto della rete di percorsi)
	Check(FastTrace(story.EscortPoint(story.EscortLast()), story.EscortPoint(story.EscortLast() - 1)), "ultimo tratto dell'accompagnatore libero");
	foreach AllActors(class'Mover', mo)
	{
		if (mo.Tag == 'Club_Doors')
		{
			clubDoors++;
			Check(mo.InitialState == 'TriggerOpenTimed', "porta del club a tempo:" @ mo.Name);
			Check(VSize((mo.Location - story.ClubDoorSpot()) * vect(1,1,0)) < 140, "porta del club dove la cerca il codice:" @ mo.Name);
		}
		if (mo.Tag == 'MaxChensOffice')
		{
			officeDoors++;
			Check(DeusExMover(mo) != None && !DeusExMover(mo).bLocked && DeusExMover(mo).bFrobbable, "porta dell'ufficio di Max apribile:" @ mo.Name);
			Check(VSize((mo.Location - story.EscortPoint(story.EscortLast())) * vect(1,1,0)) > 60, "l'accompagnatore non si ferma sull'anta:" @ mo.Name);
		}
	}
	Check(clubDoors == 2 && officeDoors == 2, "porte del club e dell'ufficio trovate");
}

function Street()
{
	local ScriptedPawn maggie, walton, holo, sp;
	local Conversation c;
	local Actor A, owner;
	local ConversationTrigger ct;
	local bool bTrigger;

	maggie = FindClass('MaggieChow', 'UCMaggieHolo');
	Check(maggie != None, "Maggie trovata");
	Check(HasCon(maggie, 'UC_MaggieMeet') && HasCon(maggie, 'UC_MaggieAgain'), "conversazioni nostre di Maggie");
	Check(!HasCon(maggie, 'MeetMaggie') && !HasCon(maggie, 'MeetMaggie2') && !HasCon(maggie, 'MaggieBarks'), "MeetMaggie vanilla tolte");

	walton = FindClass('WaltonSimons');
	Check(walton != None, "ologramma di Simons trovato");
	c = FirstCon(walton, 'M06WaltonHolo');
	Check(c != None && c.audioPackageName == "" && c.bNonInteractive, "M06WaltonHolo: parte la versione riscritta");
	foreach AllActors(class'ConversationTrigger', ct)
		if (ct.conversationTag == 'M06WaltonHolo')
		{
			bTrigger = True;
			owner = None;
			foreach AllActors(class'Actor', A)
				if (A.BindName == ct.BindName)
				{
					owner = A;
					break;
				}
			Check(owner == walton, "il trigger dell'ologramma trova Simons");
		}
	Check(bTrigger, "trigger dell'ologramma presente");
	foreach AllActors(class'ScriptedPawn', holo, 'UCMaggieHolo')
		break;
	Check(holo != None && !holo.bInWorld, "Maggie della registrazione creata (nascosta)");
	if (holo != None)
		Log("UCHKCheck ologramma Maggie a" @ holo.WorldPosition @ "Simons a" @ walton.WorldPosition);

	bTrigger = False;
	foreach AllActors(class'Actor', A, 'Sword_Triggers')
		if (A.IsA('UCSwordHook'))
			bTrigger = True;
	Check(bTrigger, "aggancio della teca (Sword_Triggers)");
	Check(EventFired('Sword_Triggers'), "qualcosa nella mappa fa scattare Sword_Triggers");

	foreach AllActors(class'ScriptedPawn', sp, 'MaggieTroop')
		if (sp.bInWorld)
			Check(sp.GetAllianceType('Player') == ALLIANCE_Friendly, "guardia MJ12 di Maggie amica:" @ sp.Name);
	foreach AllActors(class'Actor', A)
		if ((A.IsA('AllianceTrigger') || A.IsA('OrdersTrigger')) && A.Event == 'MaggieTroop')
			Check(False, "trigger contro JC sulle guardie di Maggie ancora attivo:" @ A.Name);
}

function Compound()
{
	local ScriptedPawn gordon, sp;
	local Actor A;

	gordon = FindClass('GordonQuick');
	Check(gordon != None, "Gordon trovato");
	Check(HasCon(gordon, 'UC_GordonMeet') && HasCon(gordon, 'UC_GordonEvidence') && HasCon(gordon, 'UC_GordonFinal') && HasCon(gordon, 'UC_GordonWait'), "conversazioni nostre di Gordon");
	Check(!HasCon(gordon, 'Gate_Guard2') && !HasCon(gordon, 'QuickFinalTalk') && !HasCon(gordon, 'ConvinceQuick'), "conversazioni vanilla di Gordon tolte");
	foreach AllActors(class'Actor', A, 'LumpathPissed')
		if (A.IsA('AllianceTrigger') || A.IsA('OrdersTrigger'))
			Check(A.Event == '', "LumpathPissed spento:" @ A.Name);
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.bInWorld && (sp.Alliance == 'LumPath' || sp.Alliance == 'triad_lum'))
			Check(sp.GetAllianceType('Player') != ALLIANCE_Hostile, "Luminous Path non ostile:" @ sp.Name);
}

// Battery Park (route UNATCO): strada aperta verso l'elicottero, 2 soldati di ronda.
// Hell's Kitchen: Gunther al 'Ton resta in strada e i tre entrano in fila indiana
// lungo un percorso libero (scalinata nord, portico, portone, porta dell'hotel).
function NYCStreet()
{
	local UCSceneGuntherTon scene;
	local ScriptedPawn g, anna, guard;
	local Actor hit;
	local vector a, b, hitLoc, hitNorm;
	local int i;
	local UCMod m;
	local DeusExMover gate;
	local Actor pad;

	// posto alla metro: grata aperta senza codice, Anna con tutte le sue conversazioni;
	// se Anna e' morta, un soldato (qui si provano tutti e due nella stessa mappa)
	foreach AllActors(class'UCMod', m)
		break;
	if (m == None)
		m = Spawn(class'UCMod');
	Check(m != None, "gestore creato");
	if (m != None)
	{
		// la grata si apre con Trigger (parte al tick dopo: qui si controlla solo che sia
		// una porta a scatto ancora chiusa; l'apertura si vede nelle prove in gioco)
		foreach AllActors(class'DeusExMover', gate, 'SubGate')
			Check(gate.InitialState == 'TriggerToggle' && !gate.bDestroyed, "grata della metro apribile con Trigger");
		m.OpenSubwayGateOnly();
		foreach AllActors(class'Actor', pad, 'SubKeypad')
			Check(!pad.bCollideActors, "tastierino della grata spento");
		m.RemoveSally();   // come StreetSetup: Sally e' proprio dove va il posto di guardia
		m.PlaceMetroPost(False);
		foreach AllActors(class'ScriptedPawn', anna, 'UCAnnaMetro')
			break;
		Check(anna != None && anna.IsA('AnnaNavarre'), "Anna Navarre alla metro");
		if (anna != None)
		{
			Log("UCHKCheck Anna a" @ anna.Location);
			Check(VSize(anna.Location - vect(2515, -1188, -583)) < 60, "Anna sul pianerottolo davanti alla grata");
			Check(anna.GetAllianceType('Player') == ALLIANCE_Friendly, "Anna amica di JC");
			Check(HasCon(anna, 'UC_AnnaA01') && HasCon(anna, 'UC_AnnaA02') && HasCon(anna, 'UC_AnnaA03')
				&& HasCon(anna, 'UC_AnnaA04') && HasCon(anna, 'UC_AnnaA05') && HasCon(anna, 'UC_AnnaA06'), "sei aperture di Anna");
			Check(HasCon(anna, 'UC_AnnaA10') && HasCon(anna, 'UC_AnnaA11') && HasCon(anna, 'UC_AnnaA12')
				&& HasCon(anna, 'UC_AnnaA13'), "approfondimenti e battuta di ripetizione di Anna");
			Check(FirstCon(anna, 'UC_AnnaA01').bInvokeRadius && !FirstCon(anna, 'UC_AnnaA10').bInvokeRadius,
				"l'apertura parte da sola, gli approfondimenti solo parlandole");
		}
		Check(CountTag('UCGateTrooper') == 0, "con Anna viva nessun soldato al suo posto");
		// in gioco c'e' l'uno o l'altra: qui Anna lascia libero il punto per il soldato
		if (anna != None)
			anna.LeaveWorld();
		m.PlaceMetroPost(True);
		foreach AllActors(class'ScriptedPawn', guard, 'UCGateTrooper')
			break;
		Check(guard != None && HasCon(guard, 'UC_GateGuard'), "Anna morta: soldato alla metro con il suo dialogo");
		Check(CountTag('UCAnnaMetro') == 1, "Anna non viene ricreata");
	}

	scene = Spawn(class'UCSceneGuntherTon');
	Check(scene != None, "scena di Gunther creata");
	if (scene == None)
		return;
	scene.SetupActors();
	g = scene.Gunther();
	Check(g != None, "Gunther creato");
	if (g != None)
	{
		Log("UCHKCheck Gunther a" @ g.Location);
		Check(VSize((g.Location - vect(1330, 897, -456)) * vect(1,1,0)) < 40, "Gunther sul marciapiede ai piedi della scalinata");
		Check(g.Location.Z < -420, "Gunther a livello della strada, non sul portico");
		Check(FirstCon(g, 'UC_GuntherTon1') != None && FirstCon(g, 'UC_GuntherTon1').bInvokeRadius
			&& FirstCon(g, 'UC_GuntherTon1').radiusDistance <= 260, "parla solo quando JC gli va vicino");
		Check(g.Orders == 'Standing', "Gunther sta fermo (non corre incontro a JC)");
	}
	Check(scene.Agent(1) != None && scene.Agent(2) != None, "due Special Agents");
	a = vect(1330, 897, -456);
	for (i = 1; i <= 5; i++)
	{
		b = scene.WalkPoint(i);
		Check(FastTrace(b, a), "tratto libero fino alla tappa" @ i);
		hit = Trace(hitLoc, hitNorm, b - vect(0,0,160), b, False);
		Check(hit != None && b.Z - hitLoc.Z < 90, "tappa" @ i @ "sopra il pavimento (" $ int(b.Z - hitLoc.Z) $ ")");
		a = b;
	}
}

function BatteryPark()
{
	local UCMod m;
	local RoadBlock rb;
	local BlockPlayer bp;
	local ScriptedPawn sp;
	local int roadblocks, robots, troops, closed;

	foreach AllActors(class'UCMod', m)
		break;
	if (m == None)
		m = Spawn(class'UCMod');
	Check(m != None, "gestore creato");
	if (m == None)
		return;
	m.BatteryParkSetup();
	foreach AllActors(class'RoadBlock', rb)
		roadblocks++;
	Check(roadblocks == 0, "barriere dei posti di blocco tolte (" $ roadblocks $ ")");
	foreach AllActors(class'BlockPlayer', bp)
		if (bp.CollisionRadius <= 60 && bp.Location.Z - bp.CollisionHeight <= 412 && bp.bBlockPlayers
			&& (VSize((bp.Location - vect(-2680, 1700, 0)) * vect(1,1,0)) < 200 || VSize((bp.Location - vect(-3150, 2190, 0)) * vect(1,1,0)) < 200
				|| VSize((bp.Location - vect(-3830, 1820, 0)) * vect(1,1,0)) < 150))
			closed++;
	Check(closed == 0, "muri invisibili dei posti di blocco spenti (ancora attivi: " $ closed $ ")");
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.bInWorld)
		{
			if (sp.IsA('Robot'))
				robots++;
			if (sp.IsA('UNATCOTroop'))
				troops++;
		}
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA('AnnaNavarre') || sp.IsA('GuntherHermann'))
			Check(!sp.bInWorld, sp.Name @ "non e' a Battery Park");
	Check(robots == 0, "robot tolti (" $ robots $ ")");
	Check(troops == 2, "restano 2 soldati (" $ troops $ ")");
	foreach AllActors(class'ScriptedPawn', sp, 'UCBPPatrol1')
		Log("UCHKCheck ronda 1:" @ sp.Name @ sp.Location);
	foreach AllActors(class'ScriptedPawn', sp, 'UCBPPatrol2')
		Log("UCHKCheck ronda 2:" @ sp.Name @ sp.Location);
}

// Eliporto (route UNATCO): niente allarme, porte blindate aperte, base amica.
function Helibase()
{
	local UCMod m;
	local Dispatcher d;
	local DeusExMover mv;
	local ScriptedPawn sp;
	local DataLinkTrigger dl;
	local Actor fx, van;
	local DeusExMover wall;
	local SecurityCamera cam;
	local Mover mo;
	local Texture sign;
	local Switch1 sw;
	local Light lt;
	local int nFlicker;
	local int blast, debris, nWall, nVan, nSwitch, nPanel;

	foreach AllActors(class'UCMod', m)
		break;
	if (m == None)
		m = Spawn(class'UCMod');
	Check(m != None, "gestore creato");
	if (m == None)
		return;
	foreach AllActors(class'Actor', fx)
		if ((fx.IsA('ElectricityEmitter') || fx.IsA('ParticleGenerator'))
			&& VSize((fx.Location - vect(-1240, -128, 500)) * vect(1,1,0)) < 160)
			debris++;
	Log("UCHKCheck residui dell'esplosione prima:" @ debris);
	Check(debris > 0, "scintille e fumo della porta blindata trovati");
	foreach AllActors(class'Actor', fx)
		if (fx.IsA('ControlPanel') && VSize((fx.Location - vect(-1240, -128, 500)) * vect(1,1,0)) < 160)
			nPanel++;
	Check(nPanel == 1, "quadro elettrico storto vicino alla porta blindata trovato (" $ nPanel $ ")");
	foreach AllActors(class'Switch1', sw)
		if (sw.Event == 'Helipad_Lifter')
			nSwitch++;
	Check(nSwitch == 3, "pulsanti della piattaforma trovati (" $ nSwitch $ "/3)");
	foreach AllActors(class'Light', lt)
		if (lt.LightType == LT_Flicker && lt.Location.X > -1720 && lt.Location.X < -1380 && lt.Location.Y > -260 && lt.Location.Y < 20)
			nFlicker++;
	Check(nFlicker == 4, "luci dell'atrio che tremolano trovate (" $ nFlicker $ "/4)");
	m.OpenHelibase();
	foreach AllActors(class'Light', lt)
		if (lt.LightType == LT_Flicker && lt.Location.X > -1720 && lt.Location.X < -1380 && lt.Location.Y > -260 && lt.Location.Y < 20)
			Check(False, "luce dell'atrio ancora rotta:" @ lt.Name);
	// il pulsante della piattaforma non deve ripartire da "chiuso" col tetto di Jock aperto
	foreach AllActors(class'Switch1', sw)
		Check(sw.Event != 'Helipad_Lifter' && !sw.bHighlight, "pulsante della piattaforma spento:" @ sw.Name);
	foreach AllActors(class'Dispatcher', d, 'AssaultForceDisp')
		Check(False, "dispatcher dell'assalto ancora attivo");
	foreach AllActors(class'DeusExMover', mv)
		if (mv.Tag == 'Blast_doors' || mv.Tag == 'DoorWreckage')
		{
			blast++;
			Check(!mv.bCollideActors && !mv.bBlockPlayers && mv.Location.Z > 10000, "porta blindata tolta:" @ mv.Name);
		}
	Check(blast >= 1, "porte blindate trovate (" $ blast $ ")");
	// niente scintille ne' fumo dei missili di Jock sopra/davanti alla porta
	foreach AllActors(class'Actor', fx)
		if ((fx.IsA('ElectricityEmitter') || fx.IsA('ParticleGenerator')) && !fx.bDeleteMe
			&& VSize((fx.Location - vect(-1240, -128, 500)) * vect(1,1,0)) < 160 && fx.Location.Z < 10000)
			Check(False, "residuo dell'esplosione ancora li':" @ fx.Name);
	foreach AllActors(class'Actor', fx)
		if (fx.IsA('ControlPanel') && !fx.bDeleteMe && VSize((fx.Location - vect(-1240, -128, 500)) * vect(1,1,0)) < 160
			&& fx.Location.Z < 10000)
			Check(False, "quadro elettrico storto ancora li':" @ fx.Name);
	// la scritta sopra la porta: LOCKDOWN -> ELEVATORS
	sign = Texture(DynamicLoadObject("HK_Helibase.Sn_HBLkdwn", class'Texture', True));
	Check(sign != None && sign.AnimNext == Texture'UnatcoContinues.UCSignElevators'
		&& sign.AnimCurrent == Texture'UnatcoContinues.UCSignElevators', "scritta ELEVATORS al posto di LOCKDOWN");
	Check(Texture'UnatcoContinues.UCSignElevators'.USize == 1024 && Texture'UnatcoContinues.UCSignElevators'.VSize == 128
		&& Texture'UnatcoContinues.UCSignElevators'.DrawScale == 0.125, "scritta ELEVATORS in alta risoluzione (1024x128, DrawScale 0.125): "
		$ Texture'UnatcoContinues.UCSignElevators'.USize $ "x" $ Texture'UnatcoContinues.UCSignElevators'.VSize @ Texture'UnatcoContinues.UCSignElevators'.DrawScale);
	// la mappa della mod (maps\): coperture UCWall nascoste e macerie UCVanilla presenti (gioco normale)
	foreach AllActors(class'Mover', mo)
	{
		if (Left(string(mo.Tag), 6) == "UCWall")
		{
			nWall++;
			Check(mo.bHidden && !mo.bCollideActors, "copertura nascosta nel gioco normale:" @ mo.Tag);
			Check(VSize(mo.Location - mo.BasePos) < 1, "copertura al suo posto:" @ mo.Tag);
		}
		if (Left(string(mo.Tag), 9) == "UCVanilla")
		{
			nVan++;
			Check(mo.bHidden && !mo.bCollideActors, "macerie nascoste nella mappa (le mostra il gioco normale):" @ mo.Tag);
		}
	}
	Check(nWall == 4, "coperture UCWall nella mappa (" $ nWall $ "/4: soffitto, muro sud, 2 strisce di luce)");
	Check(nVan == 2, "macerie UCVanilla nella mappa (" $ nVan $ "/2)");
	// gioco normale: le macerie tornano visibili e solide
	m.ShowVanillaOnly();
	foreach AllActors(class'Mover', mo)
		if (Left(string(mo.Tag), 9) == "UCVanilla")
			Check(!mo.bHidden && mo.bCollideActors && mo.bBlockPlayers, "macerie presenti nel gioco normale:" @ mo.Tag);
	// muri "solo UNATCO" (UCWall*) e oggetti "solo gioco normale" (UCVanilla*), con una
	// porta e un oggetto qualsiasi rinominati per la prova
	wall = None;
	foreach AllActors(class'DeusExMover', mv)
		if (mv.Tag != 'elevator_door' && mv.Tag != 'Blast_doors' && mv.Tag != 'DoorWreckage' && mv.Location.Z < 10000)
		{
			wall = mv;
			break;
		}
	if (wall != None)
	{
		wall.Tag = 'UCWallProva';
		wall.bHidden = True;
		wall.SetCollision(False, False, False);
		foreach AllActors(class'SecurityCamera', cam)
		{
			van = cam;
			break;
		}
		if (van != None)
			van.Tag = 'UCVanillaProva';
		m.bCommitted = True;
		m.RaiseRouteWalls();
		Check(!wall.bHidden && wall.bCollideActors && wall.bBlockPlayers, "muro UCWall visibile e solido sulla route UNATCO");
		Check(!wall.bFrobbable && wall.bLocked, "muro UCWall non apribile");
		Check(van == None || (van.bHidden && !van.bCollideActors && van.Tag == 'UCHiddenVanilla'), "oggetto UCVanilla nascosto sulla route UNATCO");
		foreach AllActors(class'Mover', mo)
		{
			if (mo.Tag == 'UCWallSoffitto' || mo.Tag == 'UCWallSud')
				Check(!mo.bHidden && mo.bCollideActors && mo.bBlockPlayers, "copertura solida sulla route UNATCO:" @ mo.Tag);
			if (mo.Tag == 'UCWallLuceNord' || mo.Tag == 'UCWallLuceVicina')
				Check(!mo.bHidden && !mo.bCollideActors && !mo.bBlockPlayers, "striscia di luce visibile e senza collisione:" @ mo.Tag);
			if (mo.Name == 'UCVanillaLamiere0' || mo.Name == 'UCVanillaMacerie0')
				Check(mo.bHidden && !mo.bCollideActors && mo.Location.Z > 10000, "macerie sparite sulla route UNATCO:" @ mo.Name);
		}
	}
	foreach AllActors(class'DataLinkTrigger', dl)
		if (dl.datalinkTag == 'DL_Jock_01')
			Check(!dl.bCollideActors, "InfoLink del dirottamento spento");
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.bInWorld)
			Check(sp.GetAllianceType('Player') != ALLIANCE_Hostile, "nessuno ostile:" @ sp.Name);
	Check(CountTag('UCHKOfficer') == 1, "ufficiale MJ12 creato");
	Check(CountTag('UCHKGuard') == 0, "nessuna guardia MJ12 davanti all'ascensore");
	foreach AllActors(class'ScriptedPawn', sp, 'UCHKOfficer')
		Check(HasCon(sp, 'UC_HKOfficer'), "dialogo dell'ufficiale");
	// salvataggi vecchi: la guardia gia' creata viene tolta
	sp = Spawn(class'MJ12Troop',, 'UCHKGuard', vect(-1600, 60, 433));
	Check(sp != None && m.RemoveLiftGuard() && CountTag('UCHKGuard') == 0, "guardia di un salvataggio vecchio tolta");
}

// Base di Tong: prima dell'assalto e le due ondate (posizioni valide, alleanze giuste).
function TongBase()
{
	local UCSceneTongLab lab;
	local ScriptedPawn sp, tg;
	local Trigger tr;

	lab = Spawn(class'UCSceneTongLab');
	Check(lab != None, "scena creata");
	if (lab == None)
		return;
	lab.SetupBase();
	foreach AllActors(class'ScriptedPawn', tg)
		if (tg.IsA('TracerTong'))
			break;
	Check(tg != None && HasCon(tg, 'UC_TongMeet'), "Tong ha il dialogo nuovo");
	Check(tg != None && !HasCon(tg, 'MeetTracerTong') && !HasCon(tg, 'MeetTracerTong2'), "dialoghi vanilla di Tong (killswitch) tolti");
	Check(tg != None && !tg.bInvincible, "prima dell'assalto Tong si puo' attaccare");
	foreach AllActors(class'Trigger', tr)
		if (tr.Tag == 'TurnOnTheKillSwitch' || tr.Event == 'Killswitch_Sequence')
			Check(!tr.bCollideActors, "operazione del killswitch spenta:" @ tr.Name);
	Check(FindClass('AlexJacobson') == None || !FindClass('AlexJacobson').bInWorld, "Alex non c'e'");

	lab.Guards();
	lab.Wave1();
	Check(CountTag('UCSPCommander') == 1, "il comandante entra con la prima ondata");
	Check(CountTag('UCSPLeader') == 0, "niente capo squadra separato (e' il comandante)");
	// in gioco la seconda ondata arriva quando la prima e' gia' scesa: qui la si toglie
	// di mezzo, tranne il comandante (che poi va nella sala operatoria)
	foreach AllActors(class'ScriptedPawn', sp)
		if (Left(string(sp.Tag), 4) == "UCSP" && sp.Tag != 'UCSPCommander')
		{
			Log("UCHKCheck ondata 1:" @ sp.Tag @ "a" @ sp.Location);
			sp.LeaveWorld();
		}
	lab.Wave2();
	Check(CountTag('UCSPCommando') == 5, "commando creati (" $ CountTag('UCSPCommando') $ "/5)");
	Check(CountTag('UCSPTech') == 2, "tecnici Special Projects creati (" $ CountTag('UCSPTech') $ "/2)");
	Check(CountTag('UCSPCommander') == 1 && CountTag('UCSPEscort') == 1 && CountTag('UCPrisoner') == 1, "scena del prigioniero creata (un solo comandante)");
	foreach AllActors(class'ScriptedPawn', sp, 'UCSPCommander')
		Check(sp.Orders == 'GoingTo' || VSize((sp.Location - lab.CmdPost()) * vect(1,1,0)) < 150, "il comandante va al suo posto nella sala operatoria");
	// senza comandante (morto) ne arriva un altro direttamente al posto
	foreach AllActors(class'ScriptedPawn', sp, 'UCSPCommander')
		sp.LeaveWorld();
	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.Tag == 'UCSPEscort' || sp.Tag == 'UCPrisoner')
			sp.LeaveWorld();
	lab.PrisonerScene();
	foreach AllActors(class'ScriptedPawn', sp, 'UCSPCommander')
		if (sp.bInWorld)
			Check(VSize((sp.Location - lab.CmdPost()) * vect(1,1,0)) < 150, "comandante di riserva al suo posto");
	Check(CountTag('UCLPTech') == 3, "tecnici del Luminous Path creati (" $ CountTag('UCLPTech') $ "/3)");
	foreach AllActors(class'ScriptedPawn', sp)
	{
		if (Left(string(sp.Tag), 4) == "UCSP")
		{
			Check(sp.GetAllianceType('Player') == ALLIANCE_Friendly, "Special Projects amico di JC:" @ sp.Name);
			Check(sp.GetAllianceType('Triad') == ALLIANCE_Hostile, "Special Projects ostile alle guardie:" @ sp.Name);
			Log("UCHKCheck" @ sp.Tag @ sp.FamiliarName @ "a" @ sp.Location);
		}
		if ((sp.IsA('TriadLumPath') || sp.IsA('TriadRedArrow')) && sp.bInWorld)
		{
			Check(sp.GetAllianceType('mj12') == ALLIANCE_Hostile, "guardia di Tong ostile a MJ12:" @ sp.Name);
			Check(sp.GetAllianceType('Player') != ALLIANCE_Hostile, "guardia di Tong non ostile a JC:" @ sp.Name);
		}
	}
}

function Timer()
{
	local DeusExLevelInfo info;
	local ScriptedPawn sp;
	local DeusExDecoration deco;
	local UCHKWorld world;
	local UCHKStory story;

	foreach AllActors(class'DeusExLevelInfo', info)
		mapName = Caps(info.mapName);
	Log("UCHKCheck mappa" @ mapName);

	// come fa il gioco quando entra il giocatore
	foreach AllActors(class'ScriptedPawn', sp)
		sp.ConBindEvents();
	foreach AllActors(class'DeusExDecoration', deco)
		deco.ConBindEvents();

	if (Left(mapName, 3) == "06_" && mapName != "06_HONGKONG_HELIBASE")
	{
		world = Spawn(class'UCHKWorld');
		world.mapName = mapName;
		world.bFirstVisit = True;
		world.bSetup = True;
		world.Setup();
		world.Attitudes();

		story = Spawn(class'UCHKStory');
		story.mapName = mapName;
		story.bSetup = True;
		story.SetupForMap();
	}

	if (mapName == "06_HONGKONG_WANCHAI_MARKET")
		Market();
	else if (mapName == "06_HONGKONG_WANCHAI_UNDERWORLD")
		Underworld();
	else if (mapName == "06_HONGKONG_WANCHAI_STREET")
		Street();
	else if (mapName == "06_HONGKONG_WANCHAI_COMPOUND")
		Compound();
	else if (mapName == "04_NYC_BATTERYPARK")
		BatteryPark();
	else if (mapName == "04_NYC_STREET")
		NYCStreet();
	else if (mapName == "06_HONGKONG_HELIBASE")
		Helibase();
	else if (mapName == "06_HONGKONG_TONGBASE")
		TongBase();
	else
		Check(False, "mappa non prevista:" @ mapName);

	Log("UCHKCheck:" @ mapName @ checked @ "checked," @ failed @ "failed.");
	ConsoleCommand("exit");
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(1.0, False);
}

defaultproperties
{
     bHidden=True
}
