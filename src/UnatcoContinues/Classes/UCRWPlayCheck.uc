// Opt-in real-player trial: summon only from the guarded photographer workspace.
// Uses native login and special-option buttons, not synthetic assault flags.
class UCRWPlayCheck extends UCScene;

var int checked, failed;
var float elapsed;
var name inputEvent, inputPlayback;
var float advanceAt;
var float diagnosticAt;
var bool bPrisonerPositioned;
var bool bIgnorePrisoner,bSkipCopy,bKillTong;

function Check(bool ok, string description)
{
    checked++;
    Log("UCRWPlayCheck|" $ description $ "|" $ ok);
    if (!ok) failed++;
}

// Simulate a player's click after each recording, leaving native choices untouched.
event Tick(float deltaTime)
{
    local DeusExPlayer P;
    local ConEventSpeech speech;
    local Sound voice;
    local ScriptedPawn sp;
    local UCFileCube cube;
    P=Plr();
    if (GetF('UC_SPEntryCrossed') && Level.TimeSeconds>diagnosticAt)
    {
        diagnosticAt=Level.TimeSeconds+10;
        Log("UCRWPlayCheck|scene" @ P.Location @ P.GetStateName() @ P.conPlay @ GetF('UC_AssaultWave2Spawned'));
        foreach AllActors(class'ScriptedPawn',sp)
            if (sp.Tag=='UCPrisoner' || sp.Tag=='UCSPCommander' || sp.Tag=='UCSPTech')
                Log("UCRWPlayCheck|actor" @ sp.Tag @ sp.Location @ sp.Health @ sp.bInWorld @ sp.GetStateName() @ sp.bInitialized @ sp.Enemy @ sp.Weapon);
        foreach AllActors(class'UCFileCube',cube)
            Log("UCRWPlayCheck|record" @ cube.Tag @ cube.Location);
    }
    if (GetF('UC_AssaultWave2Spawned') && !bPrisonerPositioned)
    {
        if (bIgnorePrisoner) bPrisonerPositioned=P.SetLocation(vect(-400,100,48));
        else bPrisonerPositioned=P.SetLocation(vect(1330,170,-190));
        P.ViewTarget=None; P.bBehindView=False;
        P.ViewRotation=rot(0,5000,0); P.SetRotation(P.ViewRotation);
        Log("UCRWPlayCheck|position prisoner" @ bPrisonerPositioned @ P.Location);
    }
    if (P==None || P.conPlay==None || !P.conPlay.IsInState('WaitForInput')) return;
    speech=ConEventSpeech(P.conPlay.currentEvent);
    if (speech==None) return;
    if (inputEvent!=speech.Name || inputPlayback!=P.conPlay.Name)
    {
        inputEvent=speech.Name; inputPlayback=P.conPlay.Name;
        voice=class'UCVoice'.static.Find(speech.conSpeech.speech,class'UCVoice'.static.Profile(speech.speaker,speech.speakerName));
        advanceAt=Level.TimeSeconds+FMax(1.5,GetSoundDuration(voice)+0.4);
    }
    if (Level.TimeSeconds>=advanceAt) P.conPlay.PlayNextEvent();
}

function UCInvestigation Investigation()
{
    local UCInvestigation manager;
    foreach AllActors(class'UCInvestigation',manager) return manager;
    return None;
}

