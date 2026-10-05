//=============================================================================
// UCSceneTongLab - Hong Kong, laboratorio di Tong e assalto MJ12 (HK-9/HK-10,
// design: docs\HONGKONG_ASSAULT_DESIGN.md). Primo vero reveal operativo di MJ12,
// ma nessuno spara a JC e Simons non confessa niente.
// Copione: "FINAL DIALOGUE PASS", parti IX-X (punti 29-39).
//  1. JC e' un ospite tollerato (le guardie lo avvertono a parole); Tong gli parla.
//  2. Tong gli mostra i dati VersaLife sul terminale (finestra del HUD) e gli lascia
//     un frammento: "I'm interested in changing your information."
//  3. Allarme: "Your friends." Simons (InfoLink a senso unico, JC non risponde):
//     "Hold your position." Poi Tong, di persona, spiega cosa e' successo: "You were
//     the authentication." e scappa dai portelli.
//  4. Assalto "Special Projects": il comandante raggiunge JC ("We'll secure the
//     facility from here"), poi va nella sala operatoria. Combattono le guardie,
//     uccidono i tecnici del Luminous Path, i loro tecnici cancellano i dati.
//  5. Il prigioniero (facoltativo): JC si oppone -> lo portano via ("Take him
//     upstairs"); JC se ne va -> lo giustiziano. Nessun combattimento con JC.
//  6. Il comandante dopo la fuga: "You weren't part of this operation until you
//     found the door." Poi Simons (UCSceneSimonsAfterTong): REPORT TO VERSALIFE.
// Se Tong e' morto prima dell'assalto, l'assalto parte lo stesso (archivi).
// Se JC esce a meta' scena (la scena e' transient, non resta nella mappa salvata) al
// ritorno si riprende dal punto giusto: niente conversazioni o InfoLink ripetuti.
// Copione dell'InfoLink e della reazione di Tong: "INFOLINK FIX PASS", punto 3.
// Solo nomi/flag fra un tick e l'altro.
//=============================================================================
class UCSceneTongLab extends UCScene;

var float t, sinceEscape, prisonerWait;
var int wave, n;
var bool bGuardLine;
var name barked[8];
var int numBarked;
var bool bPrisonerBark, bPrisonerDone, bExecuting;
var float execTime;
var float d;
var bool bSimonsCalled, bGreeted, bCmdPosted;
var float greetWait, afterWait;

// --- utilita' -----------------------------------------------------------------
function ScriptedPawn Tagged(name tagName)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp, tagName)
		if (sp.bInWorld && sp.Health > 0)
			return sp;
	return None;
}

function ScriptedPawn Tong()
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.IsA('TracerTong'))
			return sp;
	return None;
}

function bool TongDead()
{
	local ScriptedPawn tg;

	tg = Tong();
	return GetF('TracerTong_Dead') || (tg != None && tg.Health <= 0) || (tg == None && !GetF('TongEscapedCompound'));
}

function bool HasCon(Actor A, name conName)
{
	local ConListItem item;

	for (item = ConListItem(A.ConListItems); item != None; item = item.next)
		if (item.con != None && item.con.conName == conName)
			return True;
	return False;
}

// Solo le conversazioni nostre (le vanilla parlano del killswitch, di Paul, di Alex...).
function OnlyOurs(Actor A)
{
	local ConListItem item, prev;

	prev = None;
	item = ConListItem(A.ConListItems);
	while (item != None)
	{
		if (item.con == None || Left(string(item.con.conName), 3) != "UC_")
		{
			if (prev == None)
				A.ConListItems = item.next;
			else
				prev.next = item.next;
		}
		else
			prev = item;
		item = item.next;
	}
}

function ScriptedPawn Place(class<ScriptedPawn> cls, name tagName, string bindName, vector spot, int yaw, string shownName)
{
	local ScriptedPawn sp;
	local rotator r;
	local vector offs[5];
	local int i;

	r.Yaw = yaw;
	offs[0] = vect(0, 0, 0);
	offs[1] = vect(0, 0, 24);
	offs[2] = vect(50, 0, 12);
	offs[3] = vect(-50, 0, 12);
	offs[4] = vect(0, 50, 12);
	for (i = 0; i < 5 && sp == None; i++)
		sp = Spawn(cls,, tagName, spot + offs[i], r);
	if (sp == None)
		return None;
	sp.BindName = bindName;
	sp.ConBindEvents();
	sp.FamiliarName = shownName;
	sp.UnfamiliarName = shownName;
	sp.SetOrders('Standing', '', True);
	return sp;
}

// Squadra "Special Projects": amica di JC, nemica di Tong, delle sue guardie e dei tecnici.
function ScriptedPawn Trooper(class<ScriptedPawn> cls, name tagName, string bindName, vector spot, string shownName)
{
	local ScriptedPawn sp;

	sp = Place(cls, tagName, bindName, spot, 32768, shownName);
	if (sp == None)
		return None;
	sp.Alliance = 'mj12';
	sp.ChangeAlly('mj12', 1.0, True);
	sp.ChangeAlly('Player', 1.0, True);
	sp.ChangeAlly('Triad', -1.0, True);
	sp.ChangeAlly('Allies', -1.0, True);
	sp.ChangeAlly('LumPathTech', -1.0, True);
	sp.ChangeAlly('LumPathPrisoner', 0.0, True);
	return sp;
}

function Go(ScriptedPawn sp, name markTag, vector spot, optional bool bRun)
{
	local UCMark mark;

	if (sp == None)
		return;
	foreach AllActors(class'UCMark', mark, markTag)
		mark.Destroy();
	Spawn(class'UCMark',, markTag, spot);
	if (bRun)
		sp.SetOrders('RunningTo', markTag, True);
	else
		sp.SetOrders('GoingTo', markTag, True);
}

