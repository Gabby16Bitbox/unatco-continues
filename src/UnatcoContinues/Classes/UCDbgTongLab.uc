//=============================================================================
// UCDbgTongLab - Hong Kong, laboratorio di Tong: tregua fatta, Gordon ha dato il
// permesso (codice 1997). Si arriva dalla scala del seminterrato del compound.
//   summon UnatcoContinues.UCDbgTongLab
//=============================================================================
class UCDbgTongLab extends UCDebug;

function Run()
{
	TongLabState();
	Jump("06_HongKong_TongBase#lab", 0);
}

defaultproperties
{
}
