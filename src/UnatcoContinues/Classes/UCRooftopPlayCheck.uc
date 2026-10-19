// Opt-in trial of the Special Projects building (06_HongKong_WanChai_Rooftop): real player
// capsule moves, native Frob, the lift ride roof -> dock -> roof, the raid and the cargo label.
// Started by the photo tool: console "summon UnatcoContinues.UCRooftopPlayCheck".
class UCRooftopPlayCheck extends UCScene transient;
var int checked,failed,stairStep;
var name lastSpeech,lastPlayback;
var float advanceAt,waitUntil;
var vector spot;
function Check(bool ok,string description)
{
    checked++; if (!ok) failed++;
    Log("UCRooftopPlayCheck|" $ description $ "|" $ ok);
    Plr().FlagBase.SetInt('UC_RooftopChecks',Plr().FlagBase.GetInt('UC_RooftopChecks')+1,,99);
    if (!ok) Plr().FlagBase.SetInt('UC_RooftopFailures',Plr().FlagBase.GetInt('UC_RooftopFailures')+1,,99);
}
event Tick(float dt)
{
    local ConEventSpeech speech;
    local Sound voice;
    if (Plr()==None || Plr().conPlay==None)
    { lastSpeech=''; lastPlayback=''; return; }
    if (!Plr().conPlay.IsInState('WaitForInput')) return;
    speech=ConEventSpeech(Plr().conPlay.currentEvent);
    if (speech==None) return;
    if (lastSpeech!=speech.Name || lastPlayback!=Plr().conPlay.Name)
    {
        lastSpeech=speech.Name; lastPlayback=Plr().conPlay.Name;
        voice=class'UCVoice'.static.Find(speech.conSpeech.speech,class'UCVoice'.static.Profile(speech.speaker,speech.speakerName));
        advanceAt=Level.TimeSeconds+FMax(1.0,GetSoundDuration(voice)+0.3);
    }
    if (Level.TimeSeconds>=advanceAt) Plr().conPlay.PlayNextEvent();
}
function UCSceneHKArrival Flow()
{
    local UCSceneHKArrival f;
    foreach AllActors(class'UCSceneHKArrival',f) return f;
    return None;
}
function string MapName()
{
    local DeusExLevelInfo info;
    foreach AllActors(class'DeusExLevelInfo',info) return Caps(info.MapName);
    return "";
}
function Actor Tagged(name tagName)
{
    local Actor A;
    foreach AllActors(class'Actor',A,tagName) return A;
    return None;
}
function UCTransitButton Button(bool bDock)
{
    local UCTransitButton b;
    foreach AllActors(class'UCTransitButton',b) if (b.bToRoof==bDock) return b;
    return None;
}
function int DoorKey(name tagName)
{
    local DeusExMover m;
    foreach AllActors(class'DeusExMover',m,tagName) return m.KeyNum;
    return -1;
}
function ReadCargo()
{
    local UCFileCube cube;
    foreach AllActors(class'UCFileCube',cube)
        if (cube.document=='Shipment')
        {
            Check(Plr().SetLocation(cube.Location+vect(90,0,30)),"cargo label is physically accessible");
            cube.Frob(Plr(),None);
            Plr().SetPause(False);
            return;
        }
    Check(False,"cargo label exists");
}
function bool RaidersHostile()
{
    local UCYardRaider r;
    local int n;
    foreach AllActors(class'UCYardRaider',r)
    {
        if (r.GetAllianceType('Player')!=ALLIANCE_Hostile) return False;
        n++;
    }
    return n>0;
}
function bool InfoShown()
{
    local DeusExRootWindow root;
    root=DeusExRootWindow(Plr().rootWindow);
    return root!=None && root.hud!=None && root.hud.infolink!=None;
}
function Complete()
{
    Log("UCRooftopPlayCheck:" @ Plr().FlagBase.GetInt('UC_RooftopChecks') @ "checked," @ Plr().FlagBase.GetInt('UC_RooftopFailures') @ "failed");
    SetF('UC_RooftopProofComplete',True); SetF('UC_RooftopProofActive',False);
}
state Playing
{
Begin:
    Sleep(2);
    if (Plr()==None || Flow()==None) Goto('Begin');
    SetF('UC_RooftopProofActive',True);
    Check(MapName()=="06_HONGKONG_WANCHAI_ROOFTOP","the Special Projects building is the arrival map");
EvaWait:
    if (Plr().conPlay!=None) { Sleep(0.5); Goto('EvaWait'); }
    Sleep(1);
    if (Plr().conPlay!=None) Goto('EvaWait');
    Check(GetF('UC_EvaRooftop_Played'),"Eva's arrival exchange plays at the helicopter");
    // down the pad steps on foot
    Check(Plr().SetLocation(vect(128,-240,80)),"the helipad supports the player");
    for (stairStep=0; stairStep<6; stairStep++) { Plr().Move(vect(0,48,0)); Sleep(0.3); }
    Check(Plr().Location.Y>-112 && Plr().Location.Z<60,"the pad step leads down to the roof without a jump");
    // the liaison
    spot=Tagged('UCRoofLiaison').Location;
    Check(Plr().SetLocation(spot+vect(120,0,0)),"the liaison is reachable on the roof");
    Sleep(2);
LiaisonWait:
    if (Plr().conPlay!=None) { Sleep(0.5); Goto('LiaisonWait'); }
    Check(GetF('UC_RoofLiaisonMet'),"walking up to the liaison plays his dialogue");
    // the checkpoint opens for JC
    spot=Tagged('UCRoofCheckpoint').Location;
    spot.X+=170; spot.Z=48;
    Check(Plr().SetLocation(spot),"the checkpoint is reachable");
    spot=Tagged('UCRoofCheckpoint').Location;
    Sleep(3);
    Check(DoorKey('UCRoofCheckpoint')==1,"the checkpoint door opens for Agent Denton");
    // the guard's "You're cleared" plays first, then Simons calls
    waitUntil=Level.TimeSeconds+20;
BriefingStart:
    if (!GetF('UC_HK_SimonsBriefing') && Level.TimeSeconds<waitUntil) { Sleep(0.5); Goto('BriefingStart'); }
    Check(GetF('UC_HK_SimonsBriefing'),"Simons's briefing starts at the checkpoint");
    for (stairStep=0; stairStep<8; stairStep++) { Plr().Move(vect(-48,0,0)); Sleep(0.2); }
    Check(Plr().Location.X<spot.X-60,"the player walks through the checkpoint into the lobby");
BriefingWait:
    if (!GetF('UC_HK_SimonsDone')) { Sleep(0.5); Goto('BriefingWait'); }
    // the lift: roof cabin -> dock cabin
    spot=Button(False).Location;
    spot.X-=150; spot.Y-=20; spot.Z=48;
    Check(Plr().SetLocation(spot),"the passenger stands in the roof cabin");
    Sleep(1);
    Button(False).Frob(Plr(),None);
    Check(Flow().bLiftBusy,"the cabin button starts the descent");
    Sleep(14);
    Check(VSize(Plr().Location-Button(True).Location)<400,"the ride ends in the dock cabin");
    Check(GetF('UCHongKongRooftopArrival'),"the arrival in the loading dock is recorded");
    Check(DoorKey('UCDockLiftDoor')==1,"the dock lift door opens on arrival");
    Check(!GetF('HongKongShipmentInspected'),"the arrival does not invent cargo knowledge");
    // out into the dock: the briefing, then the raid
    spot=Tagged('UCYardLiaison').Location;
    Check(Plr().SetLocation(spot+vect(0,-130,0)),"the dock liaison is reachable");
YardInfo:
    if (InfoShown()) { Sleep(0.5); Goto('YardInfo'); }
    Sleep(3);
YardWait:
    if (Plr().conPlay!=None) { Sleep(0.5); Goto('YardWait'); }
    Check(GetF('UC_YardBriefingHeard'),"the dock liaison briefs JC about the convoy");
    Plr().ReducedDamageType='All';    // the raiders shoot at JC now: the trial must not end with him dead
    Check(Plr().SetLocation(Tagged('UCTransportVan').Location+vect(300,250,0)),"the loading dock floor is walkable");
    Sleep(3);
    Check(GetF('UCHongKongRaidStarted'),"stepping into the dock starts the diversion");
    Check(RaidersHostile(),"the Luminous Path raiders are enemies of JC");
    Check(!GetF('UCHongKongShipmentDefended'),"presence alone does not count as defending the shipment");
    Sleep(6);
    ReadCargo();
    Sleep(1);
    Check(GetF('HongKongShipmentInspected'),"reading the cargo label records the VersaLife clue");
    Sleep(36);
    Check(GetF('UCHongKongRaidResolved'),"the raid ends without killing every attacker");
    // and back up
    spot=Button(True).Location;
    spot.X-=150; spot.Y-=20; spot.Z=48;
    Check(Plr().SetLocation(spot),"the passenger stands in the dock cabin");
ReturnWait:
    if (Plr().conPlay!=None) { Sleep(1); Goto('ReturnWait'); }
    Button(True).Frob(Plr(),None);
    Sleep(14);
    Check(VSize(Plr().Location-Button(False).Location)<400,"the return ride ends in the roof cabin");
    Check(GetF('HongKongShipmentInspected'),"cargo knowledge survives the ride");
    Plr().ReducedDamageType='';
    Complete();
    Destroy();
}
defaultproperties
{
    bHidden=True
    bAlwaysTick=True
}
