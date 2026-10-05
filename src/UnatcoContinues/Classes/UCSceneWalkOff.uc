// Battery Park departure: JC holds his pose, Gunther walks into a fixed wide
// shot, and the original UNATCO theme accompanies the return to Liberty Island.
class UCSceneWalkOff extends UCScene;

var bool bWalkStarted, bSceneMusic;
var vector walkDirection, fixedCameraPosition, fixedCameraFocus;
var string previousTrackerSong;

function GuntherHermann FindGunther()
{
	local GuntherHermann g;
	foreach AllActors(class'GuntherHermann', g)
		return g;
	return None;
}

function JCDouble FindDouble()
{
	local JCDouble d;
	foreach AllActors(class'JCDouble', d)
		if (d.Tag == 'UCWalkDouble' && d.Owner == Self)
			return d;
	return None;
}

static function Music DepartureTheme()
{
	return Music(DynamicLoadObject("UNATCO_Music.UNATCO_Music", class'Music', True));
}

function DXOggMusicManager FindMusicManager(DeusExPlayer P)
{
	local DXOggMusicManager manager;
	if (P == None || P.GetEntryLevel() == None)
		return None;
	foreach P.GetEntryLevel().AllActors(class'DXOggMusicManager', manager)
		return manager;
	return None;
}

function StartDepartureMusic()
{
	local DeusExPlayer P;
	local RevJCDentonMale revisionPlayer;
	local DXOggMusicManager manager;
	local UCDialogueDirector director;
	local Music theme;
	P = Plr();
	theme = DepartureTheme();
	if (P == None || theme == None)
		return;
	// Release the preceding conversation before claiming the cinematic cue.
	foreach AllActors(class'UCDialogueDirector', director)
		director.EndDialogueMusic(P);
	previousTrackerSong = string(P.Song);
	manager = FindMusicManager(P);
	if (manager != None)
	{
		manager.StopPlayback();
		manager.musicMode = MUS_Outro;
	}
	// The original tracker theme plays for this scene even with Revision music
	// selected. Outro mode prevents automatic combat/ambient/capture replacement.
	P.ClientSetMusic(theme, 0, 255, MTRAN_FastFade);
	P.musicMode = MUS_Outro;
	revisionPlayer = RevJCDentonMale(P);
	if (revisionPlayer != None)
		revisionPlayer.musicModeRev = MUS_Outro;
	bSceneMusic = True;
	Log("UCWalkOff: original UNATCO theme, ambient section 0");
}

function EndDepartureMusic()
{
	local DeusExPlayer P;
	local RevJCDentonMale revisionPlayer;
	local DXOggMusicManager manager;
	local Music previousMusic;
	if (!bSceneMusic)
		return;
	P = Plr();
	if (P != None)
	{
		if (previousTrackerSong != "" && previousTrackerSong != "None")
			previousMusic = Music(DynamicLoadObject(previousTrackerSong, class'Music', True));
		P.ClientSetMusic(previousMusic, 255, 255, MTRAN_FastFade);
		// The vanilla music enum has no MUS_None; release its outro lock
		// through the regular conversation-to-ambient transition instead.
		P.musicMode = MUS_Conversation;
		revisionPlayer = RevJCDentonMale(P);
		if (revisionPlayer != None)
			revisionPlayer.musicModeRev = MUS_None;
		manager = FindMusicManager(P);
		if (manager != None && manager.musicMode == MUS_Outro)
		{
			manager.musicMode = MUS_None;
			manager.musicChangeTimer = 0;
			manager.musicCheckTimer = 0;
		}
	}
	bSceneMusic = False;
	previousTrackerSong = "";
}

static function bool InFrame(vector camera, vector focus, vector point)
{
	// Conservative cone inside the normal Deus Ex field of view. Check each
	// actor's head and feet as well as the centre of the walking lane.
	return (Normal(point - camera) dot Normal(focus - camera)) > 0.9063;
}

function bool VisibleShot(Pawn jc, Pawn g, vector destination, vector candidate, vector focus, out vector position)
{
	local vector hit, hitNormal, point;
	local int i;
	position = candidate;
	if (Trace(hit, hitNormal, candidate, focus, False, vect(8,8,8)) != None)
		position = hit + hitNormal * 16;
	if (VSize(position - focus) < 320)
		return False;
	if (!FastTrace(jc.Location + vect(0,0,22), position)
		|| !InFrame(position, focus, jc.Location + vect(0,0,1) * jc.CollisionHeight)
		|| !InFrame(position, focus, jc.Location - vect(0,0,1) * jc.CollisionHeight))
		return False;
	// A fixed shot must cover the entire departure, not only its first frame.
	for (i = 0; i <= 8; i++)
	{
		point = g.Location + (destination - g.Location) * float(i) / 8.0;
		if (!FastTrace(point + vect(0,0,22), position)
			|| !InFrame(position, focus, point + vect(0,0,1) * g.CollisionHeight)
			|| !InFrame(position, focus, point - vect(0,0,1) * g.CollisionHeight))
			return False;
	}
	return True;
}

