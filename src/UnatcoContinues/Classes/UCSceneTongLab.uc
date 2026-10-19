// RW: independent documents, explicit report, rear loading entry, then assault.
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
	sp.InitializePawn();
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
	local bool entering;

	if (sp == None)
		return;
	foreach AllActors(class'UCMark', mark, markTag)
		mark.Destroy();
	Spawn(class'UCMark',, markTag, spot);
	entering=sp.IsInState('UCEntry');
	if (bRun)
		sp.SetOrders('RunningTo', markTag, True);
	else
		sp.SetOrders('GoingTo', markTag, True);
	// Changing the destination must not skip the physical loading entrance.
	if (entering) sp.GotoState('UCEntry');
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
			if (!GetF('MJ12AssaultStarted') && (sp.Enemy == None || sp.Enemy != Plr()))
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
	c.Line("TracerTong", "JCDenton", "Paul said you might come.");
	c.Line("JCDenton", "TracerTong", "Paul expected me to ask for help.");
	c.Line("TracerTong", "JCDenton", "Instead you brought an arrest order.");
	c.Line("JCDenton", "TracerTong", "You're coming with me.");
	c.IfFlag('UCHongKongRaidStarted',False,"PaulRecords");
	c.IfFlag('UCHongKongShipmentDefended',False,"ObservedShipment");
	c.Line("TracerTong","JCDenton","You protected a shipment when you arrived in Hong Kong.");
	c.Jump("ShipmentQuestion");
	c.Label("ObservedShipment");
	c.Line("TracerTong","JCDenton","You were at the shipment when you arrived in Hong Kong.");
	c.Label("ShipmentQuestion");
	c.Line("JCDenton","TracerTong","Your people attacked it.");
	c.Line("TracerTong","JCDenton","Yes. Did you ever ask why?");
	c.IfFlag('HongKongShipmentInspected',False,"UninspectedShipment");
	c.Line("JCDenton","TracerTong","VersaLife.");
	c.Line("TracerTong","JCDenton","Good.");
	c.Line("JCDenton","TracerTong","What's in the container?");
	c.Line("TracerTong","JCDenton","That's the right question. Compare the identifiers with the records in the archive.");
	c.Jump("PaulRecords");
	c.Label("UninspectedShipment");
	c.Line("JCDenton","TracerTong","Why?");
	c.Line("TracerTong","JCDenton","Because your people were moving something they did not want examined. Their transfer records are in the archive.");
	c.Label("PaulRecords");
	c.Line("TracerTong", "JCDenton", "You can try. First, look at what brought your brother here.");
	c.IfFlag('UC_PaulManifestRead', False, "Unread");
	c.Line("JCDenton", "TracerTong", "I've already seen his records.");
	c.Line("TracerTong", "JCDenton", "Then compare them.");
	c.Jump("Ready");
	c.Label("Unread");
	c.Line("JCDenton", "TracerTong", "Then show me his records.");
	c.Line("TracerTong", "JCDenton", "There is a copy in the archive. Read it for yourself.");
	c.Label("Ready");
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
			c.Line("UCTongGuard", "JCDenton", "One wrong move and you don't leave this place.");
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
    // Documents are read explicitly at the native computer; no timed HUD popup.
}

function bool StartEvidence()
{
    local UCCon c;
    local ScriptedPawn tg;
    local DeusExPlayer P;
    P = Plr(); tg = Tong();
    if (P == None || tg == None || !P.CanStartConversation() || !tg.CanConverse()
        || !GetF('UC_VLManifestRead') || (!GetF('UC_PaulManifestRead') && !GetF('UC_TongPaulCopyRead')))
        return False;
    c = new(Level) class'UCCon';
    c.Begin('UC_TongEvidence', "TracerTong", False);
    c.Once();
    c.IfFlag('UC_PaulManifestRead', False, "TongCopy");
    c.Line("JCDenton", "TracerTong", "These shipment IDs match Paul's records.");
    c.Jump("Compare");
    c.Label("TongCopy");
    c.Line("JCDenton", "TracerTong", "This copy has the same shipment identifiers.");
    c.Label("Compare");
    c.Line("TracerTong", "JCDenton", "The receiving accounts belong to VersaLife.");
    c.Line("JCDenton", "TracerTong", "Level Two. Restricted nanotechnology.");
    c.Line("TracerTong", "JCDenton", "Below the laboratories they show their visitors.");
    c.IfFlag('UC_SPHelibaseAuthRead', False, "UnknownAuthorization");
    c.Line("JCDenton", "TracerTong", "These are the same authorization codes I saw at the helibase.");
    c.Line("TracerTong", "JCDenton", "Special Projects.");
    c.Jump("Limits");
    c.Label("UnknownAuthorization");
    c.Line("JCDenton", "TracerTong", "What is this authorization?");
    c.Line("TracerTong", "JCDenton", "Special Projects. Compare it with the field authorization your hosts issued.");
    c.Label("Limits");
    c.Line("JCDenton", "TracerTong", "Your records say Simons has access to VersaLife. They don't prove UNATCO is involved.");
    c.Line("TracerTong", "JCDenton", "I didn't say they did.");
    c.Line("JCDenton", "TracerTong", "I want the originals.");
    c.Line("TracerTong", "JCDenton", "Then keep looking.");
    c.SetFlag('TongEvidenceShown', True);
    c.SetFlag('TongEvidenceConversationComplete', True);
    c.Done(); return PlayConv(c, tg);
}

