//=============================================================================
// UCDbgMarket - Hong Kong, mercato di Wan Chai: JC e' appena sceso dall'eliporto.
// Il briefing di Simons parte qui. Il messaggero Red Arrow e' davanti all'ascensore.
//   summon UnatcoContinues.UCDbgMarket
//=============================================================================
class UCDbgMarket extends UCDebug;

function Run()
{
	HongKongBase();
	SetF('UC_HK_SimonsDue', True);
	SetF('UC_HK_SimonsBriefing', False);
	Jump("06_HongKong_WanChai_Market#cargoup", 0);
}

defaultproperties
{
}
