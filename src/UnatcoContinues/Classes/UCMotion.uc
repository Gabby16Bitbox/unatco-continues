//=============================================================================
// UCMotion - the animation of one object, made in the map editor's Animation panel (keyframes of
// position, rotation and scale, like Premiere's Motion or Unity's Animation window). Played at the
// start of the map, or by an interaction (play, play backwards, stop); when it ends it triggers its
// Event (an interaction "when its animation has finished").
//
// - An object (a model, a decoration, a light...): moved, turned and scaled every frame. Its keys are
//   offsets from where it was put: Pos = units, Rot = rotation units (65536 = a whole turn, so a key
//   at 65536 spins it once), Scale = times its size. Each key has its curve: 1 smooth (it passes
//   through the key without slowing down: a Catmull-Rom spline in time, as UCCutscene's camera),
//   0 linear (straight to the next key at one speed), 2 ease in (at rest at the key, it starts
//   slowly from it), 3 ease out (it slows down to a stop at the next key), 4 hold (it stays, then
//   jumps at the next key). It starts from rest at the first key and comes to rest at the last (a
//   loop whose last key is its first goes on through it). While it plays it does not collide with
//   the world (the engine would push it out of the walls it passes near: a stutter).
// - A mover (a door, an elevator, a moving block): the editor wrote its keys in its KeyPos/KeyRot
//   (the engine moves it and carries whoever stands on it); Seg[i] is the time from key i to key i+1,
//   given to the mover as its MoveTime for each step (also when it opens by itself, as a door).
//=============================================================================
class UCMotion extends Info;

var() string Target;
var() bool   bAutoPlay;
var() byte   Mode;             // 0 once, 1 loop, 2 back and forth
var() float  Length;

var() float   PosT[16];
var() vector  PosV[16];
var() byte    PosE[16];
var() int     NumPos;
var() float   RotT[16];
var() rotator RotV[16];
var() byte    RotE[16];
var() int     NumRot;
var() float   ScaleT[16];
var() float   ScaleV[16];
var() byte    ScaleE[16];
var() int     NumScale;

var() float   Seg[8];

var Actor  A;
var Mover  M;
var vector BaseLoc;
var rotator BaseRot;
var float  BaseScale, BaseRadius, BaseHeight;
var float  T, Dir;
var bool   bPlaying, bFound, bWasMoving;
var bool   bSavedWorld, bOldCollideWorld, bStuck;
var name   MState;

function Actor Find()
{
	local Actor X;

	foreach AllActors(class'Actor', X)
		if (string(X.Name) ~= Target && !X.bDeleteMe)
			return X;
	return None;
}

function Setup()
{
	if (bFound)
		return;
	bFound = True;
	A = Find();
	if (A == None)
	{
		Log("UCMotion" @ Name @ "- no object" @ Target);
		return;
	}
	M = Mover(A);
	BaseLoc = A.Location;
	BaseRot = A.Rotation;
	BaseScale = A.DrawScale;
	BaseRadius = A.CollisionRadius;
	BaseHeight = A.CollisionHeight;
	if (M != None)
	{
		MState = M.InitialState;
		if (M.KeyNum == 0 && Seg[0] > 0)
			M.MoveTime = Seg[0];
	}
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	Setup();
	if (bAutoPlay)
		Play(False);
}

// ---------------------------------------------------------------- playing
function Play(bool bBack)
{
	Setup();
	if (A == None)
		return;
	Log("UCMotion" @ Name @ "- plays" @ Target @ bBack);
	Dir = 1;
	if (bBack)
		Dir = -1;
	bPlaying = True;
	if (M != None)
	{
		MoverGo(bBack);
		return;
	}
	if (A.Physics != PHYS_None)
		A.SetPhysics(PHYS_None);          // a decoration would fall
	if (!bSavedWorld)                     // (once: played again while it plays, False is not its own)
	{
		bOldCollideWorld = A.bCollideWorld;
		bSavedWorld = True;
	}
	A.bCollideWorld = False;              // moved through the world: not pushed out of the walls it passes near
	if (bBack && T <= 0)
		T = Length;
	if (!bBack && T >= Length)
		T = 0;
}

function StopIt()
{
	bPlaying = False;
	RestoreWorld();
	Log("UCMotion" @ Name @ "- stops" @ Target);
}

function Finished()
{
	bPlaying = False;
	RestoreWorld();
	Log("UCMotion" @ Name @ "- finished" @ Target);
	if (Event != '')
		TriggerEvent(Event, Self, None);
}

// it collides with the world again as it did before it played
function RestoreWorld()
{
	if (bSavedWorld && A != None && !A.bDeleteMe)
		A.bCollideWorld = bOldCollideWorld;
	bSavedWorld = False;
}

