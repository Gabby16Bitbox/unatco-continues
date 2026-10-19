//=============================================================================
// UCSceneWIPEnd - where the finished part of the mod ends, for now: as soon as JC steps out of the
// butcher's shop onto Wan Chai Street (06_HongKong_WanChai_Street, after the Harbourline garage), an
// InfoLink in JC's own voice says that the mod stops here. An exception to the one-way InfoLink rule (JC
// never calls), asked by Gabby on 19 Oct 2026 for this message only. Once (flag UC_WIPEndShown), never
// over a conversation or another InfoLink. Spawned by UCCampaign.RouteTick.
//=============================================================================
class UCSceneWIPEnd extends UCScene transient;

var int n;
var float d;
var float outT;         // seconds JC has been out in the street, free

function bool InfoBusy()
{
	local DeusExRootWindow root;

	if (Plr() == None)
		return False;
	root = DeusExRootWindow(Plr().rootWindow);
	return Plr().dataLinkPlay != None || (root != None && root.hud != None && root.hud.infolink != None);
}

// Out of the shop's grille (the shop front is at x -192) on the pavement and the street before it
function bool OnStreet()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return False;
	return P.Location.X > -170 && P.Location.X < 260 && P.Location.Y > -2750 && P.Location.Y < -2100
		&& P.Location.Z > -40 && P.Location.Z < 140;
}

function float EndLine(int i)
{
	switch (i)
	{
		case 0: return Say("JCDenton", "This is where the road ends, for now. UNATCO Continues is a work in progress, and the finished part of the story stops here.");
		case 1: return Say("JCDenton", "There are still a few leftovers from testing around, if you want to go and find them. Just don't expect them to work.");
		case 2: return Say("JCDenton", "For news about the mod, follow the YouTube channel GABROCHACHO.");
		case 3: return Say("JCDenton", "If you like the mod, you could help finish it yourself. We're looking for passionate people who want to see it through.");
	}
	return -1;
}

function float InfoLine(int i)
{
	return EndLine(i);
}

state Playing
{
Begin:
	if (GetF('UC_WIPEndShown'))
	{
		Destroy();
		Stop;
	}
Wait:
	Sleep(0.25);
	if (Plr() == None || !OnStreet() || Talking() || InfoBusy())
	{
		outT = 0;
		Goto('Wait');
	}
	outT += 0.25;
	if (outT < 1.0)
		Goto('Wait');
	SetF('UC_WIPEndShown', True);
	InfoStart("JCDenton");
	Sleep(1.5);
	n = 0;
Next:
	if (Talking())
	{
		Sleep(0.25);
		Goto('Next');
	}
	d = EndLine(n);
	if (d >= 0)
	{
		if (d > 0)
			Sleep(d);
		n++;
		Goto('Next');
	}
	HideInfo();
	Log("UCSceneWIPEnd: the end-of-the-mod message was shown");
	Destroy();
}

defaultproperties
{
}
