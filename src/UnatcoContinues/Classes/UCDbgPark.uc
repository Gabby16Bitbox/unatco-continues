//=============================================================================
// UCDbgPark - Battery Park, appena scesi dalla metro: due secondi dopo parte la chiamata di
// Jock (UCSceneBatteryPark). Vedi anche UCDbgParkPad (gia' al pad, chiamata passata).
//   summon UnatcoContinues.UCDbgPark
//=============================================================================
class UCDbgPark extends UCDebug;

function Run()
{
	AfterPaul();
	Jump("04_NYC_BatteryPark#ToBatteryPark", 0);
}
defaultproperties
{
}