function bool Near(ScriptedPawn sp, vector spot, float dist)
{
	return sp == None || VSize((sp.Location - spot) * vect(1,1,0)) < dist;
}

function bool SeesPlayer(vector where)
{
	local DeusExPlayer P;

	P = Plr();
	return P != None && FastTrace(where, P.Location + vect(0,0,1) * P.BaseEyeHeight);
}

function float JCDist(Actor A)
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None || A == None)
		return 100000;
	return VSize(P.Location - A.Location);
}

// --- 1. arrivo: base pronta, Tong e guardie --------------------------------------
function SetupBase()
{
	local ScriptedPawn sp, tg;
	local Trigger tr;
	local DataLinkTrigger dl;
	local DeusExPlayer P;
	local UCCon c;

	P = Plr();
	if (P != None && P.FlagBase != None)
	{
		P.FlagBase.SetBool('DL_TongFixesKillswitch1_Played', True,, 99);
		P.FlagBase.SetBool('DL_TongFixesKillswitch2_Played', True,, 99);
	}
	SetF('JCLedMJ12ToTong', True);
	// niente operazione del killswitch
	foreach AllActors(class'Trigger', tr)
		if (tr.Tag == 'TurnOnTheKillSwitch' || tr.Event == 'Killswitch_Sequence' || tr.Event == 'Operation1')
			tr.SetCollision(False, False, False);
	foreach AllActors(class'DataLinkTrigger', dl)
		if (dl.datalinkTag == 'DL_TongFixesKillswitch1' || dl.datalinkTag == 'DL_TongFixesKillswitch2')
			dl.SetCollision(False, False, False);

	// le guardie tollerano JC, non sono sue amiche
	foreach AllActors(class'ScriptedPawn', sp)
		if ((sp.IsA('TriadLumPath') || sp.IsA('TriadRedArrow')) && sp.bInWorld)
		{
			OnlyOurs(sp);
			if (!GetF('MJ12AssaultStarted'))
				sp.ChangeAlly('Player', 0.0, False);
		}

	tg = Tong();
	if (tg == None || GetF('TongMeetingComplete'))
		return;
	OnlyOurs(tg);
	tg.ChangeAlly('Player', 0.0, False);
	tg.bInvincible = False;   // prima dell'assalto JC puo' attaccarlo (c'e' il ripiego)
	tg.SetOrders('Standing', '', True);
	if (HasCon(tg, 'UC_TongMeet'))
		return;

	c = new(Level) class'UCCon';
	c.Begin('UC_TongMeet', "TracerTong", False);
	c.Once();
	c.Radius(220);
	c.Line("TracerTong", "JCDenton", "J.C. Denton.");
	c.Line("JCDenton", "TracerTong", "Tracer Tong.");
	c.Line("TracerTong", "JCDenton", "Paul believed you would come here eventually. I don't think this is what he had in mind.");
	c.Line("JCDenton", "TracerTong", "Paul expected me to ask for your help.");
	c.Line("TracerTong", "JCDenton", "And instead you have orders to remove me.");
	c.Line("JCDenton", "TracerTong", "Identify your network first. Then take you out.");
	c.Line("TracerTong", "JCDenton", "A useful phrase. 'Take out.' It allows a bureaucrat to postpone deciding whether a man is a prisoner or a corpse.");
	c.Line("JCDenton", "TracerTong", "You're still here.");
	c.Line("TracerTong", "JCDenton", "Because you came to talk first.");
	// la posizione di JC
	c.Line("JCDenton", "TracerTong", "Paul says UNATCO is compromised.");
	c.Line("TracerTong", "JCDenton", "And you do not believe him.");
	c.Line("JCDenton", "TracerTong", "I believe he found evidence. I don't believe joining the NSF made the evidence more true.");
	c.Line("TracerTong", "JCDenton", "That is the difference between you and your brother. Paul reached the end of the argument before he showed you the beginning. He asked you to accept his conclusions because you trusted him.");
	c.Line("JCDenton", "TracerTong", "I don't.");
	c.Line("TracerTong", "JCDenton", "Good. Trust is useful between friends. It is a poor substitute for evidence.");
	c.Line("JCDenton", "TracerTong", "Then show me yours.");
	c.Line("TracerTong", "JCDenton", "Exactly.");
	c.SetFlag('TongMeetingStarted', True);
	c.Done();
	c.AttachTo(tg);
}

// Le guardie avvertono JC a parole quando passa (una volta ciascuna).
function GuardBarks()
{
	local DeusExPlayer P;
	local ScriptedPawn sp, other;
	local UCCon c;
	local int i;
	local bool bDone;

	P = Plr();
	if (P == None || P.conPlay != None || numBarked >= 8)
		return;
	foreach AllActors(class'ScriptedPawn', sp)
	{
		if (!(sp.IsA('TriadLumPath') || sp.IsA('TriadRedArrow')) || !sp.bInWorld || sp.Health <= 0)
			continue;
		if (VSize(sp.Location - P.Location) > 260 || !P.LineOfSightTo(sp))
			continue;
		bDone = False;
		for (i = 0; i < numBarked; i++)
			if (barked[i] == sp.Name)
				bDone = True;
		if (bDone)
			continue;
		barked[numBarked] = sp.Name;
		numBarked++;
		// il nome "UCTongGuard" lo porta solo chi parla adesso (con "Base_Guard" condiviso
		// la battuta poteva partire da un'altra guardia); nome fisso per lo strumento delle voci
		foreach AllActors(class'ScriptedPawn', other)
			if (other.BindName == "UCTongGuard")
				other.BindName = "UCTongGuardDone";
		sp.BindName = "UCTongGuard";
		c = new(Level) class'UCCon';
		c.Begin('UC_TongGuardBark', "UCTongGuard", True);
		c.Passive();
		bGuardLine = !bGuardLine;
		if (bGuardLine)
			c.Line("UCTongGuard", "JCDenton", "Tong agreed to see you. That doesn't make you welcome.");
		else
			c.Line("UCTongGuard", "JCDenton", "Keep your weapon down and there won't be a problem.");
		c.Done();
		P.StartConversation(sp, IM_Other, c.con, False, False);
		return;
	}
}

