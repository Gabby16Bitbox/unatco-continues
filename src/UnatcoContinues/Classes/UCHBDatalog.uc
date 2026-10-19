//=============================================================================
// UCHBDatalog - Mission 6, Harbourline Tower: Lam's note to Wu on the shelf by the tea machine in the
// control room (Gabby's mission doc "Mission 6 - Hong Kong opening", phase 3), the login of the
// control room's computers (HBSEC / FROSTLINE). Reading it sets UC_HB_DatalogRead and keeps the text
// in the notes, once. (As UCBPCube, without the tarp.)
//=============================================================================
class UCHBDatalog extends DataCube;

//#if vanilla
//var string SpecialText;     // Revision's InformationDevices has it: the original game reads it through UCTextBlock.UseText
//#endif

function Frob(Actor Frobber, Inventory frobWith)
{
	local DeusExPlayer P;

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
	if (!P.FlagBase.GetBool('UC_HB_DatalogRead'))
	{
		P.FlagBase.SetBool('UC_HB_DatalogRead', True,, 99);
		P.AddNote("Lam's note in the Harbourline control room:|n" $ SpecialText, False, True);
	}
}

defaultproperties
{
     SpecialText="Wu, stop calling me at three in the morning for the storeroom password. I change it every week, and this week's is below. If Kwan finds out we're writing it on notes, we're both in trouble.|nLogin: HBSEC|nPassword: FROSTLINE|n- Lam"
     bAddToVault=False
     bUnmovable=True
     bInvincible=True
     bPushable=False
}
