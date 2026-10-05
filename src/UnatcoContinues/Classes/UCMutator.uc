//=============================================================================
// UCMutator - fa partire il gestore route (UCMod) in una mappa.
// Entra nelle mappe col parametro "?Mutator=UnatcoContinues.UCMutator" (salti di
// debug; poi resta nell'URL di ogni viaggio) e, non essendo transient, viene salvato
// dentro la mappa. Quando si torna in una mappa gia' visitata il gioco la ricarica
// dal salvataggio: ne' ServerActors ne' mutator ripartono e UCMod (transient) non
// c'e' piu'. Il Tick qui sotto lo ricrea.
//=============================================================================
class UCMutator extends Mutator;

var float checkTime;

function PostBeginPlay()
{
	local UCShotRunner shots;

	Super.PostBeginPlay();
	Spawn(class'UCMod');
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
	local UCMod m;

	Super.Tick(deltaTime);
	checkTime += deltaTime;
	if (checkTime < 1.0)
		return;
	checkTime = 0;
	foreach AllActors(class'UCMod', m)
		return;
	Spawn(class'UCMod');
	Log("UnatcoContinues: gestore route ricreato (mappa ricaricata dal salvataggio)");
}

defaultproperties
{
}
