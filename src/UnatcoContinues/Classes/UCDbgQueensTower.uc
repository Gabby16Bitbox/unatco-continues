//=============================================================================
// UCDbgQueensTower - Hong Kong, Tonnochi Road (Queen's Tower, Maggie Chow).
// Briefing di Simons gia' fatto. Per la stanza della spada: ascensore principale
// fino al piano di Maggie, oppure i codici 3444 / 1709 / 718.
//   summon UnatcoContinues.UCDbgQueensTower
//=============================================================================
class UCDbgQueensTower extends UCDebug;

function Run()
{
	HongKongBase();
	SetF('UC_HK_SimonsDue', True);
	SetF('UC_HK_SimonsBriefing', True);
	Jump("06_HongKong_WanChai_Street", 0);
}

defaultproperties
{
}
