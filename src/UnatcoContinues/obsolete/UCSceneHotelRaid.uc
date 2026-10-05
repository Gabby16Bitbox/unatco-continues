//=============================================================================
// UCSceneHotelRaid - Paul e' scappato: UNATCO e Men in Black entrano nel 'Ton.
//
//  - scatto del portone, poi entrano uno alla volta DAL PORTONE i soldati con
//    il posto al pianterreno e i 2 Men in Black: corrono ai loro posti
//    (i MIB all'appartamento di Paul). Entra prima chi va piu' lontano (i MIB),
//    cosi' nessuno deve passare in mezzo a chi e' gia' fermo al suo posto;
//  - i soldati con il posto ai piani alti (difficili da raggiungere) vengono
//    messi direttamente al loro posto, ma solo quando ne' loro ne' il posto
//    sono in vista di JC;
//  - niente posti in cima alle scalette del salone (tappavano il passaggio);
//  - chi resta incastrato (non si avvicina per qualche secondo) riprova una
//    volta, poi si ferma dov'e'; viene sistemato al suo posto quando non si vede.
// Si usano i posti originali della squadra del raid (WorldPosition).
// Tiene solo NOMI e posizioni (nessun puntatore fra un tick e l'altro).
//=============================================================================
class UCSceneHotelRaid extends UCScene;

const MAXSQUAD = 14;

var name squadName[14];
var vector squadPost[14];
var byte squadKind[14];     // 0 = entra dal portone, 1 = piazzato quando non si vede, 2 = MIB
var byte squadState[14];    // 0 = fuori, 1 = in cammino, 2 = al posto, 3 = fermo (incastrato, in vista)
var float squadTime[14];    // quando e' entrato
var float squadBest[14];    // distanza minima dal posto finora
var float squadProg[14];    // ultimo momento in cui si e' avvicinato al posto
var float squadMoved[14];   // ultimo momento in cui si e' mosso davvero
var vector squadLast[14];   // posizione al controllo precedente
var byte squadTries[14];    // ripartenze dopo un incastro
var int entryOrder[14];     // ordine di entrata (prima chi va piu' lontano)
var int numSquad, nextIn;
var float t, enterPause;

var vector DoorIn;          // appena dentro il portone (lato atrio)

function ScriptedPawn FindByName(name n)
{
	local ScriptedPawn sp;

	foreach AllActors(class'ScriptedPawn', sp)
		if (sp.Name == n)
			return sp;
	return None;
}

// Posti da non usare: la cima delle due scalette fra il pianerottolo e il salone
// (chi sta li' blocca il passaggio a MIB, soldati e JC) e le scalette stesse.
function bool BadPost(vector where)
{
	if (Abs(where.X) < 200 && where.Y < -885 && where.Y > -1050 && where.Z > -45)
		return True;
	return False;
}

// Sceglie la squadra: 12 soldati + i 2 MIB del raid. Pianterreno = entrano dalla porta.
function PickSquad()
{
	local ScriptedPawn sp;
	local Actor apt;
	local vector aptSpot;
	local bool bApt;
	local int troops, i, j, k;

	foreach AllActors(class'Actor', apt, 'Apartment')
	{
		aptSpot = apt.Location;
		bApt = True;
	}

	foreach AllActors(class'ScriptedPawn', sp)
	{
		if (sp.bInWorld || numSquad >= MAXSQUAD)
			continue;
		if (sp.IsA('MIB'))
		{
			if (sp.Tag != 'MIBMoveIn' && sp.Name != 'MIB0')
				continue;
			squadKind[numSquad] = 2;
			if (bApt)
				squadPost[numSquad] = aptSpot;
			else
				squadPost[numSquad] = sp.WorldPosition;
		}
		else if (sp.IsA('UNATCOTroop'))
		{
			if (troops >= 12 || BadPost(sp.WorldPosition))
				continue;
			troops++;
			if (Abs(sp.WorldPosition.Z - DoorIn.Z) < 120)
				squadKind[numSquad] = 0;
			else
				squadKind[numSquad] = 1;
			squadPost[numSquad] = sp.WorldPosition;
		}
		else
			continue;
		squadName[numSquad] = sp.Name;
		squadState[numSquad] = 0;
		numSquad++;
	}

	// ordine di entrata: dal posto piu' lontano dal portone al piu' vicino
	for (i = 0; i < numSquad; i++)
		entryOrder[i] = i;
	for (i = 1; i < numSquad; i++)
	{
		k = entryOrder[i];
		j = i - 1;
		while (j >= 0 && VSize(squadPost[entryOrder[j]] - DoorIn) < VSize(squadPost[k] - DoorIn))
		{
			entryOrder[j + 1] = entryOrder[j];
			j--;
		}
		entryOrder[j + 1] = k;
	}
	Log("UnatcoContinues: squadra del 'Ton:" @ numSquad);
}

