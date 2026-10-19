//=============================================================================
// UCFateWatch - what happened to the characters of the map, kept for the whole game: the map editor's
// Story and Interactions ask "is he dead?" in this map or in any later one (Simons remembers).
// For every character of the map, when it goes down, permanent flags (never expire):
//   UCFate<code>_<actor>_Dead  killed
//   UCFate<code>_<actor>_KO    knocked out (an unconscious body killed afterwards becomes _Dead)
//   UCFate<code>_<actor>_Down  either: "is alive" is _Down false
// <code> is MapCode of the map's name, <actor> the character's name in the map (the editor writes the same
// names: tools/mapkit/editor/static/story.js, fateFlag). A story can also set these flags itself (a death
// in a cutscene): they are ordinary flags, the last one written counts.
// A character that leaves the map alive (destroyed while healthy: it walked away, a script took it) is
// not counted. Spawned by UCCampaign in every map, kept in the map's saved state.
//=============================================================================
class UCFateWatch extends Info;

var string code;
var ScriptedPawn who[192];
var name whoName[192];
var DeusExCarcass body[192];       // the unconscious body of a character knocked out
var vector lastLoc[192];
var int lastHealth[192];
var byte fate[192];                // 0 alive, 1 knocked out, 2 killed, 3 gone (left alive)
var byte carried[192];             // knocked out, the body in JC's arms (1)
var int num;
var float scanTime;

// a short code of the map's name for the flags (the editor computes the same: story.js fateCode)
static function string MapCode(string m)
{
	local int i, h;
	local string hex, out;

	// integers only (UnrealScript's % works in floats and loses the last digits of big numbers)
	m = Caps(m);
	for (i = 0; i < Len(m); i++)
		h = (h * 31 + Asc(Mid(m, i, 1))) & 16777215;
	hex = "0123456789abcdef";
	for (i = 0; i < 6; i++)
	{
		out = Mid(hex, h & 15, 1) $ out;
		h = h >> 4;
	}
	return out;
}

function string MapName()
{
	local DeusExLevelInfo info;

	foreach AllActors(class'DeusExLevelInfo', info)
		return info.mapName;
	return "";
}

function bool Known(ScriptedPawn sp)
{
	local int i;

	for (i = 0; i < num; i++)
		if (who[i] == sp)
			return True;
	return False;
}

function SetFlag(DeusExPlayer P, int i, string kind, bool v)
{
	P.FlagBase.SetBool(P.rootWindow.StringToName("UCFate" $ code $ "_" $ whoName[i] $ "_" $ kind), v,, 99);
}

function SetFate(DeusExPlayer P, int i, byte f)
{
	fate[i] = f;
	SetFlag(P, i, "Down", True);
	SetFlag(P, i, "Dead", f == 2);
	SetFlag(P, i, "KO", f == 1);
	if (f == 2)
		Log("UCFateWatch: " $ whoName[i] $ " killed (UCFate" $ code $ "_" $ whoName[i] $ ")");
	else
		Log("UCFateWatch: " $ whoName[i] $ " knocked out (UCFate" $ code $ "_" $ whoName[i] $ ")");
}

function bool Carrying(DeusExPlayer P)
{
	return POVCorpse(P.inHand) != None || POVCorpse(P.inHandPending) != None;
}

// the unconscious body of character i: a body not taken by another, where it fell
function DeusExCarcass FindBody(int i)
{
	local DeusExCarcass c, best;
	local int k;
	local bool taken;

	foreach RadiusActors(class'DeusExCarcass', c, 220, lastLoc[i])
	{
		if (!c.bNotDead)
			continue;
		taken = False;
		for (k = 0; k < num; k++)
			if (k != i && body[k] == c)
				taken = True;
		if (!taken && (best == None || VSize(c.Location - lastLoc[i]) < VSize(best.Location - lastLoc[i])))
			best = c;
	}
	return best;
}

event Tick(float deltaTime)
{
	local DeusExPlayer P;
	local ScriptedPawn sp;
	local int i;

	P = DeusExPlayer(GetPlayerPawn());
	if (P == None || P.FlagBase == None || P.rootWindow == None)
		return;
	if (code == "")
		code = MapCode(MapName());
	// the characters there are, and the ones that appear later (spawned by a script)
	scanTime -= deltaTime;
	if (scanTime <= 0)
	{
		scanTime = 1.0;
		foreach AllActors(class'ScriptedPawn', sp)
			if (sp.Health > 0 && num < ArrayCount(who) && !Known(sp))
			{
				who[num] = sp;
				whoName[num] = sp.Name;
				lastLoc[num] = sp.Location;
				lastHealth[num] = sp.Health;
				num++;
			}
	}
	// every frame: a character killed by an explosion is gone a moment later
	for (i = 0; i < num; i++)
	{
		if (fate[i] == 0)
		{
			if (who[i] == None || who[i].bDeleteMe)
			{
				if (lastHealth[i] > 0)
					fate[i] = 3;
				continue;
			}
			lastLoc[i] = who[i].Location;
			lastHealth[i] = who[i].Health;
			if (who[i].Health <= 0 || who[i].IsInState('Dying'))
			{
				if (who[i].bStunned && !who[i].bBurnedToDeath)
					SetFate(P, i, 1);
				else
					SetFate(P, i, 2);
			}
		}
		else if (fate[i] == 1)
		{
			// knocked out: killed afterwards (shot while lying there, blown to pieces)?
			if (carried[i] == 1)
			{
				// JC put the body down somewhere: the new body is that one (the nearest to him)
				if (!Carrying(P))
				{
					carried[i] = 0;
					lastLoc[i] = P.Location;
					body[i] = FindBody(i);
				}
			}
			else if (body[i] == None)
				body[i] = FindBody(i);
			else if (body[i].bDeleteMe)
			{
				body[i] = None;
				if (Carrying(P))
					carried[i] = 1;             // picked up
				else
					SetFate(P, i, 2);           // gone in pieces: the game kills an unconscious body before
			}
			else if (!body[i].bNotDead)
				SetFate(P, i, 2);
		}
	}
}
