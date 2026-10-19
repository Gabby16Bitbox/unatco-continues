// Baked bone-space trajectory. Root chunks manage visual followers; other chunks hold data only.
class UCAnimPropTrack extends Info;

var() bool bRoot;
var() bool bSceneSpace;
var() name AnimationName, ModelName, ModelPackage, NextName;
var() string PropClass;
var() float PropScale;
var() int FrameCount, StartFrame, SampleCount;
var() vector Positions[64];
var() rotator Rotations[64];
var UCAnimPropTrack NextTrack;
var class<Actor> Appearance;
var bool bLinked;

function PostBeginPlay()
{
    Super.PostBeginPlay();
    if (bRoot)
        SetTimer(0.1, True);
}

function bool Matches(ScriptedPawn P)
{
    return P != None && !P.bDeleteMe && P.Health > 0 && !P.bHidden
        && P.Mesh != None && P.Mesh.Name == ModelName && P.Mesh.Outer.Name == ModelPackage
        && P.AnimSequence == AnimationName;
}

function LinkChunks()
{
    local UCAnimPropTrack T, N;
    local int Guard;
    T = Self;
    while (T != None && T.NextName != '' && Guard < 100)
    {
        Guard++;
        foreach AllActors(class'UCAnimPropTrack', N)
            if (N.Name == T.NextName)
            {
                T.NextTrack = N;
                break;
            }
        T = T.NextTrack;
    }
    Appearance = class<Actor>(DynamicLoadObject(PropClass, class'Class', True));
    bLinked = True;
}

function Timer()
{
    local ScriptedPawn P;
    local UCAnimProp A, Existing;
    if (!bRoot)
        return;
    if (!bLinked)
        LinkChunks();
    if (Appearance == None || Appearance.default.Mesh == None)
    {
        SetTimer(0, False);
        return;
    }
    foreach AllActors(class'ScriptedPawn', P)
    {
        if (!Matches(P))
            continue;
        Existing = None;
        foreach ChildActors(class'UCAnimProp', A)
            if (!A.bDeleteMe && A.Who == P)
            {
                Existing = A;
                break;
            }
        if (Existing == None)
        {
            A = Spawn(class'UCAnimProp', Self,, P.Location);
            if (A != None)
                A.Bind(Self, P);
        }
    }
}

function ReadLocal(int I, out vector Pos, out rotator Rot)
{
    Pos = Positions[I];
    Rot = Rotations[I];
}

function bool Sample(int Frame, out vector Pos, out rotator Rot)
{
    local UCAnimPropTrack T;
    local int I, Guard;
    T = Self;
    while (T != None && Guard < 100)
    {
        I = Frame - T.StartFrame;
        if (I >= 0 && I < T.SampleCount && I < 64)
        {
            T.ReadLocal(I, Pos, Rot);
            return True;
        }
        T = T.NextTrack;
        Guard++;
    }
    return False;
}

defaultproperties
{
     PropScale=1.000000
     RemoteRole=ROLE_None
}
