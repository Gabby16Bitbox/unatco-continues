//=============================================================================
// UCCorpseLook - the look of the Character Creator body JC is carrying. A carried body is a
// POVCorpse, which keeps only the class of the corpse: put down, DeusExPlayer.DropItem spawns a
// new one of that class with the class's meshes and skins. This hidden item of JC's inventory
// keeps the meshes, clothes and size (travel: also to the next map) and UCCustomCarcass takes
// them back when it is put down (UCCustomLook.KeepLook / DressDropped).
//=============================================================================
class UCCorpseLook extends Inventory;

var travel string Look;     // UCCustomLook.LookOf of the carried body

defaultproperties
{
	bDisplayableInv=False
	ItemName=""
	bHidden=True
	Physics=PHYS_None
	bCollideActors=False
	bBlockActors=False
	CollisionRadius=1.000000
	CollisionHeight=1.000000
}
