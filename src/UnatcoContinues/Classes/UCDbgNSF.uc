//=============================================================================
// UCDbgNSF - salta a NSF HQ come se Paul ti avesse appena parlato.
//   summon UnatcoContinues.UCDbgNSF
//=============================================================================
class UCDbgNSF extends UCDebug;

function Run()
{
	BaseMission04();
	Jump("04_NYC_NSFHQ", 0);
}

defaultproperties
{
}
