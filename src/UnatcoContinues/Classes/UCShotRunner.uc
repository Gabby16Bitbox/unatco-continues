//=============================================================================
// UCShotRunner - foto automatiche dal gioco (per controllare le modifiche senza far
// provare ogni volta a Gabby). Lo usa tools\shots.ps1, che scrive la sezione qui sotto,
// avvia Revision su una mappa, aspetta che il gioco si chiuda e raccoglie le foto.
// Nel gioco normale non fa nulla: parte solo se la sezione qui sotto ha bActive=True.
// La sezione sta in RevisionUser.ini (config(User): Revision non legge file di
// configurazione con nomi nuovi); tools\shots.ps1 la aggiunge e poi la toglie.
//
//  [UnatcoContinues.UCShotRunner]
//  bActive=True
//  Setup=UCDbgHeliDoor        (comando UCDbg* che mette i flag e salta alla mappa; vuoto = nessuno)
//  SetupFlags=Nome=1,Altro=0  (flag da cambiare dopo il comando di preparazione: per le varianti)
//  StartDelay=6               (secondi dopo l'arrivo, perche' scene e luci partano)
//  Shots[0]=etichetta;cam;x;y;z;guardaX;guardaY;guardaZ    telecamera libera
//  Shots[1]=etichetta;view                                  quello che si vede (anche una conversazione)
//  Shots[2]=etichetta;player;x;y;z;yaw;pitch                sposta JC e guarda (prima persona)
//  Shots[3]=etichetta;wait;secondi                          solo attesa
//  Shots[4]=etichetta;console;comando                       un comando da console (es. summon ...)
//  Shots[5]=etichetta;torch;1                               torcia accesa (0 = spenta), per le foto "player"
//  Shots[6]=etichetta;follow;Tag                            alle spalle del personaggio con quel Tag
//  Shots[7]=etichetta;where;Tag                             solo la sua posizione nel log, niente foto
//  Shots[8]=etichetta;flag;NomeFlag                         valore del flag nel log
//  Shots[9]=etichetta;talk;Tag                              JC parla col personaggio (come un clic)
//  Shots[10]=etichetta;next                                 clic per la battuta successiva della conversazione
//  Shots[11]=etichetta;hud;1                                interfaccia visibile nelle foto (0 = nascosta, il normale):
//                                                           serve per le battute "al volo" in prima persona, che
//                                                           si leggono nell'interfaccia
//  Shots[12]=etichetta;waitmap;NOME_MAPPA;secondi           aspetta di essere in quella mappa (al massimo tot secondi)
//  Shots[13]=etichetta;waitflag;NomeFlag;secondi            aspetta che il flag sia vero (al massimo tot secondi)
// Se la mappa cambia a meta' elenco (un salto, un'uscita) si riparte dal passo dove si era
// rimasti (flag UC_ShotIndex): serve per provare sequenze su piu' mappe.
// Alla fine il gioco si chiude da solo (exit).
//=============================================================================
class UCShotRunner extends Actor
	config(User)
	transient;

var config bool bActive;
var config string Setup;
var config string SetupFlags;
var config float StartDelay;
var config string Shots[160];

var int i;
var string fields[8];
var int numFields;
var UCCam cam;
var bool bTake;
var bool bAgain;     // il passo va ripetuto (attesa non finita)
var float waitT;     // da quanto dura l'attesa in corso
var bool bKeepHud;   // le foto si fanno con l'interfaccia visibile (azione "hud")

function DeusExPlayer Plr()
{
	return DeusExPlayer(GetPlayerPawn());
}

function Split(string s)
{
	local int p;

	numFields = 0;
	while (numFields < ArrayCount(fields))
	{
		p = InStr(s, ";");
		if (p < 0)
		{
			fields[numFields++] = s;
			return;
		}
		fields[numFields++] = Left(s, p);
		s = Mid(s, p + 1);
	}
}

function vector V(int k)
{
	local vector r;

	r.X = float(fields[k]);
	r.Y = float(fields[k + 1]);
	r.Z = float(fields[k + 2]);
	return r;
}

function FreeView()
{
	local DeusExPlayer P;

	P = Plr();
	if (P != None && P.ViewTarget != None)
	{
		P.ViewTarget = None;
		P.bBehindView = False;
	}
}

function HideHud()
{
	local DeusExPlayer P;
	local DeusExRootWindow root;

	P = Plr();
	if (P == None)
		return;
	root = DeusExRootWindow(P.rootWindow);
	if (root == None || root.hud == None)
		return;
	if (bKeepHud)
		root.hud.Show();
	else
		root.hud.Hide();
}

