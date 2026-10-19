//=============================================================================
// UCUseWindow - while JC uses an object of the map editor that takes time (UCUsable): its use text and a
// bar filling up, under the crosshair, drawn the way the game draws the lock and door strength bars
// (FrobDisplayWindow). It never takes clicks or keys; UCUsable makes it, fills it and closes it.
//=============================================================================
class UCUseWindow extends Window
	transient;

var string label;
var float  progress;          // 0..1
var Color  colText, colBar, colBorder;

event InitWindow()
{
	Super.InitWindow();
	SetSensitivity(False);
	SetSelectability(False);
}

event DrawWindow(GC gc)
{
	local float w, h, x, y, tw, th;

	w = 220;
	h = 40;
	x = (width - w) / 2;
	y = height / 2 + 40;
	gc.SetStyle(DSTY_Modulated);
	gc.SetTileColorRGB(0, 0, 0);
	gc.DrawPattern(x, y, w, h, 0, 0, Texture'ConWindowBackground');
	gc.SetStyle(DSTY_Translucent);
	gc.SetTileColor(colBar);
	gc.DrawPattern(x + 6, y + h - 14, (w - 12) * FClamp(progress, 0, 1), 8, 0, 0, Texture'ConWindowBackground');
	gc.SetStyle(DSTY_Normal);
	gc.SetTileColor(colBorder);
	gc.DrawBox(x, y, w, h, 0, 0, 1, Texture'Solid');
	gc.DrawBox(x + 5, y + h - 15, w - 10, 10, 0, 0, 1, Texture'Solid');
	gc.SetFont(Font'FontMenuSmall_DS');
	gc.SetTextColor(colText);
	gc.SetAlignments(HALIGN_Center, VALIGN_Top);
	gc.EnableWordWrap(False);
	gc.GetTextExtent(0, tw, th, label);
	gc.DrawText(x + 4, y + 4, w - 8, th, label);
}

defaultproperties
{
     colText=(R=255,G=255,B=255)
     colBar=(R=80,G=200,B=255)
     colBorder=(R=120,G=160,B=200)
}
