//=============================================================================
// UCVoiceDriver - plays user dubs and referenced voices through the speaking
// character. Only indexed original lines lose their native soundID, in memory.
// Other original lines keep their audio. Playback tracking stores event names.
//=============================================================================
class UCVoiceDriver extends Actor
	transient;

var name lastEvent, lastPlayback, attemptedEvent;
var int attempts;
var float retryAt;
var float originalScan;
var name lastRadioEvent, lastRadioPlay;
// The end of the voice playing now, for the line it belongs to: the player's timer must not end the line before it.
// The line's own state code sets its text-length timer as it starts; whether that runs before or after this driver's
// Tick depends on the order the engine ticks them (Revision: before; the original game: after, and the next line cut
// the voice in the middle, 19 Oct 2026). So the timer is kept long enough on every Tick while the voice plays.
var name voiceEvent, radioVoiceEvent;
var float clock;            // game seconds, as the timers count them (the voices' ends are in it)
// a line is voiced the Tick after it was first seen: its state code (which stops the speech playing and sets its
// text timer) has run by then, whichever of the two the engine ticks first
var name seenEvent, seenRadioEvent;
var float voiceEnd, radioVoiceEnd;

// The player's timer (ConPlay or DataLinkPlay) ends no sooner than the voice
function KeepTimer(Actor playing, float endTime)
{
	local float left;
	left = endTime - clock;
	if (playing == None || left <= 0.05)
		return;
	if (playing.TimerRate <= 0 || playing.TimerRate - playing.TimerCounter < left - 0.05)
		playing.SetTimer(left, False);
}

// Only indexed user dubs are considered. Untouched native audio retains its soundID.
// Packages are read-only on disk; the index is rebuilt before Apply, with the game closed.
function PatchConversation(Conversation c)
{
	local ConEvent e;
	local ConEventSpeech line;
	local ConChoice choice;
	if (c == None || !class'UCVoiceDubs'.static.Any()) return;
	for (e=c.eventList; e!=None; e=e.nextEvent)
	{
		line=ConEventSpeech(e);
		if (line!=None && line.conSpeech!=None && line.conSpeech.soundID!=-1
			&& class'UCVoiceDubs'.static.Contains(class'UCVoice'.static.Key(line.speakerName $ "|" $ line.conSpeech.speech))
			&& class'UCVoice'.static.Dub(line.speakerName,line.conSpeech.speech)!=None)
		{
			line.conSpeech.soundID=-1;
			Log("UCVoice: original dub enabled" @ c.conName @ line.Name);
		}
		if (ConEventChoice(e)!=None)
			for (choice=ConEventChoice(e).ChoiceList; choice!=None; choice=choice.nextChoice)
				if (choice.soundID!=-1 && class'UCVoiceDubs'.static.Contains(class'UCVoice'.static.Key("JCDenton|" $ choice.choiceText))
					&& class'UCVoice'.static.Dub("JCDenton",choice.choiceText)!=None)
					choice.soundID=-1;
	}
}

function PatchBoundConversations()
{
	local Actor A;
	local ConListItem item;
	if (!class'UCVoiceDubs'.static.Any()) return;
	foreach AllActors(class'Actor',A)
		for (item=ConListItem(A.conListItems); item!=None; item=item.next)
			PatchConversation(item.con);
}

function RadioVoice(DeusExPlayer P)
{
	local DataLinkPlay radio;
	local ConEventSpeech line;
	local Sound snd;
	radio=P.dataLinkPlay;
	if (radio==None) { lastRadioPlay=''; lastRadioEvent=''; return; }
	PatchConversation(radio.con);
	if (lastRadioPlay!=radio.Name) { lastRadioPlay=radio.Name; lastRadioEvent=''; }
	line=ConEventSpeech(radio.currentEvent);
	if (line==None) { lastRadioEvent=''; return; }
	if (line.Name==radioVoiceEvent && radio.IsInState('WaitForSpeech'))
		KeepTimer(radio, radioVoiceEnd);
	if (line.Name==lastRadioEvent || !radio.IsInState('WaitForSpeech') || radio.bSilent
		|| line.conSpeech==None || line.conSpeech.soundID!=-1) return;
	if (seenRadioEvent!=line.Name) { seenRadioEvent=line.Name; return; }
	snd=class'UCVoiceBank'.static.Resolve(Self,line.speakerName,line.conSpeech.speech);
	if (snd==None) return;
	lastRadioEvent=line.Name;
	radio.StopSpeech();
	radio.playingSoundID=P.PlaySound(snd,SLOT_Talk,1.0,,65536.0);
	radio.SetTimer(class'UCInfoVoice'.static.GameSeconds(Self, GetSoundDuration(snd)+0.15),False);
	radioVoiceEvent=line.Name;
	radioVoiceEnd=clock+class'UCInfoVoice'.static.GameSeconds(Self, GetSoundDuration(snd)+0.15);
	Log("UCVoice: radio playback" @ snd @ "handle=" $ radio.playingSoundID);
}

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

	clock += deltaTime;
	P = DeusExPlayer(GetPlayerPawn());
	originalScan-=deltaTime;
	if (P!=None)
	{
		if (originalScan<=0) { originalScan=0.5; PatchBoundConversations(); }
		RadioVoice(P);
		if (P.conPlay!=None) PatchConversation(P.conPlay.con);
	}
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
	if (ev.Name == voiceEvent && (P.conPlay.IsInState('WaitForText') || P.conPlay.IsInState('WaitForSpeech')))
		KeepTimer(P.conPlay, voiceEnd);
	if (ev.Name == lastEvent)
		return;
	// Aspetta che ConPlay abbia impostato attori, testo e telecamera.
	// Il currentEvent esiste gia' durante le rotazioni/preparazioni della scena.
	if (!P.conPlay.IsInState('WaitForText') && !P.conPlay.IsInState('WaitForInput')
		&& !P.conPlay.IsInState('WaitForSpeech'))
		return;

	if (ev.conSpeech == None || ev.conSpeech.soundID != -1)
		return;
	if (seenEvent != ev.Name)
	{
		seenEvent = ev.Name;
		return;
	}
	// Native BindEvents has already cached both actors by this ready state.
	// A temporary bark name must not break subsequent vanilla conversations.
	class'UCCampaign'.static.RestoreBarkBinding(ev.speaker);
	class'UCCampaign'.static.RestoreBarkBinding(ev.speakingTo);
	// a voice given to this line in the map editor first, then the generated one
	snd = class'UCVoiceBank'.static.Resolve(Self, ev.speakerName, ev.conSpeech.speech);
	if (snd == None)
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
		P.conPlay.SetTimer(class'UCInfoVoice'.static.GameSeconds(Self, GetSoundDuration(snd) + 0.15), False);
	voiceEvent = ev.Name;
	voiceEnd = clock + class'UCInfoVoice'.static.GameSeconds(Self, GetSoundDuration(snd) + 0.15);
}

defaultproperties
{
     bHidden=True
	 bAlwaysTick=True
     bCollideActors=False
     bCollideWorld=False
}
