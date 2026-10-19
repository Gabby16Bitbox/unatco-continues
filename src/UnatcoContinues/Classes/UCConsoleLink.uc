//=============================================================================
// UCConsoleLink - the map editor's Console while the game runs (Play). A few times a second it execs
// System\UCConsole.txt, where the editor writes "set UCConsoleLink Cmd <command>" and
// "set UCConsoleLink Seq <n>": a new command runs as if typed in the game's own console, and the
// answer is saved with Done=<n> into this class's section of the user ini, where the editor reads it.
// A window of the HUD, not an actor: windows go on ticking while the game is paused, and the game
// pauses itself when the editor has the focus (someone typing in the Console).
// UCMutator starts it (Ensure) only when that section says bActive=True: the editor's Play.
//=============================================================================
class UCConsoleLink extends Window
	config(User)
	transient;

var config bool bActive;
var config int Seq;
var config int Done;
var config string Cmd;
var config string Result;
var float pollT;

// the link in the player's HUD, once (the root window outlives map changes, the check is cheap)
static function Ensure(Actor A)
{
	local DeusExPlayer P;
	local DeusExRootWindow root;
	local Window w;

	if (!default.bActive || A == None)
		return;
	P = DeusExPlayer(A.GetPlayerPawn());
	if (P == None)
		return;
	root = DeusExRootWindow(P.rootWindow);
	if (root == None)
		return;
	for (w = root.GetTopChild(); w != None; w = w.GetLowerSibling())
		if (UCConsoleLink(w) != None)
			return;
	root.NewChild(class'UCConsoleLink');
	Log("DeusEdix console: listening");
}

event InitWindow()
{
	Super.InitWindow();
	SetSensitivity(False);
	SetSelectability(False);
	SetSize(0, 0);
	bTickEnabled = True;
}

event Tick(float deltaTime)
{
	local PlayerPawn P;
	local string answer;

	pollT += deltaTime;
	if (pollT < 0.25)
		return;
	pollT = 0;
	P = GetPlayerPawn();
	if (P == None)
		return;
	P.ConsoleCommand("exec UCConsole.txt");
	if (Seq == Done)
		return;
	Done = Seq;
	Log("DeusEdix console >" @ Cmd);
	answer = P.ConsoleCommand(Cmd);
	Result = Left(answer, 1000);
	if (answer != "")
		Log("DeusEdix console <" @ answer);
	SaveConfig();
}

defaultproperties
{
}
