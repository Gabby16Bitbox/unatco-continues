//=============================================================================
// UCTalkHush - no talking with people while an InfoLink plays (Gabby, 18 Oct 2026: "a rule you can set").
// A third-person talk would hide the HUD and the InfoLink window with it (and the game itself would cut
// the InfoLink); so, for an InfoLink that has the rule (UCScene.bHushTalks: the map editor's InfoLinks
// unless "No talking while it plays" is off, the scenes that want it), every talk started by a click is
// switched off from its start until its window has gone, then switched back on. Only the talks this
// switched off come back: the ones that were off already stay off. One in a level, made by Hold.
//=============================================================================
class UCTalkHush extends Info;

var Conversation off[128];   // the talks switched off here
var int numOff;
var float heldUntil;         // at least this long (the window opens a moment after the call starts)
var float since;             // the lists are looked through a few times a second

static function Hold(Actor ctx)
{
	local UCTalkHush h;

	foreach ctx.AllActors(class'UCTalkHush', h)
		break;
	if (h == None)
		h = ctx.Spawn(class'UCTalkHush');
	if (h == None)
		return;
	h.heldUntil = ctx.Level.TimeSeconds + 3.0;
	h.since = 1.0;
	h.Enable('Tick');
}

function bool OnAir()
{
	local DeusExPlayer P;
	local DeusExRootWindow root;

	P = DeusExPlayer(GetPlayerPawn());
	if (P == None)
		return False;
	root = DeusExRootWindow(P.rootWindow);
	return P.dataLinkPlay != None || (root != None && root.hud != None && root.hud.infolink != None);
}

function Tick(float dt)
{
	local Actor A;
	local ConListItem item;
	local int i;

	if (Level.TimeSeconds < heldUntil || OnAir())
	{
		since += dt;
		if (since < 0.2)
			return;
		since = 0;
		// every clickable talk off, also one a scene attaches meanwhile
		foreach AllActors(class'Actor', A)
			for (item = ConListItem(A.ConListItems); item != None; item = item.next)
				if (item.con != None && item.con.bInvokeFrob && numOff < ArrayCount(off))
				{
					item.con.bInvokeFrob = False;
					off[numOff] = item.con;
					numOff++;
				}
		return;
	}
	for (i = 0; i < numOff; i++)
		if (off[i] != None)
			off[i].bInvokeFrob = True;
	numOff = 0;
	Disable('Tick');
}

defaultproperties
{
}