function bool Visible(vector where)
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return False;
	return FastTrace(where + vect(0,0,30), P.Location + vect(0,0,1) * P.BaseEyeHeight);
}

function PlayDoor(string soundName)
{
	local Sound snd;

	snd = Sound(DynamicLoadObject(soundName, class'Sound', True));
	SetLocation(DoorIn);
	if (snd != None)
		PlaySound(snd, SLOT_Misc, 1.5,, 1400);
}

// Tag della destinazione: il PatrolPoint dell'appartamento per i MIB, un segnaposto per i soldati.
function name PostTag(int i)
{
	local DeusExPlayer P;

	if (squadKind[i] == 2)
		return 'Apartment';
	P = Plr();
	if (P == None)
		return '';
	return P.rootWindow.StringToName("UCPost" $ i);
}

// Mette il PNG al posto (o appena accanto, se il punto esatto e' occupato).
function bool PlaceAt(ScriptedPawn sp, vector where)
{
	if (sp.SetLocation(where))
		return True;
	if (sp.SetLocation(where + vect(0,0,24)))
		return True;
	if (sp.SetLocation(where + vect(48,0,12)))
		return True;
	if (sp.SetLocation(where + vect(-48,0,12)))
		return True;
	if (sp.SetLocation(where + vect(0,48,12)))
		return True;
	return sp.SetLocation(where + vect(0,-48,12));
}

// Il prossimo della fila entra dal portone e corre al suo posto.
function bool EnterNext()
{
	local ScriptedPawn sp;
	local Actor mark;
	local name tagName;
	local int i;

	enterPause = 1.0;
	while (nextIn < numSquad && squadKind[entryOrder[nextIn]] == 1)
		nextIn++;
	if (nextIn >= numSquad || Plr() == None)
		return False;

	i = entryOrder[nextIn];
	sp = FindByName(squadName[i]);
	if (sp != None)
	{
		sp.EnterWorld();
		if (!sp.SetLocation(DoorIn))
		{
			sp.LeaveWorld();          // portone occupato: si riprova al prossimo giro
			sp.WorldPosition = squadPost[i];
			return True;
		}
		sp.ChangeAlly('Player', 1.0, True);
		tagName = PostTag(i);
		if (squadKind[i] == 2)
		{
			foreach AllActors(class'Actor', mark, tagName)
				break;
			enterPause = 1.8;         // i MIB entrano piu' distanziati
		}
		else
			mark = Spawn(class'UCMark',, tagName, squadPost[i]);

		// nessuna strada fino al posto: esce di nuovo e verra' piazzato quando non si vede
		if (mark == None || (!sp.ActorReachable(mark) && sp.FindPathToward(mark) == None))
		{
			sp.LeaveWorld();
			sp.WorldPosition = squadPost[i];
			if (squadKind[i] != 2)
				squadKind[i] = 1;
			else
				squadState[i] = 3;
			nextIn++;
			return True;
		}
		sp.SetOrders('RunningTo', tagName, True);
		squadState[i] = 1;
		squadTime[i] = Level.TimeSeconds;
		squadProg[i] = Level.TimeSeconds;
		squadMoved[i] = Level.TimeSeconds;
		squadBest[i] = VSize(sp.Location - squadPost[i]);
		squadLast[i] = sp.Location;
	}
	nextIn++;
	return True;
}

