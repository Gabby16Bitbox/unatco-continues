//=============================================================================
// UCCutscene - a cutscene made in the map editor (a "Cutscene camera" with its timeline, like the
// camera paths of Premiere or of the Minecraft film mods): the camera flies through its keys
// (position, direction, roll, zoom), with a curve for each step, cut into shots; subtitles, a fade from
// and to black, the black bars of a film. An interaction plays it (Then... -> Play the cutscene; a
// collision box JC walks into, a button...), a story event or dialogue (PlayCut), or the start of the
// map (bAutoPlay). What happens during it (a door opens at 3 s, a guard runs...) are the interactions
// "When it starts", each after its seconds: this actor triggers UCL_<name>_Start when it starts and
// UCL_<name>_End (and its Event) when it ends.
//
// How: as the game's own intro and endings, JC goes into the state Interpolating (no input, no weapon
// in his hands, the enemies do not see him, no saving) and, invisible and without collision, is moved
// every frame to the camera's place (his eyes there): the view is exactly the key's, and the sounds
// and the zone (fog, water) are the camera's. A UCCutDriver, spawned when it starts and so the last
// actor to tick, puts him there once more at the end of every frame: after his own physics and after
// what the camera looks at has moved. A stand-in of JC (JCDouble) stays where he was. At the
// end everything comes back as it was. While it plays the stories of the editor wait (UCEditorStory
// Timer) and the collision boxes do not count JC (UCTriggerBox).
//
//   KeyT/P/R/F/E/S  time, place (where the eyes are), rotation (with roll), field of view (degrees
//                   across the width), curve to the next key (0 linear, 1 smooth, 2 ease in, 3 ease
//                   out, 4 hold), shot (no movement between two shots: a cut)
//   bStraight       straight lines between the keys (else a smooth path through them)
//   LookAt          the name of an actor the camera always looks at (the keys give its roll and zoom)
//   Line*           subtitles: time, seconds (0: as long as the text needs), who, text, a sound
//=============================================================================
class UCCutscene extends UCEditorStory;

var() string  CutName;
var() float   KeyT[48];
var() vector  KeyP[48];
var() rotator KeyR[48];
var() float   KeyF[48];
var() byte    KeyE[48];
var() byte    KeyS[48];
var() int     NumKeys;
var() bool    bStraight;
var() string  LookAt;
var() float   LineT[24];
var() float   LineD[24];
var() string  LineWho[24];
var() string  LineText[24];
var() string  LineSnd[24];
var() int     NumLines;
var() float   Length;
var() float   FadeIn, FadeOut;
var() bool    bBars, bSkippable, bOnce, bAutoPlay, bShowJC;

var bool  bPlaying, bDone, bQueued, bArmed, bSkipNow, bLookFound;
var float T;
var int   LineNow;
var DeusExPlayer P;
var vector    SavedLoc;
var rotator   SavedRot, SavedView;
var float     SavedFOV;
var name      SavedState;
var EPhysics  SavedPhys;
var bool      SavedCA, SavedBA, SavedBP, SavedWorld;
var Inventory SavedHand;
var JCDouble  Double;
var UCCutWindow Win;
var Actor     LookActor;
var UCCutDriver Driver;

function StartStory()
{
	if (bAutoPlay)
		Play();
}

// another cutscene is playing
function bool Busy()
{
	local UCCutscene C;

	foreach AllActors(class'UCCutscene', C)
		if (C != Self && C.bPlaying)
			return True;
	return False;
}

function bool CanStart(DeusExPlayer Pl)
{
	return Pl != None && !Pl.IsInState('Dying') && !Pl.IsInState('Interpolating') && !Pl.IsInState('Paralyzed')
		&& !Pl.InConversation() && !Busy();
}

