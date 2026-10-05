//=============================================================================
// UCCaptionWindow - la targhetta delle scritte della presentazione (UCTour):
// un rettangolo nero con una riga di testo (e un eventuale titolo), sopra il gioco.
// La crea e la sposta UCTour; qui dentro nessun riferimento ad attori.
// Compare in dissolvenza (fadeTime secondi): il testo e il filetto sono disegnati
// "translucidi" con il colore attenuato; il fondo nero in stile "modulato" con la
// texture UCFade (una sfumatura di grigi: la colonna scelta e' l'opacita').
//=============================================================================
class UCCaptionWindow extends Window
	transient;

// sfumatura di grigi 128 -> 0 (tools/make_fade_texture.py): l'opacita' del fondo
#exec TEXTURE IMPORT NAME=UCFade FILE=Textures\UCFade.pcx MIPS=Off

var string title, body;
var float maxWidth;
var float boxWidth, boxHeight;   // quanto deve essere grande per il testo (SetCaption)
var float titleHeight;
var Font fontTitle, fontBody;
var Color colTitle, colBody, colEdge;
var float margin, gap;
var float fade;        // 0 = invisibile, 1 = piena
var float fadeTime;    // secondi per comparire

event InitWindow()
{
	Super.InitWindow();
	SetSensitivity(False);     // non prende mai clic ne' tasti
	SetSelectability(False);
	bTickEnabled = True;
}

// Cambia il testo e ricalcola la misura della targhetta (larga al massimo newMaxWidth).
// Una scritta nuova ricomincia la dissolvenza.
function SetCaption(string newTitle, string newBody, float newMaxWidth)
{
	local GC gc;
	local float tw, th, bw, bh;

	if (newTitle == title && newBody == body && newMaxWidth == maxWidth)
		return;
	if (newTitle != title || newBody != body)
		fade = 0;
	title = newTitle;
	body = newBody;
	maxWidth = newMaxWidth;

	gc = GetGC();
	gc.EnableWordWrap(True);
	if (title != "")
	{
		gc.SetFont(fontTitle);
		gc.GetTextExtent(maxWidth, tw, th, title);
	}
	if (body != "")
	{
		gc.SetFont(fontBody);
		gc.GetTextExtent(maxWidth, bw, bh, body);
	}
	ReleaseGC(gc);

	titleHeight = th;
	boxWidth = FMax(tw, bw) + 2 * margin + 8;   // un po' d'aria: l'ultimo carattere veniva tagliato
	boxHeight = th + bh + 2 * margin;
	if (title != "" && body != "")
		boxHeight += gap;
}

event Tick(float deltaTime)
{
	if (fade < 1.0)
		fade = FMin(1.0, fade + deltaTime / fadeTime);
}

function Color Faded(Color c)
{
	local Color r;

	r.R = c.R * fade;
	r.G = c.G * fade;
	r.B = c.B * fade;
	return r;
}

event DrawWindow(GC gc)
{
	local float y;

	if (title == "" && body == "")
		return;

	// il fondo: sempre piu' scuro
	gc.SetStyle(DSTY_Modulated);
	gc.DrawStretchedTexture(0, 0, width, height, FClamp(fade * 127, 0, 126), 0, 1, 8, Texture'UCFade');
	// il filetto e il testo: sempre piu' luminosi
	gc.SetStyle(DSTY_Translucent);
	gc.SetTileColor(Faded(colEdge));
	gc.DrawPattern(0, height - 1, width, 1, 0, 0, Texture'Solid');

	gc.EnableTranslucentText(True);
	gc.EnableWordWrap(True);
	gc.SetAlignments(HALIGN_Center, VALIGN_Top);
	y = margin;
	if (title != "")
	{
		gc.SetFont(fontTitle);
		gc.SetTextColor(Faded(colTitle));
		gc.DrawText(margin, y, width - 2 * margin, titleHeight, title);
		y += titleHeight + gap;
	}
	if (body != "")
	{
		gc.SetFont(fontBody);
		gc.SetTextColor(Faded(colBody));
		gc.DrawText(margin, y, width - 2 * margin, height - y, body);
	}
}

defaultproperties
{
     fontTitle=Font'DeusExUI.FontMenuHeaders'
     fontBody=Font'DeusExUI.FontConversationLarge'
     colTitle=(R=255,G=200,B=60)
     colBody=(R=255,G=255,B=255)
     colEdge=(R=255,G=200,B=60)
     margin=6.000000
     gap=2.000000
     fade=1.000000
     fadeTime=2.200000
}