function TriggerEvent(name E, Actor Other, Pawn Who)
{
	local Actor X;

	foreach AllActors(class'Actor', X, E)
		X.Trigger(Other, Who);
}

// a mover: through its own keys (its state's Open: / Close: code when it has one, so it plays its sounds)
function MoverGo(bool bBack)
{
	if (M.bInterpolating)
		return;
	if (!bBack && M.KeyNum < M.NumKeys - 1)
	{
		M.MoveTime = FMax(0.05, Seg[M.KeyNum]);
		if (DoorState())
			M.GotoState(M.InitialState, 'Open');
		else
			M.InterpolateTo(M.KeyNum + 1, M.MoveTime);
	}
	else if (bBack && M.KeyNum > 0)
	{
		M.MoveTime = FMax(0.05, Seg[M.KeyNum - 1]);
		if (DoorState())
			M.GotoState(M.InitialState, 'Close');
		else
			M.InterpolateTo(M.KeyNum - 1, M.MoveTime);
	}
	bWasMoving = True;
}

function bool DoorState()
{
	return M.InitialState != '' && M.IsInState(M.InitialState) && (M.InitialState == 'TriggerOpenTimed'
		|| M.InitialState == 'TriggerToggle' || M.InitialState == 'TriggerControl' || M.InitialState == 'BumpOpenTimed'
		|| M.InitialState == 'StandOpenTimed' || M.InitialState == 'BumpButton' || M.InitialState == 'TriggerPound');
}

// ---------------------------------------------------------------- the keys (which: 0 position, 1 rotation, 2 scale)
// The path goes through the keys with the speed it has at each of them (a cubic Hermite with Catmull-Rom
// speeds in time, as UCCutscene's camera): a smooth key does not stop it.

// the key at or before t
function int Before(float t, int n, byte which)
{
	local int i;

	for (i = n - 1; i > 0; i--)
		if (KeyT(which, i) <= t)
			return i;
	return 0;
}

function float KeyT(byte which, int i)
{
	if (which == 0)
		return PosT[i];
	if (which == 1)
		return RotT[i];
	return ScaleT[i];
}

function byte KeyE(byte which, int i)
{
	if (which == 0)
		return PosE[i];
	if (which == 1)
		return RotE[i];
	return ScaleE[i];
}

function int KeyN(byte which)
{
	if (which == 0)
		return NumPos;
	if (which == 1)
		return NumRot;
	return NumScale;
}

// component c of key i: X Y Z of a place, pitch yaw roll of a rotation, the scale
function float Comp(byte which, int i, int c)
{
	if (which == 0)
	{
		if (c == 0)
			return PosV[i].X;
		if (c == 1)
			return PosV[i].Y;
		return PosV[i].Z;
	}
	if (which == 1)
	{
		if (c == 0)
			return RotV[i].Pitch;
		if (c == 1)
			return RotV[i].Yaw;
		return RotV[i].Roll;
	}
	return ScaleV[i];
}

// a loop that closes: its first key at the start and its last at the end, with the same value (it goes on through them)
function bool Closes(byte which, int c)
{
	local int n;

	n = KeyN(which);
	return Mode == 1 && n >= 3 && KeyT(which, 0) <= 0.001 && Abs(KeyT(which, n - 1) - Length) <= 0.001
		&& Comp(which, 0, c) == Comp(which, n - 1, c);
}

// how fast component c changes at key i (per second): through a smooth key with the speed its neighbours give,
// along a straight step with its speed; at rest at the first and the last key, at an ease and a hold
function float Slope(byte which, int i, int c)
{
	local int n, ia, ib;
	local float ta, tb;
	local byte eIn, eOut;
	local bool bIn, bOut;

	n = KeyN(which);
	ia = i - 1;
	ib = i + 1;
	eOut = KeyE(which, i);
	if ((i == 0 || i == n - 1) && Closes(which, c))
	{
		ia = n - 2;                         // the end of the loop is its start: from the key before it to the one after
		ib = 1;
		eOut = KeyE(which, 0);
		if (i == 0)
			ta = -Length;
		else
			tb = Length;
	}
	bIn = ia >= 0;
	bOut = ib < n;
	if (bIn)
		eIn = KeyE(which, ia);
	if (eOut == 2 || eOut == 4 || (bIn && eIn == 3))
		return 0;                           // ease in: it starts from rest; hold: it stays; ease out: it comes to rest
	if (bIn && eIn == 0)                    // after a straight step: on with its speed
		return (Comp(which, i, c) - Comp(which, ia, c)) / FMax(0.001, KeyT(which, i) - KeyT(which, ia) - ta);
	if (bOut && eOut == 0)                  // before a straight step: into it with its speed
		return (Comp(which, ib, c) - Comp(which, i, c)) / FMax(0.001, KeyT(which, ib) + tb - KeyT(which, i));
	if (bIn && bOut && eIn != 4)
		return (Comp(which, ib, c) - Comp(which, ia, c)) / FMax(0.001, KeyT(which, ib) + tb - KeyT(which, ia) - ta);
	if (bIn && bOut)                        // after a hold it jumps here and goes on
		return (Comp(which, ib, c) - Comp(which, i, c)) / FMax(0.001, KeyT(which, ib) + tb - KeyT(which, i));
	return 0;                               // the first key and the last: at rest
}

