// Cooked map choice. No possession of an NPC and no changes to the game's INIs.
// A transient guard re-applies appearance after loading a save/cached level.
class UCPlayerMap extends Info;

var() string ProfileID;
var() name ProfileFlag;
var() bool bUseOriginal;
var transient bool bApplied;

function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(0.2, True);
}

function UCPlayerIdentity FindIdentity(DeusExPlayer P)
{
    local UCPlayerIdentity identity;
    foreach AllActors(class'UCPlayerIdentity', identity)
        if (identity.Owner == P) return identity;
    return None;
}

function Timer()
{
    local DeusExPlayer P;
    local UCPlayerIdentity identity;
    if (bApplied || Level.NetMode != NM_Standalone) return;
    P = DeusExPlayer(GetPlayerPawn());
    if (P == None || P.FlagBase == None || P.Health <= 0) return;
    identity = FindIdentity(P);
    if (identity == None)
    {
        // Default maps need no actor until the project actually chooses a profile.
        if (bUseOriginal)
        {
            if (ProfileFlag != '') P.FlagBase.SetBool(ProfileFlag, True,, 99);
            bApplied=True;
            return;
        }
        identity = Spawn(class'UCPlayerIdentity', P);
        if (identity != None) identity.GiveTo(P);
    }
    if (identity == None) return;
    identity.Apply(P, Self);
    bApplied=True;
}

defaultproperties
{
     ProfileID="jc"
     ProfileFlag=UCEdPlayer_jc
     bUseOriginal=True
     RemoteRole=ROLE_None
     bGameRelevant=True
}
