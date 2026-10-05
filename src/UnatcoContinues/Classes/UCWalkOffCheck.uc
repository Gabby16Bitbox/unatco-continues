// Local, headless regression check. Only runs when explicitly added to a
// temporary development server ini; it is never spawned by the installed mod.
class UCWalkOffCheck extends Actor transient;

var int checked, failed;
var float elapsed;
var bool bPrepared;
var vector startJC, startGunther;
var int cameraFrames, cameraFailures;
var int poseFailures;
var vector cameraPosition, cameraFocus;
var rotator frozenRotation;

function Check(bool ok, string message)
{
	checked++;
	if (!ok)
	{
		failed++;
		Log("UCWalkOffCheck FAIL:" @ message);
	}
}

function Prepare()
{
	local UCSceneWalkOff scene;
	local GuntherHermann g;
	local UCStandingDenton jc;
	local UCCam cam;
	local UCVoiceDriver voice;
	local UCDialogueDirector director;
	local UCMod mod;
	local vector side, destJC, destG, position, focus, proxy;
	local int voices, directors, mods;
	local bool route;

	Spawn(class'UCMod');
	Spawn(class'UCMod');
	Spawn(class'UCVoiceDriver');
	Spawn(class'UCVoiceDriver');
	Spawn(class'UCDialogueDirector');
	Spawn(class'UCDialogueDirector');
	foreach AllActors(class'UCMod', mod) if (!mod.bDeleteMe) mods++;
	foreach AllActors(class'UCVoiceDriver', voice) if (!voice.bDeleteMe) voices++;
	foreach AllActors(class'UCDialogueDirector', director) if (!director.bDeleteMe) directors++;
	Check(mods == 1 && voices == 1 && directors == 1, "One route manager, voice driver and camera/music director");
	foreach AllActors(class'GuntherHermann', g) break;
	Check(g != None, "Original Battery Park Gunther exists");
	if (g == None) return;
	g.EnterWorld();
	g.SetPhysics(PHYS_Walking);
	side = vector(g.Rotation);
	jc = Spawn(class'UCStandingDenton', Self, 'UCWalkTest', g.Location + side * 100);
	if (jc == None) jc = Spawn(class'UCStandingDenton', Self, 'UCWalkTest', g.Location - side * 100);
	Check(jc != None, "Visible JC double spawns on Gunther's floor");
	if (jc == None) return;
	jc.FreezePose();
	Log("UCWalkOffCheck actors:" @ g.Location @ jc.Location @ "world=" $ g.bInWorld @ "physics=" $ g.Physics $ "/" $ jc.Physics);
	scene = Spawn(class'UCSceneWalkOff', Self);
	scene.GotoState('');
	route = scene.ChooseRoute(jc, g, destJC, destG);
	Check(route, "Gunther has a reachable lane covered by a fixed shot in the real map");
	if (!route) return;
	position = scene.fixedCameraPosition;
	focus = scene.fixedCameraFocus;
	Check(scene.VisibleShot(jc, g, destG, position, focus, position), "Fixed camera covers JC and the complete walking lane");
	Check(Abs(position.Z - (jc.Location.Z + g.Location.Z) * 0.5) < 90, "Camera stays near actor height");
	proxy = class'UCCam'.static.ProxyPosition(position, focus);
	Check(VSize(proxy - Normal(focus - position) * 150 - position) < 0.1, "Native behind-view compensation preserves the chosen viewpoint");
	Check(VSize(destJC - jc.Location) < 0.1, "JC destination is his unchanged standing position");
	Spawn(class'UCMark', scene, 'UCWalkGunther', destG);
	cam = Spawn(class'UCCam', scene);
	cam.SetShot(position, focus);
	cameraPosition = cam.shotPosition;
	cameraFocus = cam.shotFocus;
	jc.ChangeAlly('Player', 1.0, True);
	g.ChangeAlly('Player', 1.0, True);
	g.bStasis = False;
	g.GroundSpeed = 200;
	g.WalkingSpeed = 0.5;
	startJC = jc.Location;
	frozenRotation = jc.Rotation;
	startGunther = g.Location;
	g.SetOrders('GoingTo', 'UCWalkGunther', True);
	bPrepared = True;
	Log("UCWalkOffCheck lane:" @ startJC @ startGunther @ "dest=" @ destJC @ destG @ "camera=" @ position);
}

function Finish()
{
	local UCSceneWalkOff scene;
	local GuntherHermann g;
	local UCStandingDenton jc;
	local vector position, focus;
	foreach AllActors(class'GuntherHermann', g) break;
	foreach AllActors(class'UCStandingDenton', jc, 'UCWalkTest') break;
	foreach AllActors(class'UCSceneWalkOff', scene) if (scene.Owner == Self) break;
	if (bPrepared && jc != None && g != None && scene != None)
	{
		Check(VSize(jc.Location - startJC) < 0.1 && poseFailures == 0, "JC position, rotation and pose stay fixed throughout");
		Check(VSize(g.Location - startGunther) > 100, "Gunther actually walks at least 100 units");
		Check(FastTrace(g.Location + vect(0,0,22), cameraPosition), "Fixed camera still sees Gunther at the end");
		Check(cameraFrames >= 30 && cameraFailures == 0, "Fixed camera frames both throughout Gunther's walk");
		Log("UCWalkOffCheck movement:" @ VSize(jc.Location - startJC) @ VSize(g.Location - startGunther));
		Log("UCWalkOffCheck camera samples:" @ cameraFrames @ "blocked=" $ cameraFailures);
		Log("UCWalkOffCheck static JC pose failures:" @ poseFailures);
	}
	Log("UCWalkOffCheck:" @ checked @ "checked," @ failed @ "failed.");
	ConsoleCommand("exit");
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0.1, True);
}

function Timer()
{
	local UCSceneWalkOff scene;
	local GuntherHermann g;
	local UCStandingDenton jc;
	local UCCam cam;
	local vector position, focus;

	elapsed += 0.1;
	if (elapsed < 0.15) Prepare();
	if (bPrepared)
	{
		foreach AllActors(class'GuntherHermann', g) break;
		foreach AllActors(class'UCStandingDenton', jc, 'UCWalkTest') break;
		foreach AllActors(class'UCSceneWalkOff', scene) if (scene.Owner == Self) break;
		foreach AllActors(class'UCCam', cam) if (cam.Owner == scene) break;
		cameraFrames++;
		if (scene == None || cam == None || VSize(cam.shotPosition - cameraPosition) > 0.1
			|| VSize(cam.shotFocus - cameraFocus) > 0.1
			|| !FastTrace(jc.Location + vect(0,0,22), cameraPosition)
			|| !FastTrace(g.Location + vect(0,0,22), cameraPosition)
			|| !class'UCSceneWalkOff'.static.InFrame(cameraPosition, cameraFocus, g.Location + vect(0,0,1) * g.CollisionHeight)
			|| !class'UCSceneWalkOff'.static.InFrame(cameraPosition, cameraFocus, g.Location - vect(0,0,1) * g.CollisionHeight))
			cameraFailures++;
		if (VSize(jc.Location - startJC) > 0.1 || jc.Rotation != frozenRotation
			|| jc.Physics != PHYS_None || !jc.IsInState('ScenePose')
			|| (elapsed > 1.0 && (jc.AnimSequence != 'Still' || jc.AnimRate != 0)))
			poseFailures++;
	}
	if (elapsed >= 6.0)
	{
		SetTimer(0, False);
		Finish();
	}
}

defaultproperties
{
	bHidden=True
	bAlwaysTick=True
}
