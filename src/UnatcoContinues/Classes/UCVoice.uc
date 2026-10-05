//=============================================================================
// UCVoice - trova la voce registrata (ElevenLabs) di una battuta.
// Il suono si chiama "V" + hash di voce/canale/testo, nel pacchetto UnatcoVoices.u
// (generato da tools/voices/make_voices.py: l'hash DEVE essere identico).
// Se il pacchetto o il suono non c'e', ritorna None e resta solo il testo.
//=============================================================================
class UCVoice extends Object;

static function int Key(string text)
{
	local int i, h;

	h = 7;
	for (i = 0; i < Len(text); i++)
	{
		// UE1's % operator converts to float and loses precision here.
		// Keep the remainder entirely in int arithmetic, like Python.
		h = h * 31 + Asc(Mid(text, i, 1));
		h = h - (h / 16777213) * 16777213;
	}
	return h;
}

static function string Profile(Actor speaker, string binding)
{
	if (binding ~= "UCTongGuard")
	{
		if (speaker != None)
		{
			if (speaker.BarkBindName ~= "TriadRedArrow")
				return "TriadRedArrow";
			if (speaker.BarkBindName ~= "TriadLumPath")
				return "TriadLumPath";
			if (speaker.IsA('TriadRedArrow'))
				return "TriadRedArrow";
		}
		return "TriadLumPath";
	}
	if (binding ~= "UCSPCommander")
		return "MJ12Commando";
	if (binding ~= "UCSPTech1")
		return "MJ12Troop";
	if (binding ~= "UCPrisoner")
		return "ScientistConsulting";
	// BarkBindName is the native, saved voice identity. Temporary conversation
	// bindings (UCBark / UCGreeter) must never choose a different actor's voice.
	if (speaker != None && (speaker.IsA('UNATCOTroop') || speaker.IsA('Soldier')))
	{
		if (speaker.IsA('Soldier') || speaker.BarkBindName ~= "UNATCOTroopB" || speaker.BindName ~= "UNATCOTroopB")
			return "UNATCOTroopB";
		return "UNATCOTroop";
	}
	if (speaker != None && speaker.IsA('MJ12Troop'))
	{
		if (speaker.BarkBindName ~= "MJ12TroopB" || speaker.BindName ~= "MJ12TroopB"
			|| speaker.BindName ~= "UCHKGuard" || speaker.Tag == 'UCHKGuard')
			return "MJ12TroopB";
		return "MJ12Troop";
	}
	// Special Agents al 'Ton (MIB presentati come "Special Agent")
	if ((speaker != None && speaker.IsA('MIB')) || Left(binding, 14) ~= "UCSpecialAgent")
		return "MIB";
	if (binding ~= "UCMaggieHolo")
		return "MaggieChow";
	if (binding ~= "UCMessenger" || binding ~= "UCLMRedArrow")
		return "Red_Arrow_01";
	if (binding ~= "UCGreeter")
		return "UNATCOTroop";
	if (binding ~= "UCHKOfficer")
		return "MJ12Troop";
	if (binding ~= "UCHKGuard")
		return "MJ12TroopB";
	return binding;
}

static function int VoiceKey(string voiceName, string text, optional bool bRadio)
{
	if (bRadio && voiceName != "JCDenton")
		return Key(voiceName $ "|radio|" $ text);
	return Key(voiceName $ "|direct|" $ text);
}

static function Sound Find(string text, optional string voiceName, optional bool bRadio)
{
	local string objectName;
	local Sound snd;

	if (voiceName == "")
		objectName = "UnatcoVoices.V" $ Key(text);
	else
		objectName = "UnatcoVoices.V" $ VoiceKey(voiceName, text, bRadio);
	snd = Sound(DynamicLoadObject(objectName, class'Sound', True));
	if (snd == None)
		Log("UCVoice: missing audio " $ objectName);
	return snd;
}

defaultproperties
{
}