// component c between key i and the next at time t: a cubic through both, with their speeds
function float Value(byte which, int i, int c, float t)
{
	local float d, u, u2, u3, p0, p1;

	d = FMax(0.001, KeyT(which, i + 1) - KeyT(which, i));
	u = FClamp((t - KeyT(which, i)) / d, 0, 1);
	p0 = Comp(which, i, c);
	p1 = Comp(which, i + 1, c);
	if (KeyE(which, i) == 4)
		return p0;
	if (KeyE(which, i) == 0)
		return p0 + (p1 - p0) * u;
	u2 = u * u;
	u3 = u2 * u;
	return (2 * u3 - 3 * u2 + 1) * p0 + (u3 - 2 * u2 + u) * d * Slope(which, i, c)
		+ (3 * u2 - 2 * u3) * p1 + (u3 - u2) * d * Slope(which, i + 1, c);
}

function Apply(float t)
{
	local int i;
	local vector p;
	local rotator r;
	local float s;

	if (NumPos > 0)
	{
		i = Before(t, NumPos, 0);
		if (i >= NumPos - 1 || t <= PosT[0])
			p = PosV[Min(i, NumPos - 1)];
		else
		{
			p.X = Value(0, i, 0, t);
			p.Y = Value(0, i, 1, t);
			p.Z = Value(0, i, 2, t);
		}
		if (!A.SetLocation(BaseLoc + p) && !bStuck)
		{
			bStuck = True;                  // (said once, not every frame)
			Log("UCMotion" @ Name @ "- cannot move" @ Target @ "to" @ string(BaseLoc + p));
		}
	}
	if (NumRot > 0)
	{
		i = Before(t, NumRot, 1);
		if (i >= NumRot - 1 || t <= RotT[0])
			r = RotV[Min(i, NumRot - 1)];
		else
		{
			r.Pitch = int(Value(1, i, 0, t));
			r.Yaw = int(Value(1, i, 1, t));
			r.Roll = int(Value(1, i, 2, t));
		}
		A.SetRotation(BaseRot + r);
	}
	if (NumScale > 0)
	{
		i = Before(t, NumScale, 2);
		if (i >= NumScale - 1 || t <= ScaleT[0])
			s = ScaleV[Min(i, NumScale - 1)];
		else
			s = Value(2, i, 0, t);
		s = FMax(0.01, s);
		A.DrawScale = BaseScale * s;
		A.SetCollisionSize(BaseRadius * s, BaseHeight * s);
	}
}

function Tick(float dt)
{
	local int nextKey;

	if (A == None || A.bDeleteMe)
		return;
	if (M != None)
	{
		// the time of the next step of the mover, before it chains to it (also when a door opens by itself)
		if (M.bInterpolating)
		{
			if (M.KeyNum > M.PrevKeyNum && M.KeyNum < M.NumKeys - 1)
				M.MoveTime = FMax(0.05, Seg[M.KeyNum]);
			else if (M.KeyNum < M.PrevKeyNum && M.KeyNum > 0)
				M.MoveTime = FMax(0.05, Seg[M.KeyNum - 1]);
			bWasMoving = True;
		}
		else
		{
			if (M.KeyNum == 0)
				M.MoveTime = FMax(0.05, Seg[0]);
			else if (M.KeyNum == M.NumKeys - 1)
				M.MoveTime = FMax(0.05, Seg[M.NumKeys - 2]);
			if (bPlaying && bWasMoving)
			{
				bWasMoving = False;
				if ((Dir > 0 && M.KeyNum == M.NumKeys - 1) || (Dir < 0 && M.KeyNum == 0))
				{
					if (Mode == 0)
						Finished();
					else
					{
						Dir = -Dir;            // a mover loops back and forth
						MoverGo(Dir < 0);
					}
				}
			}
		}
		return;
	}
	if (!bPlaying)
		return;
	T += dt * Dir;
	if (T >= Length || T <= 0)
	{
		if (Mode == 1)
			T = T - Length * Dir;           // loop: on from the start
		else if (Mode == 2)
		{
			T = FClamp(T, 0, Length);
			Dir = -Dir;
		}
		else
		{
			T = FClamp(T, 0, Length);
			Apply(T);
			Finished();
			return;
		}
	}
	Apply(T);
}

defaultproperties
{
     Mode=0
     Length=1.000000
}
