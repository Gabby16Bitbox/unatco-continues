//=============================================================================
// UCSceneBattery - Battery Park, stazione della metro.
// JC scende dalla metro e Anna Navarre gli corre incontro: scena concitata
// (conversazione nativa). Poi Anna prende la metro per dare la caccia a Paul.
// Jock aspetta con l'elicottero oltre il forte (UCMod.AttachJockTalk).
//=============================================================================
class UCSceneBattery extends UCScene;

var float waited;

function AnnaNavarre FindAnna()
{
	local AnnaNavarre a;

	foreach AllActors(class'AnnaNavarre', a)
		return a;
	return None;
}

function StartRunToJC()
{
	local DeusExPlayer P;
	local AnnaNavarre anna;

	P = Plr();
	anna = FindAnna();
	if (P == None || anna == None)
		return;
	Spawn(class'UCMark',, 'UCJCMark', P.Location);
	anna.SetOrders('RunningTo', 'UCJCMark', True);
}

function bool AnnaArrived()
{
	local DeusExPlayer P;
	local AnnaNavarre anna;

	P = Plr();
	anna = FindAnna();
	return (P == None || anna == None || VSize(anna.Location - P.Location) < 240);
}

function StopAnnaForTalk()
{
	local AnnaNavarre anna;

	anna = FindAnna();
	if (anna != None)
		anna.SetOrders('Standing', '', True);
}

function bool StartAnnaTalk()
{
	local UCCon c;
	local DeusExPlayer P;
	local AnnaNavarre anna;

	P = Plr();
	anna = FindAnna();
	// Wait for menus, falling, other conversations and the end of Anna's run.
	if (P == None || anna == None || !P.CanStartConversation() || !anna.CanConverse())
		return False;

	c = new(Level) class'UCCon';
	c.Begin('UC_M1_AnnaBP', "AnnaNavarre", False);
	c.Once();
	c.Line("AnnaNavarre", "JCDenton", "Denton! Where is he?");
	c.Line("JCDenton", "AnnaNavarre", "Not my assignment. Tong is.");
	c.Line("AnnaNavarre", "JCDenton", "He's carrying UNATCO codes, troop rotations, safehouse locations. Every hour he's out there, agents die.");
	c.Line("JCDenton", "AnnaNavarre", "Then don't waste the hour on me.");
	c.Line("AnnaNavarre", "JCDenton", "I'm taking the subway sweep. If he went underground, I'll find him.");
	c.Line("AnnaNavarre", "JCDenton", "Your pilot's been sitting in this park for hours. Manderley expected you in Hong Kong by now.");
	c.Line("JCDenton", "AnnaNavarre", "I'm on my way.");
	c.Line("AnnaNavarre", "JCDenton", "And Denton. Next time you see your brother, make sure you're the one who walks away.");
	c.Line("JCDenton", "AnnaNavarre", "Is that a threat?");
	c.Line("AnnaNavarre", "JCDenton", "Yes.");
	c.Done();

	return PlayConv(c, anna);
}

// Anna prende la metro (corre al binario da cui JC e' arrivato).
function AnnaTakesSubway()
{
	local AnnaNavarre anna;
	local UCMark mark;

	foreach AllActors(class'UCMark', mark, 'UCJCMark')
		mark.Destroy();
	anna = FindAnna();
	if (anna != None)
		anna.SetOrders('RunningTo', 'ToBatteryPark', True);
}

// Anna sparisce quando e' sul binario o non si vede piu'.
function bool AnnaGone()
{
	local DeusExPlayer P;
	local AnnaNavarre anna;
	local Actor dest;

	P = Plr();
	anna = FindAnna();
	if (anna == None || anna.bHidden)
		return True;
	foreach AllActors(class'Actor', dest, 'ToBatteryPark')
		if (VSize(anna.Location - dest.Location) < 160)
			return True;
	return (P != None && !P.LineOfSightTo(anna) && VSize(anna.Location - P.Location) > 700);
}

state Playing
{
Begin:
	Sleep(1.5);
	StartRunToJC();
	waited = 0;
WaitArrive:
	if (!AnnaArrived() && waited < 12.0)
	{
		Sleep(0.5);
		waited += 0.5;
		Goto('WaitArrive');
	}
	StopAnnaForTalk();
	Sleep(0.25);
StartTalk:
	if (FindAnna() == None)
		Goto('AfterTalk');
	if (!StartAnnaTalk())
	{
		Sleep(0.25);
		Goto('StartTalk');
	}
	Sleep(0.5);
WaitConv:
	if (Talking())
	{
		Sleep(0.25);
		Goto('WaitConv');
	}
AfterTalk:
	SetF('UC_BP_AnnaDone', True);
	AnnaTakesSubway();
	waited = 0;
WaitAnna:
	if (!AnnaGone() && waited < 40.0)
	{
		Sleep(0.5);
		waited += 0.5;
		Goto('WaitAnna');
	}
	if (FindAnna() != None)
		FindAnna().LeaveWorld();
	Destroy();
}

defaultproperties
{
}
