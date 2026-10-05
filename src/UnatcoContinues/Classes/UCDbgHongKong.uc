//=============================================================================
// UCDbgHongKong - Hong Kong, appena atterrati con Jock all'eliporto.
//   summon UnatcoContinues.UCDbgHongKong
//=============================================================================
class UCDbgHongKong extends UCDebug;

function Run()
{
	AfterPaul();
	SetF('UC_JockGoal', True);
	SetF('PaulLeftTonHotel', True);
	SetF('UC_BP_Started', True);
	SetF('UC_JockBP_Played', True);
	SetF('UC_JockGo', True);
	SetF('UC_Takeoff_Started', True);
	SetF('UNATCORoute_DepartedNYC', True);
	SetF('UC_JockHK_Played', False);
	SetF('UC_HK_Started', False);
	SetF('UC_HKOfficer_Played', False);
	SetF('UC_HK_SimonsDue', False);
	SetF('UC_HK_SimonsBriefing', False);
	class'UCMod'.static.PrepareHongKongFlags(flags);
	Jump("06_HongKong_Helibase", 0);
}

defaultproperties
{
}
