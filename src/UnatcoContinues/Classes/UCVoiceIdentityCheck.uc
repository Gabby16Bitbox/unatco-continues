// Native regression: actual map soldiers retain their voice across bindings.
class UCVoiceIdentityCheck extends Actor;

var int checked, failed;

function Check(bool ok, string description)
{
	checked++;
	if (!ok)
	{
		failed++;
		Log("UCVoiceIdentityCheck FAIL:" @ description);
	}
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0.5, False);
}

function CheckTroop(ScriptedPawn troop)
{
	local string oldBind, oldBark, voice;
	local Sound a, b;
	oldBind = troop.BindName;
	oldBark = troop.BarkBindName;

	troop.BarkBindName = "UNATCOTroop";
	troop.BindName = "UCGreeter";
	voice = class'UCVoice'.static.Profile(troop, "UCGreeter");
	Check(voice == "UNATCOTroop", string(troop.Name) @ "A greeter");
	a = class'UCVoice'.static.Find("Agent Denton.", voice);
	troop.BindName = "UCBark17";
	Check(class'UCVoice'.static.Profile(troop, troop.BindName) == voice, string(troop.Name) @ "A bark same voice");
	class'UCMod'.static.RestoreBarkBinding(troop);
	Check(class'UCVoice'.static.Profile(troop, troop.BindName) == voice, string(troop.Name) @ "A original binding same voice");

	troop.BarkBindName = "UNATCOTroopB";
	troop.BindName = "UCGreeter";
	voice = class'UCVoice'.static.Profile(troop, "UCGreeter");
	Check(voice == "UNATCOTroopB", string(troop.Name) @ "B greeter");
	b = class'UCVoice'.static.Find("Agent Denton.", voice);
	troop.BindName = "UCBark81";
	Check(class'UCVoice'.static.Profile(troop, troop.BindName) == voice, string(troop.Name) @ "B bark same voice");
	class'UCMod'.static.RestoreBarkBinding(troop);
	Check(class'UCVoice'.static.Profile(troop, troop.BindName) == voice, string(troop.Name) @ "B original binding same voice");
	Check(a != None && b != None && a != b, "same text loads two distinct native soldier Sounds");
	troop.BindName = oldBind;
	troop.BarkBindName = oldBark;
}