// Prepara l'inquadratura i-esima; bTake = True se poi va scattata la foto.
function float Prepare(int k)
{
	local DeusExPlayer P;
	local rotator r;

	bTake = False;
	bAgain = False;
	P = Plr();
	if (P == None || Shots[k] == "")
		return -1;
	Split(Shots[k]);
	Log("UCShot" @ k @ fields[0] @ fields[1]);
	switch (fields[1])
	{
		case "cam":
			if (cam == None)
				cam = Spawn(class'UCCam',,, V(2));
			if (cam != None)
			{
				cam.SetShot(V(2), V(5));
				P.ViewTarget = cam;
				P.bBehindView = True;
				cam.ApplyView(P);
			}
			bTake = True;
			return 0.8;
		case "view":
			FreeView();
			bTake = True;
			return 0.3;
		case "player":
			FreeView();
			P.SetLocation(V(2));
			r.Yaw = int(fields[5]);
			r.Pitch = int(fields[6]);
			P.ViewRotation = r;
			P.SetRotation(r);
			bTake = True;
			return 0.8;
		case "wait":
			return float(fields[2]);
		case "waitmap":
			if (!(Caps(MapName()) == Caps(fields[2])) && waitT < float(fields[3]))
				bAgain = True;
			return Waiting(k);
		case "waitflag":
			if (!P.FlagBase.GetBool(P.rootWindow.StringToName(fields[2])) && waitT < float(fields[3]))
				bAgain = True;
			return Waiting(k);
		case "console":
			// il comando puo' far cambiare mappa: il passo e' gia' fatto, non va ripetuto all'arrivo
			P.FlagBase.SetInt('UC_ShotIndex', k + 1,, 99);
			P.ConsoleCommand(fields[2]);
			return 0.5;
		case "torch":
			Torch(P, fields[2] == "1");
			return 0.5;
		case "follow":
			if (!Follow(P, fields[2]))
				return 0.1;
			bTake = True;
			return 0.4;
		case "where":
			Follow(P, fields[2]);
			FreeView();
			return 0.05;
		case "hand":
			// cosa ha in mano JC (per capire chi gli fa riporre l'arma)
			Log("UCShot mano" @ P.inHand @ "in arrivo" @ P.inHandPending @ "arma" @ P.Weapon @ "stato" @ P.GetStateName() @ "bersaglio" @ P.FrobTarget);
			return 0.05;
		case "flag":
			Log("UCShot flag" @ fields[2] @ P.FlagBase.GetBool(P.rootWindow.StringToName(fields[2])));
			return 0.05;
		case "talk":
			Talk(P, fields[2]);
			return 0.5;
		case "hud":
			bKeepHud = (fields[2] == "1");
			HideHud();
			return 0.1;
		case "next":
			// come un clic nella conversazione (le battute senza audio aspettano il clic)
			if (P.conPlay != None)
				P.conPlay.PlayNextEvent();
			return 0.6;
	}
	return 0;
}

function string MapName()
{
	local DeusExLevelInfo info;

	foreach AllActors(class'DeusExLevelInfo', info)
		return info.mapName;
	return "";
}

// Un giro di attesa (waitmap / waitflag): un quarto di secondo, poi si ricontrolla.
function float Waiting(int k)
{
	if (bAgain)
	{
		waitT += 0.25;
		return 0.25;
	}
	Log("UCShot attesa" @ k @ fields[0] @ "finita dopo" @ waitT @ "in" @ MapName());
	waitT = 0;
	return 0.05;
}

// I flag di SetupFlags ("Nome=1,Altro=0"): il comando di preparazione ha gia' messo i
// suoi e chiesto il cambio mappa (che avviene a fine tick); questi li correggono.
function ApplySetupFlags()
{
	local DeusExPlayer P;
	local string s, item, flagName;
	local int p1, p2;

	P = Plr();
	s = SetupFlags;
	while (P != None && s != "")
	{
		p1 = InStr(s, ",");
		if (p1 < 0)
		{
			item = s;
			s = "";
		}
		else
		{
			item = Left(s, p1);
			s = Mid(s, p1 + 1);
		}
		p2 = InStr(item, "=");
		if (p2 > 0)
		{
			flagName = Left(item, p2);
			P.FlagBase.SetBool(P.rootWindow.StringToName(flagName), Mid(item, p2 + 1) == "1",, 99);
			Log("UCShot flag impostato" @ flagName @ Mid(item, p2 + 1));
		}
	}
}

