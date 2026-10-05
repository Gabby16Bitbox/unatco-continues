//=============================================================================
// UCDbgGuntherStreet - Hell's Kitchen davanti al 'Ton, subito dopo il dialogo con
// Gunther: lui e i due Special Agents salgono la scalinata, si fermano alla porta
// dell'hotel in vista ed entrano solo quando JC non li guarda (UCSceneGuntherTon).
//   summon UnatcoContinues.UCDbgGuntherStreet
//=============================================================================
class UCDbgGuntherStreet extends UCDebug;

function Run()
{
	AfterPaul();
	SetF('UC_GuntherTon1_Played', True);   // dialogo gia' fatto: parte la camminata
	SetF('GuntherKnowsJCMetPaul', True);
	SetF('GuntherReportedJCConduct', True);
	SetF('UC_PaulContactReportSent', True);
	Jump("04_NYC_Street", 0);
}

defaultproperties
{
}
