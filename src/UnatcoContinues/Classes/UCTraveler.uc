//=============================================================================
// UCTraveler - oggetto invisibile nell'inventario di JC che fa ripartire la mod
// in ogni mappa.
// Le uscite di Revision (MapExit, ascensori di Hong Kong...) ricostruiscono
// l'URL con BuildOptionString() e "?Mutator=" vuoto, e i ServerActors in single
// player non vengono creati: senza questo oggetto UCMod non partirebbe nelle
// mappe raggiunte giocando. L'inventario invece viaggia sempre con il giocatore.
// Non si vede ne' nell'inventario ne' nella cintura.
//=============================================================================
class UCTraveler extends Inventory;

var float checkTime;

// arrivo in una nuova mappa (o in una gia' visitata)
event TravelPostAccept()
{
	Super.TravelPostAccept();
	EnsureMod();
	CloseStaleWindows();
}

// Le scene della mod sono transient: se JC cambia zona a meta' di un InfoLink (o del
// terminale di Tong) la scena sparisce e la sua finestra del HUD resterebbe aperta.
// Il gioco originale chiude i suoi InfoLink da solo (DeusExPlayer.PreTravel).
function CloseStaleWindows()
{
	local DeusExPlayer P;
	local DeusExRootWindow root;
	local UCCaptionWindow cap;

	P = DeusExPlayer(GetPlayerPawn());
	if (P == None)
		return;
	root = DeusExRootWindow(P.rootWindow);
	// la scritta della presentazione per il video (UCTour) rimasta dalla mappa prima
	if (root != None)
	{
		cap = class'UCTour'.static.FindCaption(root);
		if (cap != None)
			cap.Hide();
	}
	if (P.dataLinkPlay != None || root == None || root.hud == None)
		return;
	if (root.hud.infolink != None)
		root.hud.DestroyInfoLinkWindow();
	if (root.hud.info != None && root.hud.info.IsVisible())
	{
		root.hud.info.ClearTextWindows();
		root.hud.info.Hide();
	}
}

// riserva: partite caricate da un salvataggio in una mappa dove la mod non girava
event Tick(float deltaTime)
{
	Super.Tick(deltaTime);
	checkTime += deltaTime;
	if (checkTime < 1.0)
		return;
	checkTime = 0;
	EnsureMod();
}

function EnsureMod()
{
	local UCMod m;

	foreach AllActors(class'UCMod', m)
		if (!m.bDeleteMe)
			return;
	Spawn(class'UCMod');
	Log("UnatcoContinues: gestore route avviato dall'inventario di JC");
}

defaultproperties
{
     bDisplayableInv=False
     bInObjectBelt=False
     bHidden=True
     bTravel=True
     ItemName="UNATCO Continues"
     Icon=None
     Mesh=None
     CollisionRadius=1.000000
     CollisionHeight=1.000000
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
