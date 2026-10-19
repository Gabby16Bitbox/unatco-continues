//=============================================================================
// UCBPJockCarcass - Battery Park: Jock's body under the tarp (UCSceneBatteryPark). The game's own
// Jock carcass; searching it gives his flask. It cannot be carried off or blown apart, and it does
// not alarm anyone (a placed body, not a pawn that died here).
// While the tarp is still over him a click goes to the tarp: the game frobs the smallest object
// on the line of sight, and that is the body under the tarp (review of 15 Oct).
// The flask is made when JC searches him, and held (state Idle2) like the items of the bodies the
// map places: those get that state from the level's start, but an item spawned during play stays a
// pickup lying there. As a pickup it showed on top of the body and the search took it twice (the
// game's pickup, then the body's own hand-over, which let go of it): JC got it without an owner,
// unusable, and clicking it in the inventory crashed the game (Gabby, 15 Oct).
//=============================================================================
class UCBPJockCarcass extends JockCarcass;

var bool bFlaskGiven;      // the flask has been handed over (saved with the map)

function Frob(Actor Frobber, Inventory frobWith)
{
	local UCBPTarp tarp;
	local Inventory flask;

	foreach AllActors(class'UCBPTarp', tarp)
		if (!tarp.bLifted)
		{
			tarp.Frob(Frobber, frobWith);
			return;
		}
	if (!bFlaskGiven && DeusExPlayer(Frobber) != None)
	{
		flask = Spawn(class'UCBPFlask', self);
		if (flask != None)
		{
			flask.bHidden = True;
			flask.SetPhysics(PHYS_None);
			AddInventory(flask);
			flask.GotoState('Idle2');
		}
		bFlaskGiven = True;
	}
	Super.Frob(Frobber, frobWith);
}

defaultproperties
{
     bInvincible=True
     FamiliarName="Jock"
}