// --- 2. il terminale ------------------------------------------------------------
function ShowTerminal(bool bShow)
{
	local DeusExPlayer P;
	local DeusExRootWindow root;
	local HUDInformationDisplay info;
	local TextWindow winText;

	P = Plr();
	if (P == None)
		return;
	root = DeusExRootWindow(P.rootWindow);
	if (root == None || root.hud == None)
		return;
	info = root.hud.ShowInfoWindow();
	if (info == None)
		return;
	info.ClearTextWindows();
	if (!bShow)
	{
		info.Hide();
		return;
	}
	winText = info.AddTextWindow();
	winText.SetText("AMBROSIA SHIPPING RECORDS -- UNATCO MANIFESTS (COPIED BY P. DENTON)|n"
		$ "  AMB-2219-A   rerouted via: VERSALIFE PHARMACEUTICAL SUBSIDIARY 4|n"
		$ "  AMB-2219-B   rerouted via: VERSALIFE LOGISTICS (HONG KONG)|n"
		$ "  AMB-2231-C   rerouted via: [REDACTED]|n|n"
		$ "VERSALIFE CORPORATION -- LABORATORY AUTHORIZATIONS|n"
		$ "  facility ............ LEVEL 2 (NOT PUBLICLY LISTED)|n"
		$ "  research ............ NANOTECHNOLOGY -- RESTRICTED|n"
		$ "  project file ........ [CORRUPTED]|n"
		$ "  cross-reference ..... 'GRAY'  [DATA INCOMPLETE]");
}

function bool StartEvidence()
{
	local UCCon c;
	local ScriptedPawn tg;
	local DeusExPlayer P;

	P = Plr();
	tg = Tong();
	if (P == None || tg == None || !P.CanStartConversation() || !tg.CanConverse())
		return False;
	c = new(Level) class'UCCon';
	c.Begin('UC_TongEvidence', "TracerTong", False);
	c.Once();
	c.Line("TracerTong", "JCDenton", "These are shipping records Paul obtained before he left UNATCO. Compare the identifiers with these.");
	c.Line("JCDenton", "TracerTong", "Same Ambrosia shipments.");
	c.Line("TracerTong", "JCDenton", "Rerouted through VersaLife subsidiaries. Here are the corresponding laboratory authorizations.");
	c.Line("JCDenton", "TracerTong", "Nanotechnology.");
	c.Line("TracerTong", "JCDenton", "Restricted research, below the publicly listed facilities.");
	c.Line("JCDenton", "TracerTong", "This proves VersaLife is involved with the shipments. It doesn't prove UNATCO is.");
	c.Line("TracerTong", "JCDenton", "No. So keep looking.");
	c.Line("JCDenton", "TracerTong", "Why give this to me?");
	c.Line("TracerTong", "JCDenton", "Because Paul tried to change your allegiance. I'm interested in changing your information.");
	c.SetFlag('TongEvidenceShown', True);
	c.Done();
	return PlayConv(c, tg);
}

function Fragment()
{
	AddFragment(Plr());
}

// Il frammento di dati VersaLife (nota + flag). Static: lo usano anche UCHKStory e
// UCSceneSimonsAfterTong.
static function AddFragment(DeusExPlayer P)
{
	if (P == None || P.FlagBase == None || P.FlagBase.GetBool('VersaLifeEvidenceFragment'))
		return;
	P.FlagBase.SetBool('VersaLifeEvidenceFragment', True,, 99);
	P.AddNote("VersaLife data fragment (Tong's terminal): Ambrosia shipments from UNATCO manifests rerouted through VersaLife subsidiaries. Restricted nanotechnology research below the publicly listed facilities. Cross-reference: 'GRAY'. Incomplete.", False, True);
}

// --- 3. allarme e fuga ----------------------------------------------------------
function bool StartAlarmTalk()
{
	local UCCon c;
	local ScriptedPawn tg;
	local DeusExPlayer P;

	P = Plr();
	tg = Tong();
	if (P == None || tg == None || !P.CanStartConversation() || !tg.CanConverse())
		return False;
	c = new(Level) class'UCCon';
	c.Begin('UC_TongAlarm', "TracerTong", False);
	c.Once();
	c.Line("JCDenton", "TracerTong", "What happened?");
	c.Line("TracerTong", "JCDenton", "Several armed teams just entered the upper compound. Coalition weapons, coordinated movement.");
	c.Line("TracerTong", "JCDenton", "Your friends.");
	c.Line("JCDenton", "TracerTong", "UNATCO?");
	c.Line("TracerTong", "JCDenton", "You tell me.");
	c.Done();
	return PlayConv(c, tg);
}

