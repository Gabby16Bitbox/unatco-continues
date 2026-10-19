//=============================================================================
// UCCutWindow - what a cutscene of the map editor (UCCutscene) draws over the game: the black bars of
// a film (the picture 2.35 times as wide as it is tall), the fade from and to black, the subtitles (who
// speaks, in yellow, and the line) in the bottom bar, and "Click or Space: skip" for a moment.
// It never takes clicks or keys. UCCutscene creates it, moves its values and closes it; Close(secs)
// takes the bars away and lets the black fade out by itself before it destroys itself.
//=============================================================================
class UCCutWindow extends Window
	transient;

var bool   bBars;
var float  fade;              // 0 = the game, 1 = all black
var string who, line;
var float  hint;              // seconds the "skip" hint is still shown
var float  closing, closeTime;
var Font   fontWho, fontLine, fontHint;
var Color  colWho, colLine, colHint;

event InitWindow()
{
	Super.InitWindow();
	SetWindowAlignments(HALIGN_Full, VALIGN_Full);
	SetSensitivity(False);
	SetSelectability(False);
	bTickEnabled = True;
}

function SetLine(string newWho, string newLine)
{
	who = newWho;
	line = newLine;
}

function Close(float secs)
{
	bBars = False;
	who = "";
	line = "";
	hint = 0;
	if (secs <= 0 || fade <= 0)
	{
		Destroy();
		return;
	}
	closeTime = secs;
	closing = secs;
}

event Tick(float deltaTime)
{
	local RootWindow root;

	// Stay full-screen during arrival, resolution changes AND the closing fade.
	// Sizing only when created can retain the previous viewport's bottom edge.
	root = GetRootWindow();
	if (root != None && (x != 0 || y != 0 || width != root.width || height != root.height))
		SetConfiguration(0, 0, root.width, root.height);
	if (hint > 0)
		hint -= deltaTime;
	if (closeTime > 0)
	{
		closing -= deltaTime;
		fade = FMin(fade, FMax(0, closing / closeTime));
		if (closing <= 0)
			Destroy();
	}
}

function float BarHeight()
{
	if (!bBars)
		return 0;
	return FMax(0, (height - width / 2.35) * 0.5);
}

// UCFade: a strip of greys from 128 (no change) to 0 (black); the column is how dark
function Black(GC gc, float x, float y, float w, float h, float a)
{
	local float right, bottom;

	if (w <= 0 || h <= 0 || a <= 0)
		return;
	// GC truncates the origin and extent separately. At 1280x721, for example,
	// int(632.84) + int(88.16) stops at 720 and exposes the last screen row.
	// Round OUTWARD from the endpoints, not each length independently.
	right = x + w;
	bottom = y + h;
	x = int(x);
	y = int(y);
	w = int(right + 0.9999) - x;
	h = int(bottom + 0.9999) - y;
	gc.SetStyle(DSTY_Modulated);
	gc.DrawStretchedTexture(x, y, w, h, FClamp(a * 127, 0, 127), 0, 1, 8, Texture'UCFade');
}

event DrawWindow(GC gc)
{
	local float bar, tw, th, y, h;
	local string s;

	bar = BarHeight();
	// One full-screen fade, then the opaque bars: no uncovered seam between
	// three independently rounded rectangles at fractional UI scales.
	Black(gc, 0, 0, width, height, fade);
	Black(gc, 0, 0, width, bar, 1);
	Black(gc, 0, height - bar, width, bar, 1);

	gc.EnableTranslucentText(False);
	gc.EnableWordWrap(True);
	gc.SetStyle(DSTY_Normal);
	if (line != "")
	{
		h = bar;                              // in the bottom bar (no bars: a dark band low on the screen)
		if (h <= 0)
			h = height * 0.16;
		y = height - h + 6;
		if (bar <= 0)
			Black(gc, width * 0.1, y - 4, width * 0.8, h - 12, 0.55);
		if (who != "")
		{
			gc.SetFont(fontWho);
			gc.SetTextColor(colWho);
			gc.SetAlignments(HALIGN_Center, VALIGN_Top);
			gc.GetTextExtent(width * 0.8, tw, th, who);
			gc.DrawText(width * 0.1, y, width * 0.8, th, who);
			y += th + 2;
		}
		gc.SetFont(fontLine);
		gc.SetTextColor(colLine);
		gc.SetAlignments(HALIGN_Center, VALIGN_Top);
		gc.DrawText(width * 0.1, y, width * 0.8, height - y, line);
	}
	if (hint > 0)
	{
		s = "Click or Space: skip";
		gc.SetFont(fontHint);
		gc.SetTextColor(colHint);
		gc.SetAlignments(HALIGN_Right, VALIGN_Top);
		gc.DrawText(width * 0.5, FMax(4, bar * 0.5 - 6), width * 0.5 - 12, 20, s);
	}
}
defaultproperties
{
     fontWho=Font'DeusExUI.FontMenuHeaders'
     fontLine=Font'DeusExUI.FontConversationLarge'
     fontHint=Font'DeusExUI.FontMenuSmall'
     colWho=(R=255,G=200,B=60)
     colLine=(R=255,G=255,B=255)
     colHint=(R=150,G=150,B=150)
     hint=3.000000
}
