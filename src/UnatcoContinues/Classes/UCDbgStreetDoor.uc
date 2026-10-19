//=============================================================================
// UCDbgStreetDoor - Hong Kong, route UNATCO: raid finito, Simons gia' sentito, JC e' in cima
// alla scala di servizio della zona di carico di Special Projects, davanti alla porta del retro
// della macelleria: aprendola e passando si carica Wan Chai Street (#UCSpecialProjects, nel retro
// vero); dalla saracinesca si esce in strada, dove il messaggero Red Arrow aspetta di fronte.
//   summon UnatcoContinues.UCDbgStreetDoor
//=============================================================================
class UCDbgStreetDoor extends UCDebug;

function Run()
{
	HongKongBase();
	SetF('UC_HK_SimonsDue', True);
	SetF('UC_HK_SimonsBriefing', True);
	SetF('UC_HK_SimonsOpen', True);
	SetF('UC_HK_SimonsDone', True);
	SetF('UC_EvaRooftop_Played', True);
	SetF('UC_RooftopIntroduced', True);
	SetF('UC_RoofLiaison_Played', True);
	SetF('UC_RoofLiaisonMet', True);
	SetF('UCHongKongRooftopArrival', True);
	SetF('UCHongKongRaidStarted', True);
	SetF('UCHongKongRaidResolved', True);
	SetF('UC_MessengerPlaced', False);
	SetF('UC_Messenger_Played', False);
	SetF('UC_HK_MessengerDone', False);
	Jump("06_HongKong_WanChai_Rooftop#UCStreetDoor", 0);
}

defaultproperties
{
}
