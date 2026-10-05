//=============================================================================
// UCDbgHeliDoor - Hong Kong, eliporto: JC davanti al passaggio verso gli ascensori
// (porta blindata "riparata" della route UNATCO), Jock gia' ripartito.
//   summon UnatcoContinues.UCDbgHeliDoor
//=============================================================================
class UCDbgHeliDoor extends UCDebug;

function Run()
{
	HongKongBase();
	SetF('UC_HK_SimonsDue', True);
	SetF('UC_HK_SimonsBriefing', True);
	Jump("06_HongKong_Helibase", 5);
}

defaultproperties
{
}
