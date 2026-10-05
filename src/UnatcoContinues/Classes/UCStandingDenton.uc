// Visible stand-in for this scene only: no walking AI, turning or idle fidgets.
class UCStandingDenton extends JCDouble transient;

function FreezePose()
{
	GotoState('ScenePose');
}

state ScenePose
{
	ignores Tick, AnimEnd, SeePlayer, HearNoise, Bump, Touch;
	function BeginState()
	{
		Velocity = vect(0,0,0);
		Acceleration = vect(0,0,0);
		DesiredRotation = Rotation;
		SetPhysics(PHYS_None);
		SetCollision(False, False, False);
		bCanTurnHead = False;
		bPlayIdle = False;
		bStasis = False;
		TweenAnim('Still', 0.15);
	}
}

defaultproperties
{
	bPlayIdle=False
	bCanTurnHead=False
}
