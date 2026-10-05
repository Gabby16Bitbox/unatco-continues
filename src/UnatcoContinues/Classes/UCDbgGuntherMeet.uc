//=============================================================================
// UCDbgGuntherMeet - Hell's Kitchen: JC esce dal 'Ton dopo aver detto no a Paul.
// Gunther e i due Special Agents aspettano ai piedi della scalinata: scendendo,
// parte il dialogo (UCSceneGuntherTon).
//   summon UnatcoContinues.UCDbgGuntherMeet
//=============================================================================
class UCDbgGuntherMeet extends UCDebug;

function Run()
{
	AfterPaul();
	// arriva dalla porta dell'hotel, come uscendo davvero (subito vicino a Gunther: con
	// la partenza della mappa lontana la scena lo darebbe per evitato)
	Jump("04_NYC_Street#FromHotelFrontDoor", 0);
}

defaultproperties
{
}
