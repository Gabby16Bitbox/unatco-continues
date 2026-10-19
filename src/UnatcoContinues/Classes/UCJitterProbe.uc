//=============================================================================
// UCJitterProbe - photo tool helper (UCShotRunner step "track"): for some seconds it logs, every
// frame, where an actor is and where the view looks, to measure how smooth a moving shot is
// (Gabby, 15 Oct: the helicopter "vibrates" in cutscenes). One line per frame in the log:
// "UCJitter t dt x y z err" with err = angle in degrees between the view direction and the line
// from the eye to the actor (+20 up, where the scene cameras aim). The eye is the cutscene camera's
// shot position when JC views through a UCCam, else JC's own eye.
//=============================================================================
class UCJitterProbe extends Actor
	transient;

var Actor target;
var float timeLeft, t;

function Track(Actor A, float seconds)
{
	target = A;
	timeLeft = seconds;
	t = 0;
	Log("UCJitter start" @ A @ seconds);
}

event Tick(float dt)
{
	local DeusExPlayer P;
	local UCCam cam;
	local vector eye, toTarget;
	local float err;

	if (target == None || timeLeft <= 0)
		return;
	P = DeusExPlayer(GetPlayerPawn());
	if (P == None)
		return;
	t += dt;
	timeLeft -= dt;
	cam = UCCam(P.ViewTarget);
	if (cam != None)
		eye = cam.shotPosition;
	else
		eye = P.Location + vect(0,0,1) * P.BaseEyeHeight;
	toTarget = Normal(target.Location + vect(0,0,20) - eye);
	err = FClamp(vector(P.ViewRotation) dot toTarget, 0.01, 1);   // UE1 has no ACos
	err = Atan(Sqrt(1 - err * err) / err) * 57.2958;
	Log("UCJitter" @ t @ dt @ target.Location.X @ target.Location.Y @ target.Location.Z @ err);
	if (timeLeft <= 0)
		Log("UCJitter end");
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
