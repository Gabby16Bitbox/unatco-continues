//=============================================================================
// UCCigarette - how a cigarette looks, for the Animation Studio's props (UCAnimProp copies the look of a
// class's defaults). The game has only the pack (DeusExItems.Cigarettes), so (Gabby, 17 Oct 2026: "a very
// small flare, retextured") it is the flare's model a third of its size, about 4 units long, with
// UCCigaretteTex (tools\make_cigarette_tex.py: filter, paper, ash, the burning tip at the model's -Y end).
// Never placed in a map by itself.
//=============================================================================
class UCCigarette extends Actor
	abstract;

#exec TEXTURE IMPORT NAME=UCCigaretteTex FILE=Textures\UCCigaretteTex.pcx MIPS=On

defaultproperties
{
	DrawType=DT_Mesh
	Mesh=LodMesh'DeusExItems.Flare'
	Skin=Texture'UnatcoContinues.UCCigaretteTex'
	MultiSkins(0)=Texture'UnatcoContinues.UCCigaretteTex'
	DrawScale=0.330000
	bHidden=True
	bCollideActors=False
	bCollideWorld=False
	bBlockActors=False
	bBlockPlayers=False
}
