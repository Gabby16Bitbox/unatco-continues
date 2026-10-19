//=============================================================================
// UCMutator - fa partire il gestore route (UCCampaign) in una mappa.
// Entra nelle mappe col parametro "?Mutator=UnatcoContinues.UCMutator" (salti di
// debug; poi resta nell'URL di ogni viaggio) e, non essendo transient, viene salvato
// dentro la mappa. Quando si torna in una mappa gia' visitata il gioco la ricarica
// dal salvataggio: ne' ServerActors ne' mutator ripartono e UCCampaign (transient) non
// c'e' piu'. Il Tick qui sotto lo ricrea.
//=============================================================================
class UCMutator extends Mutator;

var float checkTime;

function PostBeginPlay()
{
	local UCShotRunner shots;

	Super.PostBeginPlay();
	Spawn(class'UCCampaign');
	class'UCConsoleLink'.static.Ensure(Self);      // the map editor's Console (its Play only)
	// foto automatiche (tools\shots.ps1): solo se la sezione in RevisionUser.ini le chiede
	if (class'UCShotRunner'.default.bActive)
	{
		foreach AllActors(class'UCShotRunner', shots)
			return;
		Spawn(class'UCShotRunner');
	}
}

event Tick(float deltaTime)
{
	local UCCampaign m;
	local UCShotRunner shots;

	Super.Tick(deltaTime);
	checkTime += deltaTime;
	if (checkTime < 1.0)
		return;
	checkTime = 0;
	class'UCConsoleLink'.static.Ensure(Self);
	// Returning to a cached map also removes the transient photographer.
	// Resume its persisted shot index before looking for the route manager.
	if (class'UCShotRunner'.default.bActive)
	{
		foreach AllActors(class'UCShotRunner', shots) break;
		if (shots == None) Spawn(class'UCShotRunner');
	}
	foreach AllActors(class'UCCampaign', m)
		return;
	Spawn(class'UCCampaign');
	Log("UnatcoContinues: gestore route ricreato (mappa ricaricata dal salvataggio)");
}

defaultproperties
{
}
