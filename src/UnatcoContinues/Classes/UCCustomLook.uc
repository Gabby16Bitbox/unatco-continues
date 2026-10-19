//=============================================================================
// UCCustomLook - the look of the characters made in the map editor's Character Creator.
// The map gives the pawn its Mesh and MultiSkins (any face and clothes of the game, on any body);
// LookBody is the game character the body comes from: gender, walk, eye height, pain sounds and
// the meshes of the dead body. The game's own classes put their class skins back when the map
// starts (Facelift, for the HDTP models) and their corpses always wear the class skins:
// UCCustomCivilian, UCCustomSoldier and UCCustomThug keep the map's look, and their corpse
// (UCCustomCarcass) wears the same clothes, also after JC carries it and puts it down (UCCorpseLook).
//=============================================================================
class UCCustomLook extends Object
	abstract;

// gender, walk and voice of the body's character (before ScriptedPawn sets the female sounds)
static function TakeBody(ScriptedPawn P, class<ScriptedPawn> Body)
{
	if (P == None || Body == None)
		return;
	if (P.Mesh == None)
		P.Mesh = Body.default.Mesh;
	P.bIsFemale = Body.default.bIsFemale;
	P.WalkingSpeed = Body.default.WalkingSpeed;
	P.GroundSpeed = Body.default.GroundSpeed;
	P.BaseEyeHeight = Body.default.BaseEyeHeight;
	P.BaseAssHeight = Body.default.BaseAssHeight;
	P.walkAnimMult = Body.default.walkAnimMult;
	P.runAnimMult = Body.default.runAnimMult;
	P.Mass = Body.default.Mass;
	P.Buoyancy = Body.default.Buoyancy;
	P.HitSound1 = Body.default.HitSound1;
	P.HitSound2 = Body.default.HitSound2;
	P.Die = Body.default.Die;
}

// the dead body gets the meshes of the body's own corpse (front, back, floating)
static function PrepareCarcass(class<ScriptedPawn> Body)
{
	local class<DeusExCarcass> C;

	if (Body != None)
		C = class<DeusExCarcass>(Body.default.CarcassType);
	if (C == None)
		C = class'Male1Carcass';
	class'UCCustomCarcass'.default.Mesh = C.default.Mesh;
	class'UCCustomCarcass'.default.Mesh2 = C.default.Mesh2;
	class'UCCustomCarcass'.default.Mesh3 = C.default.Mesh3;
	// not a body put down by JC (one he carries must not give it its look)
	class'UCCustomCarcass'.default.bFromPawn = True;
}

// ...and the clothes the character wore (the corpse meshes have the same skin slots), and the size
// of the body's own corpse (collision sizes are constants: they cannot be given as defaults)
static function DressCarcass(ScriptedPawn P, Carcass carc, class<ScriptedPawn> Body)
{
	local int i;
	local class<DeusExCarcass> C;

	class'UCCustomCarcass'.default.bFromPawn = False;
	if (P == None || carc == None)
		return;
	if (Body != None)
		C = class<DeusExCarcass>(Body.default.CarcassType);
	if (C != None)
		carc.SetCollisionSize(C.default.CollisionRadius * carc.DrawScale, C.default.CollisionHeight * carc.DrawScale);
	for (i = 0; i < 8; i++)
		carc.MultiSkins[i] = P.MultiSkins[i];
	carc.Skin = P.Skin;
	carc.Texture = P.Texture;
}

// ---------------------------------------------------------------- a body JC carries
// The look of a body as a string: meshes (front, back, floating), Skin, Texture, the 8 skins,
// DrawScale and collision size, separated by |
static function string LookOf(DeusExCarcass C)
{
	local int i;
	local string s;

	s = string(C.Mesh) $ "|" $ string(C.Mesh2) $ "|" $ string(C.Mesh3) $ "|" $ string(C.Skin) $ "|" $ string(C.Texture);
	for (i = 0; i < 8; i++)
		s = s $ "|" $ string(C.MultiSkins[i]);
	return s $ "|" $ C.DrawScale $ "|" $ C.CollisionRadius $ "|" $ C.CollisionHeight;
}

// JC picked it up: its look in his UCCorpseLook (he carries one body at a time)
static function KeepLook(Pawn Holder, string Look)
{
	local Inventory inv;
	local UCCorpseLook L;

	if (Holder == None)
		return;
	for (inv = Holder.Inventory; inv != None && L == None; inv = inv.Inventory)
		L = UCCorpseLook(inv);
	if (L == None)
	{
		L = Holder.Spawn(class'UCCorpseLook', Holder);
		if (L == None)
			return;
		L.GiveTo(Holder);
	}
	L.Look = Look;
}

// A new body of this class: is it the one JC is putting down? (DropItem spawns it while his
// POVCorpse of this class still exists) Then it gets the look he kept.
static function bool DressDropped(DeusExCarcass C)
{
	local POVCorpse carried, P;
	local UCCorpseLook L;
	local string s;
	local int i;
	local float r, h, scale;

	foreach C.AllActors(class'POVCorpse', P)
		if (carried == None && P.Owner != None && P.carcClassString ~= string(C.Class))
			carried = P;
	if (carried == None)
		return false;
	foreach C.AllActors(class'UCCorpseLook', L)
		if (s == "" && L.Owner == carried.Owner)
			s = L.Look;
	if (s == "")
		return false;
	C.Mesh = MeshOf(Part(s), C.Mesh);
	C.Mesh2 = MeshOf(Part(s), C.Mesh2);
	C.Mesh3 = MeshOf(Part(s), C.Mesh3);
	C.Skin = TexOf(Part(s));
	C.Texture = TexOf(Part(s));
	for (i = 0; i < 8; i++)
		C.MultiSkins[i] = TexOf(Part(s));
	scale = float(Part(s));
	r = float(Part(s));
	h = float(Part(s));
	if (scale > 0)
		C.DrawScale = scale;
	if (r > 0 && h > 0)
		C.SetCollisionSize(r, h);
	return true;
}

// the next part of a look string (taken away from it)
static function string Part(out string s)
{
	local int i;
	local string p;

	i = InStr(s, "|");
	if (i < 0)
	{
		p = s;
		s = "";
	}
	else
	{
		p = Left(s, i);
		s = Mid(s, i + 1);
	}
	return p;
}

static function Mesh MeshOf(string s, Mesh Current)
{
	local Mesh M;

	if (s != "" && s != "None")
		M = Mesh(DynamicLoadObject(s, class'Mesh', True));
	if (M == None)
		return Current;
	return M;
}

static function Texture TexOf(string s)
{
	if (s == "" || s == "None")
		return None;
	return Texture(DynamicLoadObject(s, class'Texture', True));
}
