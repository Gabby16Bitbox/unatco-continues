// Private headless snapshot. Never installed into the user's game.
class UCBridgeSnapshot extends Actor transient;

var bool bPrepared;
var int count;

function string Safe(string value)
{
    local string result;
    local int i;
    for (i = 0; i < Len(value); i++)
        if (Mid(value, i, 1) == "|")
            result = result $ "/";
        else
            result = result $ Mid(value, i, 1);
    return result;
}

function Prepare()
{
    local DeusExLevelInfo info;
    local UCMod mod;
    local UCHKWorld world;
    local UCHKStory story;
    local string mapName, mode;

    mode = GetConfig("UCMapBridge", "Mode");
    foreach AllActors(class'DeusExLevelInfo', info)
        mapName = Caps(info.mapName);
    Log("UCBridgeMap|" $ mapName $ "|" $ mode);
    if (mode != "hk_setup")
        return;
    if (mapName == "06_HONGKONG_HELIBASE")
    {
        mod = Spawn(class'UCMod');
        if (mod != None)
        {
            mod.SetTimer(0, False);
            mod.OpenHelibase();
        }
    }
    else if (Left(mapName, 3) == "06_")
    {
        world = Spawn(class'UCHKWorld');
        if (world != None)
        {
            world.SetTimer(0, False);
            world.mapName = mapName;
            world.bFirstVisit = True;
            world.bSetup = True;
            world.Setup();
            world.Attitudes();
        }
        story = Spawn(class'UCHKStory');
        if (story != None)
        {
            story.SetTimer(0, False);
            story.mapName = mapName;
            story.bSetup = True;
            story.SetupForMap();
        }
    }
}

function Timer()
{
    local Actor a;
    local ScriptedPawn pawn;
    local string extra;
    if (!bPrepared)
    {
        bPrepared = True;
        Prepare();
        SetTimer(0.5, False);
        return;
    }
    foreach AllActors(class'Actor', a)
    {
        extra = "";
        pawn = ScriptedPawn(a);
        if (pawn != None)
            extra = Safe(pawn.FamiliarName) $ "|" $ pawn.BarkBindName;
        else
            extra = "|";
        Log("UCBridgeActor|" $ a.Name $ "|" $ a.Class $ "|" $ a.Tag $ "|" $ a.Event
            $ "|" $ a.Location.X $ "|" $ a.Location.Y $ "|" $ a.Location.Z
            $ "|" $ a.Rotation.Pitch $ "|" $ a.Rotation.Yaw $ "|" $ a.Rotation.Roll
            $ "|" $ a.bHidden $ "|" $ a.bCollideActors $ "|" $ a.bBlockActors
            $ "|" $ a.bBlockPlayers $ "|" $ extra);
        count++;
    }
    Log("UCBridgeDone|" $ count);
    ConsoleCommand("exit");
}

function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(0.5, False);
}

defaultproperties
{
    bHidden=True
    bAlwaysTick=True
}
