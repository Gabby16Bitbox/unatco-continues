//=============================================================================
// UCBPFlareAgent - Battery Park: the Special Agent who marks Eva's landing zone (Gabby, 17 Oct 2026: the flare
// in front of the helicopter is lit by a Man in Black, who holds it up high to his left, arm straight, palm
// open, the flare in front of it; talked to, he tells JC to move and not waste time). UCSceneBatteryPark
// places him by the clearing after Simons's call (out of JC's sight) and calls LightUp when JC comes near:
// he takes out a flare, strikes it and raises it (UCFlareLight), then holds it up (UCFlareHold). Both made in
// the map editor's Animation Studio on GM_Suit; the flare in his hand is a real flare (UCHeldFlare, made by the
// tracks UCTrackFlareLight/UCTrackFlareHold the scene places). Friendly to JC like the other agents (Tag
// UCSpecialAgent: shooting him breaks the loyal route). Without UCAnims (an old install) he just stands
// and the scene lights the flare on the ground as before.
//=============================================================================
class UCBPFlareAgent extends MIB;

var bool bLighting;     // striking it (UCFlareLight)
var bool bHolding;      // holding it up (UCFlareHold): kept through talks, saved with him

// Placed in the map (the editor's Hierarchy) he is a MIB, hostile to JC by birth: friendly as the scene's agents
// are (not for ever: shooting him makes him hostile and ends the route). Out of the world (bInWorld False in
// the map) until UCSceneBatteryPark brings him in.
function InitializeAlliances()
{
	Super.InitializeAlliances();
	ChangeAlly('Player', 1.0, False);
}

function bool UseFlareModel()
{
	local Mesh M;

	if (Mesh != None && Mesh.Outer.Name == 'UCAnims')
		return HasAnim('UCFlareHold');
	M = Mesh(DynamicLoadObject("UCAnims.GM_Suit", class'Mesh', True));
	if (M == None)
		return False;
	Mesh = M;
	return HasAnim('UCFlareHold') && HasAnim('UCFlareLight');
}

// the scene: JC is coming, light it
function LightUp()
{
	if (bLighting || bHolding || !UseFlareModel())
		return;
	bLighting = True;
	PlayAnim('UCFlareLight', 1.0, 0.2);
}

// The strike played to its end (Standing's AnimEnd calls PlayWaiting then): from now on he holds it up.
function bool KeepPose()
{
	if (bLighting)
	{
		if (AnimSequence == 'UCFlareLight' && !bAnimFinished && AnimFrame < 0.95)
			return True;
		bLighting = False;
		bHolding = True;
	}
	if (bHolding && UseFlareModel())
	{
		if (AnimSequence != 'UCFlareHold')
			LoopAnim('UCFlareHold', 1.0, 0.15);
		return True;
	}
	return False;
}

// standing, turning to JC and talking all keep the flare up
function PlayWaiting()
{
	if (!KeepPose())
		Super.PlayWaiting();
}

function TweenToWaiting(float tweentime)
{
	if (!KeepPose())
		Super.TweenToWaiting(tweentime);
}

function PlayTurning()
{
	if (!KeepPose())
		Super.PlayTurning();
}

function PlayIdle()
{
	if (!KeepPose())
		Super.PlayIdle();
}

function LoopBaseConvoAnim()
{
	if (!KeepPose())
		Super.LoopBaseConvoAnim();
}

defaultproperties
{
	FamiliarName="Special Agent"
	UnfamiliarName="Special Agent"
}
