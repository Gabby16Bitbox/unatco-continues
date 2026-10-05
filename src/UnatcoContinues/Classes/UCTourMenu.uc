//=============================================================================
// UCTourMenu - menu della presentazione per il video (dal menu di debug, tasto Home).
// Ogni pulsante parte da un capitolo; al passo dopo si va con PagSu. "Varianti" apre il
// menu delle scene rifatte con un passato diverso (UCTourVariantsMenu).
//=============================================================================
class UCTourMenu extends UCDebugMenu;

defaultproperties
{
     ButtonNames(0)="1. Paul"
     ButtonNames(1)="2. Gunther"
     ButtonNames(2)="3. Hotel"
     ButtonNames(3)="4. Anna - metro"
     ButtonNames(4)="5. Battery Park"
     ButtonNames(5)="6. HK - eliporto"
     ButtonNames(6)="7. HK - mercato"
     ButtonNames(7)="8. Max Chen"
     ButtonNames(8)="9. Tracer Tong"
     ButtonNames(9)="Varianti"
     ButtonNames(10)="Ferma"
     ButtonNames(11)="Chiudi"
     buttonDefaults(0)=(Y=13,Action=MA_Custom,Key="UCDbgTour")
     buttonDefaults(1)=(Y=49,Action=MA_Custom,Key="UCDbgTour2")
     buttonDefaults(2)=(Y=85,Action=MA_Custom,Key="UCDbgTour3")
     buttonDefaults(3)=(Y=121,Action=MA_Custom,Key="UCDbgTour4")
     buttonDefaults(4)=(Y=157,Action=MA_Custom,Key="UCDbgTour5")
     buttonDefaults(5)=(Y=193,Action=MA_Custom,Key="UCDbgTour6")
     buttonDefaults(6)=(Y=229,Action=MA_Custom,Key="UCDbgTour7")
     buttonDefaults(7)=(Y=265,Action=MA_Custom,Key="UCDbgTour8")
     buttonDefaults(8)=(Y=301,Action=MA_Custom,Key="UCDbgTour9")
     buttonDefaults(9)=(Y=349,Action=MA_Custom,Key="UCDbgTourVariants")
     buttonDefaults(10)=(Y=385,Action=MA_Custom,Key="UCDbgTourStop")
     buttonDefaults(11)=(Y=445,Action=MA_Previous)
     Title="UNATCO Continues - Video"
}
