//=============================================================================
// UCBPShooter - Battery Park: the Special Agent who shot Jock (UCSceneBatteryPark). He stays by the
// body behind the vine wall, pistol in hand; when JC comes round the wall he walks up to him and
// tries to send him away with a few words (Gabby, 15 Oct). Friendly to JC like the other agents
// (Tag UCSpecialAgent: shooting him breaks the loyal route).
//=============================================================================
class UCBPShooter extends MIB;

defaultproperties
{
     InitialInventory(0)=(Inventory=Class'DeusEx.WeaponPistol')
     InitialInventory(1)=(Inventory=Class'DeusEx.Ammo10mm',Count=2)
     bKeepWeaponDrawn=True
     WalkingSpeed=0.320000
     FamiliarName="Special Agent"
     UnfamiliarName="Special Agent"
}
