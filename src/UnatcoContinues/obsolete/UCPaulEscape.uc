//=============================================================================
// UCPaulEscape - Paul scappa dal 'Ton dopo il rifiuto di JC.
//   - corre verso il portone dell'hotel;
//   - se JC lo segue e lui arriva al portone: scatto della porta, Paul svanisce
//     in dissolvenza (e' uscito), la porta si richiude;
//   - se JC lo perde di vista per un paio di secondi: viene tolto in silenzio.
// Paul NON muore (PaulDenton_Dead resta False): lascia solo questa mappa.
// Nessun puntatore tenuto fra un tick e l'altro.
//=============================================================================
class UCPaulEscape extends Actor
	transient;

var float t;          // tempo dall'inizio della fuga
var float unseen;     // da quanto JC non lo vede
var float fade;       // > 0 = sta svanendo sulla porta
var bool bDone;

// dentro l'atrio, davanti al portone che da' sulla strada
var vector DoorSpot;

function PostBeginPlay()
{
	local PaulDenton paul;
	local Trigger trig;

	Super.PostBeginPlay();

	// il trigger vanilla vicino all'uscita farebbe partire PaulLeaves (fine del raid): spento
	foreach AllActors(class'Trigger', trig)
		if (trig.Event == 'PaulLeaves')
			trig.SetCollision(False, False, False);

	Spawn(class'UCMark',, 'UCHotelDoor', DoorSpot);
	foreach AllActors(class'PaulDenton', paul)
		paul.SetOrders('RunningTo', 'UCHotelDoor', True);
}

function PaulDenton FindPaul()
{
	local PaulDenton paul;

	foreach AllActors(class'PaulDenton', paul)
		if (!paul.bHidden)
			return paul;
	return None;
}

function PlayDoor(string soundName, vector where)
{
	local Sound snd;

	snd = Sound(DynamicLoadObject(soundName, class'Sound', True));
	if (snd != None)
		PlaySound(snd, SLOT_Misc, 1.5,, 1200);
}

function Finish(bool bViaDoor)
{
	local DeusExPlayer P;
	local PaulDenton paul;
	local UCMark mark;

	bDone = True;
	paul = FindPaul();
	if (paul != None)
	{
		paul.LeaveWorld();
		paul.Style = paul.Default.Style;
		paul.ScaleGlow = paul.Default.ScaleGlow;
	}
	foreach AllActors(class'UCMark', mark, 'UCHotelDoor')
		mark.Destroy();

	P = DeusExPlayer(GetPlayerPawn());
	if (P != None && P.FlagBase != None)
	{
		P.FlagBase.SetBool('PaulEscapedTon', True,, 99);
		P.FlagBase.SetBool('PaulLocationUnknown', True,, 99);
		P.FlagBase.SetBool('PaulDenton_Dead', False,, 99);
	}
	Log("UnatcoContinues: Paul ha lasciato il 'Ton" @ bViaDoor);
	Destroy();
}

event Tick(float deltaTime)
{
	local DeusExPlayer P;
	local PaulDenton paul;

	if (bDone)
		return;
	t += deltaTime;
	P = DeusExPlayer(GetPlayerPawn());
	paul = FindPaul();
	if (paul == None || P == None)
	{
		Finish(False);
		return;
	}

	// sta uscendo dal portone: dissolvenza
	if (fade > 0)
	{
		fade -= deltaTime;
		paul.Style = STY_Translucent;
		paul.ScaleGlow = FMax(0.0, fade);
		if (fade <= 0)
		{
			SetLocation(DoorSpot);
			PlayDoor("MoverSFX.door.WoodDoorClose", DoorSpot);
			Finish(True);
		}
		return;
	}

	// arrivato al portone
	if (VSize(paul.Location - DoorSpot) < 110)
	{
		SetLocation(DoorSpot);
		PlayDoor("MoverSFX.door.WoodDoorOpen", DoorSpot);
		paul.SetOrders('Standing', '', True);
		fade = 1.0;
		return;
	}

	// JC lo ha perso di vista
	if (!P.LineOfSightTo(paul) && VSize(paul.Location - P.Location) > 500)
		unseen += deltaTime;
	else
		unseen = 0;
	if (unseen > 2.0 || t > 60.0)
		Finish(False);
}

defaultproperties
{
     bHidden=True
     DoorSpot=(X=-372.000000,Y=290.000000,Z=-7.000000)
}
