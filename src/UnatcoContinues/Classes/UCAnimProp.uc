// An inert render-only accessory. Never spawn the real inventory/decoration actor.
class UCAnimProp extends Actor;

var UCAnimPropTrack Track;
var ScriptedPawn Who;
var float BaseScale;
var vector AnchorLocation;
var rotator AnchorRotation;
var float AnchorScale;

function Bind(UCAnimPropTrack T, ScriptedPawn P)
{
    local int I;
    Track = T;
    Who = P;
    AnchorLocation = P.Location;
    AnchorRotation = P.Rotation;
    AnchorScale = P.DrawScale;
    Mesh = T.Appearance.default.Mesh;
    Skin = T.Appearance.default.Skin;
    Texture = T.Appearance.default.Texture;
    Style = T.Appearance.default.Style;
    ScaleGlow = T.Appearance.default.ScaleGlow;
    PrePivot = T.Appearance.default.PrePivot;
    for (I = 0; I < 8; I++)
        MultiSkins[I] = T.Appearance.default.MultiSkins[I];
    BaseScale = T.Appearance.default.DrawScale * T.PropScale;
    Tick(0);
}

function int BlendAngle(int A, int B, float Alpha)
{
    local int D;
    D = (B - A) & 65535;
    if (D > 32767)
        D -= 65536;
    return A + int(float(D) * Alpha);
}

function Tick(float DeltaTime)
{
    local float Frame, Alpha;
    local int First, Second;
    local vector A, B, X, Y, Z, Origin;
    local rotator R, S, WorldRot, Basis;
    local float Size;
    if (Track == None || !Track.Matches(Who))
    {
        Destroy();
        return;
    }
    // Negative AnimFrame is engine tweening between sequences: do not float through an unrelated pose.
    if (Who.AnimFrame < 0)
    {
        bHidden = True;
        return;
    }
    Frame = FClamp(Who.AnimFrame * Track.FrameCount, 0, Track.FrameCount - 0.0001);
    First = int(Frame);
    Second = First + 1;
    Alpha = Frame - First;
    if (Second >= Track.FrameCount)
    {
        if (Who.bAnimLoop)
            Second = 0;
        else
            Second = First;
    }
    if (!Track.Sample(First, A, R) || !Track.Sample(Second, B, S))
    {
        bHidden = True;
        return;
    }
    R.Pitch = BlendAngle(R.Pitch, S.Pitch, Alpha);
    R.Yaw = BlendAngle(R.Yaw, S.Yaw, Alpha);
    R.Roll = BlendAngle(R.Roll, S.Roll, Alpha);
    Origin = Who.Location;
    Basis = Who.Rotation;
    Size = Who.DrawScale;
    if (Track.bSceneSpace)
    {
        Origin = AnchorLocation;
        Basis = AnchorRotation;
        Size = AnchorScale;
    }
    GetAxes(R, X, Y, Z);
    WorldRot = OrthoRotation(X >> Basis, Y >> Basis, Z >> Basis);
    SetRotation(WorldRot);
    SetLocation(Origin + ((A + (B - A) * Alpha) * Size >> Basis));
    DrawScale = BaseScale * Size;
    bHidden = False;
}

defaultproperties
{
     bHidden=True
     RemoteRole=ROLE_None
     DrawType=DT_Mesh
     CollisionRadius=0.000000
     CollisionHeight=0.000000
}