// Incastrato: se nessuno vede va al posto, altrimenti riprova una volta e poi si ferma li'.
function Stuck(int i, ScriptedPawn sp)
{
	if (!Visible(sp.Location) && !Visible(squadPost[i]) && PlaceAt(sp, squadPost[i]))
	{
		sp.SetOrders('Standing', '', True);
		squadState[i] = 2;
	}
	else if (squadTries[i] == 0)
	{
		squadTries[i] = 1;
		sp.SetOrders('RunningTo', PostTag(i), True);
		squadProg[i] = Level.TimeSeconds;
		squadMoved[i] = Level.TimeSeconds;
		squadTime[i] = FMin(squadTime[i], Level.TimeSeconds - 25.0);   // ancora 15 s al massimo
	}
	else
	{
		sp.SetOrders('Standing', '', True);
		squadState[i] = 3;
	}
}

// Controlla tutti: arrivati -> fermi; incastrati, in ritardo o "difficili" -> al posto se nessuno vede.
function bool UpdateSquad()
{
	local int i;
	local ScriptedPawn sp;
	local bool bAllDone;
	local float d;

	bAllDone = True;
	for (i = 0; i < numSquad; i++)
	{
		if (squadState[i] == 2)
			continue;
		bAllDone = False;
		sp = FindByName(squadName[i]);
		if (sp == None)
		{
			squadState[i] = 2;
			continue;
		}

		// soldati "difficili": compaiono al posto quando ne' loro ne' il posto sono in vista
		if (squadState[i] == 0)
		{
			if (squadKind[i] == 1 && !Visible(squadPost[i]))
			{
				sp.EnterWorld();
				sp.ChangeAlly('Player', 1.0, True);
				sp.SetOrders('Standing', '', True);
				squadState[i] = 2;
			}
			continue;
		}

		// fermo perche' incastrato in vista di JC: appena nessuno guarda va al suo posto
		if (squadState[i] == 3)
		{
			if (!Visible(squadPost[i]) && (!sp.bInWorld || !Visible(sp.Location)))
			{
				if (!sp.bInWorld)
				{
					sp.EnterWorld();
					sp.ChangeAlly('Player', 1.0, True);
				}
				if (PlaceAt(sp, squadPost[i]))
				{
					sp.SetOrders('Standing', '', True);
					squadState[i] = 2;
				}
			}
			continue;
		}

		if (squadState[i] == 1)
		{
			d = VSize(sp.Location - squadPost[i]);
			// arrivato al posto (il MIB si ferma da solo al PatrolPoint)
			if (d < 80 || (squadKind[i] == 2 && d < 200 && sp.GetStateName() == 'Standing'))
			{
				if (squadKind[i] != 2)
					sp.SetOrders('Standing', '', True);
				squadState[i] = 2;
			}
			else
			{
				if (d < squadBest[i] - 24)
				{
					squadBest[i] = d;
					squadProg[i] = Level.TimeSeconds;
				}
				if (VSize(sp.Location - squadLast[i]) > 40)
					squadMoved[i] = Level.TimeSeconds;
				squadLast[i] = sp.Location;
				// fermo (corre contro un muro/ringhiera) da 3 s, non si avvicina da 7 s
				// (il giro per le scale puo' allontanarlo un po'), o in giro da troppo
				if (Level.TimeSeconds - squadMoved[i] > 3.0 || Level.TimeSeconds - squadProg[i] > 7.0
					|| Level.TimeSeconds - squadTime[i] > 40.0)
					Stuck(i, sp);
			}
		}
	}
	return bAllDone;
}

function Cleanup()
{
	local UCMark mark;
	local int i;
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	for (i = 0; i < numSquad; i++)
		foreach AllActors(class'UCMark', mark, P.rootWindow.StringToName("UCPost" $ i))
			mark.Destroy();
}

state Playing
{
Begin:
	PickSquad();
	Sleep(2.0);
	PlayDoor("MoverSFX.door.WoodDoorOpen");
	Sleep(0.4);
EnterLoop:
	if (EnterNext())
	{
		Sleep(enterPause);
		UpdateSquad();
		Goto('EnterLoop');
	}
	Sleep(1.0);
	PlayDoor("MoverSFX.door.WoodDoorClose");
	t = 0;
Watch:
	if (!UpdateSquad() && t < 600.0)
	{
		Sleep(0.5);
		t += 0.5;
		Goto('Watch');
	}
	Cleanup();
	Destroy();
}

defaultproperties
{
     DoorIn=(X=-376.000000,Y=200.000000,Z=-7.000000)
}
