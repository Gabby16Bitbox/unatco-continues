//=============================================================================
// UCDbgLucky - Hong Kong, davanti al Lucky Money: il messaggero ha gia' parlato,
// il briefing di Simons e' fatto. I due agenti governativi parlano col Red Arrow, che
// poi porta JC da Max Chen.
//   summon UnatcoContinues.UCDbgLucky
//=============================================================================
class UCDbgLucky extends UCDebug;

function Run()
{
	HongKongBase();
	SetF('UC_HK_SimonsDue', True);
	SetF('UC_HK_SimonsBriefing', True);
	SetF('UC_Messenger_Played', True);
	SetF('UC_HK_MessengerDone', True);
	Jump("06_HongKong_WanChai_Underworld", 7);
}

defaultproperties
{
}
