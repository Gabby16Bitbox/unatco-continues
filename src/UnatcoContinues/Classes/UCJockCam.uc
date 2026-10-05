//=============================================================================
// UCJockCam - Hong Kong, eliporto: inquadratura fissa per il dialogo con Jock.
// L'hangar e' basso (soffitto a 256 unita' dal pavimento) e l'elicottero e' enorme:
// le inquadrature calcolate del gioco (fra chi parla) finivano contro il tetto o
// dentro l'elicottero. Durante la conversazione UC_JockHK la telecamera della
// conversazione viene agganciata a un punto scelto (modalita' "attore", aggiornamenti
// bloccati): dal lato sud dell'hangar, fra JC (parte da x 1931) e l'elicottero (x 1388).
// Si toglie da sola a dialogo finito. La crea UCMod.HelibaseSetup.
//=============================================================================
class UCJockCam extends Actor
	transient;

var UCMark camPoint;

function BlackHelicopter Heli()
{
	local BlackHelicopter h;

	foreach AllActors(class'BlackHelicopter', h, 'chopper')
		return h;
	return None;
}

event Tick(float deltaTime)
{
	local DeusExPlayer P;
	local ConCamera cam;
	local vector spot, focus;

	P = DeusExPlayer(GetPlayerPawn());
	if (P == None || P.FlagBase == None)
		return;
	if (P.conPlay == None || P.conPlay.con == None || P.conPlay.con.conName != 'UC_JockHK')
	{
		if (P.FlagBase.GetBool('UC_JockHK_Played'))
			Destroy();
		return;
	}
	cam = P.conPlay.cameraInfo;
	if (cam == None)
		return;
	if (camPoint == None)
	{
		spot = vect(1660, -850, 580);
		focus = vect(1570, -45, 480);
		camPoint = Spawn(class'UCMark',, 'UCJockCamPoint', spot);
		if (camPoint == None)
			return;
		camPoint.DesiredRotation = rotator(focus - spot);
		camPoint.SetRotation(camPoint.DesiredRotation);
	}
	cam.cameraType = CT_Actor;
	cam.cameraMode = CT_Actor;
	cam.cameraOffset = vect(0, 0, 0);
	cam.rotation = rot(0, 0, 0);
	cam.ignoreSetActors = False;
	cam.SetActors(camPoint, Heli());
	cam.ignoreSetActors = True;
}

event Destroyed()
{
	if (camPoint != None)
		camPoint.Destroy();
	Super.Destroyed();
}

defaultproperties
{
     bHidden=True
     bAlwaysTick=True
}
