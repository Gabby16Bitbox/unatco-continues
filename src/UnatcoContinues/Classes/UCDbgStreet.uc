//=============================================================================
// UCDbgStreet - Hell's Kitchen dopo il prologo: strade bloccate da UNATCO,
// la metro per Battery Park e' aperta. Si arriva davanti all'hotel.
//   summon UnatcoContinues.UCDbgStreet
//=============================================================================
class UCDbgStreet extends UCDebug;

function Run()
{
	AfterPaul();
	Jump("04_NYC_Street#FromHotelFrontDoor", 0);
}

defaultproperties
{
}
