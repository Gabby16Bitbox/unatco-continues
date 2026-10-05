//=============================================================================
// UCDbgStatus - mostra a schermo i flag della route.
//   summon UnatcoContinues.UCDbgStatus
//=============================================================================
class UCDbgStatus extends UCDebug;

function Show(Name flagName)
{
	local string s;

	if (flags.GetBool(flagName))
		s = "SI";
	else
		s = "no";
	Player.ClientMessage("[UC] " $ flagName $ " = " $ s);
}

function Run()
{
	Show('PaulInjured_Played');
	Show('DL_GotUplinkCode_Played');
	Show('NSFSignalSent');
	Show('M04PlayerLikesUNATCO_Played');
	Show('PaulDenton_Dead');
	Show('UNATCORoute_EvidenceFound');
	Show('UNATCORouteActive');
	Show('UNATCORouteCommitted');
	Show('PaulLeftTonHotel');
	Show('UC_JockBP_Played');
	Show('UNATCORoute_DepartedNYC');
	Show('UC_JockHK_Played');
	Destroy();
}

defaultproperties
{
     bKeepTour=True
}
