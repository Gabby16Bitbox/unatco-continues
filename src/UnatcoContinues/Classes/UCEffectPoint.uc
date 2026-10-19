//=============================================================================
// UCEffectPoint - an effect point placed with the map editor (Objects > Triggers > Effect point): an
// invisible spot for the effects of the interactions ("An effect on it", UCLink's effect, UCEffect).
// An effect put on it sits exactly here, and its rotation is the way the effect goes: mist, smoke,
// sparks and the flames of a fire are blown along its forward vector (the big arrow of the editor),
// a blinking or pulsing light shines from this spot. By itself it does nothing.
//=============================================================================
class UCEffectPoint extends Keypoint;

defaultproperties
{
     bStatic=False
     bDirectional=True
}
