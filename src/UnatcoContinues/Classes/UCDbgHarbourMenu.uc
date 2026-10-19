//=============================================================================
// UCDbgHarbourMenu - apre il menu di debug di Harbourline Tower (UCHarbourMenu: tetto, garage,
// dopo l'attacco). Il menu principale ha gia' i suoi 12 pulsanti.
//=============================================================================
class UCDbgHarbourMenu extends UCDebug;

function Run()
{
	local DeusExRootWindow root;

	root = DeusExRootWindow(Player.rootWindow);
	if (root != None)
		root.InvokeMenu(class'UCHarbourMenu');
	Player = None;
	flags = None;
	Destroy();
}

defaultproperties
{
     bKeepTour=True
}
