//=============================================================================
// UCMotionCheck - an in-game check of the map editor's runtime (15 Oct 2026). A helicopter animated by a
// UCMotion through smooth keys that dip into the floor (with bCollideWorld it would be pushed out of it: a
// stutter), and a UCCutscene that looks at it, spawned before the UCMotion as the editor exports them (so
// it ticks first: without its UCCutDriver it would aim where the helicopter was in the last frame).
// Spawned by the photo tool (the game must be closed):
//   .\tools\shots.ps1 -Map 06_HongKong_WanChai_Rooftop -Name motioncheck -Shots @('jc;player;64;-320;64;16384;0',
//     'go;spawn;UnatcoContinues.UCMotionCheck;64;-320;64;16384', 'w;wait;3', 'mid;view', 'end;wait;6')
// One line per frame in Revision.log, "UCMotionCheck <role> T dt speed locErr eyeErr aimErr", from two
// probes: role 1 ticks before the cutscene's driver (what the view was without it), role 2 after it (what
// is drawn). Then a summary line for each.
//=============================================================================
class UCMotionCheck extends Actor
	transient;

var int Role;                    // 0 the setup, 1 measures before the cutscene's driver, 2 after it
var BlackHelicopter Heli;
var UCMotion Mot;
var UCCutscene Cut;
var bool bPrepared, bDone;
var vector LastLoc;
var int Frames;
var float MaxLoc, MaxEye, MaxAim, MinSpeed, KeySpeed[3];

function UCMotionCheck Probe(int r)
{
	local UCMotionCheck C;

	C = Spawn(class'UCMotionCheck',,, Location);
	if (C != None)
	{
		C.Role = r;
		C.Heli = Heli;
		C.Mot = Mot;
		C.Cut = Cut;
		C.MinSpeed = 100000;
	}
	return C;
}

function Prepare()
{
	local vector B, HitLoc, HitNorm;
	local float floorZ;
	local rotator r;
	local int i;

	bPrepared = True;
	B = Location + vect(0,1400,700);
	floorZ = Location.Z - 64;
	if (Trace(HitLoc, HitNorm, B - vect(0,0,3000), B) != None)
		floorZ = HitLoc.Z;
	B.Z = floorZ + 600;
	Heli = Spawn(class'BlackHelicopter',,, B, r);
	if (Heli == None)
	{
		Log("UCMotionCheck FAIL: no helicopter at" @ B);
		return;
	}
	// the cutscene first: it ticks before the UCMotion, as in a map made in the editor
	Cut = Spawn(class'UCMotionCheckCut',,, Location);
	UCMotionCheckCut(Cut).Init(Location, string(Heli.Name));

	Mot = Spawn(class'UCMotion',,, Location);
	Mot.Target = string(Heli.Name);
	Mot.bFound = False;               // (it looked for its object when it was spawned, with no name yet)
	Mot.Length = 6;
	Mot.NumPos = 5;
	Mot.PosT[0] = 0;
	Mot.PosT[1] = 1.5;
	Mot.PosV[1] = vect(600,300,-560); // 40 above the floor: the cylinder (88 high) is in it
	Mot.PosT[2] = 3;
	Mot.PosV[2] = vect(0,700,-560);
	Mot.PosT[3] = 4.5;
	Mot.PosV[3] = vect(-600,300,-300);
	Mot.PosT[4] = 6;
	Mot.NumRot = 3;
	Mot.RotT[1] = 3;
	Mot.RotV[1].Yaw = 16384;
	Mot.RotT[2] = 6;
	Mot.RotV[2].Yaw = 32768;
	for (i = 0; i < 5; i++)
	{
		Mot.PosE[i] = 1;
		Mot.RotE[i] = 1;
	}

	Probe(1);                         // before the driver Play spawns
	Mot.Play(False);
	Cut.Play();
	Probe(2);
	Log("UCMotionCheck start" @ Heli @ "floor" @ floorZ @ "driver" @ Cut.Driver @ "collides with the world" @ Heli.bCollideWorld);
}

function Measure(float dt)
{
	local DeusExPlayer P;
	local vector off, pos, eye, dir;
	local rotator r;
	local float fov, speed, locErr, eyeErr, aimErr;
	local int i;

	if (Mot == None || Heli == None || Cut == None)
		return;
	if (!Mot.bPlaying && !Cut.bPlaying)
	{
		if (!bDone)
		{
			bDone = True;
			Log("UCMotionCheck summary" @ Role @ "frames" @ Frames @ "maxLocErr" @ MaxLoc @ "maxEyeErr" @ MaxEye
				@ "maxAimErr" @ MaxAim @ "minSpeed" @ MinSpeed @ "atKeys" @ KeySpeed[0] @ KeySpeed[1] @ KeySpeed[2]
				@ "collides with the world again" @ Heli.bCollideWorld);
		}
		return;
	}
	P = DeusExPlayer(GetPlayerPawn());
	// where the UCMotion means it to be at its time
	i = Mot.Before(Mot.T, Mot.NumPos, 0);
	if (i >= Mot.NumPos - 1 || Mot.T <= Mot.PosT[0])
		off = Mot.PosV[Min(i, Mot.NumPos - 1)];
	else
	{
		off.X = Mot.Value(0, i, 0, Mot.T);
		off.Y = Mot.Value(0, i, 1, Mot.T);
		off.Z = Mot.Value(0, i, 2, Mot.T);
	}
	locErr = VSize(Heli.Location - (Mot.BaseLoc + off));
	if (Frames > 0 && dt > 0)
		speed = VSize(Heli.Location - LastLoc) / dt;
	LastLoc = Heli.Location;
	Frames++;
	if (Mot.bPlaying && Mot.T > 0.3 && Mot.T < 5.7 && Frames > 1)
	{
		MinSpeed = FMin(MinSpeed, speed);
		for (i = 0; i < 3; i++)
			if (Abs(Mot.T - 1.5 * (i + 1)) < 0.05)
				KeySpeed[i] = speed;
	}
	if (Cut.bPlaying && P != None)
	{
		Cut.Pose(Cut.T, pos, r, fov);
		eye = P.Location + vect(0,0,1) * P.EyeHeight;
		eyeErr = VSize(eye - pos);
		dir = Normal(Heli.Location - eye);
		if ((dir dot vector(P.ViewRotation)) > 0)
			aimErr = Atan(VSize(dir cross vector(P.ViewRotation)) / (dir dot vector(P.ViewRotation))) * 180 / Pi;
		else
			aimErr = 180;
	}
	MaxLoc = FMax(MaxLoc, locErr);
	MaxEye = FMax(MaxEye, eyeErr);
	MaxAim = FMax(MaxAim, aimErr);
	Log("UCMotionCheck" @ Role @ Mot.T @ dt @ speed @ locErr @ eyeErr @ aimErr);
}

event Tick(float dt)
{
	if (Role == 0)
	{
		if (!bPrepared)
			Prepare();
		return;
	}
	Measure(dt);
}

defaultproperties
{
     bHidden=True
     bAlwaysTick=True
}
