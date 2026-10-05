//=============================================================================
// UCDbgPark - Battery Park, appena scesi dalla metro: Anna e Gunther arrivano.
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