// ---------------------------------------------------------------- playing
function Play()
{
	local DeusExRootWindow root;
	local rotator stand;

	if (bPlaying || (bOnce && bDone) || NumKeys <= 0)
		return;
	P = Plr();
	if (P == None)
		return;
	if (!CanStart(P))
	{
		bQueued = True;                 // as soon as the conversation (or the other cutscene) is over
		Log("UCCutscene" @ Name @ "- waits (a conversation or another cutscene)");
		return;
	}
	bQueued = False;
	bDone = True;
	bPlaying = True;
	bArmed = False;
	bSkipNow = False;
	bLookFound = False;
	T = 0;
	LineNow = -1;

	SavedLoc = P.Location;
	SavedRot = P.Rotation;
	SavedView = P.ViewRotation;
	SavedFOV = P.DesiredFOV;
	SavedState = P.GetStateName();
	SavedPhys = P.Physics;
	SavedCA = P.bCollideActors;
	SavedBA = P.bBlockActors;
	SavedBP = P.bBlockPlayers;
	SavedWorld = P.bCollideWorld;
	SavedHand = P.inHand;
	if (P.CarriedDecoration != None)
		P.DropDecoration();

	P.SetCollision(False, False, False);
	P.bCollideWorld = False;
	P.Velocity = vect(0,0,0);
	P.Acceleration = vect(0,0,0);
	P.SetPhysics(PHYS_Falling);         // (a falling JC cannot be drawn into a conversation)
	P.bHidden = True;
	P.GotoState('Interpolating');

	if (bShowJC)
	{
		stand.Yaw = SavedRot.Yaw;
		Double = Spawn(class'JCDouble', Self,, SavedLoc, stand);
		if (Double != None)
		{
			Double.SetSkin(P);
			Double.SetOrders('Standing',, True);
		}
	}

	root = DeusExRootWindow(P.rootWindow);
	if (root != None)
	{
		Win = UCCutWindow(root.NewChild(class'UCCutWindow'));
		if (Win != None)
		{
			Win.SetPos(0, 0);
			Win.SetSize(root.width, root.height);
			Win.bBars = bBars;
			if (!bSkippable)
				Win.hint = 0;
			if (FadeIn > 0)
				Win.fade = 1;
		}
	}
	Log("UCCutscene" @ Name @ "- plays" @ CutName @ "(" $ Length @ "s)");
	Apply(0);
	Drive();
	TriggerTag(StringToName("UCL_" $ Name $ "_Start"));
}

// the camera's place once more at the end of every frame (UCCutDriver)
function Drive()
{
	if (Driver != None && !Driver.bDeleteMe)
		return;
	Driver = Spawn(class'UCCutDriver', Self);
	if (Driver != None)
		Driver.Cut = Self;
}

function Stop()
{
	bQueued = False;
	if (bPlaying)
		Finish(True, False);
}

function Tick(float dt)
{
	local float a;

	if (bQueued && !bPlaying)
	{
		if (CanStart(Plr()))
			Play();
		return;
	}
	if (!bPlaying)
		return;
	if (P == None || P.bDeleteMe)
	{
		bPlaying = False;
		return;
	}
	T += dt;
	if (bSkippable)
	{
		if (P.bFire == 0 && P.aUp <= 0)
			bArmed = True;              // let go first: a click held when it started does not skip it
		else if (bArmed && T > 0.3)
			bSkipNow = True;
	}
	if (bSkipNow || T >= Length)
	{
		Finish(bSkipNow, False);
		return;
	}
	Apply(T);
	Drive();
	ShowLines(T);
	if (Win != None)
	{
		a = 0;
		if (FadeIn > 0 && T < FadeIn)
			a = 1 - T / FadeIn;
		if (FadeOut > 0 && T > Length - FadeOut)
			a = FMax(a, (T - (Length - FadeOut)) / FadeOut);
		Win.fade = FClamp(a, 0, 1);
	}
}

