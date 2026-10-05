//=============================================================================
// UCSignalMenu - la scelta al trasmettitore NSF: mandare il segnale di Paul o no.
// (Nel gioco originale questa scelta era prevista ma e' stata tagliata.)
//=============================================================================
class UCSignalMenu extends MenuUIMenuWindow;

function ProcessCustomMenuButton(string key)
{
	local class<Actor> cmd;
	local DeusExPlayer P;

	P = player;
	cmd = class<Actor>(DynamicLoadObject("UnatcoContinues." $ key, class'Class'));
	root.ClearWindowStack();
	if (cmd != None && P != None)
		P.Spawn(cmd);
}

defaultproperties
{
     ButtonNames(0)="Send Paul's distress signal"
     ButtonNames(1)="Don't send it"
     ButtonNames(2)="Not yet"
     buttonXPos=7
     buttonWidth=245
     buttonDefaults(0)=(Y=13,Action=MA_Custom,Key="UCSignalSend")
     buttonDefaults(1)=(Y=49,Action=MA_Custom,Key="UCSceneRefuse")
     buttonDefaults(2)=(Y=109,Action=MA_Previous)
     Title="NSF Transmitter"
     ClientWidth=258
     ClientHeight=150
     verticalOffset=2
     clientTextures(0)=Texture'DeusExUI.UserInterface.MenuMainBackground_1'
     clientTextures(1)=Texture'DeusExUI.UserInterface.MenuMainBackground_2'
     clientTextures(2)=Texture'DeusExUI.UserInterface.MenuMainBackground_3'
     textureCols=2
}
