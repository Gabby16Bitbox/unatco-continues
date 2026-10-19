// Per-level references to audio in the player's game install. No audio is imported.
class UCVoiceBank extends Info;

var int used;
var int keys[64];
var string paths[64];

function bool Store(int key, string path)
{
	local int i;
	for (i=0; i<used; i++)
		if (keys[i]==key) { paths[i]=path; return True; }
	if (used>=ArrayCount(keys)) return False;
	keys[used]=key; paths[used++]=path;
	return True;
}

function string PathFor(int key)
{
	local int i;
	for (i=0; i<used; i++) if (keys[i]==key) return paths[i];
	return "";
}

static function Clear(Actor context)
{
	local UCVoiceBank bank;
	foreach context.AllActors(class'UCVoiceBank', bank)
		if (bank.Owner == context)
			bank.used = 0;
}

static function Register(Actor context, string speaker, string text, string path)
{
	local UCVoiceBank bank;
	local int key;
	key = class'UCVoice'.static.Key(speaker $ "|" $ text);
	foreach context.AllActors(class'UCVoiceBank', bank)
	{
		if (bank.Owner != context)
			continue;
		if (bank.Store(key,path)) return;
	}
	bank = context.Spawn(class'UCVoiceBank', context);
	if (bank!=None) bank.Store(key,path);
}

static function Sound Resolve(Actor context, string speaker, string text)
{
	local Sound snd;
	local UCVoiceBank bank;
	local int key;
	local string path;
	snd = class'UCVoice'.static.Dub(speaker, text);
	if (snd != None)
		return snd;
	key = class'UCVoice'.static.Key(speaker $ "|" $ text);
	foreach context.AllActors(class'UCVoiceBank', bank)
	{
		path=bank.PathFor(key);
		if (path!="") return Sound(DynamicLoadObject(path, class'Sound', True));
	}
	return None;
}

defaultproperties
{
     bHidden=True
}
