//=============================================================================
// UCInfoLinkFX - the opening and the closing of an InfoLink window, as the game's own
// (DataLinkPlay): "INCOMING TRANSMISSION..." with the DataLink icon blinking in the portrait's
// place (1.5 s, every 0.5 s, no text cursor) before the first speaker shows, and at the end
// "END TRANSMISSION..." blinking for a second before the window closes.
// An actor of its own: a scene often ends (Destroy) right after HideInfo. No pointer to the
// player or to the window is kept between two blinks (a map change would leave it dangling).
//=============================================================================
class UCInfoLinkFX extends Info;

var bool bClosing;      // the end of the transmission (else its start)
var float t;            // seconds since the start or the end began

static function HUDInfoLinkDisplay InfoWindow(Actor A, optional bool bCreate)
{
	local DeusExPlayer P;
	local DeusExRootWindow root;

	P = DeusExPlayer(A.GetPlayerPawn());
	if (P == None)
		return None;
	root = DeusExRootWindow(P.rootWindow);
	if (root == None || root.hud == None)
		return None;
	if (root.hud.infolink == None && bCreate)
		return root.hud.CreateInfoLinkWindow();
	return root.hud.infolink;
}

static function UCInfoLinkFX Effect(Actor A)
{
	local UCInfoLinkFX fx;

	foreach A.AllActors(class'UCInfoLinkFX', fx)
		return fx;
	return A.Spawn(class'UCInfoLinkFX');
}

// The window opens on "INCOMING TRANSMISSION..." and the blinking DataLink icon.
static function Open(Actor A)
{
	local HUDInfoLinkDisplay win;
	local UCInfoLinkFX fx;

	win = InfoWindow(A, True);
	if (win == None)
		return;
	win.winName.SetText(class'HUDInfoLinkDisplay'.default.IncomingTransmission);
	win.winName.Show(True);
	win.ClearScreen();
	win.ShowTextCursor(False);
	win.ShowDatalinkIcon(True);
	fx = Effect(A);
	if (fx == None)
		return;
	fx.bClosing = False;
	fx.t = 0;
	fx.SetTimer(0.5, True);
}

// A speaker comes on: the opening is over (a scene may not wait the whole 1.5 s).
static function Speaking(Actor A)
{
	local UCInfoLinkFX fx;
	local HUDInfoLinkDisplay win;

	foreach A.AllActors(class'UCInfoLinkFX', fx)
		if (!fx.bClosing)
		{
			fx.Destroy();
			win = InfoWindow(A);
			if (win != None)
				win.ShowTextCursor(True);
		}
}

// "END TRANSMISSION..." blinks, then the window closes.
static function Close(Actor A)
{
	local HUDInfoLinkDisplay win;
	local UCInfoLinkFX fx;

	win = InfoWindow(A);
	if (win == None)
		return;
	win.winName.SetText(class'DataLinkPlay'.default.EndTransmission);
	win.winName.Show(True);
	win.ShowTextCursor(False);
	fx = Effect(A);
	if (fx == None)
	{
		DeusExRootWindow(DeusExPlayer(A.GetPlayerPawn()).rootWindow).hud.DestroyInfoLinkWindow();
		return;
	}
	fx.bClosing = True;
	fx.t = 0;
	fx.SetTimer(0.5, True);
}

function Timer()
{
	local HUDInfoLinkDisplay win;

	t += 0.5;
	win = InfoWindow(Self);
	if (win == None)
	{
		Destroy();
		return;
	}
	if (!bClosing)
	{
		if (t >= 1.5)
		{
			win.ShowTextCursor(True);
			Destroy();
			return;
		}
		win.ShowDatalinkIcon(!win.winPortrait.IsVisible());
		return;
	}
	// another InfoLink took the window meanwhile: it is not ours to close
	if (win.winName.GetText() != class'DataLinkPlay'.default.EndTransmission)
	{
		win.winName.Show(True);
		Destroy();
		return;
	}
	if (t >= 1.0)
	{
		DeusExRootWindow(DeusExPlayer(GetPlayerPawn()).rootWindow).hud.DestroyInfoLinkWindow();
		Destroy();
		return;
	}
	win.winName.Show(!win.winName.IsVisible());
}

defaultproperties
{
}
