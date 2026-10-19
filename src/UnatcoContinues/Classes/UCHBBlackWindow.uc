//=============================================================================
// UCHBBlackWindow - the black over the screen while Eva's helicopter comes down on Harbourline Tower
// (Mission 6, UCSceneHarbourline): a UCCutWindow (film bars, fades) that is black already on the very
// first frame of a first arrival (UCTraveler makes it on arrival, before anything is drawn:
// UCSceneHarbourline.ArrivalBlack) and that goes away by itself when nothing keeps it. The scene calls
// Keep() every frame while it needs it; when the game's time passes the last Keep (the scene is gone, the
// landing never came) or goes back (another map, a loaded game) it fades out. Nothing holds a pointer to
// it: the scene finds it among the root window's children (Find).
//=============================================================================
class UCHBBlackWindow extends UCCutWindow
	transient;

var float aliveUntil;       // the game's time (Level.TimeSeconds) until which it stays with no new Keep()
var float lastNow;          // the game's time when it last looked

// The black of the scene, if there is one (and it is not already going away).
static function UCHBBlackWindow Find(DeusExRootWindow root)
{
	local Window w;

	if (root == None)
		return None;
	for (w = root.GetTopChild(); w != None; w = w.GetLowerSibling())
		if (UCHBBlackWindow(w) != None && UCHBBlackWindow(w).closeTime <= 0)
			return UCHBBlackWindow(w);
	return None;
}

// The black, all black, with the bars: the one already there or a new one; kept for secs seconds.
static function UCHBBlackWindow Make(DeusExPlayer P, float secs)
{
	local DeusExRootWindow root;
	local UCHBBlackWindow win;

	if (P == None)
		return None;
	root = DeusExRootWindow(P.rootWindow);
	if (root == None)
		return None;
	win = Find(root);
	if (win == None)
	{
		win = UCHBBlackWindow(root.NewChild(class'UCHBBlackWindow'));
		if (win == None)
			return None;
		win.SetPos(0, 0);
		win.SetSize(root.width, root.height);
		win.bBars = True;
		win.fade = 1;
		win.hint = 0;
		Log("UCHBBlackWindow: made," @ root.width @ "x" @ root.height);
	}
	win.Keep(P, secs);
	return win;
}

function Keep(Actor context, float secs)
{
	if (context == None)
		return;
	aliveUntil = FMax(aliveUntil, context.Level.TimeSeconds + secs);
	lastNow = context.Level.TimeSeconds;
}

event Tick(float deltaTime)
{
	local DeusExRootWindow root;
	local float now;

	Super.Tick(deltaTime);
	if (closeTime > 0)
		return;                     // already fading away (or destroyed by the line above)
	root = DeusExRootWindow(GetRootWindow());
	if (root == None || root.parentPawn == None)
		return;
	// UCCutWindow follows the root size, including while this window fades out.
	now = root.parentPawn.Level.TimeSeconds;
	if (now + 0.01 < lastNow || now > aliveUntil)
	{
		Log("UCHBBlackWindow: nothing keeps the black any more, it fades");
		Close(0.6);
		return;
	}
	lastNow = now;
}
defaultproperties
{
     hint=0.000000
}
