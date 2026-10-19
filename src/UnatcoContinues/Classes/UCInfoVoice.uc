//=============================================================================
// UCInfoVoice - the voice of the mod's InfoLinks (UCScene.Say) on a channel of its own: an invisible actor
// that stays on JC and plays the line on its SLOT_Talk (on the player's own SLOT_Talk another line played
// through him would cut it). One for all the scenes (UCInfoVoice.Get); transient.
//
// It also measures how fast the game's clock runs against the real one (the PC's clock: LevelInfo's
// Hour/Minute/Second/Millisecond). The original Deus Ex on a modern PC runs its clock fast (it times itself
// by a CPU speed it measured wrong): a Sleep of a voice's length ended before the voice, and the next line cut
// it, in every InfoLink (Gabby, 19 Oct 2026; Jock's lines came 18% early). Voices play in real time: the waits
// for them are made in game seconds by GameSeconds(). Revision's clock is right: the ratio stays 1.
//=============================================================================
class UCInfoVoice extends Info
	transient;

var int voiceId;
var float ratio;            // game seconds per real second (1 until measured)
var float winGame;          // game seconds since the measuring window began
var float winReal;          // its start, real seconds of the day
var bool bWin;
var int nLogs;
var int nWin;               // windows measured

static function UCInfoVoice Get(Actor from)
{
	local UCInfoVoice v;

	foreach from.AllActors(class'UCInfoVoice', v)
		if (!v.bDeleteMe)
			return v;
	return from.Spawn(class'UCInfoVoice');
}

// A length of real time (a voice) in game seconds, for Sleep and SetTimer
static function float GameSeconds(Actor from, float realSeconds)
{
	local UCInfoVoice v;

	v = Get(from);
	if (v == None || v.ratio <= 0)
		return realSeconds;
	return realSeconds * v.ratio;
}

function float RealNow()
{
	return Level.Hour * 3600.0 + Level.Minute * 60.0 + Level.Second + Level.Millisecond / 1000.0;
}

// Plays the line where JC is, as loud as the game's own InfoLinks; its id (0: not started)
function int Speak(DeusExPlayer P, Sound snd)
{
	if (P == None || snd == None)
		return 0;
	SetLocation(P.Location);
	StopVoice();
	voiceId = PlaySound(snd, SLOT_Talk, 1.0,, 65536.0);
	return voiceId;
}

function StopVoice()
{
	if (voiceId != 0)
		StopSound(voiceId);
	voiceId = 0;
}

event Tick(float deltaTime)
{
	local PlayerPawn P;
	local float now, real, r;

	P = GetPlayerPawn();
	if (P != None)
		SetLocation(P.Location);

	// the clocks, over windows of 2 real seconds (a midnight or a long hitch starts the window again)
	now = RealNow();
	if (!bWin || now < winReal)
	{
		bWin = True;
		winReal = now;
		winGame = 0;
		return;
	}
	winGame += deltaTime;
	real = now - winReal;
	if (real < 2.0)
		return;
	if (real < 10.0 && winGame > 0)
	{
		r = winGame / real;
		if (r > 0.5 && r < 3.0)
		{
			if (nWin == 0)
				ratio = r;              // the first window at once: an InfoLink may come soon
			else
				ratio = ratio * 0.7 + r * 0.3;
			nWin++;
			if ((nWin == 1 || nWin == 10) && Abs(ratio - 1.0) > 0.03)
			{
				Log("UCInfoVoice: the game's clock runs at" @ ratio @ "x real time: voices are waited for that much longer");
			}
		}
	}
	winReal = now;
	winGame = 0;
}

defaultproperties
{
	ratio=1.000000
	bAlwaysTick=True
	bHidden=True
	bStatic=False
	bCollideActors=False
	bCollideWorld=False
	bBlockActors=False
	bBlockPlayers=False
	RemoteRole=ROLE_None
}