function bool ComputerButton(bool north, int index)
{
    local Computers pc;
    local DeusExPlayer P;
    local ComputerScreenLogin login;
    local ComputerScreenSpecialOptions options;
    local DeusExRootWindow root;
    local bool matched;
    local rotator look;
    P=Plr(); if (P==None) return False;
    root=DeusExRootWindow(P.rootWindow);
    foreach AllActors(class'Computers',pc)
        if ((north && pc.Tag=='UCNorthConsole') || (!north && VSize(pc.Location-vect(274,-28,49))<90)) { matched=True; break; }
    if (!matched || pc==None) return False;
    if (north) P.SetLocation(vect(280,-1010,48));
    else if (!P.SetLocation(vect(420,125,48)))
        P.SetLocation(vect(110,125,48));
    P.ViewTarget=None; P.bBehindView=False;
    look=rotator(pc.Location-P.Location);
    P.ViewRotation=look; P.SetRotation(look);
    // A remote scripted Frob must keep its animation ticking while repositioning.
    pc.bStasis=False;
    // Native Frob starts Activate/FinishAnim; wait across state ticks before login.
    if (pc.termwindow==None)
    {
        if (pc.curFrobber==None && !pc.bAnimating) pc.Frob(P,None);
        if (elapsed>=8) Log("UCRWPlayCheck|login timeout" @ pc @ pc.GetStateName() @ pc.bOn @ pc.bAnimating @ pc.curFrobber @ P.GetStateName() @ P.Location);
        return False;
    }
    login=ComputerScreenLogin(pc.termwindow.winComputer);
    if (login!=None)
    {
        login.editUserName.SetText(pc.UserList[0].userName);
        login.editPassword.SetText(pc.UserList[0].password);
        login.ProcessLogin();
    }
    options=ComputerScreenSpecialOptions(pc.termwindow.winComputer);
    if (options==None || options.optionButtons[index].btnSpecial==None) return False;
    options.ButtonActivated(options.optionButtons[index].btnSpecial);
    // Leave modal documents visible for screenshots while the trial clock runs.
    P.SetPause(False);
    return True;
}

function CloseDocument()
{
    local DeusExRootWindow root;
    root=DeusExRootWindow(Plr().rootWindow);
    if (MenuUIMessageBoxWindow(root.GetTopWindow())!=None)
        MenuUIMessageBoxWindow(root.GetTopWindow()).ButtonActivated(MenuUIMessageBoxWindow(root.GetTopWindow()).btnOK);
}

function PGoPrisoner()
{
    local DeusExPlayer P;
    P=Plr();
    P.ViewTarget=None; P.bBehindView=False;
    if (bIgnorePrisoner) P.SetLocation(vect(-400,100,48));
    else P.SetLocation(vect(1540,150,-190));
    P.ViewRotation=rot(0,24000,0); P.SetRotation(P.ViewRotation);
}

function CloseComputer()
{
    local Computers pc;
    CloseDocument();
    foreach AllActors(class'Computers',pc)
        if (pc.termwindow!=None) pc.termwindow.CloseScreen("EXIT");
}

function GateCollisionCheck(bool opened)
{
    local DeusExPlayer P;
    local vector before;
    local bool positioned;
    P=Plr();
    before=P.Location;
    positioned=P.SetLocation(vect(128,-1080,56));
    Check(positioned,"JC collision probe starts in the actual warehouse passage");
    if (positioned)
    {
        // Native Move sweeps the player's capsule; SetLocation alone cannot
        // prove a door prevents a player from walking through it.
        P.Move(vect(0,-208,0));
        if (opened) Check(P.Location.Y<-1240,"JC walks through the fully lowered wall");
        else Check(P.Location.Y>-1140,"closed wall physically blocks JC's swept movement");
        Log("UCRWPlayCheck|JC capsule" @ opened @ P.Location @ P.CollisionRadius @ P.CollisionHeight @ P.bCollideWorld);
    }
    P.SetLocation(before);
}