// Everything back as it was. Skipped: what was still to happen during it (the interactions "when it
// starts" with their seconds) happens at once.
function Finish(bool bSkipped, bool bNoHurry)
{
	local UCLink L;
	local Weapon W;

	bPlaying = False;
	if (Driver != None)
	{
		Driver.Destroy();
		Driver = None;
	}
	if (bSkipped && !bNoHurry)
		foreach AllActors(class'UCLink', L, StringToName("UCL_" $ Name $ "_Start"))
			L.Hurry();
	if (P != None && !P.bDeleteMe)
	{
		P.bHidden = False;
		P.SetLocation(SavedLoc);
		P.bCollideWorld = SavedWorld;
		P.SetCollision(SavedCA, SavedBA, SavedBP);
		P.SetRotation(SavedRot);
		P.ViewRotation = SavedView;
		P.DesiredFOV = SavedFOV;
		P.FOVAngle = SavedFOV;
		P.Velocity = vect(0,0,0);
		P.Acceleration = vect(0,0,0);
		if (SavedState == '' || SavedState == 'Interpolating')
			SavedState = 'PlayerWalking';
		P.GotoState(SavedState);
		if (SavedPhys == PHYS_None)
			SavedPhys = PHYS_Walking;
		P.SetPhysics(SavedPhys);
		P.bDetectable = True;
		P.ShowHud(True);
		W = Weapon(SavedHand);
		if (W != None)
			W.bHideWeapon = False;
		if (SavedHand != None && !SavedHand.bDeleteMe && SavedHand.Owner == P)
			P.PutInHand(SavedHand);
	}
	if (Double != None)
	{
		Double.Destroy();
		Double = None;
	}
	if (Win != None)
	{
		if (bSkipped)
		{
			Win.fade = 1;
			Win.Close(0.4);
		}
		else if (FadeOut > 0)
			Win.Close(0.6);             // the black fades away on JC's own view
		else
			Win.Close(0);
		Win = None;
	}
	Log("UCCutscene" @ Name @ "- ends" @ CutName @ "at" @ T @ "s" @ bSkipped);
	TriggerTag(StringToName("UCL_" $ Name $ "_End"));
	if (Event != '')
		TriggerTag(Event);
}

// ---------------------------------------------------------------- the camera
// The path goes through the keys with the speed it has at each of them (a Catmull-Rom spline in time, as the
// camera paths of film tools): the camera does not slow down at a key. It starts from rest at the first key
// and comes to rest at the last; across a cut it keeps moving up to the cut and from it. Per key (KeyE):
// 1 smooth (passes through), 2 or 3 stop (slows down to it and starts again), 0 linear (straight to the next
// key at the same speed), 4 hold (stays until the next key, then jumps).

// component c of key i: 0-2 place, 3-5 pitch, yaw, roll, 6 field of view
function float Comp(int i, int c)
{
	if (c == 0)
		return KeyP[i].X;
	if (c == 1)
		return KeyP[i].Y;
	if (c == 2)
		return KeyP[i].Z;
	if (c == 3)
		return KeyR[i].Pitch;
	if (c == 4)
		return KeyR[i].Yaw;
	if (c == 5)
		return KeyR[i].Roll;
	return KeyF[i];
}

// how fast component c changes at key i (per second)
function float Slope(int i, int c)
{
	local bool bPrev, bNext;

	if (KeyE[i] == 2 || KeyE[i] == 3)
		return 0;
	bPrev = i > 0 && KeyS[i - 1] == KeyS[i];
	bNext = i + 1 < NumKeys && KeyS[i + 1] == KeyS[i];
	if (bPrev && bNext)
		return (Comp(i + 1, c) - Comp(i - 1, c)) / FMax(0.001, KeyT[i + 1] - KeyT[i - 1]);
	if (i == 0 || i == NumKeys - 1)
		return 0;                                      // the start and the end of the cutscene: at rest
	if (bNext)
		return (Comp(i + 1, c) - Comp(i, c)) / FMax(0.001, KeyT[i + 1] - KeyT[i]);    // a shot after a cut
	if (bPrev)
		return (Comp(i, c) - Comp(i - 1, c)) / FMax(0.001, KeyT[i] - KeyT[i - 1]);    // a shot up to a cut
	return 0;
}

