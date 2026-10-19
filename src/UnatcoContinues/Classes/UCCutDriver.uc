//=============================================================================
// UCCutDriver - while a UCCutscene plays, it puts the camera at its place once more at the end of every
// frame. Spawned when the cutscene starts, it comes last in the level's list of actors, so it ticks after
// JC's own physics (his falling would drop the view a little, more at a low frame rate) and after what the
// camera looks at has moved (a UCMotion, a character: the aim is where it is now, not where it was).
//=============================================================================
class UCCutDriver extends Info
	transient;

var UCCutscene Cut;

function Tick(float dt)
{
	if (Cut == None || Cut.bDeleteMe || !Cut.bPlaying || Cut.Driver != Self)
	{
		Destroy();
		return;
	}
	if (Cut.P != None && !Cut.P.bDeleteMe)
		Cut.Apply(Cut.T);
}
