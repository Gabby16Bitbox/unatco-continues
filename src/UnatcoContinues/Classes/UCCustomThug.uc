//=============================================================================
// UCCustomThug - a criminal made in the map editor's Character Creator: the map sets its
// Mesh, MultiSkins and LookBody (see UCCustomLook). Same AI as the game's thugs.
//=============================================================================
class UCCustomThug extends HumanThug;

var() class<ScriptedPawn> LookBody;     // the game character whose body this is

event PreBeginPlay()
{
	class'UCCustomLook'.static.TakeBody(self, LookBody);
	Super.PreBeginPlay();
}

// keep the look of the map (no HDTP model, no class skins put back)
function bool Facelift(bool bOn)
{
	return false;
}

function Carcass SpawnCarcass()
{
	local Carcass carc;

	class'UCCustomLook'.static.PrepareCarcass(LookBody);
	carc = Super.SpawnCarcass();
	class'UCCustomLook'.static.DressCarcass(self, carc, LookBody);
	return carc;
}

defaultproperties
{
	LookBody=Class'DeusEx.ThugMale'
	CarcassType=Class'UnatcoContinues.UCCustomCarcass'
	WalkingSpeed=0.213333
	BaseAssHeight=-23.000000
	GroundSpeed=180.000000
	BaseEyeHeight=38.000000
	Mesh=LodMesh'DeusExCharacters.GM_Trench'
	MultiSkins(0)=Texture'DeusExCharacters.Skins.ThugMaleTex0'
	MultiSkins(1)=Texture'DeusExCharacters.Skins.ThugMaleTex2'
	MultiSkins(2)=Texture'DeusExCharacters.Skins.ThugMaleTex3'
	MultiSkins(3)=Texture'DeusExCharacters.Skins.ThugMaleTex0'
	MultiSkins(4)=Texture'DeusExCharacters.Skins.ThugMaleTex1'
	MultiSkins(5)=Texture'DeusExItems.Skins.PinkMaskTex'
	MultiSkins(6)=Texture'DeusExItems.Skins.GrayMaskTex'
	MultiSkins(7)=Texture'DeusExItems.Skins.BlackMaskTex'
	CollisionRadius=20.000000
	CollisionHeight=47.500000
	BindName="CustomCharacter"
	FamiliarName="Thug"
	UnfamiliarName="Thug"
}
