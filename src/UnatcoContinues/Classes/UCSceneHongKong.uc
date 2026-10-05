//=============================================================================
// UCSceneHongKong - eliporto di Hong Kong, dopo il dialogo con Jock.
// Tutto insieme, appena finito il dialogo:
//  - titolo HONG KONG e i nuovi obiettivi: Tong e' il bersaglio, non il salvatore;
//  - un ufficiale MJ12 arriva di corsa da JC e lo manda all'ascensore, poi torna al posto;
//  - il tetto dell'hangar si apre (SequenceTrigger vanilla 'hangar_open'), Jock decolla
//    in verticale e se ne va (intanto l'ufficiale parla).
// L'elicottero si muove a passi con SetLocation (collisioni spente): niente
// dipendenza dai percorsi vanilla, pensati per la sequenza dei missili.
//=============================================================================
class UCSceneHongKong extends UCScene;

var float t;
var vector vel;
var int heliStage;      // 0 a terra, 1 sale, 2 se ne va, 3 sparito
var int officerStage;   // 0 corre da JC, 1 parla, 2 torna al posto, 3 fatto
var float officerT, tickT;

function BlackHelicopter Chopper()
{
	local BlackHelicopter heli;

	foreach AllActors(class'BlackHelicopter', heli, 'chopper')
		return heli;
	return None;
}

function LiftOff()
{
	local BlackHelicopter heli;

	heli = Chopper();
	if (heli == None)
		return;
	heli.SetCollision(False, False, False);
	heli.bCollideWorld = False;
	heli.SetPhysics(PHYS_None);
}

function Step(float dt)
{
	local BlackHelicopter heli;

	heli = Chopper();
	if (heli != None)
		heli.SetLocation(heli.Location + vel * dt);
}

function ScriptedPawn Officer()
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp, 'UCHKOfficer')
		return sp;
	return None;
}

// L'ufficiale MJ12 corre verso JC (un passo davanti a lui); quando e' vicino
// parte da solo il suo dialogo (UC_HKOfficer, per vicinanza: vedi UCMod).
function OfficerFollow()
{
	local DeusExPlayer P;
	local ScriptedPawn o;
	local UCMark mark;
	local vector spot, dir;

	P = Plr();
	o = Officer();
	if (P == None || o == None)
		return;
	dir = (o.Location - P.Location) * vect(1,1,0);
	spot = P.Location + Normal(dir) * 110;
	foreach AllActors(class'UCMark', mark, 'UCHKOfficerGoal')
	{
		mark.SetLocation(spot);
		return;
	}
	Spawn(class'UCMark',, 'UCHKOfficerGoal', spot);
	o.SetOrders('RunningTo', 'UCHKOfficerGoal', True);
}

// Torna al suo posto.
function OfficerBack()
{
	local ScriptedPawn o;
	local UCMark mark;

	foreach AllActors(class'UCMark', mark, 'UCHKOfficerGoal')
		mark.Destroy();
	o = Officer();
	if (o != None)
		o.SetOrders('GoingTo', 'UCHKOfficerPost', True);
}

function bool OfficerHome()
{
	local ScriptedPawn o;
	local UCMark mark;

	o = Officer();
	if (o == None)
		return True;
	foreach AllActors(class'UCMark', mark, 'UCHKOfficerPost')
		return VSize((o.Location - mark.Location) * vect(1,1,0)) < 80;
	return True;
}

// Obiettivo principale a Hong Kong (static: lo usa anche UCSceneSimonsBriefing).
static function TongGoal(DeusExPlayer P)
{
	if (P != None && P.FindGoal('FindTracerTong') == None)
		P.GoalAdd('FindTracerTong', "Locate Tracer Tong, a principal contact for Paul Denton and several terrorist organizations in the region. Find his base and establish who is protecting him before Tong is taken out.", True);
}

// L'elicottero: 3 secondi a terra col tetto che si apre, 5 di salita, 6 per andarsene.
function HeliTick(float dt)
{
	if (heliStage == 0 && t >= 3.0)
	{
		heliStage = 1;
		LiftOff();
		vel = vect(0, 0, 170);
	}
	if (heliStage == 1 && t >= 8.0)
	{
		heliStage = 2;
		vel = vect(-300, -160, 120);
	}
	if (heliStage == 1 || heliStage == 2)
		Step(dt);
	if (heliStage == 2 && t >= 14.0)
	{
		heliStage = 3;
		if (Chopper() != None)
			Chopper().Destroy();
	}
}

// L'ufficiale (ogni mezzo secondo): corre da JC, parla, torna al suo posto.
function OfficerTick()
{
	officerT += 0.5;
	if (officerStage == 0)
	{
		if (!GetF('UC_HKOfficer_Played') && !Talking() && officerT < 25.0)
		{
			OfficerFollow();
			return;
		}
		officerStage = 1;
	}
	if (officerStage == 1)
	{
		if (Talking())
			return;
		OfficerBack();
		// JC chiama Simons (UCSceneSimonsBriefing, avviata da UCMod)
		SetF('UC_HK_SimonsDue', True);
		officerStage = 2;
		officerT = 0;
		return;
	}
	if (officerStage == 2 && (OfficerHome() || officerT >= 20.0))
	{
		if (Officer() != None)
			Officer().SetOrders('Standing', '', True);
		officerStage = 3;
	}
}

state Playing
{
Begin:
	// aspetta la fine del dialogo con Jock
	if (Talking())
	{
		Sleep(0.25);
		Goto('Begin');
	}
	// subito: il titolo, l'ufficiale di corsa da JC, il tetto dell'hangar che si apre
	TitleCard("HONG KONG");
	TongGoal(Plr());
	OfficerFollow();
	FireTag('hangar_open');
	t = 0;
	tickT = 0;
Run:
	HeliTick(0.05);
	tickT += 0.05;
	if (tickT >= 0.5)
	{
		tickT = 0;
		OfficerTick();
	}
	Sleep(0.05);
	t += 0.05;
	if (heliStage < 3 || officerStage < 3)
		Goto('Run');
	Destroy();
}

defaultproperties
{
}