// Dopo la chiamata di Simons: Tong ha capito perche' l'hanno trovato, e se ne va.
function bool StartUnderstands()
{
	local UCCon c;
	local ScriptedPawn tg;
	local DeusExPlayer P;

	P = Plr();
	tg = Tong();
	if (P == None || tg == None || !P.CanStartConversation() || !tg.CanConverse())
		return False;
	c = new(Level) class'UCCon';
	c.Begin('UC_TongUnderstands', "TracerTong", False);
	c.Once();
	c.Line("TracerTong", "JCDenton", "There is your answer.");
	c.Line("JCDenton", "TracerTong", "To what?");
	c.Line("TracerTong", "JCDenton", "Why they let you find me.");
	c.Line("TracerTong", "JCDenton", "They did not send you here because they trusted you to kill me. They sent you because I would allow Paul Denton's brother through a door I would close to any other UNATCO agent.");
	c.Line("JCDenton", "TracerTong", "They could have followed me from the market.");
	c.Line("TracerTong", "JCDenton", "And found another safehouse. Another basement. Another empty room.");
	c.Line("TracerTong", "JCDenton", "You were the authentication.");
	// la fuga
	c.Line("TracerTong", "JCDenton", "Come with me.");
	c.Line("JCDenton", "TracerTong", "No.");
	c.Line("TracerTong", "JCDenton", "Then stay here.");
	c.Line("TracerTong", "JCDenton", "Paul wanted you to believe him. I don't.");
	c.Line("TracerTong", "JCDenton", "Watch what your people do.");
	c.SetFlag('JCWasTheAuthentication', True);
	c.Done();
	return PlayConv(c, tg);
}

function Alarm()
{
	local AlarmUnit a;

	SetF('UC_TongAlarmRang', True);
	foreach AllActors(class'AlarmUnit', a)
		a.Trigger(Self, Plr());
}

// Tong apre i portelli dell'ala ovest e sparisce nel magazzino.
function TongFlees()
{
	local ScriptedPawn tg;

	tg = Tong();
	SetF('MJ12AssaultStarted', True);
	SetF('TongEscapedCompound', True);
	SetF('TongLocationUnknown', True);
	if (tg == None)
		return;
	tg.bInvincible = True;   // la fuga scriptata non puo' fallire
	FireTag('hatch');
	Go(tg, 'UCTongExit', vect(-1500, 450, -128), True);
}

function bool TongGone()
{
	local ScriptedPawn tg;
	local DeusExPlayer P;

	tg = Tong();
	P = Plr();
	if (tg == None || !tg.bInWorld || tg.Health <= 0)
		return True;
	if (!GetF('TongEscapedCompound'))
		return False;
	// sparisce oltre i portelli, o appena JC lo perde di vista
	if ((Near(tg, vect(-1500, 450, -128), 150) || sinceEscape > 6) && (P == None || !P.LineOfSightTo(tg)))
	{
		tg.LeaveWorld();
		return True;
	}
	if (sinceEscape > 45)
	{
		tg.LeaveWorld();
		return True;
	}
	return False;
}

// --- 4. l'assalto ---------------------------------------------------------------
function Guards()
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if ((sp.IsA('TriadLumPath') || sp.IsA('TriadRedArrow')) && sp.bInWorld)
		{
			sp.ChangeAlly('mj12', -1.0, True);
			sp.ChangeAlly('Player', 0.0, False);
		}
}

function Wave1()
{
	local ScriptedPawn sp;

	FireTag('Secretdoor01');   // la porta fra la sala d'ingresso e il laboratorio
	// il comandante va da JC (vicino al laboratorio); il saluto lo fa partire GreetTick
	sp = Trooper(class'MJ12Commando', 'UCSPCommander', "UCSPCommander", vect(1240, -860, 306), "Special Projects Commander");
	Go(sp, 'UCSPGo1', vect(250, 100, 48), True);
	sp = Trooper(class'MJ12Commando', 'UCSPCommando', "UCSPCommando", vect(1280, -760, 306), "Special Projects Commando");
	Go(sp, 'UCSPGo2', vect(0, -150, 48), True);
	sp = Trooper(class'MJ12Commando', 'UCSPCommando', "UCSPCommando", vect(1180, -880, 306), "Special Projects Commando");
	Go(sp, 'UCSPGo3', vect(450, -750, 48), True);
	sp = Trooper(class'MJ12Commando', 'UCSPCommando', "UCSPCommando", vect(1140, -760, 262), "Special Projects Commando");
	Go(sp, 'UCSPGo4', vect(-100, -800, 48), True);

	// tecnici del Luminous Path nei laboratori: non sono una minaccia
	LPTech(vect(450, 150, -128));
	LPTech(vect(750, 300, -128));
	LPTech(vect(130, -200, -256));
}

function LPTech(vector spot)
{
	local ScriptedPawn sp;

	sp = Place(class'ScientistMale', 'UCLPTech', "UCLPTech", spot, 0, "Luminous Path Technician");
	if (sp == None)
		return;
	sp.Alliance = 'LumPathTech';
	sp.ChangeAlly('LumPathTech', 1.0, True);
	sp.ChangeAlly('mj12', -1.0, True);
	sp.ChangeAlly('Player', 0.0, False);
}

function Wave2()
{
	local ScriptedPawn sp;
	local UCCon c;

	sp = Trooper(class'MJ12Troop', 'UCSPTech', "UCSPTech1", vect(1240, -860, 306), "Special Projects Technician");
	Go(sp, 'UCSPTech1Go', vect(225, -60, 48));
	if (sp != None)
	{
		c = new(Level) class'UCCon';
		c.Begin('UC_SPTechTalk', "UCSPTech1", False);
		c.Once();
		c.Radius(220);
		c.Line("JCDenton", "UCSPTech1", "What are you doing?");
		c.Line("UCSPTech1", "JCDenton", "Sanitizing the network. Tong's people had access to restricted Coalition material.");
		c.Line("JCDenton", "UCSPTech1", "Those systems are evidence.");
		c.Line("UCSPTech1", "JCDenton", "Anything relevant has already been copied.");
		c.Line("JCDenton", "UCSPTech1", "By who?");
		c.Line("UCSPTech1", "JCDenton", "Special Projects.");
		c.SetFlag('JCSawDataSanitized', True);
		c.Done();
		c.AttachTo(sp);
	}
	sp = Trooper(class'MJ12Troop', 'UCSPTech', "UCSPTech2", vect(1280, -760, 306), "Special Projects Technician");
	Go(sp, 'UCSPTech2Go', vect(650, 250, -128));
	sp = Trooper(class'MJ12Commando', 'UCSPCommando', "UCSPCommando", vect(1180, -880, 306), "Special Projects Commando");
	Go(sp, 'UCSPGo5', vect(-550, 300, 48), True);
	sp = Trooper(class'MJ12Commando', 'UCSPCommando', "UCSPCommando", vect(1140, -760, 262), "Special Projects Commando");
	Go(sp, 'UCSPGo6', vect(130, -200, -256), True);
	PrisonerScene();
}

