// Project-only identity. Preserve the actual Original/Revision player class and
// its BindName, movement, inventory and mission logic. This actor travels with it.
// UE1 exports the inventory chain, not arbitrary owned Info actors.
class UCPlayerIdentity extends Inventory;

var travel string ProfileID;
var travel name ProfileFlag;
// Travel's object exporter duplicates mesh/texture references as empty objects.
// Stable package paths survive travel and native saves without cloning assets.
var travel string OriginalMeshPath;
var travel string OriginalSkinsPath[8];
var travel string OriginalSkinPath;
var travel string OriginalTexturePath;
var travel bool bCaptured;

function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(0.5, True);
}

event TravelPostAccept()
{
    Super.TravelPostAccept();
    SetTimer(0.5, True);
}

function Restore(DeusExPlayer P)
{
    local int i;
    local mesh Body;
    Body=mesh(DynamicLoadObject(OriginalMeshPath, class'Mesh', True));
    if (Body == None) Body=P.Default.Mesh;
    P.Mesh = Body;
    P.Skin = LoadSkin(OriginalSkinPath);
    P.Texture = LoadSkin(OriginalTexturePath);
    for (i=0; i<8; i++) P.MultiSkins[i] = LoadSkin(OriginalSkinsPath[i]);
}

function texture LoadSkin(string Path)
{
    if (Path == "" || Path == "None") return None;
    return texture(DynamicLoadObject(Path, class'Texture', True));
}

function Timer()
{
    local UCPlayerMap M;
    local DeusExPlayer P;
    if (!bCaptured || ProfileID == "jc") return;
    P=DeusExPlayer(Owner);
    if (P == None || P.FlagBase == None) return;
    foreach AllActors(class'UCPlayerMap', M) return;
    // Leaving the project's rebuilt maps must not reskin the ordinary game.
    Restore(P);
    if (ProfileFlag != '') P.FlagBase.SetBool(ProfileFlag, False,, 99);
    ProfileID="jc";
    ProfileFlag='UCEdPlayer_jc';
    P.FlagBase.SetBool(ProfileFlag, True,, 99);
}

function Capture(DeusExPlayer P)
{
    local int i;
    if (bCaptured) return;
    OriginalMeshPath = string(P.Mesh);
    OriginalSkinPath = string(P.Skin);
    OriginalTexturePath = string(P.Texture);
    for (i=0; i<8; i++) OriginalSkinsPath[i] = string(P.MultiSkins[i]);
    bCaptured = True;
}

function Apply(DeusExPlayer P, UCPlayerMap M)
{
    local int i;
    Capture(P);
    if (M.bUseOriginal)
    {
        Restore(P);
    }
    else
    {
        P.Mesh = M.Mesh;
        P.Skin = M.Skin;
        P.Texture = M.Texture;
        for (i=0; i<8; i++) P.MultiSkins[i] = M.MultiSkins[i];
    }
    if (P.FlagBase != None)
    {
        if (ProfileFlag != '' && ProfileFlag != M.ProfileFlag)
            P.FlagBase.SetBool(ProfileFlag, False,, 99);
        if (M.ProfileFlag != '') P.FlagBase.SetBool(M.ProfileFlag, True,, 99);
    }
    ProfileID = M.ProfileID;
    ProfileFlag = M.ProfileFlag;
    Log("DeusEdix player profile:" @ ProfileID @ "on" @ P.Class);
}

defaultproperties
{
     ProfileID="jc"
     ProfileFlag=UCEdPlayer_jc
     bDisplayableInv=False
     bHidden=True
     Physics=PHYS_None
     RemoteRole=ROLE_None
     bGameRelevant=True
     CollisionRadius=1.000000
     CollisionHeight=1.000000
     bCollideActors=False
     bBlockActors=False
}