function float Value(int i, int c, float t)
{
	local float d, u, u2, u3;

	d = FMax(0.001, KeyT[i + 1] - KeyT[i]);
	u = FClamp((t - KeyT[i]) / d, 0, 1);
	if (bStraight || KeyE[i] == 0)
		return Comp(i, c) + (Comp(i + 1, c) - Comp(i, c)) * u;
	u2 = u * u;
	u3 = u2 * u;
	return (2 * u3 - 3 * u2 + 1) * Comp(i, c) + (u3 - 2 * u2 + u) * d * Slope(i, c)
		+ (3 * u2 - 2 * u3) * Comp(i + 1, c) + (u3 - u2) * d * Slope(i + 1, c);
}

function Pose(float t, out vector pos, out rotator r, out float fov)
{
	local int i;

	if (NumKeys <= 0)
		return;
	i = 0;
	while (i < NumKeys - 1 && KeyT[i + 1] <= t)          // the last key at or before t
		i++;
	if (t <= KeyT[0] || i >= NumKeys - 1 || KeyS[i + 1] != KeyS[i] || KeyE[i] == 4)
	{
		pos = KeyP[i];                                   // before the first key, after the last of its shot, held
		r = KeyR[i];
		fov = KeyF[i];
		return;
	}
	pos.X = Value(i, 0, t);
	pos.Y = Value(i, 1, t);
	pos.Z = Value(i, 2, t);
	r.Pitch = int(Value(i, 3, t));
	r.Yaw = int(Value(i, 4, t));
	r.Roll = int(Value(i, 5, t));
	fov = Value(i, 6, t);
}

function Actor Looked()
{
	local Actor A;

	if (!bLookFound)
	{
		bLookFound = True;
		LookActor = None;
		if (LookAt != "")
			foreach AllActors(class'Actor', A)
				if (string(A.Name) ~= LookAt && !A.bDeleteMe)
				{
					LookActor = A;
					break;
				}
	}
	if (LookActor != None && LookActor.bDeleteMe)
		LookActor = None;
	return LookActor;
}

function vector Focus(Actor A)
{
	if (Pawn(A) != None)
		return A.Location + vect(0,0,1) * Pawn(A).BaseEyeHeight;
	return A.Location;
}

function Apply(float t)
{
	local vector pos;
	local rotator r, lr;
	local float fov;
	local Actor A;

	Pose(t, pos, r, fov);
	A = Looked();
	if (A != None)
	{
		lr = rotator(Focus(A) - pos);
		r.Pitch = lr.Pitch;
		r.Yaw = lr.Yaw;
	}
	if (fov < 5)
		fov = SavedFOV;
	P.SetLocation(pos - vect(0,0,1) * P.EyeHeight);
	P.Velocity = vect(0,0,0);
	P.Acceleration = vect(0,0,0);
	P.ViewRotation = r;
	P.WalkBob = vect(0,0,0);
	P.DesiredFOV = fov;
	P.FOVAngle = fov;
	P.FrobTarget = None;
}

// ---------------------------------------------------------------- subtitles
function float LineLen(int i)
{
	if (LineD[i] > 0)
		return LineD[i];
	return 2.0 + Len(LineText[i]) * 0.06;
}

function ShowLines(float t)
{
	local int i, now;
	local Sound snd;

	now = -1;
	for (i = 0; i < NumLines; i++)
		if (t >= LineT[i] && t < LineT[i] + LineLen(i))
			now = i;
	if (now == LineNow)
		return;
	LineNow = now;
	if (Win != None)
	{
		if (now < 0)
			Win.SetLine("", "");
		else
			Win.SetLine(LineWho[now], LineText[now]);
	}
	if (now >= 0 && LineSnd[now] != "")
	{
		snd = Sound(DynamicLoadObject(LineSnd[now], class'Sound', True));
		if (snd != None)
			P.PlaySound(snd, SLOT_None, 1.0,, 100000);
		else
			Log("UCCutscene" @ Name @ "- no sound" @ LineSnd[now]);
	}
}

defaultproperties
{
     bRouteOnly=False
     bBars=True
     bSkippable=True
     bOnce=True
     bShowJC=True
     Length=5.000000
}
