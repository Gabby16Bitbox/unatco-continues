//=============================================================================
// UCTourVariantsMenu - le varianti della presentazione per il video: la stessa scena con
// un passato diverso. Ci si arriva anche con PagSu dopo la scena base; da qui si scelgono
// direttamente. I numeri sono quelli dei capitoli del menu Video.
//=============================================================================
class UCTourVariantsMenu extends UCDebugMenu;

defaultproperties
{
     ButtonNames(0)="2b. Anna dead"
     ButtonNames(1)="4b. Anna-Lebedev"
     ButtonNames(2)="4c. Soldier"
     ButtonNames(3)="6b. Majestic 12"
     ButtonNames(4)="Back"
     ButtonNames(5)="Close"
     ButtonNames(6)=""
     ButtonNames(7)=""
     ButtonNames(8)=""
     ButtonNames(9)=""
     ButtonNames(10)=""
     ButtonNames(11)=""
     buttonDefaults(0)=(Y=13,Action=MA_Custom,Key="UCDbgTourVarGunther")
     buttonDefaults(1)=(Y=49,Action=MA_Custom,Key="UCDbgTourVarAnna")
     buttonDefaults(2)=(Y=85,Action=MA_Custom,Key="UCDbgTourVarTrooper")
     buttonDefaults(3)=(Y=121,Action=MA_Custom,Key="UCDbgTourVarOfficer")
     buttonDefaults(4)=(Y=169,Action=MA_Custom,Key="UCDbgTourMenu")
     buttonDefaults(5)=(Y=205,Action=MA_Previous)
     Title="UNATCO Continues - Variants"
}
