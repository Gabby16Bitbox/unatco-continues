//=============================================================================
// UCVoiceDriver - durante le conversazioni create dalla mod (battute senza
// audio, soundID = -1) fa dire la battuta con la voce registrata, dalla bocca
// di chi parla. Le conversazioni vanilla (che hanno gia' l'audio) non le tocca.
// Non tiene puntatori: ricorda solo il NOME dell'ultimo evento.
//=============================================================================
class UCVoiceDriver extends Actor
	transient;

var name lastEvent, lastPlayback, attemptedEvent;
var int attempts;
var float retryAt;

function bool OwnsDispatch()
{
	local UCVoiceDriver other;
	foreach AllActors(class'UCVoiceDriver', other)
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

event Tick(float deltaTime)
{
	local DeusExPlayer P;
	local ConEventSpeech ev;
	local Sound snd;
	local Actor spk;
	local float soundRadius;
	local int handle;

	// Save loading can leave orphan helpers from an earlier route manager.
	// Only the first live driver may touch the native speech channel.
	if (!OwnsDispatch())
	{
		Destroy();
		return;
	}

	P = DeusExPlayer(GetPlayerPawn());
	if (P == None || P.conPlay == None)
	{
		lastEvent = '';
		lastPlayback = '';
		attemptedEvent = '';
		return;
	}
	if (lastPlayback != P.conPlay.Name)
	{
		lastPlayback = P.conPlay.Name;
		lastEvent = '';
		attemptedEvent = '';
	}
	ev = ConEventSpeech(P.conPlay.currentEvent);
	if (ev == None)
	{
		lastEvent = '';
		return;
	}
	if (ev.Name == lastEvent)
		return;
	// Aspetta che ConPlay abbia impostato attori, testo e telecamera.
	// Il currentEvent esiste gia' durante le rotazioni/preparazioni della scena.
	if (!P.conPlay.IsInState('WaitForText') && !P.conPlay.IsInState('WaitForInput')
		&& !P.conPlay.IsInState('WaitForSpeech'))
		return;

	if (ev.conSpeech == None || ev.conSpeech.soundID != -1)
		return;
	// Native BindEvents has already cached both actors by this ready state.
	// A temporary bark name must not break subsequent vanilla conversations.
	class'UCMod'.static.RestoreBarkBinding(ev.speaker);
	class'UCMod'.static.RestoreBarkBinding(ev.speakingTo);
	snd = class'UCVoice'.static.Find(ev.conSpeech.speech,
		class'UCVoice'.static.Profile(ev.speaker, ev.speakerName));
	if (snd == None)
	{
		lastEvent = ev.Name;
		return;
	}
	if (attemptedEvent != ev.Name)
	{
		attemptedEvent = ev.Name;
		attempts = 0;
		retryAt = 0;
	}
	if (Level.TimeSeconds < retryAt)
		return;

	spk = ev.speaker;
	if (spk == None)
		spk = P;
	// Match ConPlay.PlaySpeech: letterbox conversations stay close/audible;
	// a passive world bark retains the original distance falloff.
	if (P.conPlay.GetForcePlay() || P.conPlay.initialRadius == 0)
	{
		soundRadius = 65536.0;
		if (VSize(P.Location - spk.Location) > 400)
			spk = P;
	}
	else if (P.conPlay.con.bCannotBeInterrupted || !P.conPlay.con.bFirstPerson)
		soundRadius = 65536.0;
	else
		soundRadius = 512.0 + P.conPlay.initialRadius;
	// Registra l'handle nel lettore nativo: saltare/chiudere una battuta deve
	// fermare anche la nostra voce, come avviene per i dialoghi originali.
	handle = spk.PlaySound(snd, SLOT_Talk, 1.0,, soundRadius);
	if (handle == 0)
	{
		attempts++;
		retryAt = Level.TimeSeconds + 0.05;
		if (attempts < 3)
			return;
		if (spk != P)
			handle = P.PlaySound(snd, SLOT_Talk, 1.0,, 65536.0);
		if (handle == 0)
			Log("UCVoice: could not start" @ snd @ "event=" $ ev.Name);
	}
	lastEvent = ev.Name;
	P.conPlay.playingSoundID = handle;
	Log("UCVoice: conversation playback" @ snd @ "speaker=" $ spk @ "handle=" $ P.conPlay.playingSoundID);
	P.conPlay.StartSpeakingAnimation();
	// Le battute passive dei soldati/MIB durano quanto l'audio, evitando che
	// il timer del solo testo faccia partire la voce successiva troppo presto.
	if (P.conPlay.IsInState('WaitForText') || P.conPlay.IsInState('WaitForSpeech'))
		P.conPlay.SetTimer(GetSoundDuration(snd) + 0.15, False);
}

defaultproperties
{
     bHidden=True
	 bAlwaysTick=True
     bCollideActors=False
     bCollideWorld=False
}
