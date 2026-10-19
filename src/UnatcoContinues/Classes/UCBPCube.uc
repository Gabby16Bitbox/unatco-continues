//=============================================================================
// UCBPCube - Battery Park: the datacube Paul left for Jock, beside Jock's body (UCSceneBatteryPark).
// Reading it sets UC_BP_PaulCubeRead (the MIB confrontation gets an extra answer, Mission 7 reads it)
// and keeps the text in the notes, once.
//=============================================================================
class UCBPCube extends DataCube;

//#if vanilla
//var string SpecialText;     // Revision's InformationDevices has it: the original game reads it through UCTextBlock.UseText
//#endif

function Frob(Actor Frobber, Inventory frobWith)
{
	local DeusExPlayer P;
	local UCBPTarp tarp;

	// it lies by the body: while the tarp covers them, a click goes to the tarp (the cube is
	// also hidden until then, UCSceneBatteryPark.PlaceBody / UCBPTarp.Lift)
	foreach AllActors(class'UCBPTarp', tarp)
		if (!tarp.bLifted)
		{
			tarp.Frob(Frobber, frobWith);
			return;
		}
	// SpecialText would otherwise make an empty note under the empty text tag
	bAddToVault = False;
	//#if vanilla
	//if (textTag == '')
	//	class'UCTextBlock'.static.UseText(self, SpecialText);
	//#endif
	Super.Frob(Frobber, frobWith);
	P = DeusExPlayer(Frobber);
	if (P == None || P.FlagBase == None)
		return;
	if (!P.FlagBase.GetBool('UC_BP_PaulCubeRead'))
	{
		P.FlagBase.SetBool('UC_BP_PaulCubeRead', True,, 99);
		P.AddNote("Datacube on Jock's body:|n" $ SpecialText, False, True);
	}
}

defaultproperties
{
     SpecialText="Jock - thanks for the ride. You didn't have to.|nLie low for a while, they'll come asking.|n- P."
     bAddToVault=False
     bUnmovable=True
     bInvincible=True
     bPushable=False
}
