//=============================================================================
// UCDbgIsland - Liberty Island, appena atterrati: inizia la nuova campagna.
//   summon UnatcoContinues.UCDbgIsland
//=============================================================================
class UCDbgIsland extends UCDebug;

function Run()
{
	AfterPrologue();
	SetF('UC_BP_Started', True);
	SetF('UC_BP_Met', True);
	SetF('UC_Scene_Takeoff_Started', True);
	SetF('UC_Scene_Takeoff', True);
	SetF('UNATCORoute_ReturnToHQ', True);
	Jump("04_NYC_UNATCOIsland", 3);
}

defaultproperties
{
}
