//=============================================================================
// UCMotionCheckCut - the cutscene of UCMotionCheck: a UCCutscene whose keys it sets itself (UnrealScript
// cannot write an array this large through another object).
//=============================================================================
class UCMotionCheckCut extends UCCutscene;

function Init(vector base, string look)
{
	CutName = "check";
	NumKeys = 3;
	KeyT[0] = 0;
	KeyP[0] = base + vect(0,0,40);
	KeyT[1] = 3.5;
	KeyP[1] = base + vect(500,300,300);
	KeyT[2] = 7;
	KeyP[2] = base + vect(-400,500,150);
	KeyE[0] = 1;
	KeyE[1] = 1;
	KeyE[2] = 1;
	LookAt = look;
	Length = 7;
	bSkippable = False;
}