// Come se JC cliccasse sul personaggio con quel Tag (parte la sua conversazione).
function Talk(DeusExPlayer P, string tagName)
{
	local Actor A;
	local Conversation c;
	local ConListItem item;

	foreach AllActors(class'Actor', A)
		if (string(A.Tag) ~= tagName)
			break;
	if (A == None || !(string(A.Tag) ~= tagName))
	{
		Log("UCShot parla" @ tagName @ "non trovato");
		return;
	}
	// perche' una conversazione non parte: chi sta gia' parlando, se JC e il PNG possono
	// conversare, quale conversazione sceglierebbe il gioco
	c = P.GetActiveConversation(A, IM_Frob);
	if (P.conPlay != None && P.conPlay.con != None)
		Log("UCShot parla: in corso" @ P.conPlay.con.conName);
	if (c != None)
		Log("UCShot parla: scelta" @ c.conName @ "JC puo'" @ P.CanStartConversation() @ "PNG puo'" @ (ScriptedPawn(A) == None || ScriptedPawn(A).CanConverse()) @ "stato" @ A.GetStateName());
	else
	{
		Log("UCShot parla: nessuna conversazione valida, stato" @ A.GetStateName() @ "a" @ A.Location @ "JC a" @ P.Location);
		for (item = ConListItem(A.ConListItems); item != None; item = item.next)
			if (item.con != None)
				Log("UCShot parla:   in lista" @ item.con.conName @ "requisiti ok" @ P.CheckFlagRefs(item.con.flagRefList));
	}
	Log("UCShot parla con" @ tagName @ P.StartConversation(A, IM_Frob));
}

// Telecamera alle spalle del personaggio con quel Tag (per seguire chi cammina); scrive
// nel log dove si trova. Falso se non c'e'.
function bool Follow(DeusExPlayer P, string tagName)
{
	local Actor A, hitActor;
	local vector spot, look, hitLoc, hitNormal;

	foreach AllActors(class'Actor', A)
		if (string(A.Tag) ~= tagName)
			break;
	if (A == None || !(string(A.Tag) ~= tagName))
	{
		Log("UCShot segui" @ tagName @ "non trovato");
		return False;
	}
	if (Mover(A) != None)
		Log("UCShot segui" @ tagName @ "a" @ A.Location @ "stato" @ A.GetStateName() @ "posizione" @ Mover(A).KeyNum);
	else
		Log("UCShot segui" @ tagName @ "a" @ A.Location @ "stato" @ A.GetStateName());
	look = A.Location + vect(0,0,20);
	spot = A.Location - vector(A.Rotation) * 170 + vect(0,0,75);
	hitActor = Trace(hitLoc, hitNormal, spot, look, False);
	if (hitActor != None)
		spot = hitLoc + hitNormal * 12;
	if (cam == None)
		cam = Spawn(class'UCCam',,, spot);
	if (cam == None)
		return False;
	cam.SetShot(spot, look);
	P.ViewTarget = cam;
	P.bBehindView = True;
	cam.ApplyView(P);
	return True;
}

// Torcia (potenziamento luce) accesa o spenta: segue lo sguardo di JC, quindi va usata
// con le foto "player" (non con la telecamera libera).
function Torch(DeusExPlayer P, bool bOn)
{
	local Augmentation aug;

	if (P.AugmentationSystem == None)
		return;
	aug = P.AugmentationSystem.FindAugmentation(class'AugLight');
	if (aug == None || !aug.bHasIt)
		aug = P.AugmentationSystem.GivePlayerAugmentation(class'AugLight', True);
	if (aug == None)
		return;
	if (bOn)
	{
		P.Energy = P.EnergyMax;
		aug.Activate();
	}
	else
		aug.Deactivate();
}

// auto: il mutator lo crea mentre la mappa si avvia, e alla fine dell'avvio il motore
// rimette ogni attore nel suo stato iniziale (un GotoState fatto prima andrebbe perso).
auto state Shooting
{
Begin:
	Sleep(1.0);
	if (Plr() == None)
		Goto('Begin');
	// prima volta: il comando di preparazione mette i flag e ricarica la mappa
	if (Setup != "" && !Plr().FlagBase.GetBool('UC_ShotSetupDone'))
	{
		Plr().FlagBase.SetBool('UC_ShotSetupDone', True,, 99);
		Log("UCShot setup" @ Setup);
		Spawn(class<Actor>(DynamicLoadObject("UnatcoContinues." $ Setup, class'Class')));
		ApplySetupFlags();
		Stop;
	}
	Sleep(StartDelay);
	HideHud();
	i = Plr().FlagBase.GetInt('UC_ShotIndex');   // dopo un cambio di mappa: da dove si era rimasti
Next:
	if (i < ArrayCount(Shots) && Shots[i] != "")
	{
		Sleep(FMax(0.05, Prepare(i)));
		if (bAgain)
			Goto('Next');
		if (bTake)
		{
			HideHud();
			Plr().ConsoleCommand("shot");
			Log("UCShot preso" @ i @ fields[0]);
			Sleep(0.6);
		}
		i++;
		Plr().FlagBase.SetInt('UC_ShotIndex', i,, 99);
		Goto('Next');
	}
	Log("UCShot fine");
	Sleep(0.5);
	Plr().ConsoleCommand("exit");
}

// Il gioco si mette in pausa quando la sua finestra perde il fuoco (SETPAUSE del motore):
// le foto devono andare avanti lo stesso, quindi la pausa si toglie da sola.
event Tick(float deltaTime)
{
	if (Level.Pauser != "")
		Level.Pauser = "";
}

defaultproperties
{
     StartDelay=6.000000
     bHidden=True
     bAlwaysTick=True
}