// Disposable actors and inventory in the private trial, never in normal gameplay.
function InventoryChecks()
{
    local DeusExPlayer P;
    local WeaponNanoSword sword;
    local MaxChen max;
    local GordonQuick gordon;
    local bool verified, convinced, ceasefire, murder;
    P=Plr();
    if (P.FindInventoryType(class'WeaponNanoSword')!=None) return;
    verified=GetF('UC_ChowSwordVerified'); convinced=GetF('MaxChenConvinced');
    ceasefire=GetF('UC_RedArrowCeasefire'); murder=GetF('UC_YuenCaseCorroborated');
    max=Spawn(class'MaxChen',,'UCTrialMax',vect(36,-900,48));
    gordon=Spawn(class'GordonQuick',,'UCTrialGordon',vect(220,-900,48));
    Check(max!=None && gordon!=None,"temporary inventory recipients spawned in valid space");
    Check(!Investigation().GiveSword('MaxChen') && !GetF('UC_SwordGivenMax'),"no weapon means no custody claim");
    sword=Spawn(class'WeaponNanoSword');
    if (sword==None) return;
    sword.GiveTo(P);
    SetF('UC_ChowSwordVerified',False);
    Check(!Investigation().GiveSword('MaxChen') && sword.Owner==P,"unverified weapon cannot be delivered");
    SetF('UC_ChowSwordVerified',True);
    Check(Investigation().GiveSword('MaxChen') && sword.Owner==max,"voluntary Max transfer changes actual inventory ownership");
    Check(P.FindInventoryType(class'WeaponNanoSword')==None && GetF('UC_SwordGivenMax'),"Max custody removes the player's weapon");
    Check(GetF('UC_YuenCaseCorroborated')==murder,"weapon delivery does not establish murder evidence");
    max.DeleteInventory(sword); sword.GiveTo(P);
    SetF('UC_SwordGivenMax',False);
    Check(Investigation().GiveSword('GordonQuick') && sword.Owner==gordon,"voluntary Gordon transfer changes actual inventory ownership");
    Check(GetF('UC_SwordGivenGordon') && !GetF('QuickConvinced'),"Gordon custody does not grant a global truce");
    if (sword.Owner==gordon) gordon.DeleteInventory(sword);
    sword.Destroy();
    max.Destroy(); gordon.Destroy();
    SetF('UC_SwordGivenMax',False); SetF('UC_SwordGivenGordon',False);
    SetF('UC_ChowSwordVerified',verified); SetF('MaxChenConvinced',convinced);
    SetF('UC_RedArrowCeasefire',ceasefire);
}

