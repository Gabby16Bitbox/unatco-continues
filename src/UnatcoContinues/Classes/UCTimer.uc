//=============================================================================
// UCTimer - a timer placed with the map editor (Objects > Triggers > Timer): an invisible object that
// counts down. The map's interactions start, stop, pause and resume it (UCLink: timerstart, timerstop,
// timerpause, timerresume) and react when it runs out (When "finished": it triggers UCL_<name>_Done) or
// when an action stops it (When "stopped": UCL_<name>_Stop).
// With a HUD label it shows on the HUD, in the game's own timer slot above the object belt
// (UCTimerWindow): when several run, the one closest to its end shows, red under 10 seconds. A timer
// with no label counts unseen.
// Everything lives in the actor (saved with the game); the HUD window is made again after a load.
//=============================================================================
class UCTimer extends UCEditorStory;

var() float  Seconds;       // how long it counts
var() string HUDLabel;      // shown with the time on the HUD (empty: not on the HUD)
var() bool   bAutoStart;    // it starts with the map
var() bool   bLoop;         // when it runs out it starts again

var bool  bRunning;         // counting (or paused)
var bool  bPaused;
var bool  bBegun;           // the start of the map was seen (bAutoStart)
var float TimeLeft;             // seconds left
var float Total;            // the length of this run
var float hudT;             // seconds since the HUD was last updated

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0, False);         // (no story here: only Tick)
}

function StartIt(optional float secs)
{
	Total = Seconds;
	if (secs > 0)
		Total = secs;
	Total = FMax(0.1, Total);
	TimeLeft = Total;
	bRunning = True;
	bPaused = False;
	hudT = 1;
	Log("UCTimer" @ Name @ "- starts," @ Total @ "s");
}

// stopped by an action: its "stopped" interactions run
function StopIt()
{
	if (!bRunning)
		return;
	bRunning = False;
	bPaused = False;
	Log("UCTimer" @ Name @ "- stopped," @ TimeLeft @ "s left");
	TimeLeft = 0;
	HUDOff();
	TriggerTag(StringToName("UCL_" $ Name $ "_Stop"));
}

function PauseIt()
{
	if (bRunning && !bPaused)
	{
		bPaused = True;
		Log("UCTimer" @ Name @ "- paused," @ TimeLeft @ "s left");
	}
}

function ResumeIt()
{
	if (bRunning && bPaused)
	{
		bPaused = False;
		Log("UCTimer" @ Name @ "- goes on," @ TimeLeft @ "s left");
	}
}

// it ran out: its "finished" interactions run; a loop starts again at once
function Finish()
{
	Log("UCTimer" @ Name @ "- finished");
	if (bLoop)
		TimeLeft = FMax(0.1, TimeLeft + Total);
	else
	{
		bRunning = False;
		TimeLeft = 0;
		HUDOff();
	}
	TriggerTag(StringToName("UCL_" $ Name $ "_Done"));
}

function Tick(float deltaTime)
{
	Super.Tick(deltaTime);
	if (!bBegun)
	{
		if (Plr() == None || Plr().rootWindow == None)
			return;
		bBegun = True;
		if (bAutoStart)
			StartIt();
	}
	if (bRunning && !bPaused)
	{
		TimeLeft -= deltaTime;
		if (TimeLeft <= 0)
			Finish();
	}
	hudT += deltaTime;
	if (bRunning && HUDLabel != "" && hudT >= 0.1)
	{
		hudT = 0;
		HUDShow();
	}
}

// ---------------------------------------------------------------- the HUD
function UCTimerWindow HUDWindow(bool bMake)
{
	local DeusExRootWindow root;
	local UCTimerWindow win;

	if (Plr() == None)
		return None;
	root = DeusExRootWindow(Plr().rootWindow);
	if (root == None || root.hud == None)
		return None;
	win = UCTimerWindow(root.hud.timer);
	if (win == None && bMake && root.hud.timer == None)     // (the slot of a mission's own timer is left alone)
	{
		win = UCTimerWindow(root.hud.NewChild(class'UCTimerWindow'));
		root.hud.timer = win;
		if (win != None)
			win.AskParentForReconfigure();
	}
	return win;
}

// The timer closest to its end shows (only one slot on the HUD).
function bool Soonest()
{
	local UCTimer T;

	foreach AllActors(class'UCTimer', T)
		if (T != Self && T.bRunning && T.HUDLabel != "" && (T.TimeLeft < TimeLeft || (T.TimeLeft == TimeLeft && string(T.Name) < string(Name))))
			return False;
	return True;
}

function HUDShow()
{
	local UCTimerWindow win;

	if (!Soonest())
		return;
	win = HUDWindow(True);
	if (win == None)
		return;
	win.Keep(Self);
	win.message = HUDLabel;
	win.time = FMax(0, TimeLeft);
	win.bCritical = TimeLeft < 10;
}

// gone at once when no other timer on the HUD runs (else the next one takes the slot at its next update)
function HUDOff()
{
	local UCTimer T;
	local UCTimerWindow win;

	foreach AllActors(class'UCTimer', T)
		if (T != Self && T.bRunning && T.HUDLabel != "")
			return;
	win = HUDWindow(False);
	if (win != None)
		win.Destroy();
}

defaultproperties
{
     Seconds=30.000000
     bRouteOnly=False
}