// Il comandante e un prigioniero nella sala operatoria (est), dove JC non guarda.
function PrisonerScene()
{
	local ScriptedPawn cmd, pr, esc;

	cmd = Tagged('UCSPCommander');
	if (cmd == None)
		cmd = Trooper(class'MJ12Commando', 'UCSPCommander', "UCSPCommander", CmdPost(), "Special Projects Commander");
	else
		Go(cmd, 'UCSPCmdPost', CmdPost());   // ci va a piedi; fuori dalla vista di JC arriva subito
	esc = Trooper(class'MJ12Commando', 'UCSPEscort', "UCSPEscort", vect(1400, 420, -190), "Special Projects Commando");
	pr = Place(class'ScientistMale', 'UCPrisoner', "UCPrisoner", vect(1600, 330, -195), 32768, "Luminous Path Technician");
	if (pr != None)
	{
		pr.Alliance = 'LumPathPrisoner';
		pr.ChangeAlly('mj12', 0.0, True);
		pr.ChangeAlly('Player', 0.0, False);
	}
	if (cmd != None && pr != None && Near(cmd, CmdPost(), 150))
		cmd.DesiredRotation = rotator(pr.Location - cmd.Location);
}

// Il posto del comandante nella sala operatoria, davanti al prigioniero.
function vector CmdPost()
{
	return vect(1450, 250, -190);
}

// Il comandante raggiunge il suo posto: a piedi se JC lo guarda, subito se no.
// Ritorna True quando e' li'.
function bool CommanderPosted()
{
	local ScriptedPawn cmd, pr;
	local DeusExPlayer P;

	cmd = Tagged('UCSPCommander');
	if (cmd == None)
		return False;
	if (bCmdPosted || Near(cmd, CmdPost(), 150))
	{
		if (!bCmdPosted)
		{
			bCmdPosted = True;
			cmd.SetOrders('Standing', '', True);
			pr = Tagged('UCPrisoner');
			if (pr != None)
				cmd.DesiredRotation = rotator(pr.Location - cmd.Location);
		}
		return True;
	}
	P = Plr();
	if (P != None && !P.LineOfSightTo(cmd) && !SeesPlayer(CmdPost() + vect(0,0,40)))
	{
		cmd.SetLocation(CmdPost());
		return False;   // al prossimo giro si sistema
	}
	return False;
}

// Tecnici: uno ripulisce il terminale di Tong, l'altro piazza cariche nei laboratori.
function TechWork()
{
	local ScriptedPawn tech;
	local ComputerPersonal pc;
	local CrateExplosiveSmall bomb;
	local bool bCharges;

	foreach AllActors(class'ScriptedPawn', tech, 'UCSPTech')
	{
		if (tech.BindName == "UCSPTech1" && Near(tech, vect(225, -60, 48), 90) && !GetF('UC_TongPCWiped'))
		{
			foreach AllActors(class'ComputerPersonal', pc)
				if (VSize(pc.Location - vect(274, -28, 49)) < 80 && !pc.bHidden)
				{
					SetF('UC_TongPCWiped', True);
					Spawn(class'ExplosionSmall',,, pc.Location);
					pc.PlaySound(Sound(DynamicLoadObject("DeusExSounds.Generic.Spark1", class'Sound', True)), SLOT_None);
					pc.bHidden = True;
					pc.SetCollision(False, False, False);
				}
		}
		if (tech.BindName == "UCSPTech2" && Near(tech, vect(650, 250, -128), 110))
		{
			foreach AllActors(class'CrateExplosiveSmall', bomb)
				if (bomb.Tag == 'UCCharge')
					bCharges = True;
			if (!bCharges)
			{
				Spawn(class'CrateExplosiveSmall',, 'UCCharge', tech.Location + vect(40, 30, -30));
				Spawn(class'CrateExplosiveSmall',, 'UCCharge', tech.Location + vect(-45, -25, -30));
			}
		}
	}
}

// --- 6. il prigioniero ----------------------------------------------------------
function bool StartPrisonerTalk()
{
	local UCCon c;
	local ScriptedPawn cmd;
	local DeusExPlayer P;

	P = Plr();
	cmd = Tagged('UCSPCommander');
	if (P == None || cmd == None || !P.CanStartConversation() || !cmd.CanConverse())
		return False;
	c = new(Level) class'UCCon';
	c.Begin('UC_PrisonerTalk', "UCSPCommander", False);
	c.Once();
	c.Line("JCDenton", "UCSPCommander", "Hold your fire.");
	c.Line("UCSPCommander", "JCDenton", "He's part of Tong's technical staff.");
	c.Line("JCDenton", "UCSPCommander", "Then arrest him.");
	c.Line("UCSPCommander", "JCDenton", "We weren't instructed to process prisoners.");
	c.Line("JCDenton", "UCSPCommander", "You are now.");
	c.Line("UCSPCommander", "UCSPEscort", "Take him upstairs.");
	c.SetFlag('JCObjectedToMJ12Execution', True);
	c.Done();
	return PlayConv(c, cmd);
}

