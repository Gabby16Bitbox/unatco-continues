// Per-light state shared by all links. No fixed-size limit for room-wide actions.
class UCLightMemory extends Info;

var Actor Target;
var ELightType OriginalType;

defaultproperties
{
     bHidden=True
     bStatic=False
}
