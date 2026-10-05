//=============================================================================
// UCDbgTransmitter - NSF HQ, sul tetto davanti al computer del trasmettitore,
// con il codice dell'uplink gia' trovato: usa "Broadcast Message" per la scelta.
//   summon UnatcoContinues.UCDbgTransmitter
//=============================================================================
class UCDbgTransmitter extends UCDebug;

function Run()
{
	BaseMission04();
	SetF('GotUplinkCode', True);
	SetF('DL_GotUplinkCode_Played', True);
	SetF('M04MeetGateGuard_Played', True);
	Jump("04_NYC_NSFHQ", 4);   // 4 = davanti al computer del trasmettitore
}

defaultproperties
{
}
