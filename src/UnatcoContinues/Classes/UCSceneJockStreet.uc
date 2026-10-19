//=============================================================================
// UCSceneJockStreet - Hell's Kitchen (04_NYC_Street), UNATCO route: Jock's InfoLink as soon as JC is out
// of the 'Ton and walking the street between the hotel and the subway (Gabby, 17 Oct 2026: he says to come
// quickly, he is seeing strange movements, they have to move; it gives the goal). Only Jock speaks (house
// rule: one-way InfoLinks). It comes after Gunther's talk outside the hotel (or after the window exit
// that skips it), never over a conversation or another InfoLink, and waits for the "Bring him in alive"
// exchange of UCSceneGuntherTon while JC is still near Gunther. It sets up Battery Park, where his next
// call is cut by the shot (UCSceneBatteryPark.JockLine): there he says "JC! Thank God", here he is still
// calm, just uneasy. Flags: UC_JockStreetCall (started, before the lines: a reload or a map change
// mid-call counts as heard), UC_JockStreetCallDone (over: UCCampaign.RouteTick then gives the goal
// MeetJockBatteryPark, which Battery Park closes). Spawned by UCCampaign.RouteTick.
//=============================================================================
class UCSceneJockStreet extends UCScene transient;

var int n;
var float d;
var float inT;          // seconds JC has been in the street, free, before the call

function bool InfoBusy()
{
	local DeusExRootWindow root;

	if (Plr() == None)
		return False;
	root = DeusExRootWindow(Plr().rootWindow);
	return Plr().dataLinkPlay != None || (root != None && root.hud != None && root.hud.infolink != None);
}

// On the avenue south of the hotel and along to the subway (street level, not the porch nor the
// subway's stairs), where the window's alley comes out too (the map's path nodes, 17 Oct).
function bool InStreet()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return False;
	return P.Location.Z > -560 && P.Location.Z < -440
		&& P.Location.X > 1150 && P.Location.X < 2150 && P.Location.Y > -1250 && P.Location.Y < 650;
}

// Gunther's "Bring him in alive" is still to come while JC is near him
function bool GuntherPending()
{
	local UCSceneGuntherTon g;
	local ScriptedPawn sp;

	foreach AllActors(class'UCSceneGuntherTon', g)
		if (g.bMet && !g.bAliveDone)
		{
			sp = g.Gunther();
			if (sp != None && Plr() != None && VSize(sp.Location - Plr().Location) < 1200)
				return True;
		}
	return False;
}

function bool Free()
{
	return !Talking() && !InfoBusy() && !GuntherPending() && !GetF('UC_Tour')
		&& !GetF('UC_AnnaMetroOpened') && !GetF('UC_GateGuard_Played') && !GetF('JCBrokeWithUNATCO');
}

// One-way: Jock only. Short: from the street to Anna at the subway is a few seconds' walk.
function float JockLine(int i)
{
	switch (i)
	{
		case 0: return Say("Jock", "JC, it's Jock. I'm on the pad at Battery Park, rotors warm.");
		case 1: return Say("Jock", "Something's off down here. Cars I don't know, guys in suits walking the park like they own it.");
		case 2: return Say("Jock", "I don't like it. Grab the subway and get here fast. We need to be in the air.");
	}
	return -1;
}

function float InfoLine(int i)
{
	return JockLine(i);
}

state Playing
{
Begin:
	// a call cut by a reload or a map change: heard (the goal comes from UCCampaign)
	if (GetF('UC_JockStreetCall'))
	{
		SetF('UC_JockStreetCallDone', True);
		Destroy();
		Stop;
	}
Wait:
	Sleep(0.25);
	if (Plr() == None || !InStreet() || !Free())
	{
		inT = 0;
		Goto('Wait');
	}
	inT += 0.25;
	if (inT < 1.5)
		Goto('Wait');
	SetF('UC_JockStreetCall', True);
	InfoStart("Jock");
	Sleep(1.5);
	n = 0;
Next:
	// a conversation goes first (a third-person one hides the HUD and this window): Jock waits for it
	if (Talking())
	{
		Sleep(0.25);
		Goto('Next');
	}
	d = JockLine(n);
	if (d >= 0)
	{
		if (d > 0)
			Sleep(d);
		n++;
		Goto('Next');
	}
	HideInfo();
	SetF('UC_JockStreetCallDone', True);
	Log("UCJockStreet: Jock's call over, the goal follows");
	Destroy();
}

defaultproperties
{
}
