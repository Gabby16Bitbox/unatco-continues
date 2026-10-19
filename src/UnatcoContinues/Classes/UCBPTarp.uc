//=============================================================================
// UCBPTarp - Battery Park: the tarp over Jock's body (UCSceneBatteryPark). The game's market
// canvas (HKMarketTarp mesh) turned upside down so it domes over the body, in the blue-grey cloth
// of the game's textiles (black plastic vanished in that dark corner: photos of 15 Oct). JC lifts
// it by clicking it: it is pulled aside and the body shows (flag UC_BP_JockBodyFound). Not solid:
// JC can step on it. The body and the cube under it pass their clicks on to it until it is lifted.
//=============================================================================
class UCBPTarp extends DeusExDecoration;

var bool bLifted;

function BeginPlay()
{
	local Texture tex;

	Super.BeginPlay();
	PlayAnim('Still');
	tex = Texture(DynamicLoadObject("CoreTexTextile.Textile.ClenBlueGrey_A", class'Texture', True));
	if (tex != None)
		Skin = tex;
}

function Frob(Actor Frobber, Inventory frobWith)
{
	local DeusExPlayer P;

	P = DeusExPlayer(Frobber);
	if (P == None || bLifted)
		return;
	Lift();
	// a rustle, once: PushPlastic is the sound of a pushed object, a loop that never stopped
	// (Gabby, 15 Oct)
	P.PlaySound(Sound'DeusExSounds.Generic.PlasticHit2', SLOT_None, 0.8);
	if (P.FlagBase != None)
		P.FlagBase.SetBool('UC_BP_JockBodyFound', True,, 99);
}

// Pulled back towards the wall, bunched up: the body and the datacube beside it are uncovered.
function Lift()
{
	local UCBPCube cube;

	if (bLifted)
		return;
	bLifted = True;
	foreach AllActors(class'UCBPCube', cube)
		cube.bHidden = False;
	SetCollision(False, False, False);
	SetLocation(Location + vect(10, 85, 0));
	SetRotation(rot(2000, 8000, 32768));
	DrawScale = 0.65;
	bHighlight = False;
}

defaultproperties
{
     ItemName="Tarp"
     Mesh=LodMesh'DeusExDeco.HKMarketTarp'
     Skin=Texture'DeusExDeco.Skins.TrashbagTex1'
     DrawScale=0.850000
     bInvincible=True
     bPushable=False
     bFlammable=False
     bHighlight=True
     Physics=PHYS_None
     bCollideWorld=False
     bCollideActors=True
     bBlockActors=False
     bBlockPlayers=False
     CollisionRadius=56.000000
     CollisionHeight=12.000000
     Mass=200.000000
     Buoyancy=5.000000
}
