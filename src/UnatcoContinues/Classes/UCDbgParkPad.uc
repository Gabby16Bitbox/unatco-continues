//=============================================================================
// UCDbgParkPad - Battery Park, vicino all'elicottero di Jock: la chiamata di Jock e lo sparo ci
// sono gia' stati (UCSceneBatteryPark: i Special Agents parlano appena JC si avvicina).
//   summon UnatcoContinues.UCDbgParkPad
//=============================================================================
class UCDbgParkPad extends UCDebug;

function Run()
{
	AfterPaul();
	SetF('UC_BP_JockCall', True);
	SetF('UC_JockDead', True);
	Jump("04_NYC_BatteryPark#ToBatteryPark", 2);
}

defaultproperties
{
}
