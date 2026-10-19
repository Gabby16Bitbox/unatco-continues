//=============================================================================
// UCDbgReset - azzera i flag della route UNATCO (non cambia mappa).
//   summon UnatcoContinues.UCDbgReset
//=============================================================================
class UCDbgReset extends UCDebug;

function Run()
{
	ResetRoute();
	Player.ClientMessage("[UC] The route's flags are reset.");
	Destroy();
}

defaultproperties
{
}
