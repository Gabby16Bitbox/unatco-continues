//=============================================================================
// UCCam - telecamera invisibile per le cutscene (il giocatore la usa come ViewTarget).
//=============================================================================
class UCCam extends Actor
	transient;

var vector shotPosition, shotFocus;
var bool bExactShot;

static function vector ProxyPosition(vector position, vector focus)
{
	// PlayerPawn.CalcBehindView ignores ViewTarget.Rotation and subtracts
	// 180 - 30 units along the player's ViewRotation. Compensate explicitly.
	return position + Normal(focus - position) * 150;
}

function SetShot(vector position, vector focus)
{
	shotPosition = position;
	shotFocus = focus;
	bExactShot = True;
	SetLocation(ProxyPosition(position, focus));
	SetRotation(rotator(focus - position));
}

function ApplyView(DeusExPlayer P)
{
	if (P != None && bExactShot)
		P.ViewRotation = rotator(shotFocus - shotPosition);
}

event Tick(float deltaTime)
{
	local DeusExPlayer P;
	P = DeusExPlayer(GetPlayerPawn());
	if (P != None && P.ViewTarget == Self)
		ApplyView(P);
}

defaultproperties
{
     bHidden=True
	 bAlwaysTick=True
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
