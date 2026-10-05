//=============================================================================
// UCDebugMenu - menu di debug con pulsanti (tasto Home, oppure "uc" in console).
// Ogni pulsante fa partire un comando UCDbg*.
// (La porta dell'eliporto, "5b", ha lasciato il posto alla presentazione per il video:
// resta in console, summon UnatcoContinues.UCDbgHeliDoor.)
//=============================================================================
class UCDebugMenu extends MenuUIMenuWindow;

function ProcessCustomMenuButton(string key)
{
	local class<Actor> cmd;
	local DeusExPlayer P;

	P = player;
	cmd = class<Actor>(DynamicLoadObject("UnatcoContinues." $ key, class'Class'));

	root.ClearWindowStack();   // chiude il menu e riprende il gioco

	if (cmd != None && P != None)
		P.Spawn(cmd);
}

defaultproperties
{
     ButtonNames(0)="1. NSF HQ"
     ButtonNames(1)="1b. Trasmettitore"
     ButtonNames(2)="2. 'Ton - Paul"
     ButtonNames(3)="3. Hell's Kitchen"
     ButtonNames(4)="4. Battery Park"
     ButtonNames(5)="5. HK - eliporto"
     ButtonNames(6)="6. HK - mercato"
     ButtonNames(7)="7. HK - Maggie"
     ButtonNames(8)="8. HK - Gordon"
     ButtonNames(9)="VIDEO"
     ButtonNames(10)="9. HK - Tong"
     ButtonNames(11)="Chiudi"
     buttonXPos=7
     buttonWidth=245
     buttonDefaults(0)=(Y=13,Action=MA_Custom,Key="UCDbgNSF")
     buttonDefaults(1)=(Y=49,Action=MA_Custom,Key="UCDbgTransmitter")
     buttonDefaults(2)=(Y=85,Action=MA_Custom,Key="UCDbgHotel")
     buttonDefaults(3)=(Y=121,Action=MA_Custom,Key="UCDbgStreet")
     buttonDefaults(4)=(Y=157,Action=MA_Custom,Key="UCDbgPark")
     buttonDefaults(5)=(Y=193,Action=MA_Custom,Key="UCDbgHongKong")
     buttonDefaults(6)=(Y=229,Action=MA_Custom,Key="UCDbgMarket")
     buttonDefaults(7)=(Y=265,Action=MA_Custom,Key="UCDbgQueensTower")
     buttonDefaults(8)=(Y=301,Action=MA_Custom,Key="UCDbgCompound")
     buttonDefaults(9)=(Y=349,Action=MA_Custom,Key="UCDbgTourMenu")
     buttonDefaults(10)=(Y=385,Action=MA_Custom,Key="UCDbgTongLab")
     buttonDefaults(11)=(Y=445,Action=MA_Previous)
     Title="UNATCO Continues - Debug"
     ClientWidth=258
     ClientHeight=496
     verticalOffset=2
     clientTextures(0)=Texture'DeusExUI.UserInterface.MenuMainBackground_1'
     clientTextures(1)=Texture'DeusExUI.UserInterface.MenuMainBackground_2'
     clientTextures(2)=Texture'DeusExUI.UserInterface.MenuMainBackground_3'
     textureCols=2
}
