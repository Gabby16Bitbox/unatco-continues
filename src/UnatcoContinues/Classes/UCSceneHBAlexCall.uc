//=============================================================================
// UCSceneHBAlexCall - Mission 6, Harbourline Tower: Alex Jacobson's InfoLinks (Gabby's mission doc
// "Mission 6 - Hong Kong opening", with the house rule of one-way InfoLinks: only Alex speaks, JC never
// answers on the radio; build plan hk6_plan.md section 5).
//  which 1, on the roof after Eva (UCSceneHarbourline.AlexTick): where Paul's plane landed, the
//    killswitch, Kwan and his vehicle. Flag UC_HB_AlexArrival, goal UCHBMeetKwan.
//  which 2, by the vehicle after the attack (phase 6): the report, the containers, the airstrip,
//    then the line goes dead (HideInfo(True)). Flag UC_HB_AlexReport, goal UCHBAirstrip if missing.
// The flag and the goal come before the call (UCScene.InfoStart: a call cut short by a map change
// still counts as heard and is in the history).
//=============================================================================
class UCSceneHBAlexCall extends UCScene transient;

var int which;
var int n;
var float d;

function bool InfoBusy()
{
	local DeusExRootWindow root;

	if (Plr() == None)
		return False;
	root = DeusExRootWindow(Plr().rootWindow);
	return Plr().dataLinkPlay != None || (root != None && root.hud != None && root.hud.infolink != None);
}

// One line each (seconds to hold it, 0 = skipped, -1 = over); the pauses of the doc after the lines.
function float AlexLine(int i)
{
	if (which == 2)
	{
		switch (i)
		{
			case 0: return Say("AlexJacobson", "JC, I just saw Harbourline's preliminary report. A Luminous Path attack.") + 0.8;
			case 1: return Say("AlexJacobson", "Your biomonitor says you're in one piece. Good.");
			case 2: return Say("AlexJacobson", "And I know what you're going to ask. What's in those containers.") + 2.0;
			case 3: return Say("AlexJacobson", "That's above my clearance.") + 1.0;
			case 4: return Say("AlexJacobson", "And I don't think it's within yours.");
			case 5:
				if (!GetF('UC_HB_ContainerBlew'))
					return 0;
				return Say("AlexJacobson", "The report also says you let a container blow. Three people in New York have already read it.");
			case 6: return Say("AlexJacobson", "Sending you the airstrip coordinates. Eva's already been told.");
		}
		return -1;
	}
	switch (i)
	{
		case 0: return Say("AlexJacobson", "JC, it's Alex. Paul's plane touched down at a private airstrip north of the harbor, about six hours ago.");
		case 1: return Say("AlexJacobson", "If the killswitch numbers are right, he's only got a few hours left. Enough to reach Tong... if Tong is really here.");
		case 2: return Say("AlexJacobson", "The Coalition has a vehicle for you on the ground floor. Your contact is Victor Kwan, head of security.");
		case 3: return Say("AlexJacobson", "One more thing, JC.") + 1.5;     // the silence where JC's "Yes?" was
		case 4: return Say("AlexJacobson", "...Nothing. Watch your back. All of it.");
	}
	return -1;
}

function float InfoLine(int i)
{
	return AlexLine(i);
}

function CallEffects()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	if (which == 2)
	{
		SetF('UC_HB_AlexReport', True);
		if (P.FindGoal('UCHBAirstrip') == None)
			GoalNew('UCHBAirstrip', "Find the private airstrip north of the harbor where Paul's plane landed. Kwan's pilot is Lo.");
		return;
	}
	SetF('UC_HB_AlexArrival', True);
	if (P.FindGoal('UCHBMeetKwan') == None)
		GoalNew('UCHBMeetKwan', "Meet Victor Kwan, Harbourline's head of security, on the ground floor. He has a vehicle for you.");
}

state Playing
{
Begin:
	Sleep(1.0);
	// no InfoLink over a conversation or another InfoLink
	if (Plr() == None || Talking() || InfoBusy())
		Goto('Begin');
	CallEffects();
	InfoStart("AlexJacobson");
	Sleep(1.5);
	n = 0;
Next:
	// a conversation goes first (a third-person one hides the HUD and this window): Alex waits for it
	// (the scene also takes the clicks off its people's talks while he calls: UCSceneHarbourline.FrobTalks)
	if (Talking())
	{
		Sleep(0.25);
		Goto('Next');
	}
	d = AlexLine(n);
	if (d >= 0)
	{
		Log("UCHBAlexCall: line" @ n @ "held" @ d @ "at" @ Level.TimeSeconds);
		if (d > 0)
			Sleep(d);
		n++;
		Goto('Next');
	}
	HideInfo(which == 2);              // the second call ends abruptly: the line goes dead
	Log("UCHBAlexCall: call" @ which @ "over");
	Destroy();
}

defaultproperties
{
     which=1
}