function bool ChooseShot(Pawn jc, Pawn g, vector destination, out vector position, out vector focus)
{
	local vector mid, side, candidate;
	local int i;
	mid = (jc.Location + destination) * 0.5;
	focus = mid + vect(0,0,20);
	side = Normal(walkDirection cross vect(0,0,1));
	for (i = 0; i < 6; i++)
	{
		if (i == 0) candidate = mid - walkDirection * 120 + side * 500 + vect(0,0,35);
		if (i == 1) candidate = mid - walkDirection * 120 - side * 500 + vect(0,0,35);
		if (i == 2) candidate = mid + side * 560 + vect(0,0,35);
		if (i == 3) candidate = mid - side * 560 + vect(0,0,35);
		if (i == 4) candidate = mid - walkDirection * 500 + side * 300 + vect(0,0,35);
		if (i == 5) candidate = mid - walkDirection * 500 - side * 300 + vect(0,0,35);
		if (VisibleShot(jc, g, destination, candidate, focus, position))
			return True;
	}
	return False;
}

function bool ChooseRoute(Pawn anchor, GuntherHermann g, out vector destJC, out vector destGunther)
{
	local NavigationPoint node;
	local vector delta, preferred, direction, destination, hit, groundNormal, position, focus, bestDirection;
	local float distance, score, bestScore;
	local int i;
	if (anchor == None || g == None)
		return False;
	destJC = anchor.Location; // JC remains exactly where the dialogue ended.
	preferred = g.Location - anchor.Location;
	preferred.Z = 0;
	if (VSize(preferred) < 40)
		preferred = -vector(g.Rotation);
	preferred = Normal(preferred);
	foreach AllActors(class'NavigationPoint', node)
	{
		delta = node.Location - g.Location;
		distance = VSize(delta);
		if (distance < 260 || distance > 450 || Abs(delta.Z) > 64 || !g.PointReachable(node.Location))
			continue;
		delta.Z = 0;
		direction = Normal(delta);
		walkDirection = direction;
		if (!ChooseShot(anchor, g, node.Location, position, focus))
			continue;
		score = distance + FMax(direction dot preferred, 0) * 250;
		if (score > bestScore)
		{
			bestScore = score;
			destination = node.Location;
			bestDirection = direction;
			fixedCameraPosition = position;
			fixedCameraFocus = focus;
		}
	}
	if (bestScore > 0)
	{
		walkDirection = bestDirection;
		destGunther = destination;
		return True;
	}
	for (i = 0; i < 8; i++)
	{
		direction.X = Cos(float(i) * 0.785398);
		direction.Y = Sin(float(i) * 0.785398);
		direction.Z = 0;
		destination = g.Location + direction * 330;
		if (Trace(hit, groundNormal, destination - vect(0,0,180), destination + vect(0,0,35), False) == None || groundNormal.Z < 0.7)
			continue;
		destination = hit + vect(0,0,1) * g.CollisionHeight;
		if (Abs(destination.Z - g.Location.Z) > 64 || !g.PointReachable(destination))
			continue;
		walkDirection = direction;
		if (ChooseShot(anchor, g, destination, position, focus))
		{
			destGunther = destination;
			fixedCameraPosition = position;
			fixedCameraFocus = focus;
			return True;
		}
	}
	return False;
}

function bool StartWalk()
{
	local DeusExPlayer P;
	local GuntherHermann g;
	local UCStandingDenton jc;
	local SecurityBot2 bot;
	local vector destJC, destGunther;
	local UCCam cam;
	P = Plr();
	g = FindGunther();
	if (P == None || g == None)
		return False;
	foreach AllActors(class'SecurityBot2', bot)
		if (VSize(bot.Location - g.Location) < 1500)
			bot.Destroy();
	P.SetCollision(False, False, False);
	jc = Spawn(class'UCStandingDenton', Self, 'UCWalkDouble', P.Location, P.Rotation);
	if (jc == None)
	{
		P.SetCollision(True, True, True);
		return False;
	}
	jc.SetSkin(P);
	jc.ChangeAlly('Player', 1.0, True);
	jc.FreezePose();
	g.SetPhysics(PHYS_Walking);
	if (!ChooseRoute(jc, g, destJC, destGunther))
	{
		jc.Destroy();
		P.SetCollision(True, True, True);
		Log("UCWalkOff: no visible fixed departure shot / Gunther route");
		return False;
	}
	Spawn(class'UCMark', Self, 'UCWalkGunther', destGunther);
	CutsceneStart(fixedCameraPosition, g);
	cam = FindCam();
	if (cam != None)
	{
		cam.SetShot(fixedCameraPosition, fixedCameraFocus);
		cam.ApplyView(P);
	}
	g.bStasis = False;
	g.GroundSpeed = 200;
	g.WalkingSpeed = 0.5;
	g.ChangeAlly('Player', 1.0, True);
	g.SetOrders('GoingTo', 'UCWalkGunther', True);
	StartDepartureMusic();
	Log("UCWalkOff: JC stationary=" $ jc.Location @ "Gunther destination=" $ destGunther @ "fixed camera=" $ fixedCameraPosition);
	return True;
}

event Destroyed()
{
	EndDepartureMusic();
	Super.Destroyed();
}

state Playing
{
Begin:
	if (Talking())
	{
		Sleep(0.25);
		Goto('Begin');
	}
	GoalDone('FindHermann');
	SetF('UNATCORoute_ReturnToHQ', True);
	Sleep(0.6);
	bWalkStarted = StartWalk();
	if (!bWalkStarted)
		Goto('Departure');
	// No tracking or repeated re-framing: this camera is deliberately static.
	Sleep(7.0);
	EndDepartureMusic();
	CutsceneEnd();
Departure:
	TravelTo("04_NYC_UNATCOIsland", 3);
	Destroy();
}
