//=============================================================================
// UCMeshDeco - a 3D model placed with the map editor's Models: any mesh of the game, of another
// mod or imported into the mod's UCModels package. It stays where it was put (it does not fall),
// it is solid, and it cannot be pushed or destroyed unless its Properties say so. Its collision
// cylinder and PrePivot come from the size of the model (the editor sets them).
// IdleAnim: an animated model (imported with its animations, 20 Oct 2026) loops this sequence of its mesh,
// IdleRate times as fast as it was made.
//=============================================================================
class UCMeshDeco extends DeusExDecoration;

var() name IdleAnim;
var() float IdleRate;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	if (IdleAnim != '' && HasAnim(IdleAnim))
		LoopAnim(IdleAnim, IdleRate);
}

defaultproperties
{
     bInvincible=True
     bPushable=False
     bHighlight=False
     bFlammable=False
     ItemArticle="an"
     ItemName="Object"
     Physics=PHYS_None
     bCollideWorld=False
     Mass=100.000000
     Buoyancy=50.000000
     CollisionRadius=16.000000
     CollisionHeight=16.000000
     IdleRate=1.000000
}
