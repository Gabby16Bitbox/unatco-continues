//=============================================================================
// UCEdInfoLink - an InfoLink written in the map editor (Story panel). One-way, as the mod's
// rule wants: only the caller speaks, JC never answers by radio. Made by UCEditorStory.InfoLink
// (the generated story fills the lines right after spawning it). It waits for conversations
// and for another InfoLink of the editor to finish. As in the game, the whole text goes to the
// conversation history at the start (UCScene.InfoStart): an InfoLink cut by a level change
// counts as heard.
//=============================================================================
class UCEdInfoLink extends UCScene;

var string caller;          // portrait: InfoPortraits.<caller> (WaltonSimons, AlexJacobson...)
var string callerName;      // the name shown above the text
var string lines[32];
var int numLines;
var int n;
var float d;
var bool bPlaying;
var bool bQuickStart;   // Tutorial room guidance: the latest room replaces the previous one.

function CancelGuidance()
{
	StopInfoVoice();
	if (bPlaying)
		HideInfo(True);
	bPlaying = False;
	GotoState('');        // Cancel a latent Sleep and all remaining lines, including queued calls.
	Destroy();
}

function AddLine(string s)
{
	if (s == "" || numLines >= ArrayCount(lines))
		return;
	lines[numLines] = s;
	numLines++;
}

function string DisplayName(string bindName)
{
	if (bindName == caller && callerName != "")
		return callerName;
	return Super.DisplayName(bindName);
}

function float InfoLine(int i)
{
	if (i < numLines)
		return Say(caller, lines[i]);
	return -1;
}

function bool OtherPlaying()
{
	local UCEdInfoLink other;

	foreach AllActors(class'UCEdInfoLink', other)
		if (other != Self && !other.bDeleteMe && other.bPlaying)
			return True;
	return False;
}

state Playing
{
Begin:
	// never over a conversation or another InfoLink
	if (Plr() == None || Talking() || OtherPlaying())
	{
		Sleep(0.5);
		Goto('Begin');
	}
	bPlaying = True;
	if (!bQuickStart)
		Sleep(0.5);
	Log("UCEd: InfoLink from" @ caller @ "(" $ numLines @ "lines)");
	InfoStart(caller);
	if (!bQuickStart)
		Sleep(1.5);
	n = 0;
Next:
	d = InfoLine(n);
	if (d >= 0)
	{
		Sleep(d);
		bInfoVoiceActive = False;
		n++;
		Goto('Next');
	}
	HideInfo();
	bPlaying = False;
	Destroy();
}

defaultproperties
{
     bHushTalks=True
}
