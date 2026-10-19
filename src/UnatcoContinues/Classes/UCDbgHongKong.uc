//=============================================================================
// UCDbgHongKong - Hong Kong, Harbourline Tower (missione 6): l'elicottero di Eva sta per atterrare
// sul tetto (atterraggio, Eva, Alex, Lam, le guardie, la sala di controllo).
//   summon UnatcoContinues.UCDbgHongKong
//=============================================================================
class UCDbgHongKong extends UCDebug;

function Run()
{
	Arrival();
	Jump("06_HongKong_WanChai_Rooftop", 0);
}

// I flag di un arrivo a Harbourline Tower mai visto (anche per UCDbgHarbourDock/After).
function Arrival()
{
	AfterPaul();
	SetF('UC_JockGoal', True);
	SetF('UC_JockStreetCall', True);
	SetF('UC_JockStreetCallDone', True);
	SetF('PaulLeftTonHotel', True);
	SetF('UC_BP_Started', True);
	SetF('UC_JockBP_Played', True);
	SetF('UC_JockGo', True);
	SetF('UC_Takeoff_Started', True);
	SetF('UC_JockDead', True);           // Battery Park: Jock shot, Eva flies JC (UCSceneBatteryPark)
	SetF('UC_EvaGo', True);
	SetF('UNATCORoute_DepartedNYC', True);
	SetF('UC_JockHK_Played', False);
	SetF('UC_HK_Started', False);
	SetF('UC_HKOfficer_Played', False);
	SetF('UC_HK_SimonsDue', False);
	SetF('UC_HK_SimonsBriefing', False);
	class'UCCampaign'.static.PrepareHongKongFlags(flags);
	SetF('UC_EvaRooftop_Played', False);
	SetF('UC_EvaRooftopAgain_Played', False);
	SetF('UC_RooftopIntroduced', False);
	SetF('UC_RoofLiaison_Played', False);
	SetF('UC_RoofLiaisonMet', False);
	SetF('UCHongKongRooftopArrival', False);
	SetF('UCHongKongRaidStarted', False);
	SetF('UCHongKongRaidResolved', False);
	SetF('UCHongKongCaseTaken', False);
	SetF('UCHongKongShipmentDefended', False);
	SetF('HongKongShipmentInspected', False);
	ResetHarbourline();
}

defaultproperties
{
}
