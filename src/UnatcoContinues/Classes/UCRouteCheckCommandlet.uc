// Controlli nel motore per la route "Jock a Battery Park":
// struttura della conversazione con la scelta (etichette, salti, flag del decollo)
// e porte di Battery Park da chiudere o lasciare aperte.
//   ucc.exe UnatcoContinues.UCRouteCheckCommandlet
class UCRouteCheckCommandlet extends Commandlet;

var int checked, failed;

function Check(bool ok, string description)
{
	checked++;
	if (!ok)
	{
		failed++;
		Log("UCRouteCheck FAIL:" @ description);
	}
}

// Dall'evento e alla fine del ramo: c'e' il flag del decollo? finisce con End?
function CheckBranch(ConEvent e, bool wantGo, string what)
{
	local bool bGo, bEnd;
	local ConEventSetFlag f;
	local int n;

	while (e != None && n < 20)
	{
		n++;
		f = ConEventSetFlag(e);
		if (f != None && f.flagRef != None && f.flagRef.flagName == 'UC_JockGo' && f.flagRef.value)
			bGo = True;
		if (ConEventEnd(e) != None)
		{
			bEnd = True;
			break;
		}
		e = e.nextEvent;
	}
	Check(bEnd, what @ "finisce con End");
	Check(bGo == wantGo, what @ "flag UC_JockGo =" @ wantGo);
}

function CheckJock(UCCon c, name conName, bool bOnce)
{
	local ConEvent e;
	local ConEventChoice choice;
	local ConEventSpeech speech;
	local ConChoice ch;
	local int shots, choices, speeches;

	Check(c.con.conName == conName, conName @ "nome");
	Check(c.con.bDisplayOnce == bOnce, conName @ "una volta sola =" @ bOnce);
	Check(c.con.bInvokeRadius && c.con.radiusDistance > 480, conName @ "parte avvicinandosi (raggio oltre la fusoliera)");
	Check(c.con.bInvokeFrob, conName @ "parte anche cliccando");
	Check(ConEventMoveCamera(c.con.eventList) != None
		&& ConEventMoveCamera(c.con.eventList).cameraPosition == CP_SideAbove45, conName @ "inquadratura fissa all'inizio");

	for (e = c.con.eventList; e != None; e = e.nextEvent)
	{
		Check(e.conversation == c.con, conName @ "eventi della conversazione");
		if (ConEventMoveCamera(e) != None)
			shots++;
		speech = ConEventSpeech(e);
		if (speech != None)
		{
			speeches++;
			Check(speech.conSpeech != None && speech.conSpeech.soundID == -1, conName @ "battuta testuale/voce mod");
			Check(speech.speakerName == "Jock" || speech.speakerName == "JCDenton", conName @ "parlano Jock e JC");
		}
		if (ConEventChoice(e) != None)
		{
			choices++;
			choice = ConEventChoice(e);
		}
	}
	Check(shots == 1, conName @ "una sola camera (niente primi piani dell'elicottero)");
	Check(choices == 1 && choice != None, conName @ "una scelta");
	if (choice == None)
		return;

	ch = choice.ChoiceList;
	Check(ch != None && ch.nextChoice != None && ch.nextChoice.nextChoice == None, conName @ "due risposte");
	Check(ch.choiceLabel == "Ready" && ch.nextChoice.choiceLabel == "Wait", conName @ "etichette delle risposte");
	Check(c.con.GetEventFromLabel("Ready") != None, conName @ "etichetta Ready trovata");
	Check(c.con.GetEventFromLabel("Wait") != None, conName @ "etichetta Wait trovata");
	Check(ConEventSpeech(c.con.GetEventFromLabel("Ready")) != None
		&& ConEventSpeech(c.con.GetEventFromLabel("Ready")).speakerName == "JCDenton", conName @ "Ready inizia con JC");
	CheckBranch(c.con.GetEventFromLabel("Ready"), True, conName @ "ramo Ready");
	CheckBranch(c.con.GetEventFromLabel("Wait"), False, conName @ "ramo Wait");
	Log("UCRouteCheck:" @ conName @ speeches @ "battute");
}

function bool HasRequire(UCCon c, name flagName, bool value)
{
	local ConFlagRef r;

	for (r = c.con.flagRefList; r != None; r = r.nextFlagRef)
		if (r.flagName == flagName && r.value == value)
			return True;
	return False;
}

function int Main(string Parms)
{
	local UCCon c;

	c = new(Self) class'UCCon';
	class'UCMod'.static.JockParkTalk(c);
	CheckJock(c, 'UC_JockBP', True);
	Check(c.con.flagRefList == None, "UC_JockBP senza requisiti");

	// facoltativa (tornando dopo "Give me a minute"): una volta, con la stessa scelta
	c = new(Self) class'UCCon';
	class'UCMod'.static.JockExtraTalk(c);
	CheckJock(c, 'UC_JockBPExtra', True);
	Check(HasRequire(c, 'UC_JockBP_Played', True), "battute su Paul solo dopo la prima conversazione");

	c = new(Self) class'UCCon';
	class'UCMod'.static.JockReadyTalk(c);
	CheckJock(c, 'UC_JockBPReady', False);
	Check(HasRequire(c, 'UC_JockBP_Played', True), "Ready? solo dopo la prima conversazione");
	Check(HasRequire(c, 'UC_JockBPExtra_Played', True), "Ready? solo dopo le battute su Paul");

	// porte di Battery Park: aperte quelle sul percorso, chiuse le altre
	Check(class'UCMod'.static.DistFromParkPath(vect(-5024, 2656, 8)) <= 220, "porta vicino alle scale della metro resta aperta");
	Check(class'UCMod'.static.DistFromParkPath(vect(-5024, 3040, 6)) <= 220, "porta vicino all'arrivo resta aperta");
	Check(class'UCMod'.static.DistFromParkPath(vect(-4528, 3424, -288)) > 220, "porta laterale della stazione chiusa");
	Check(class'UCMod'.static.DistFromParkPath(vect(-3568, 2192, 320)) > 220, "cancello nel recinto chiuso");
	Check(class'UCMod'.static.DistFromParkPath(vect(-2900, 1110, 340)) < 50, "il percorso arriva all'elicottero");

	Log("UCRouteCheck:" @ checked @ "checked," @ failed @ "failed.");
	return failed;
}

defaultproperties
{
	HelpCmd="UCRouteCheck"
	HelpOneLiner="Validate the Jock / Battery Park route conversations and doors"
	LazyLoad=False
	ShowBanner=False
}
