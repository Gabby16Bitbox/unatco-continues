//=============================================================================
// UCCam - telecamera invisibile per le cutscene (il giocatore la usa come ViewTarget).
//=============================================================================
class UCCam extends Actor
	transient;

var vector shotPosition, shotFocus;
var bool bExactShot;
var Actor trackActor;      // aimed at every frame (Track): a moving target stays steady in the shot
var vector trackOffset;

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

// Follow an actor from the shot's position, re-aiming every frame (in Tick). Aiming from a scene's
// latent code (a Sleep loop, 20 times a second) made a moving helicopter judder in the shot while
// it moved every frame (Gabby, 15 Oct).
function Track(Actor A, vector offset)
{
	trackActor = A;
	trackOffset = offset;
	if (A != None)
		SetShot(shotPosition, A.Location + offset);
}

function ApplyView(DeusExPlayer P)
{
	if (P != None && bExactShot)
		P.ViewRotation = rotator(shotFocus - shotPosition);
}

event Tick(float deltaTime)
{
	local DeusExPlayer P;

	// the camera is spawned when the cutscene starts, after the scene and what it moves: it ticks
	// after them, so it aims at where the target is this frame
	if (trackActor != None && !trackActor.bDeleteMe)
		SetShot(shotPosition, trackActor.Location + trackOffset);
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
