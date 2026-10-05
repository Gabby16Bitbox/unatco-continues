// Directs mod conversations through the native ConCamera and Revision music.
// Only names/strings are retained: no player, window or cross-map actor pointers.
class UCDialogueDirector extends Actor
	transient;

var name lastConversation, lastEvent, lastSpeaker, lastSpeakingTo;
var bool bMusicOwned;
var string ownedMusicLoop;

function bool OwnsDispatch()
{
	local UCDialogueDirector other;
	foreach AllActors(class'UCDialogueDirector', other)
		if (!other.bDeleteMe)
			return other == Self;
	return False;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	if (!OwnsDispatch())
		Destroy();
}

static function ConfigureFallbacks(ConCamera camera)
{
	if (camera == None)
		return;
	// Prefer a visible face if the primary shot is blocked by the station walls.
	camera.cameraFallbackPositions[0] = CP_HeadShotMid;
	camera.cameraFallbackPositions[1] = CP_HeadShotSlightRight;
	camera.cameraFallbackPositions[2] = CP_HeadShotSlightLeft;
	camera.cameraFallbackPositions[3] = CP_HeadShotRight;
	camera.cameraFallbackPositions[4] = CP_HeadShotLeft;
	camera.cameraFallbackPositions[5] = CP_HeadShotTight;
	camera.cameraFallbackPositions[6] = CP_ShoulderRight;
	camera.cameraFallbackPositions[7] = CP_ShoulderLeft;
	camera.cameraFallbackPositions[8] = CP_SideMid;
}

static function SpeakerShot(ConCamera camera, Actor speaker, Actor listener, bool bPlayerSpeaker)
{
	if (camera == None)
		return;
	camera.ignoreSetActors = False;
	camera.SetActors(speaker, listener);
	camera.cameraType = CT_Predefined;
	if (bPlayerSpeaker)
		camera.cameraPosition = CP_HeadShotSlightRight;
	else
		camera.cameraPosition = CP_HeadShotSlightLeft;
	camera.SetCameraValues();
	camera.ResetFallbackPosition();
	camera.bCameraLocationSaved = False;
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

function StartDialogueMusic(DeusExPlayer P)
{
	local DXOggMusicManager manager;
	local RevJCDentonMale revisionPlayer;
	local string introFile, loopFile, variantIntro, variantLoop;

	revisionPlayer = RevJCDentonMale(P);
	if (revisionPlayer == None || !revisionPlayer.bUseRevisionSoundtrack)
		return; // The tracker soundtrack already follows the native player state.
	manager = FindMusicManager(P);
	if (manager == None || manager.bPaused)
		return;

	introFile = manager.MusicInfo.ConversationIntroOggFile;
	loopFile = manager.MusicInfo.ConversationOggFile;
	if (manager.bConversationExists == FILE_Ver2)
	{
		if (introFile != "")
			variantIntro = Left(introFile, Len(introFile) - 4) $ "_Ver2.ogg";
		if (loopFile != "")
			variantLoop = Left(loopFile, Len(loopFile) - 4) $ "_Ver2.ogg";
		if (loopFile != "" && manager.CheckFiles(variantIntro, variantLoop))
		{
			introFile = variantIntro;
			loopFile = variantLoop;
		}
	}
	// Some maps have no conversation cue. NYC's restrained conversation loop
	// is a fallback; honour the user's PS2 soundtrack when that file is present.
	if (loopFile == "" || !manager.CheckFiles(introFile, loopFile))
	{
		introFile = "";
		if (Human(P).bUsePS2Soundtrack)
			loopFile = "PS2_NYC_Convo.ogg";
		else
			loopFile = "02_NYC_Convo.ogg";
		if (!manager.CheckFiles(introFile, loopFile))
			return;
	}
	if (manager.musicMode == MUS_Ambient)
	{
		manager.savedSongPos = manager.GetCurrentSongPosition();
		manager.savedmusicMode = MUS_Ambient;
	}
	manager.SetCurrentOggWithVolume(introFile, loopFile, 0, MTRAN_Segue, 0.65);
	manager.musicMode = MUS_Conversation;
	ownedMusicLoop = loopFile;
	bMusicOwned = True;
	Log("UCDialogue: music" @ loopFile @ "background gain=0.65");
}

function EndDialogueMusic(DeusExPlayer P)
{
	local DXOggMusicManager manager;

	if (!bMusicOwned)
		return;
	manager = FindMusicManager(P);
	// A level change or a music trigger may have already selected another song.
	if (manager != None && !manager.bPaused && manager.GetNextOggFileLoop() == ownedMusicLoop)
	{
		manager.musicMode = MUS_None;
		manager.musicChangeTimer = 5;
		manager.musicCheckTimer = 5;
		manager.Timer(); // Native fade/resume, including the saved ambient position.
	}
	bMusicOwned = False;
	ownedMusicLoop = "";
}

event Tick(float deltaTime)
{
	local DeusExPlayer P;
	local ConPlay playback;
	local ConEventSpeech speech;

	if (!OwnsDispatch())
	{
		// The surviving director owns the same native music manager.
		bMusicOwned = False;
		ownedMusicLoop = "";
		Destroy();
		return;
	}

	P = DeusExPlayer(GetPlayerPawn());
	if (P != None)
		playback = P.conPlay;
	if (playback == None || playback.con == None || playback.con.bFirstPerson
		|| playback.GetForcePlay() || Left(string(playback.con.conName), 3) != "UC_")
	{
		EndDialogueMusic(P);
		lastConversation = '';
		lastEvent = '';
		lastSpeaker = '';
		lastSpeakingTo = '';
		return;
	}
	// StartConversation creates the camera asynchronously in the player state.
	if (playback.cameraInfo == None || !playback.ConversationStarted())
		return;
	if (lastConversation != playback.Name)
	{
		EndDialogueMusic(P);
		lastConversation = playback.Name;
		lastEvent = '';
		lastSpeaker = '';
		lastSpeakingTo = '';
		playback.randomCamera = False;
		ConfigureFallbacks(playback.cameraInfo);
		StartDialogueMusic(P);
	}
	speech = ConEventSpeech(playback.currentEvent);
	if (speech == None || speech.Name == lastEvent || speech.speaker == None || speech.speakingTo == None)
		return;
	if (!playback.IsInState('WaitForInput') && !playback.IsInState('WaitForText') && !playback.IsInState('WaitForSpeech'))
		return;
	lastEvent = speech.Name;
	if (lastSpeaker == speech.speaker.Name && lastSpeakingTo == speech.speakingTo.Name)
		return;
	// Jock parla dall'elicottero: resta l'inquadratura fissa della conversazione.
	if (!speech.speaker.IsA('Pawn') || !speech.speakingTo.IsA('Pawn'))
		return;
	// Also directs conversations stored in older saves, without camera events.
	SpeakerShot(playback.cameraInfo, speech.speaker, speech.speakingTo, speech.speaker == P);
	playback.bSetupInitialCamera = True;
	lastSpeaker = speech.speaker.Name;
	lastSpeakingTo = speech.speakingTo.Name;
	Log("UCDialogue: camera speaker=" $ speech.speaker @ "listener=" $ speech.speakingTo);
}

event Destroyed()
{
	EndDialogueMusic(DeusExPlayer(GetPlayerPawn()));
	Super.Destroyed();
}

defaultproperties
{
	bHidden=True
	bAlwaysTick=True
	bCollideActors=False
	bCollideWorld=False
}
