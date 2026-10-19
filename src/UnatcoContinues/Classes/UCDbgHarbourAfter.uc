//=============================================================================
// UCDbgHarbourAfter - Hong Kong, Harbourline Tower (Mission 6): as UCDbgHarbourDock, with the Luminous
// Path's attack on the garage already over (Kwan's debrief, the leader, Alex's report, the van).
//   summon UnatcoContinues.UCDbgHarbourAfter
// The scene puts the garage right on arrival (UC_HB_DebugAfter: the blown doors gone, the squad's hidden
// men removed) and the squad leader, taken (UC_HB_LeaderCaptured), kneels by Kwan once JC looks away.
// For the other outcomes set the flags before the jump (or with the shot runner's "flag" step):
// UC_HB_LeaderCaptured False and UC_HB_LeaderKilled True (no leader), UC_HB_ContainerBlew True (Kwan's
// "report" line, Alex's container line, the gloves line), UC_HB_Mail4Read True (the container-4 answer).
//=============================================================================
class UCDbgHarbourAfter extends UCDbgHarbourDock;

function DockFlags()
{
	Super.DockFlags();
	SetF('UC_HBKwanWelcome_Played', True);
	SetF('UC_HBGuardPhoto_Played', True);
	SetF('UC_HB_BreachStarted', True);
	SetF('UC_HB_BreachOver', True);
	SetF('UC_HB_AllDefused', True);
	SetF('UC_HB_LeaderCaptured', True);
	SetF('UC_HB_DebugAfter', True);
}

defaultproperties
{
}
