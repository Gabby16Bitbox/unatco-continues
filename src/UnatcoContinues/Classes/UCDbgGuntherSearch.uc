//=============================================================================
// UCDbgGuntherSearch - 'Ton, dentro l'hotel dopo l'incontro con Gunther davanti
// all'ingresso: Paul se n'e' gia' andato (sangue in camera), Gunther e lo Special
// Agent sono appena entrati e vanno alla camera di Paul (UCSceneGuntherSearch).
//   summon UnatcoContinues.UCDbgGuntherSearch
//=============================================================================
class UCDbgGuntherSearch extends UCDebug;

function Run()
{
	AfterPaul();
	SetF('PaulLeftTonHotel', True);
	SetF('GuntherTonEncounterPlayed', True);
	SetF('GuntherKnowsJCMetPaul', True);
	SetF('GuntherReportedJCConduct', True);
	SetF('UC_PaulContactReportSent', True);
	SetF('UC_JockGoal', True);
	Jump("04_NYC_Hotel", 0);
}

defaultproperties
{
}
