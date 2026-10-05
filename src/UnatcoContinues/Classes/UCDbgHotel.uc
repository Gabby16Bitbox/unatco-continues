//=============================================================================
// UCDbgHotel - salta da Paul al 'Ton: prova NSF trovata, segnale NON inviato.
// Parli con Paul e parte la conversazione M04PlayerLikesUNATCO.
//   summon UnatcoContinues.UCDbgHotel
//=============================================================================
class UCDbgHotel extends UCDebug;

function Run()
{
	PaulDecision();
	SetF('UC_DbgAutoConv', True);   // all'arrivo parte da sola la conversazione del bivio
	Jump("04_NYC_Hotel", 1);
}

defaultproperties
{
}
