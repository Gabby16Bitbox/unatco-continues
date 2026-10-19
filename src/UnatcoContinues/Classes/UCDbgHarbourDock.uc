//=============================================================================
// UCDbgHarbourDock - Hong Kong, Harbourline Tower (Mission 6): landing, Eva and Alex's call done, JC
// is at the bottom of the freight lift in the garage, before Kwan's welcome.
//   summon UnatcoContinues.UCDbgHarbourDock
// The arrival point is the map's disabled Teleporter UCHBDockStart (without it JC lands on the roof).
//=============================================================================
class UCDbgHarbourDock extends UCDbgHongKong;

function Run()
{
	Arrival();
	DockFlags();
	Jump("06_HongKong_WanChai_Rooftop#UCHBDockStart", 0);
}

function DockFlags()
{
	SetF('UNATCORoute_DepartedNYC', True);
	SetF('UC_HB_LandingSeen', True);
	SetF('UC_EvaRooftop_Played', True);
	SetF('UC_HB_TitleShown', True);
	SetF('UC_HB_AlexArrival', True);
	SetF('UC_RooftopIntroduced', True);
	SetF('UCHongKongRooftopArrival', True);
}

defaultproperties
{
}
