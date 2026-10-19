//=============================================================================
// UCHBChargeTimer - the countdown of the Luminous Path's charges on the HUD (Mission 6, the garage of
// Harbourline Tower; plan 5.4): the game's own timer window (TimerDisplay, the one slot DeusExHUD.timer,
// placed by the HUD above the object belt), showing whole seconds (mm:ss) instead of the game's
// fractions. UCSceneHarbourline.ChargeTick makes it, sets it (the charge that blows first: "Charge -
// container N", red under 10 seconds) and keeps it; when the scene stops keeping it (the game's time
// passes the last Keep, or goes back: another map, a loaded game) it goes away by itself.
//=============================================================================
class UCHBChargeTimer extends TimerDisplay;

var float aliveUntil;       // the game's time (Level.TimeSeconds) until which it stays with no new Keep()
var float lastNow;          // the game's time when it last looked

// Wider than the game's (100): "Charge - container N" fits (the HUD places it by its size, DeusExHUD).
event InitWindow()
{
	Super.InitWindow();
	SetSize(150, 36);
}

function Keep(Actor context)
{
	if (context == None)
		return;
	aliveUntil = context.Level.TimeSeconds + 1.0;
	lastNow = context.Level.TimeSeconds;
}

event Tick(float deltaTime)
{
	local DeusExRootWindow root;
	local float now;

	Super.Tick(deltaTime);
	root = DeusExRootWindow(GetRootWindow());
	if (root == None || root.parentPawn == None)
		return;
	now = root.parentPawn.Level.TimeSeconds;
	if (now + 0.01 < lastNow || now > aliveUntil)
	{
		Destroy();                  // (DeusExHUD.ChildRemoved frees its timer slot)
		return;
	}
	lastNow = now;
}

event DrawWindow(GC gc)
{
	local string str;
	local int secs, mins;

	Super(Window).DrawWindow(gc);

	gc.SetFont(Font'FontComputer8x20_B');
	gc.SetAlignments(HALIGN_Center, VALIGN_Bottom);
	gc.EnableWordWrap(False);
	if (bCritical)
		gc.SetTextColor(colCritical);
	else
		gc.SetTextColor(colNormal);
	secs = Max(0, int(time + 0.99));
	mins = secs / 60;
	secs -= mins * 60;              // (UnrealScript's % works on floats: "08.000000")
	str = "0" $ mins $ ":";
	if (secs < 10)
		str = str $ "0";
	str = str $ secs;
	if (bFlash && flashTime >= 0.75)
	{
		gc.SetTextColor(colBlack);
		if (flashTime >= 1.0)
			flashTime = 0;
	}
	gc.DrawText(0, 0, width, height, str);

	gc.SetFont(Font'TechSmall');
	gc.SetAlignments(HALIGN_Left, VALIGN_Top);
	gc.DrawText(2, 2, width - 2, height - 2, message);
}

defaultproperties
{
}
