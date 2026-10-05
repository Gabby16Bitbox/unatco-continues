//=============================================================================
// UCDbgCompound - Hong Kong, compound del Luminous Path (Gordon Quick al cancello).
// Briefing di Simons gia' fatto; niente prova ne' tregua (si provano in ordine).
//   summon UnatcoContinues.UCDbgCompound
//=============================================================================
class UCDbgCompound extends UCDebug;

function Run()
{
	HongKongBase();
	SetF('UC_HK_SimonsDue', True);
	SetF('UC_HK_SimonsBriefing', True);
	Jump("06_HongKong_WanChai_Compound#CompoundFromMarket1", 0);
}

defaultproperties
{
}
