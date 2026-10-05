//=============================================================================
// UCDbgMetro - Hell's Kitchen, in cima alle scale della metro, dopo l'incontro con
// Gunther davanti al 'Ton (il rapporto "JC ha parlato con Paul" e' gia' stato trasmesso).
// Alla grata c'e' Anna Navarre (se e' morta: un soldato). Stato di partenza: Lebedev
// ucciso da JC, Anna viva. Le altre varianti si provano cambiando i flag:
// AnnaKilledLebedev / PlayerKilledLebedev, AnnaNavarre_Dead, UC_PaulContactReportSent.
//   summon UnatcoContinues.UCDbgMetro
//=============================================================================
class UCDbgMetro extends UCDebug;

function Run()
{
	AfterPaul();
	SetF('PaulLeftTonHotel', True);
	SetF('GuntherTonEncounterPlayed', True);
	SetF('GuntherKnowsJCMetPaul', True);
	SetF('GuntherReportedJCConduct', True);
	SetF('UC_PaulContactReportSent', True);
	SetF('UC_GuntherTon1_Played', True);
	SetF('UC_JockGoal', True);
	Jump("04_NYC_Street", 6);
}

defaultproperties
{
}
