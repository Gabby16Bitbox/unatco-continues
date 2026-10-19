//=============================================================================
// UCCustomCivilian - a civilian made in the map editor's Character Creator: the map sets its
// Mesh, MultiSkins and LookBody (see UCCustomLook). Same AI as the game's civilians.
//=============================================================================
class UCCustomCivilian extends HumanCivilian;

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
	LookBody=Class'DeusEx.Male1'
	CarcassType=Class'UnatcoContinues.UCCustomCarcass'
	WalkingSpeed=0.296000
	walkAnimMult=0.750000
	GroundSpeed=200.000000
	BaseEyeHeight=39.000000
	Mesh=LodMesh'DeusExCharacters.GM_DressShirt_F'
	MultiSkins(0)=Texture'DeusExCharacters.Skins.Male1Tex0'
	MultiSkins(1)=Texture'DeusExItems.Skins.PinkMaskTex'
	MultiSkins(2)=Texture'DeusExItems.Skins.PinkMaskTex'
	MultiSkins(3)=Texture'DeusExCharacters.Skins.PantsTex1'
	MultiSkins(4)=Texture'DeusExCharacters.Skins.Male1Tex0'
	MultiSkins(5)=Texture'DeusExCharacters.Skins.Male1Tex1'
	MultiSkins(6)=Texture'DeusExItems.Skins.GrayMaskTex'
	MultiSkins(7)=Texture'DeusExItems.Skins.BlackMaskTex'
	CollisionRadius=20.000000
	CollisionHeight=47.500000
	BindName="CustomCharacter"
	FamiliarName="Civilian"
	UnfamiliarName="Civilian"
}