function Fragment()
{
	AddFragment(Plr());
}

// Il frammento di dati VersaLife (nota + flag). Static: lo usano anche UCHKStory e
// UCSceneSimonsAfterTong.
static function AddFragment(DeusExPlayer P)
{
    // Kept for old callers: it never invents an independent copy.
    if (P == None || P.FlagBase == None || !P.FlagBase.GetBool('UC_VLManifestCopied')
        || P.FlagBase.GetBool('VersaLifeEvidenceFragment')) return;
    P.FlagBase.SetBool('VersaLifeEvidenceFragment', True,, 99);
    P.AddNote("Independent field copy: " $ class'UCInvestigation'.static.DocumentText('Manifest'), False, True);
}

// --- 3. allarme e fuga ----------------------------------------------------------
function bool StartAlarmTalk()
{
    local UCCon c; local ScriptedPawn tg; local DeusExPlayer P;
    P = Plr(); tg = Tong();
    if (P == None || tg == None || !P.CanStartConversation() || !tg.CanConverse() || JCDist(tg)>700) return False;
    c = new(Level) class'UCCon';
    c.Begin('UC_TongAlarm', "TracerTong", True); c.Passive();
    c.Line("TracerTong", "JCDenton", "They didn't send you to kill me.");
    c.Line("TracerTong", "JCDenton", "They sent you to open the door.");
    c.Line("TracerTong", "JCDenton", "Now watch what comes through it.");
    c.SetFlag('JCWasTheAuthentication', True);
    c.Done(); return P.StartConversation(tg, IM_Other, c.con, False, False);
}