state Playing
{
Begin:
    if (Investigation()==None) { Sleep(0.25); Goto('Begin'); }
    SetF('UC_RWTrialActive',True);
    InventoryChecks();
    if (bKillTong) KillTong();
    // Finish any arrival conversation, then wait without sending/opening anything.
    Sleep(30);
    Check(!GetF('MJ12AssaultStarted'),"no raid while the player withholds authorization");
    Check(!GetF('UC_TongLocationReported'),"no automatic location report");
    GateCollisionCheck(False);
    elapsed=0;
OpenManifest:
    if (!ComputerButton(False,0) && elapsed<8) { Sleep(0.25); elapsed+=0.25; Goto('OpenManifest'); }
    Check(elapsed<8,"native login and read-manifest button");
    Check(GetF('UC_VLManifestRead') && !GetF('UC_VLManifestCopied'),"reading does not copy the archive");
    Sleep(6);
    CloseDocument();
    elapsed=0;
OpenCopy:
    if (bSkipCopy) { Check(!GetF('UC_VLManifestCopied'),"omitted copy command leaves no independent field copy"); Goto('NoCopy'); }
    if (!ComputerButton(False,1) && elapsed<8) { Sleep(0.25); elapsed+=0.25; Goto('OpenCopy'); }
    Check(elapsed<8,"native independent-copy button");
NoCopy:
    Check(GetF('UC_VLManifestCopied')!=bSkipCopy,"copy state reflects the player's chosen command");
    elapsed=0;
OpenPaul:
    if (!ComputerButton(False,3) && elapsed<8) { Sleep(0.25); elapsed+=0.25; Goto('OpenPaul'); }
    Check(elapsed<8,"native Paul archive-copy button");
    Check(GetF('UC_TongPaulCopyRead') && !GetF('UC_PaulManifestRead'),"archive copy never pretends to be a New York reading");
    Sleep(5);
    CloseDocument();
    elapsed=0;
OpenReport:
    if (!ComputerButton(False,2) && elapsed<8) { Sleep(0.25); elapsed+=0.25; Goto('OpenReport'); }
    Check(elapsed<8,"native report-location button");
    Sleep(0.5);
    elapsed=0;
WaitOrder:
    if (!GetF('UC_TransferOrderReceived') && elapsed<30) { Sleep(0.5); elapsed+=0.5; Goto('WaitOrder'); }
    Check(GetF('UC_TransferOrderReceived'),"Simons transfer order received");
    Sleep(20);
    Check(!GetF('MJ12AssaultStarted') && !GetF('UC_NorthAccessOpened'),"reported location alone does not launch a raid");
    elapsed=0;
OpenSecurity:
    if (!ComputerButton(True,0) && elapsed<8) { Sleep(0.25); elapsed+=0.25; Goto('OpenSecurity'); }
    Check(elapsed<8,"native security login and explicit team-entry button");
    Sleep(0.5);
    elapsed=0;
WaitDoor:
    if (!GetF('UC_NorthAccessOpened') && elapsed<8) { Sleep(0.25); elapsed+=0.25; Goto('WaitDoor'); }
    Check(GetF('UC_NorthAccessOpened'),"rear loading door reached open position");
    // Test before the approaching soldiers occupy the narrow doorway.
    GateCollisionCheck(True);
    elapsed=0;
WaitCross:
    if (!GetF('UC_SPEntryCrossed') && elapsed<40) { Sleep(0.5); elapsed+=0.5; Goto('WaitCross'); }
    Check(GetF('UC_SPEntryCrossed') && GetF('MJ12AssaultStarted'),"squad physically crossed before assault");
    elapsed=0;
    CloseComputer();
    // Stand beside the surgery-room confrontation and object through native dialogue.
    PGoPrisoner();
WaitSweep:
    if (!GetF('UC_SweepComplete') && elapsed<150) { Sleep(0.5); elapsed+=0.5; Goto('WaitSweep'); }
    if (bIgnorePrisoner) Check(GetF('JCIgnoredMJ12Execution') && !GetF('UC_PrisonerSaved') && PrisonerDead(),"ignored confrontation actually kills the detainee without inventing a rescue");
    else Check(GetF('UC_PrisonerSaved') && GetF('UC_PrisonerIdentityRecorded'),"objection saves the technician and records custody identity");
    Check(GetF('UC_SweepComplete'),"the actual assault sequence reaches the report stage");
    Check(GetF('UC_VLManifestCopied')!=bSkipCopy && !GetF('UC_FinalReportRequested'),"completed sweep preserves chosen provenance without sending a report");
    elapsed=0;
WaitWipe:
    if (!GetF('UC_TongPCWiped') && elapsed<60) { Sleep(0.5); elapsed+=0.5; Goto('WaitWipe'); }
    Check(GetF('UC_TongPCWiped') && GetF('UC_SPTeamRecordsRecovered'),"technician reaches the real archive and performs selective sanitization");
    elapsed=0;
WaitAfter:
    if (Talking() && elapsed<40) { Sleep(0.5); elapsed+=0.5; Goto('WaitAfter'); }
    elapsed=0;
OpenFinal:
    if (!ComputerButton(False,2) && elapsed<8) { Sleep(0.25); elapsed+=0.25; Goto('OpenFinal'); }
    Check(elapsed<8 && GetF('UC_FinalReportRequested'),"operation report is submitted by the native terminal button");
    elapsed=0;
WaitAssignment:
    if (!GetF('VersaLifeInvestigationAuthorized') && elapsed<50) { Sleep(0.5); elapsed+=0.5; Goto('WaitAssignment'); }
    Check(GetF('VersaLifeInvestigationAuthorized') && GetF('MJ12AssaultResolved'),"explicit report produces the authorized VersaLife assignment");
    SetF('UC_RWTrialComplete',True);
    SetF('UC_RWTrialPassed',failed==0);
    Log("UCRWPlayCheck:" @ checked @ "checked," @ failed @ "failed");
    Destroy();
}

function KillTong()
{
    local ScriptedPawn sp;
    foreach AllActors(class'ScriptedPawn',sp)
        if (sp.IsA('TracerTong')) sp.TakeDamage(3000,Plr(),sp.Location,vect(0,0,0),'Shot');
}

function bool PrisonerDead()
{
    local ScriptedPawn sp;
    local Carcass corpse;
    foreach AllActors(class'ScriptedPawn',sp,'UCPrisoner')
        if (sp.Health<=0) return True;
    foreach AllActors(class'Carcass',corpse)
        if (corpse.BindName=="UCPrisoner") return True;
    return False;
}
