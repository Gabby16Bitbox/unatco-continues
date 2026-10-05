//=============================================================================
// UCSceneTakeoff - Battery Park: JC sale sull'elicottero di Jock e si parte.
// Parte quando JC risponde "I'm ready" a Jock (flag UC_JockGo, vedi UCMod).
//  - goal MeetJockBatteryPark completato, UNATCORoute_DepartedNYC = True;
//  - JC e' a bordo (sparisce), la telecamera guarda l'elicottero;
//  - l'elicottero decolla sul percorso vanilla della mappa ('HelicopterFlysOff',
//    lo stesso del decollo di inizio missione);
//  - dopo qualche secondo: Hong Kong.
//=============================================================================
class UCSceneTakeoff extends UCScene;

var float t;
var string HongKongURL;

// Punto per la telecamera: a lato dell'elicottero, con la vista libera.
function vector CamSpot()
{
	local BlackHelicopter heli;
	local vector base, cand;
	local vector offs[5];
	local int i;

	heli = FindHeli();
	if (heli == None)
		return Location;
	base = heli.Location;
	offs[0] = vect(950, -650, 140);
	offs[1] = vect(950, 650, 140);
	offs[2] = vect(-950, -650, 140);
	offs[3] = vect(0, -1100, 200);
	offs[4] = vect(0, 1100, 200);
	for (i = 0; i < 5; i++)
	{
		cand = base + offs[i];
		if (FastTrace(cand, base + vect(0,0,120)) && FastTrace(cand, base + vect(0,0,600)))
			return cand;
	}
	return base + vect(700, 0, 700);
}

// Come InterpolateTrigger.SendActorOnPath: l'elicottero segue i punti del suo Event.
function StartTakeoff()
{
	local BlackHelicopter heli;
	local InterpolationPoint I;

	heli = FindHeli();
	if (heli == None)
		return;
	heli.Tag = 'JockTakesOff';
	if (heli.Event == '')
		heli.Event = 'HelicopterFlysOff';
	foreach AllActors(class'InterpolationPoint', I, heli.Event)
		if (I.Position == 1)
		{
			heli.SetCollision(False, False, False);
			heli.bCollideWorld = False;
			heli.Target = I;
			heli.SetPhysics(PHYS_Interpolating);
			heli.PhysRate = 1.0;
			heli.PhysAlpha = 0.0;
			heli.bInterpolating = True;
			heli.bStasis = False;
			heli.GotoState('Interpolating');
			return;
		}
	// percorso non trovato: sale in verticale
	heli.SetPhysics(PHYS_Projectile);
	heli.Velocity = vect(0, 0, 220);
}

state Playing
{
Begin:
	// aspetta la fine della conversazione con Jock
	if (Talking())
	{
		Sleep(0.25);
		Goto('Begin');
	}
	GoalDone('MeetJockBatteryPark');
	SetF('UNATCORoute_DepartedNYC', True);
	Sleep(0.3);

	// JC e' salito: si vede solo l'elicottero
	CutsceneStart(CamSpot(), FindHeli());
	Sleep(1.5);
	StartTakeoff();
	t = 0;
Fly:
	CamLookAt(FindHeli());
	Sleep(0.05);
	t += 0.05;
	if (t < 6.5)
		Goto('Fly');

	CutsceneEnd();
	if (Plr() != None)
		class'UCMod'.static.PrepareHongKongFlags(Plr().FlagBase);
	TravelTo(HongKongURL, 0);
	Destroy();
}

defaultproperties
{
     HongKongURL="06_HongKong_Helibase"
}