function PrisonerBark()
{
	local UCCon c;
	local ScriptedPawn pr;
	local DeusExPlayer P;

	P = Plr();
	pr = Tagged('UCPrisoner');
	if (P == None || pr == None || P.conPlay != None)
		return;
	c = new(Level) class'UCCon';
	c.Begin('UC_PrisonerBark', "UCPrisoner", True);
	c.Passive();
	c.Line("UCPrisoner", "UCSPCommander", "I'm unarmed! I'm not security!");
	c.Done();
	P.StartConversation(pr, IM_Other, c.con, False, False);
	bPrisonerBark = True;
}

// JC se n'e' andato: il comandante esegue (ostile al prigioniero; dopo un attimo,
// se non e' ancora morto, il colpo e' andato a segno comunque).
function Execute()
{
	local ScriptedPawn cmd;

	cmd = Tagged('UCSPCommander');
	SetF('JCIgnoredMJ12Execution', True);
	if (cmd != None)
		cmd.ChangeAlly('LumPathPrisoner', -1.0, True);
	bExecuting = True;
	execTime = 0;
}

function ExecuteTick()
{
	local ScriptedPawn cmd, pr;

	if (!bExecuting)
		return;
	execTime += 0.5;
	if (execTime < 2.5)
		return;
	bExecuting = False;
	cmd = Tagged('UCSPCommander');
	pr = Tagged('UCPrisoner');
	if (pr != None)
		pr.TakeDamage(1000, cmd, pr.Location, vect(0,0,0), 'Shot');
}

// JC si e' opposto: un soldato porta via il prigioniero.
function TakeAway()
{
	Go(Tagged('UCPrisoner'), 'UCSPExit', vect(1180, -830, 340));
	Go(Tagged('UCSPEscort'), 'UCSPExit2', vect(1220, -860, 330));
}

function PrisonerTick()
{
	local ScriptedPawn pr, cmd;
	local DeusExPlayer P;

	if (bPrisonerDone)
		return;
	P = Plr();
	pr = Tagged('UCPrisoner');
	cmd = Tagged('UCSPCommander');
	if (P == None || pr == None || cmd == None)
	{
		bPrisonerDone = True;
		return;
	}
	if (GetF('UC_PrisonerTalk_Played') && P.conPlay == None)
	{
		bPrisonerDone = True;
		TakeAway();
		return;
	}
	if (!CommanderPosted())
		return;
	if (!bPrisonerBark)
	{
		if (JCDist(pr) < 700 && P.LineOfSightTo(pr))
			PrisonerBark();
		return;
	}
	prisonerWait += 0.5;
	if (JCDist(cmd) < 350 && P.LineOfSightTo(cmd) && !GetF('UC_PrisonerTalk_Played'))
	{
		StartPrisonerTalk();
		return;
	}
	if (JCDist(pr) > 1000 || prisonerWait > 15)
	{
		bPrisonerDone = True;
		Execute();
	}
}

// Chi porta via il prigioniero sparisce all'uscita, quando JC non guarda.
function CleanupEscort()
{
	local ScriptedPawn sp;
	local DeusExPlayer P;

	P = Plr();
	foreach AllActors(class'ScriptedPawn', sp)
		if ((sp.Tag == 'UCPrisoner' || sp.Tag == 'UCSPEscort') && sp.bInWorld && sp.Health > 0
			&& sp.IsInState('GoingTo') && Near(sp, vect(1200, -840, 0), 160) && (P == None || !P.LineOfSightTo(sp)))
			sp.LeaveWorld();
}

// JC ha sparato alla squadra: la route continua, Simons ne parlera'.
function CheckFired()
{
	local ScriptedPawn sp;

	if (GetF('JCAttackedSpecialProjects'))
		return;
	foreach AllActors(class'ScriptedPawn', sp)
		if (Left(string(sp.Tag), 4) == "UCSP" && sp.bInWorld && sp.GetAllianceType('Player') == ALLIANCE_Hostile)
		{
			SetF('JCAttackedSpecialProjects', True);
			return;
		}
}

// 36. Il comandante raggiunge JC appena entrato.
function bool StartCommanderMeet()
{
	local UCCon c;
	local ScriptedPawn cmd;
	local DeusExPlayer P;

	P = Plr();
	cmd = Tagged('UCSPCommander');
	if (P == None || cmd == None || !P.CanStartConversation() || !cmd.CanConverse())
		return False;
	c = new(Level) class'UCCon';
	c.Begin('UC_SPCommanderMeet', "UCSPCommander", False);
	c.Once();
	c.Line("UCSPCommander", "JCDenton", "Agent Denton. Special Projects. We'll secure the facility from here.");
	c.IfFlag('TongEscapedCompound', True, "Fled");
	c.Line("JCDenton", "UCSPCommander", "Tong is dead.");
	c.Line("UCSPCommander", "JCDenton", "Then his data is what matters. Your orders are to preserve any intelligence you recovered and stay clear of the sweep.");
	c.Jump("Orders");
	c.Label("Fled");
	c.Line("JCDenton", "UCSPCommander", "Tong's moving through the rear section.");
	c.Line("UCSPCommander", "JCDenton", "Teams are covering the exits. Your orders are to preserve any intelligence you recovered and stay clear of the sweep.");
	c.Label("Orders");
	c.Line("JCDenton", "UCSPCommander", "Simons told me to secure the facility.");
	c.Line("UCSPCommander", "JCDenton", "Then we have compatible objectives.");
	c.Done();
	return PlayConv(c, cmd);
}

