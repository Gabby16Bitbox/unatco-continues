// Native-engine checks for the conversation graph and camera configuration.
class UCDialogueCheckCommandlet extends Commandlet;

var int checked, failed;

function Check(bool ok, string description)
{
	checked++;
	if (!ok)
	{
		failed++;
		Log("UCDialogueCheck FAIL:" @ description);
	}
}

function CheckGraph(bool firstPerson)
{
	local UCCon builder;
	local ConEvent event;
	local ConEventMoveCamera shot;
	local ConEventSpeech speech;
	local int shots, speeches, ends;
	local bool pendingShot;

	builder = new(Self) class'UCCon';
	builder.Begin('UC_Check', "AnnaNavarre", firstPerson);
	builder.Line("AnnaNavarre", "JCDenton", "First sentence.");
	builder.Line("AnnaNavarre", "JCDenton", "Same speaker.");
	builder.Line("JCDenton", "AnnaNavarre", "Is that a threat?");
	builder.Line("AnnaNavarre", "JCDenton", "Yes.");
	builder.Done();
	Check(!builder.con.bRandomCamera, "No random camera can retain the listener's frame");
	for (event = builder.con.eventList; event != None; event = event.nextEvent)
	{
		Check(event.conversation == builder.con, "Every event belongs to its native conversation");
		shot = ConEventMoveCamera(event);
		speech = ConEventSpeech(event);
		if (shot != None)
		{
			shots++;
			Check(!pendingShot && shot.eventType == ET_MoveCamera, "Camera event before speech");
			Check(shot.cameraType == CT_Predefined && shot.cameraTransition == TR_Jump, "Native cut transition");
			pendingShot = True;
		}
		if (speech != None)
		{
			speeches++;
			if (!firstPerson && speeches != 2)
			{
				Check(pendingShot, "Every change of speaker has a camera cut");
				if (speech.speakerName == "JCDenton")
					Check(shot == None && ConEventMoveCamera(event.nextEvent) != None, "JC followed by Navarre's countershot");
			}
			else
				Check(!pendingShot, "Same speaker / first-person retains the view");
			pendingShot = False;
		}
		if (ConEventEnd(event) != None)
			ends++;
	}
	Check(speeches == 4 && ends == 1 && !pendingShot, "Complete dialogue with no dangling camera event");
	if (firstPerson)
		Check(shots == 0, "Barks and InfoLink do not become cutscenes");
	else
		Check(shots == 3, "Cuts only on a change of speaking pair");
}

function int Main(string Parms)
{
	local ConCamera camera;
	local Sound speech;
	local vector desired, focus, proxy;
	local ConListItem barkItem, originalItem;

	CheckGraph(False);
	CheckGraph(True);
	camera = new(Self) class'ConCamera';
	camera.ignoreSetActors = True;
	camera.bCameraLocationSaved = True;
	camera.currentFallback = 4;
	class'UCDialogueDirector'.static.ConfigureFallbacks(camera);
	class'UCDialogueDirector'.static.SpeakerShot(camera, None, None, True);
	Check(camera.cameraType == CT_Predefined && camera.cameraMode == CT_Actor, "Native face camera mode");
	Check(camera.cameraPosition == CP_HeadShotSlightRight, "JC front shot");
	Check(!camera.ignoreSetActors && !camera.bCameraLocationSaved && camera.currentFallback == 0, "Previous speaker frame cannot persist");
	Check(camera.cameraFallbackPositions[0] == CP_HeadShotMid, "Obstructed camera first retries a face shot");
	class'UCDialogueDirector'.static.SpeakerShot(camera, None, None, False);
	Check(camera.cameraPosition == CP_HeadShotSlightLeft, "NPC front countershot");
	speech = class'UCVoice'.static.Find("Who's asking?", "JCDenton");
	Check(speech != None, "Current JC messenger reply resolves to the compiled voice");
	Check(class'DXOgg'.static.CheckFiles("", "02_NYC_Convo.ogg"), "Revision conversation soundtrack exists");
	Check(class'DXOgg'.static.CheckFiles("", "PS2_NYC_Convo.ogg"), "Selected PS2 soundtrack fallback exists");
	Check(class'UCSceneWalkOff'.static.DepartureTheme() != None, "Original UNATCO departure theme loads");
	Check(class'UCSceneWalkOff'.static.InFrame(vect(0,-500,35), vect(0,0,20), vect(100,0,53)), "Departure shot retains walking actor in frame");
	Check(!class'UCSceneWalkOff'.static.InFrame(vect(0,-500,35), vect(0,0,20), vect(800,0,53)), "Departure shot rejects an actor outside the frame");
	desired = vect(-3600,1600,410);
	focus = vect(-3417,1670,394);
	proxy = class'UCCam'.static.ProxyPosition(desired, focus);
	Check(VSize(proxy - Normal(focus - desired) * 150 - desired) < 0.1, "Behind-view camera offset restores chosen viewpoint");
	barkItem = new(Self) class'ConListItem';
	barkItem.con = new(Self) class'Conversation';
	barkItem.con.conName = 'UC_Bark';
	barkItem.con.conOwnerName = "UCBark12";
	originalItem = new(Self) class'ConListItem';
	originalItem.con = new(Self) class'Conversation';
	originalItem.con.conName = 'M04Guard';
	originalItem.con.conOwnerName = "HotelGuard";
	barkItem.next = originalItem;
	Check(class'UCMod'.static.OriginalBarkBinding(barkItem, "UNATCOTroop") == "HotelGuard", "Original NPC conversation binding survives a temporary bark");
	Check(class'UCMod'.static.OriginalBarkBinding(None, "UNATCOTroop") == "UNATCOTroop", "Spawned guards recover their class binding");
	barkItem.next = None;
	Check(class'UCMod'.static.OriginalBarkBinding(barkItem, "MIB") == "MIB", "Temporary bark owner cannot become the permanent binding");
	Log("UCDialogueCheck:" @ checked @ "checked," @ failed @ "failed.");
	if (failed != 0)
		return 1;
	return 0;
}

defaultproperties
{
	HelpCmd="UCDialogueCheck"
	HelpOneLiner="Validate native mod camera cuts, JC voice and conversation music"
	LazyLoad=False
	ShowBanner=False
}
