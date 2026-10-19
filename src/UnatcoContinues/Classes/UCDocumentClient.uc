// A scalable native menu background for the scrollable records viewer.
class UCDocumentClient extends MenuUIClientWindow;

event DrawWindow(GC gc)
{
    gc.SetStyle(DSTY_Normal);
    gc.SetTileColor(colBackground);
    gc.DrawPattern(0,0,width,height,0,0,Texture'Solid');
    gc.SetTileColorRGB(70,100,125);
    gc.DrawBox(0,0,width,height,0,0,1,Texture'Solid');
}
