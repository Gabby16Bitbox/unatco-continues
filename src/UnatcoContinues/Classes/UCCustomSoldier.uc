//=============================================================================
// UCCustomSoldier - a soldier made in the map editor's Character Creator: the map sets its
// Mesh, MultiSkins and LookBody (see UCCustomLook). Same AI as the game's soldiers.
//=============================================================================
class UCCustomSoldier extends HumanMilitary;

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
	LookBody=Class'DeusEx.Soldier'
	bShouldGuardPoints=True
	Professionalism=1.200000
	CarcassType=Class'UnatcoContinues.UCCustomCarcass'
	WalkingSpeed=0.296000
	walkAnimMult=0.780000
	GroundSpeed=200.000000
	BaseEyeHeight=39.000000
	Texture=Texture'DeusExItems.Skins.PinkMaskTex'
	Mesh=LodMesh'DeusExCharacters.GM_Jumpsuit'
	MultiSkins(0)=Texture'DeusExCharacters.Skins.SoldierTex0'
	MultiSkins(1)=Texture'DeusExCharacters.Skins.SoldierTex2'
	MultiSkins(2)=Texture'DeusExCharacters.Skins.SoldierTex1'
	MultiSkins(3)=Texture'DeusExCharacters.Skins.SoldierTex0'
	MultiSkins(4)=Texture'DeusExItems.Skins.PinkMaskTex'
	MultiSkins(5)=Texture'DeusExItems.Skins.GrayMaskTex'
	MultiSkins(6)=Texture'DeusExCharacters.Skins.SoldierTex3'
	MultiSkins(7)=Texture'DeusExItems.Skins.PinkMaskTex'
	CollisionRadius=20.000000
	CollisionHeight=47.500000
	BindName="CustomCharacter"
	FamiliarName="Soldier"
	UnfamiliarName="Soldier"
}
