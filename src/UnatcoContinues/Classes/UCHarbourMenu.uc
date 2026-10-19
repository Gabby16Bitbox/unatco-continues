//=============================================================================
// UCHarbourMenu - i salti di debug di Harbourline Tower (missione 6, 06_HongKong_WanChai_Rooftop):
// l'atterraggio sul tetto, il garage prima di Kwan, il garage dopo l'attacco.
//=============================================================================
class UCHarbourMenu extends UCDebugMenu;

defaultproperties
{
     ButtonNames(0)="5. Roof - landing"
     ButtonNames(1)="5b. Garage - Kwan"
     ButtonNames(2)="5c. Garage - after the attack"
     ButtonNames(3)="Back"
     ButtonNames(4)="Close"
     ButtonNames(5)=""
     ButtonNames(6)=""
     ButtonNames(7)=""
     ButtonNames(8)=""
     ButtonNames(9)=""
     ButtonNames(10)=""
     ButtonNames(11)=""
     buttonDefaults(0)=(Y=13,Action=MA_Custom,Key="UCDbgHongKong")
     buttonDefaults(1)=(Y=49,Action=MA_Custom,Key="UCDbgHarbourDock")
     buttonDefaults(2)=(Y=85,Action=MA_Custom,Key="UCDbgHarbourAfter")
     buttonDefaults(3)=(Y=133,Action=MA_Custom,Key="UCDbgMenu")
     buttonDefaults(4)=(Y=169,Action=MA_Previous)
     Title="UNATCO Continues - Harbourline"
}