// Il saluto parte quando il comandante e' vicino a JC e lo vede (al massimo 30 s).
function bool GreetTick()
{
	local ScriptedPawn cmd;
	local DeusExPlayer P;

	if (bGreeted || GetF('UC_SPCommanderMeet_Played'))
		return True;
	P = Plr();
	cmd = Tagged('UCSPCommander');
	greetWait += 0.5;
	if (P == None || cmd == None || greetWait > 30 || cmd.GetAllianceType('Player') == ALLIANCE_Hostile)
		return True;
	if (P.conPlay == None && JCDist(cmd) < 320 && cmd.LineOfSightTo(P) && StartCommanderMeet())
		bGreeted = True;
	return False;
}

// 39. Dopo la fuga di Tong: il comandante, se JC gli va vicino. Poi chiama Simons.
function bool StartCommanderAfter()
{
	local UCCon c;
	local ScriptedPawn cmd;
	local DeusExPlayer P;

	P = Plr();
	cmd = Tagged('UCSPCommander');
	if (P == None || cmd == None || !P.CanStartConversation() || !cmd.CanConverse())
		return False;
	c = new(Level) class'UCCon';
	c.Begin('UC_SPCommanderAfter', "UCSPCommander", False);
	c.Once();
	c.IfFlag('TongEscapedCompound', True, "Fled");
	c.Line("UCSPCommander", "JCDenton", "The facility is secure. The network, personnel and data are ours.");
	c.Line("JCDenton", "UCSPCommander", "Nobody told me that was the objective.");
	c.Jump("Door");
	c.Label("Fled");
	c.Line("JCDenton", "UCSPCommander", "Tong got out.");
	c.Line("UCSPCommander", "JCDenton", "The facility is secure.");
	c.Line("JCDenton", "UCSPCommander", "Tong was the objective.");
	c.Line("UCSPCommander", "JCDenton", "Tong was one objective. The network, personnel and data were the others.");
	c.Line("JCDenton", "UCSPCommander", "Nobody told me that.");
	c.Label("Door");
	c.Line("UCSPCommander", "JCDenton", "You weren't part of this operation until you found the door.");
	c.Done();
	return PlayConv(c, cmd);
}

// True quando si puo' passare alla chiamata di Simons.
function bool AfterTick()
{
	local ScriptedPawn cmd;
	local DeusExPlayer P;

	if (GetF('UC_SPCommanderAfter_Played'))
		return !Talking();
	P = Plr();
	cmd = Tagged('UCSPCommander');
	afterWait += 0.5;
	if (P == None || cmd == None || afterWait > 40 || cmd.GetAllianceType('Player') == ALLIANCE_Hostile)
		return True;
	if (afterWait > 3 && P.conPlay == None && JCDist(cmd) < 380 && P.LineOfSightTo(cmd))
		StartCommanderAfter();
	return False;
}

// Cliccandolo dopo: una battuta.
function CommanderAgain()
{
	local ScriptedPawn cmd;
	local UCCon c;

	cmd = Tagged('UCSPCommander');
	if (cmd == None || HasCon(cmd, 'UC_SPCommanderAgain'))
		return;
	c = new(Level) class'UCCon';
	c.Begin('UC_SPCommanderAgain', "UCSPCommander", False);
	c.Require('UC_SPCommanderMeet_Played', True);
	c.Line("UCSPCommander", "JCDenton", "Stay clear of the sweep, Agent Denton.");
	c.Done();
	c.AttachTo(cmd);
}

function SimonsAssault()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	if (P.FindGoal('FindTracerTong') != None)
		P.GoalCompleted('FindTracerTong');
	if (TongDead() && !GetF('TongEscapedCompound'))
	{
		if (P.FindGoal('UCTongArchives') == None)
			P.GoalAdd('UCTongArchives', "Tracer Tong is dead. A Special Projects recovery team is sweeping his facility: do not interfere, secure any intelligence you have already recovered and assist the team only if requested.", True);
		return;
	}
	if (P.FindGoal('UCSecureTong') == None)
		P.GoalAdd('UCSecureTong', "A Special Projects recovery team is sweeping Tracer Tong's facility. Hold your position: do not interfere, secure any intelligence you have already recovered and assist the team only if requested.", True);
}

// InfoLink a senso unico: Simons non ammette niente, a capire ci pensa Tong (dopo).
// Variante (non nel copione): Tong gia' morto -> "Tong's death has been confirmed."
function float SimonsLine(int i)
{
	local bool bDead;

	bDead = TongDead() && !GetF('TongEscapedCompound');
	switch (i)
	{
		case 0: return Say("WaltonSimons", "Denton. Hold your position. A Special Projects recovery team is entering the compound.");
		case 1:
			if (bDead)
				return Say("WaltonSimons", "Tong's death has been confirmed. Do not interfere with the sweep. Secure any intelligence you've already recovered and assist the team only if requested.");
			return Say("WaltonSimons", "Tong's location has been confirmed. Do not interfere with the sweep. Secure any intelligence you've already recovered and assist the team only if requested.") + 1.0;
		case 2:
			if (bDead)
				return -1;
			return Say("WaltonSimons", "You've completed the locating phase of your assignment.");
	}
	return -1;
}

function float InfoLine(int i)
{
	return SimonsLine(i);
}

// Inizio dell'InfoLink dell'assalto: goal e flag subito (se JC cambia zona a meta'
// vale come ascoltato, UCScene.InfoStart).
function StartSimonsCall()
{
	bSimonsCalled = True;
	SetF('UC_TongAssaultCall', True);
	SimonsAssault();
	InfoStart("WaltonSimons");
}

