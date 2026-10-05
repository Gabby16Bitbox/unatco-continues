//=============================================================================
// UCDbgTourMenu - apre il menu della presentazione per il video (UCTourMenu).
//=============================================================================
class UCDbgTourMenu extends UCDebug;

function Run()
{
	local DeusExRootWindow root;

	root = DeusExRootWindow(Player.rootWindow);
	if (root != None)
		root.InvokeMenu(class'UCTourMenu');
	Player = None;
	flags = None;
	Destroy();
}

defaultproperties
{
     bKeepTour=True
}
