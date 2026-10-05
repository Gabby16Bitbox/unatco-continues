//=============================================================================
// UCDbgMenu - apre il menu di debug.  Tasto Home, oppure in console:  uc
//=============================================================================
class UCDbgMenu extends UCDebug;

function Run()
{
	local DeusExRootWindow root;

	root = DeusExRootWindow(Player.rootWindow);
	if (root != None)
		root.InvokeMenu(class'UCDebugMenu');
	Player = None;
	flags = None;
	Destroy();
}

defaultproperties
{
     bKeepTour=True
}