function AfterCall()
{
	local UCSceneSimonsAfterTong s;

	s = Spawn(class'UCSceneSimonsAfterTong');
	if (s != None)
	{
		s.bTongDead = TongDead() && !GetF('TongEscapedCompound');
		s.bFired = GetF('JCAttackedSpecialProjects');
	}
}

function bool AfterTongPlaying()
{
	local UCSceneSimonsAfterTong s;

	foreach AllActors(class'UCSceneSimonsAfterTong', s)
		return True;
	return False;
}

state Playing
{
Begin:
	Sleep(0.5);
	SetupBase();
	if (GetF('MJ12AssaultResolved'))
		Goto('Finish');
	if (GetF('MJ12AssaultStarted'))
		Goto('AfterAssault');   // salvataggio a meta' assalto: si riprende dalla fine
	// JC era uscito a meta' scena: si riprende dal punto giusto
	if (GetF('UC_TongAssaultCall'))
	{
		bSimonsCalled = True;
		if (TongDead() || GetF('UC_TongUnderstands_Played'))
			Goto('Assault');
		Goto('Understand');
	}
	if (GetF('UC_TongAlarm_Played'))
		Goto('Call');
	if (GetF('UC_TongEvidence_Played'))
		Goto('AlarmStart');
Meet:
	// Tong morto prima di parlare: l'assalto parte lo stesso
	if (TongDead())
	{
		Sleep(5.0);
		Goto('Assault');
	}
	GuardBarks();
	if (!GetF('UC_TongMeet_Played') || Talking())
	{
		Sleep(0.5);
		Goto('Meet');
	}
	SetF('TongMeetingComplete', True);
	// Tong va al terminale
	Go(Tong(), 'UCTongPC', vect(225, -60, 48));
	t = 0;
ToPC:
	if (!TongDead() && !Near(Tong(), vect(225, -60, 48), 90) && t < 8)
	{
		Sleep(0.5);
		t += 0.5;
		Goto('ToPC');
	}
	if (TongDead())
		Goto('Assault');
	if (Tong() != None)
		Tong().SetOrders('Standing', '', True);
	ShowTerminal(True);
	Sleep(9.0);
	ShowTerminal(False);
	Fragment();
Evidence:
	if (TongDead())
		Goto('Assault');
	if (!StartEvidence())
	{
		Sleep(0.25);
		Goto('Evidence');
	}
	Sleep(0.5);
WaitEvidence:
	if (Talking())
	{
		Sleep(0.25);
		Goto('WaitEvidence');
	}
	SetF('TongEvidenceConversationComplete', True);
	// l'allarme
	Sleep(2.0);
AlarmStart:
	if (!GetF('UC_TongAlarmRang'))
		Alarm();
	Sleep(1.5);
AlarmTalk:
	if (TongDead())
		Goto('Assault');
	if (!StartAlarmTalk())
	{
		Sleep(0.25);
		Goto('AlarmTalk');
	}
	Sleep(0.5);
WaitAlarm:
	if (Talking())
	{
		Sleep(0.25);
		Goto('WaitAlarm');
	}
	Sleep(1.0);
Call:
	// Simons (InfoLink, parla solo lui): "Hold your position." Tong resta li'
	if (TongDead())
		Goto('Assault');
	StartSimonsCall();
	Sleep(1.0);
	n = 0;
SimonsNext:
	d = SimonsLine(n);
	if (d >= 0)
	{
		Sleep(d);
		n++;
		Goto('SimonsNext');
	}
	HideInfo();
	Sleep(0.5);
Understand:
	if (TongDead())
		Goto('Assault');
	if (!StartUnderstands())
	{
		Sleep(0.25);
		Goto('Understand');
	}
	Sleep(0.5);
WaitUnderstand:
	if (Talking())
	{
		Sleep(0.25);
		Goto('WaitUnderstand');
	}
Assault:
	if (!TongDead())
		TongFlees();
	Guards();
	Wave1();
	CommanderAgain();
	SetF('MJ12AssaultStarted', True);
	sinceEscape = 0;
	Sleep(2.0);
	if (bSimonsCalled)
		Goto('Greet');
	// Tong morto prima della chiamata: Simons la fa adesso
	StartSimonsCall();
	Sleep(1.0);
	n = 0;
DeadNext:
	d = SimonsLine(n);
	if (d >= 0)
	{
		Sleep(d);
		n++;
		Goto('DeadNext');
	}
	HideInfo();
Greet:
	// il comandante raggiunge JC: "We'll secure the facility from here."
	TongGone();
	CheckFired();
	if (!GreetTick() || Talking())
	{
		Sleep(0.5);
		sinceEscape += 0.5;
		Goto('Greet');
	}
	Wave2();
AfterAssault:
	CommanderAgain();
	t = 0;
Watch:
	TongGone();
	TechWork();
	PrisonerTick();
	ExecuteTick();
	CleanupEscort();
	CheckFired();
	Fragment();
	Sleep(0.5);
	t += 0.5;
	sinceEscape += 0.5;
	// dopo la fuga: quando il prigioniero e' risolto (o comunque dopo un po')
	if ((!bPrisonerDone && t < 60) || Talking() || !TongGone())
		Goto('Watch');
	afterWait = 0;
CommanderTalk:
	// "You weren't part of this operation until you found the door."
	TechWork();
	CleanupEscort();
	CheckFired();
	if (!AfterTick())
	{
		Sleep(0.5);
		Goto('CommanderTalk');
	}
	AfterCall();
	t = 0;
Linger:
	// la scena resta per i tecnici e la scorta finche' l'InfoLink non e' finito
	TechWork();
	CleanupEscort();
	CheckFired();
	Sleep(0.5);
	t += 0.5;
	if (AfterTongPlaying() && t < 150)
		Goto('Linger');
Finish:
	CommanderAgain();
	Destroy();
}

defaultproperties
{
}
