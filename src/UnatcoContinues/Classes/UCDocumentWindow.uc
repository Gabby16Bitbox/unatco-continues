// Documents need scrolling and a working Close action, unlike a short alert.
class UCDocumentWindow extends MenuUIMessageBoxWindow;

var MenuUIScrollAreaWindow recordScroll;
var LargeTextWindow recordText;

function CreateTextWindow()
{
    recordScroll=CreateScrollAreaWindow(winClient);
    recordScroll.SetPos(16,12);
    recordScroll.SetSize(clientWidth-32,clientHeight-24);
    recordText=LargeTextWindow(recordScroll.clipWindow.NewChild(class'LargeTextWindow'));
    recordText.SetTextMargins(0,0);
    recordText.SetFont(Font'FontMenuSmall');
    recordText.SetTextColor(player.ThemeManager.GetCurrentMenuColorTheme().GetColorFromName('MenuColor_ButtonTextNormal'));
    recordText.SetWordWrap(True);
    recordText.SetTextAlignments(HALIGN_Left,VALIGN_Top);
    recordText.SetWindowAlignments(HALIGN_Full,VALIGN_Top);
}

function SetMessageText(string text)
{
    recordText.SetText(text);
    AskParentForReconfigure();
}

function PostResult(int buttonNumber)
{
    root.PopWindow();
}

defaultproperties
{
    ClientWidth=460
    ClientHeight=290
    btnLabelOK="|&Close"
    winClientClass=Class'UnatcoContinues.UCDocumentClient'
    winShadowClass=None
}