// Dopo l'ingresso fisico: Tong propone la propria via di fuga a JC.
function bool StartUnderstands()
{
    local UCCon c; local ScriptedPawn tg; local DeusExPlayer P;
    P = Plr(); tg = Tong();
    if (P == None || tg == None || !P.CanStartConversation() || !tg.CanConverse() || JCDist(tg)>500) return False;
    c = new(Level) class'UCCon';
    c.Begin('UC_TongUnderstands', "TracerTong", True); c.Passive();
    c.Line("TracerTong", "JCDenton", "Come with me.");
    c.Line("JCDenton", "TracerTong", "No.");
    c.Line("TracerTong", "JCDenton", "Then watch.");
    c.Done(); return P.StartConversation(tg, IM_Other, c.con, False, False);
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

function bool EntryWarning()
{
    local UCCon c; local ScriptedPawn guard,cmd; local DeusExPlayer P;
    P=Plr(); cmd=Tagged('UCSPCommander');
    if(P==None || cmd==None || !P.CanStartConversation() || GetF('UC_EntryWarning_Played')) return False;
    foreach AllActors(class'ScriptedPawn',guard)
        if(guard.IsA('TriadLumPath') && guard.bInWorld && guard.Health>0) break;
    c=new(Level) class'UCCon'; c.Begin('UC_EntryWarning',"UCSPCommander",True); c.Passive();
    if(guard!=None && guard.IsA('TriadLumPath') && guard.Health>0)
    {
        guard.BindName="UCTongGuard";
        c.Line("UCTongGuard","UCSPCommander","Stop. This is Luminous Path territory.");
    }
    c.Line("UCSPCommander","UCTongGuard","Separate the personnel from the systems.");
    c.SetFlag('UC_EntryWarning_Played',True); c.Done();
    return P.StartConversation(cmd,IM_Other,c.con,False,False);
}

function Wave1()
{
    local ScriptedPawn sp;
    if (GetF('UC_AssaultWave1Spawned')) return;
    SetF('UC_AssaultWave1Spawned', True);
    Guards();
    foreach AllActors(class'ScriptedPawn', sp)
        if (Left(string(sp.Tag), 4)=="UCSP")
        {
            sp.ChangeAlly('Triad', -1.0, True);
            sp.ChangeAlly('LumPath', -1.0, True);
            sp.ChangeAlly('triad_lum', -1.0, True);
            sp.ChangeAlly('LumPathTech', -1.0, True);
            // Keep the loading threshold clear for the technicians/escort.
            // Assign native orders even while they are still entering, so a
            // combat interruption resumes the route rather than Standing.
            if (sp.Tag=='UCSPCommander') Go(sp,'UCSPReceivingPost',vect(128,-704,48));
            else if (sp.Tag=='UCSPEntry2') Go(sp,'UCSPReceiving2',vect(128,-420,48),True);
            else if (sp.Tag=='UCSPEntry3') Go(sp,'UCSPReceiving3',vect(600,-752,48),True);
            else if (sp.Tag=='UCSPEntry4') Go(sp,'UCSPReceiving4',vect(-224,-640,48),True);
        }
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
	if (GetF('UC_AssaultWave2Spawned')) return;
	SetF('UC_AssaultWave2Spawned', True);

	sp = Trooper(class'UCSPTech', 'UCSPTech', "UCSPTech1", class'UCServiceAccess'.static.Stage(0), "Special Projects Technician");
	Go(sp, 'UCSPTech1Go', vect(160, 95, 48));
	if (sp != None) sp.GotoState('UCEntry');
	if (sp != None)
	{
		c = new(Level) class'UCCon';
		c.Begin('UC_SPTechTalk', "UCSPTech1", False);
		c.Once();
		c.Radius(220);
		c.Line("JCDenton", "UCSPTech1", "Those systems are evidence.");
		c.Line("UCSPTech1", "JCDenton", "The authorized copies have been secured.");
		c.Line("JCDenton", "UCSPTech1", "Authorized by whom?");
		c.Line("UCSPTech1", "JCDenton", "Special Projects.");
		c.SetFlag('JCSawDataSanitized', True);
		c.Done();
		c.AttachTo(sp);
	}
	sp = Trooper(class'UCSPTech', 'UCSPTech', "UCSPTech2", class'UCServiceAccess'.static.Stage(1), "Special Projects Technician");
	Go(sp, 'UCSPTech2Go', vect(650, 250, -128));
	if (sp != None) sp.GotoState('UCEntry');
	sp = Trooper(class'UCSPCommando', 'UCSPCommando', "UCSPCommando", class'UCServiceAccess'.static.Stage(2), "Special Projects Commando");
	Go(sp, 'UCSPGo5', vect(-550, 300, 48), True);
	if (sp != None) sp.GotoState('UCEntry');
	sp = Trooper(class'UCSPCommando', 'UCSPCommando', "UCSPCommando", class'UCServiceAccess'.static.Stage(3), "Special Projects Commando");
	Go(sp, 'UCSPGo6', vect(130, -200, -256), True);
	if (sp != None) sp.GotoState('UCEntry');
	PrisonerScene();
}

// Il comandante e la scorta raggiungono il prigioniero dall'accesso di carico.
function PrisonerScene()
{
	local ScriptedPawn cmd, pr, esc;

	cmd = Tagged('UCSPCommander');
	if (cmd == None)
	{
		cmd = Trooper(class'UCSPCommando', 'UCSPCommander', "UCSPCommander", class'UCServiceAccess'.static.Stage(0), "Special Projects Commander");
		Go(cmd, 'UCSPCmdPost', CmdPost());
		if (cmd != None) cmd.GotoState('UCEntry');
	}
	else
		Go(cmd, 'UCSPCmdPost', CmdPost());   // ci va a piedi; fuori dalla vista di JC arriva subito
	esc = Trooper(class'UCSPCommando', 'UCSPEscort', "UCSPEscort", class'UCServiceAccess'.static.Stage(1), "Special Projects Commando");
	Go(esc, 'UCSPEscortPost', vect(1400, 420, -190));
	if (esc != None) esc.GotoState('UCEntry');
	pr = Place(class'UCPrisoner', 'UCPrisoner', "UCPrisoner", vect(1600, 330, -195), 32768, "Luminous Path Technician");
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
		if (tech.BindName == "UCSPTech1" && Near(tech, vect(160, 95, 48), 90) && !GetF('UC_TongPCWiped'))
		{
			foreach AllActors(class'ComputerPersonal', pc)
				if (VSize(pc.Location - vect(274, -28, 49)) < 80 && !pc.bHidden
					&& VSize(tech.Location-pc.Location)<256 && tech.LineOfSightTo(pc))
				{
					SetF('UC_TongPCWiped', True);
					Spawn(class'ExplosionSmall',,, pc.Location);
					pc.PlaySound(Sound(DynamicLoadObject("DeusExSounds.Generic.Spark1", class'Sound', True)), SLOT_None);
					SetF('UC_SPTeamRecordsRecovered', True);
					if (GetF('UC_VLManifestCopied'))
						Msg("The archive was sanitized. Your independent copy remains available in Notes.");
					else Msg("The archive was sanitized. No independent field copy was preserved.");
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
	c.Line("UCSPCommander", "JCDenton", "Step back, Agent Denton.");
	c.Line("JCDenton", "UCSPCommander", "Arrest him.");
	c.Line("UCSPCommander", "JCDenton", "He is not cleared for transfer.");
	c.Line("JCDenton", "UCSPCommander", "Then clear him.");
	// The escort may still be approaching. Keep the native conversation local.
	c.Line("UCSPCommander", "JCDenton", "Take him.");
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
	c.Line("UCPrisoner", "UCSPCommander", "I'm unarmed!");
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
	Go(Tagged('UCPrisoner'), 'UCSPExit', vect(128,-1000,48));
	Go(Tagged('UCSPEscort'), 'UCSPExit2', vect(128,-1000,48));
}

function PrisonerTick()
{
	local ScriptedPawn pr, cmd;
	local DeusExPlayer P;

	if (bPrisonerDone || GetF('UC_PrisonerSaved')) return;
	if (GetF('JCIgnoredMJ12Execution'))
	{
		bPrisonerDone=True;
		Execute();
		return;
	}
	P = Plr();
	pr = Tagged('UCPrisoner');
	cmd = Tagged('UCSPCommander');
	if (P == None || pr == None || cmd == None)
	{
		bPrisonerDone = True;
		return;
	}
	if (pr.Health <= 0) { bPrisonerDone=True; return; }
	// The player cannot leave during this exchange; its audio must not consume
	// the time available to object to the execution.
	if (P.conPlay!=None && (P.conPlay.con.conName=='UC_PrisonerTalk' || P.conPlay.con.conName=='UC_PrisonerBark')) return;
	if (GetF('JCObjectedToMJ12Execution') && P.conPlay == None)
	{
		bPrisonerDone = True;
		SetF('UC_PrisonerSaved', True);
		if (!GetF('UC_PrisonerIdentityRecorded'))
		{
			SetF('UC_PrisonerIdentityRecorded', True);
			P.AddNote("Detainee LP-T17: Tong laboratory technician, taken alive after my objection. Special Projects custody. Request his transfer record and testimony at VersaLife.", False, True);
		}
		TakeAway();
		return;
	}
	if (!CommanderPosted())
		return;
	prisonerWait += 0.5;
	if (!bPrisonerBark)
	{
		if (JCDist(pr) < 700 && P.LineOfSightTo(pr)) PrisonerBark();
		else if (prisonerWait > 25 && JCDist(pr) > 1000)
		{
			bPrisonerDone = True;
			Execute();
		}
		return;
	}
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
			&& GetF('UC_PrisonerSaved'))
		{
			if (sp.IsInState('GoingTo') && Near(sp,vect(128,-1000,48),110))
				sp.GotoState('UCExit');
			if (sp.IsInState('UCExit') && Near(sp,class'UCServiceAccess'.static.Stage(0),140)
				&& Abs(sp.Location.Z-class'UCServiceAccess'.static.Stage(0).Z)<64
				&& (P==None || !P.LineOfSightTo(sp))) sp.LeaveWorld();
		}
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
    local UCCon c; local ScriptedPawn cmd; local DeusExPlayer P;
    P=Plr(); cmd=Tagged('UCSPCommander');
    if(P==None || cmd==None || !P.CanStartConversation() || !cmd.CanConverse()) return False;
    c=new(Level) class'UCCon'; c.Begin('UC_SPCommanderMeet', "UCSPCommander", False); c.Once();
    c.Line("UCSPCommander", "JCDenton", "Agent Denton. We have the facility from here.");
    c.IfFlag('TracerTong_Dead', True, "Dead");
    c.Line("JCDenton", "UCSPCommander", "Tong is supposed to be taken alive.");
    c.Jump("Orders"); c.Label("Dead");
    c.Line("JCDenton", "UCSPCommander", "Tong is dead.");
    c.Label("Orders");
    c.Line("UCSPCommander", "JCDenton", "Our orders include his network. Keep clear of the sweep.");
    c.Done(); return PlayConv(c, cmd);
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
    local UCCon c; local ScriptedPawn cmd; local DeusExPlayer P;
    P=Plr(); cmd=Tagged('UCSPCommander');
    if(P==None || cmd==None || !P.CanStartConversation() || !cmd.CanConverse()) return False;
    c=new(Level) class'UCCon'; c.Begin('UC_SPCommanderAfter',"UCSPCommander",False); c.Once();
    c.Line("UCSPCommander","JCDenton","The facility is secure.");
    c.Line("JCDenton","UCSPCommander","Those systems are evidence.");
    c.Line("UCSPCommander","JCDenton","The authorized copies have been secured. Submit your report from the terminal.");
    c.Done(); return PlayConv(c,cmd);
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
{ return -1; }

function float InfoLine(int i)
{
	return SimonsLine(i);
}

// Inizio dell'InfoLink dell'assalto: goal e flag subito (se JC cambia zona a meta'
// vale come ascoltato, UCScene.InfoStart).
function StartSimonsCall()
{ }

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
    if (GetF('MJ12AssaultResolved')) Goto('Finish');
    if (GetF('MJ12AssaultStarted')) Goto('Assault');
WaitForPlayer:
    GuardBarks();
    if (!TongDead() && GetF('UC_TongMeet_Played') && !Talking() && !GetF('TongMeetingComplete'))
    {
        SetF('TongMeetingComplete', True);
        Go(Tong(), 'UCTongPC', vect(225, -60, 48));
    }
    if (!TongDead() && GetF('TongMeetingComplete') && GetF('UC_VLManifestRead')
        && !GetF('UC_TongEvidence_Played') && (GetF('UC_PaulManifestRead') || GetF('UC_TongPaulCopyRead'))
        && JCDist(Tong())<450 && !Talking()) StartEvidence();
    if (GetF('MJ12AssaultStarted')) Goto('Assault');
    Sleep(0.5);
    Goto('WaitForPlayer');
Assault:
    // Only UCInvestigation's observed crossing (or a migrated old save) gets here.
    if (!GetF('UC_SPEntryCrossed') && !GetF('UC_LegacyAssault')) Goto('WaitForPlayer');
    if (!GetF('UC_TongAlarmRang')) Alarm();
    EntryWarning();
    Sleep(0.5);
Challenge:
    if (Talking()) { Sleep(0.25); Goto('Challenge'); }
    Wave1();
    if (!TongDead() && !GetF('TongEscapedCompound'))
    {
        StartAlarmTalk();
        Sleep(0.5);
        Goto('Escape');
    }
    Goto('Greet');
Escape:
    if (Talking()) { Sleep(0.25); Goto('Escape'); }
    StartUnderstands();
    Sleep(0.5);
WaitEscape:
    if (Talking()) { Sleep(0.25); Goto('WaitEscape'); }
    if (!TongDead()) TongFlees();
Greet:
    CommanderAgain();
    TongGone();
    CheckFired();
    if (!GreetTick() || Talking()) { Sleep(0.5); sinceEscape+=0.5; Goto('Greet'); }
    Wave2();
    t=0;
Watch:
    TongGone(); TechWork(); PrisonerTick(); ExecuteTick(); CleanupEscort(); CheckFired();
    Sleep(0.5); t+=0.5; sinceEscape+=0.5;
    if ((!bPrisonerDone && t<90) || bExecuting || Talking()) Goto('Watch');
    SetF('UC_SweepComplete', True);
    if (!GetF('UC_SPTeamRecordsRecovered')) SetF('UC_SPTeamRecordsRecovered', True);
    if (Plr().FindGoal('UCSubmitOperationReport') == None)
        GoalNew('UCSubmitOperationReport', "Submit the Special Projects operation report from Tong's archive or a secure terminal in the compound office, Queen's Tower or Wan Chai police station.");
    Msg("Sweep complete. Upload the operation report from the archive terminal or another secure terminal.");
    afterWait=0;
CommanderTalk:
    TechWork(); CleanupEscort(); CheckFired();
    if (!AfterTick()) { Sleep(0.5); Goto('CommanderTalk'); }
AwaitReport:
    TechWork(); CleanupEscort(); CheckFired();
    if (!GetF('UC_FinalReportRequested')) { Sleep(0.5); Goto('AwaitReport'); }
    AfterCall();
    Sleep(1.0);
Finish:
    CommanderAgain(); Destroy();
}

defaultproperties
{
}
