//=============================================================================
// UCDbgTourVariants - apre il menu delle varianti della presentazione (UCTourVariantsMenu).
//=============================================================================
class UCDbgTourVariants extends UCDebug;

function Run()
{
	local DeusExRootWindow root;

	root = DeusExRootWindow(Player.rootWindow);
	if (root != None)
		root.InvokeMenu(class'UCTourVariantsMenu');
	Player = None;
	flags = None;
	Destroy();
}

defaultproperties
{
     bKeepTour=True
}