function Timer()
{
	local ScriptedPawn troop;
	local MJ12Troop officer, guard;
	local UNATCOTroop gateGuard;
	local MIB agent;
	local Female2 projection;
	local TriadRedArrow messenger;
	local TriadLumPath tongGuard;
	local MJ12Commando commander;
	local ScientistMale prisoner;
	local vector testPosition;
	local int troops;
	foreach AllActors(class'ScriptedPawn', troop)
		if (troop.IsA('UNATCOTroop'))
		{
			CheckTroop(troop);
			troops++;
		}
	Check(troops > 0, "actual route map soldiers tested");
	Check(class'UCVoice'.static.Profile(None, "UCHKOfficer") == "MJ12Troop", "HK officer uses MJ12 A");
	Check(class'UCVoice'.static.Profile(None, "UCHKGuard") == "MJ12TroopB", "HK guard uses MJ12 B");
	Check(class'UCVoice'.static.Profile(None, "UCSpecialAgent1") == "MIB", "special agent 1 alias uses MIB");
	Check(class'UCVoice'.static.Profile(None, "UCSpecialAgent2") == "MIB", "special agent 2 alias uses MIB");
	foreach AllActors(class'ScriptedPawn', troop)
		if (troop.IsA('UNATCOTroop'))
			break;
	if (troop != None)
	{
		// Inactive vanilla patrols are stored 20,000 units above the map.
		// Their WorldPosition is the real walkable floor used by EnterWorld.
		if (troop.bInWorld)
			testPosition = troop.Location;
		else
			testPosition = troop.WorldPosition;
		officer = Spawn(class'MJ12Troop',, 'UCHKOfficer', testPosition);
		if (officer != None)
		{
			officer.BindName = "UCHKOfficer";
			officer.BarkBindName = class'UCVoice'.static.Profile(officer, officer.BindName);
			Check(officer.BarkBindName == "MJ12Troop", "actual HK officer native barks use A");
			officer.BindName = "UCBark1";
			Check(class'UCVoice'.static.Profile(officer, officer.BindName) == "MJ12Troop", "actual HK officer retains A after bark rename");
			officer.SetCollision(False, False, False);
			officer.Destroy();
		}
		guard = Spawn(class'MJ12Troop',, 'UCHKGuard', testPosition);
		if (guard != None)
		{
			guard.BindName = "UCHKGuard";
			guard.BarkBindName = class'UCVoice'.static.Profile(guard, guard.BindName);
			Check(guard.BarkBindName == "MJ12TroopB", "actual HK guard native barks use B");
			guard.BindName = "UCBark2";
			Check(class'UCVoice'.static.Profile(guard, guard.BindName) == "MJ12TroopB", "actual HK guard retains B after bark rename");
			guard.SetCollision(False, False, False);
			guard.Destroy();
		}
		Check(officer != None && guard != None, "actual MJ12 actors spawned for identity tests");
		gateGuard = Spawn(class'UNATCOTroop',, 'UCGateTrooper', testPosition);
		if (gateGuard != None)
		{
			gateGuard.BindName = "UCGateGuard";
			gateGuard.BarkBindName = class'UCVoice'.static.Profile(gateGuard, gateGuard.BindName);
			Check(gateGuard.BarkBindName == "UNATCOTroop", "new subway guard keeps native A voice");
			Check(class'UCVoice'.static.Find("The line is open to UNATCO personnel. Go ahead.", gateGuard.BarkBindName) != None, "current subway guard audio loads through its actual actor profile");
			gateGuard.SetCollision(False, False, False);
			gateGuard.Destroy();
		}
		agent = Spawn(class'MIB',, 'UCSpecialAgent1', testPosition);
		if (agent != None)
		{
			agent.BindName = "UCSpecialAgent1";
			Check(class'UCVoice'.static.Profile(agent, agent.BindName) == "MIB", "actual special agent uses MIB voice");
			Check(class'UCVoice'.static.Find("Stay calm, please. Do not interfere with this operation.", class'UCVoice'.static.Profile(agent, agent.BindName)) != None, "current special agent lobby audio loads through its actor profile");
			agent.BindName = "UCLMAgent1";
			Check(class'UCVoice'.static.Find("We'll continue this later.", class'UCVoice'.static.Profile(agent, agent.BindName)) != None, "Lucky Money agent uses MIB audio through the actor profile");
			agent.SetCollision(False, False, False);
			agent.Destroy();
		}
		Check(gateGuard != None && agent != None, "actual new gate guard and special agent spawned for tests");
		projection = Spawn(class'Female2',, 'UCMaggieHolo', testPosition);
		if (projection != None)
		{
			projection.BindName = "UCMaggieHolo";
			Check(class'UCVoice'.static.Profile(projection, projection.BindName) == "MaggieChow", "generic hologram body uses Maggie voice");
			Check(class'UCVoice'.static.Find("And if Paul changed his mind?", class'UCVoice'.static.Profile(projection, projection.BindName)) != None, "recorded Maggie audio loads through the hologram profile");
			projection.SetCollision(False, False, False);
			projection.Destroy();
		}
		messenger = Spawn(class'TriadRedArrow',, 'UCMessenger', testPosition);
		if (messenger != None)
		{
			messenger.BindName = "UCMessenger";
			Check(class'UCVoice'.static.Profile(messenger, messenger.BindName) == "Red_Arrow_01", "messenger uses the original Red Arrow actor clone");
			Check(class'UCVoice'.static.Find("Denton?", class'UCVoice'.static.Profile(messenger, messenger.BindName)) != None, "messenger greeting audio loads through its actor profile");
			messenger.BindName = "UCLMRedArrow";
			Check(class'UCVoice'.static.Find("Max never asked for the shipment.", class'UCVoice'.static.Profile(messenger, messenger.BindName)) != None, "Lucky Money Red Arrow retains the same clone");
			messenger.BindName = "UCTongGuard";
			messenger.BarkBindName = "TriadRedArrow";
			Check(class'UCVoice'.static.Profile(messenger, messenger.BindName) == "TriadRedArrow", "Tong Red Arrow guard retains its native bark actor");
			Check(class'UCVoice'.static.Find("Keep your weapon down and there won't be a problem.", class'UCVoice'.static.Profile(messenger, messenger.BindName)) != None, "Tong Red Arrow guard audio loads");
			messenger.Destroy();
		}
		Check(projection != None && messenger != None, "actual Hong Kong hologram and messenger bodies spawned for tests");
		tongGuard = Spawn(class'TriadLumPath',, 'UCTongGuard', testPosition);
		if (tongGuard != None)
		{
			tongGuard.BindName = "UCTongGuard";
			tongGuard.BarkBindName = "TriadLumPath";
			Check(class'UCVoice'.static.Profile(tongGuard, tongGuard.BindName) == "TriadLumPath", "Tong Luminous Path guard retains its native bark actor");
			Check(class'UCVoice'.static.Find("Tong agreed to see you. That doesn't make you welcome.", class'UCVoice'.static.Profile(tongGuard, tongGuard.BindName)) != None, "Tong Luminous Path guard audio loads");
			tongGuard.Destroy();
		}
		commander = Spawn(class'MJ12Commando',, 'UCSPCommander', testPosition + vect(0,0,24));
		if (commander != None)
		{
			commander.BindName = "UCSPCommander";
			Check(class'UCVoice'.static.Profile(commander, commander.BindName) == "MJ12Commando", "Special Projects commander uses the commando voice");
			Check(class'UCVoice'.static.Find("Stay clear of the sweep, Agent Denton.", class'UCVoice'.static.Profile(commander, commander.BindName)) != None, "Special Projects commander audio loads");
			commander.Destroy();
		}
		prisoner = Spawn(class'ScientistMale',, 'UCPrisoner', testPosition);
		if (prisoner != None)
		{
			prisoner.BindName = "UCPrisoner";
			Check(class'UCVoice'.static.Profile(prisoner, prisoner.BindName) == "ScientistConsulting", "unarmed technician uses an isolated scientist voice");
			Check(class'UCVoice'.static.Find("I'm unarmed! I'm not security!", class'UCVoice'.static.Profile(prisoner, prisoner.BindName)) != None, "prisoner plea audio loads");
			prisoner.Destroy();
		}
		Check(tongGuard != None && commander != None && prisoner != None, "actual Tong assault roles spawned for voice checks");
		Check(class'UCVoice'.static.Profile(None, "UCSPTech1") == "MJ12Troop", "Special Projects technician retains the MJ12 A voice");
		Check(class'UCVoice'.static.Find("Special Projects.", class'UCVoice'.static.Profile(None, "UCSPTech1")) != None, "Special Projects technician audio loads");
	}
	Check(class'UCVoice'.static.VoiceKey("JCDenton", "No.") != class'UCVoice'.static.VoiceKey("Jock", "No."), "short replies cannot share another character's voice");
	Check(class'UCVoice'.static.VoiceKey("PaulDenton", "All right.", True) != class'UCVoice'.static.VoiceKey("PaulDenton", "All right."), "radio and direct channels stay separate");
	Log("UCVoiceIdentityCheck:" @ checked @ "checked," @ failed @ "failed," @ troops @ "native soldiers.");
	ConsoleCommand("EXIT");
}

defaultproperties
{
	bHidden=True
	bCollideActors=False
	bCollideWorld=False
}
