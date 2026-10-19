// The Special Projects building in Wan Chai (06_HongKong_WanChai_Rooftop): roof -> checkpoint ->
// freight lift -> loading dock -> cargo raid -> service stair up to the butcher's shop of Wan Chai
// Street that fronts for the dock -> its roll-up grille (06_HongKong_WanChai_Street#UCSpecialProjects).
// Roof and dock are in the same map: the two lift cabins are identical, so the ride moves JC from
// one cabin to the other while the doors are shut (positions come from the two lift buttons).
// Flags describe observed events. Neither a kill count nor a dialogue is a gate.
class UCSceneHKArrival extends UCScene transient;

var bool bBriefing, bLiftBusy, bCleared;
var float raidTime;
var int bark;
var Conversation yardCon;

function ScriptedPawn PawnTag(name tagName)
{
    local ScriptedPawn npc;
    foreach AllActors(class'ScriptedPawn',npc,tagName)
        if (npc.Health>0 && npc.bInWorld) return npc;
    return None;
}
function Actor FirstTag(name tagName)
{
    local Actor A;
    foreach AllActors(class'Actor',A,tagName) return A;
    return None;
}
function UCTransitButton LiftButton(bool bDock)
{
    local UCTransitButton b;
    foreach AllActors(class'UCTransitButton',b)
        if (b.bToRoof==bDock) return b;
    return None;
}
function vector CasePoint()
{
    local Actor A;
    A=FirstTag('UCHKSecuredCase');
    if (A!=None) return A.Location;
    A=FirstTag('UCTransportVan');
    if (A!=None) return A.Location;
    return Plr().Location;
}
function bool AtDock()
{
    local UCTransitButton b;
    b=LiftButton(True);
    return b!=None && VSize(Plr().Location-b.Location)<4000;
}
function OpenDoor(name tagName, bool bOpen)
{
    local DeusExMover door;
    foreach AllActors(class'DeusExMover',door,tagName)
    {
        door.bLocked=False;
        if (door.KeyNum!=int(bOpen)) door.InterpolateTo(int(bOpen),door.MoveTime);
    }
}
function Friendly()
{
    local UCTransitGuard guard;
    foreach AllActors(class'UCTransitGuard',guard)
    {
        guard.ChangeAlly('Player',1.0,True);
        guard.ChangeAlly('UCTransport',1.0,True);
        guard.ChangeAlly('UCCargoRaid',-1.0,True);
        guard.ConListItems=None;
    }
}
function RoofTalks()
{
    local BlackHelicopter heli;
    local ScriptedPawn officer;
    local UCCon c;
    foreach AllActors(class'BlackHelicopter',heli,'chopper')
    {
        // the pilot is Eva (Jock is dead from Battery Park on): the cockpit exchange of the mission design
        // (docs: "Mission 6, Hong Kong: Opening", phase 1), then what she says if JC goes back to her
        heli.BindName="Eva";
        heli.FamiliarName="Eva";
        heli.UnfamiliarName="Eva";
        heli.ConListItems=None;
        class'UCSceneBatteryPark'.static.PaintEva(heli);   // her dark blue helicopter, as at Battery Park
        c=new(Level) class'UCCon';
        c.Begin('UC_EvaRooftop',"Eva",False);
        c.Once(); c.Radius(680); c.WideShot();
        c.Line("Eva","JCDenton","Harbourline Tower. I'm dropping you here and staying with the chopper.");
        c.Line("JCDenton","Eva","Copy that.");
        c.Line("Eva","JCDenton","My orders are to log when you come back. And who with.");
        c.Line("JCDenton","Eva","Simons' orders?");
        c.Line("Eva","JCDenton","Orders. Get out, Denton.");
        c.Done(); c.AttachTo(heli);
        c=new(Level) class'UCCon';
        c.Begin('UC_EvaRooftopAgain',"Eva",False);
        c.Once();
        c.Require('UC_EvaRooftop_Played',True);
        c.Line("Eva","JCDenton","I've got nothing to say to you, Denton.");
        c.Done(); c.AttachTo(heli);
        c=new(Level) class'UCCon';
        c.Begin('UC_EvaRooftopLast',"Eva",False);
        c.Require('UC_EvaRooftopAgain_Played',True);
        c.Line("Eva","JCDenton","Go. It's your brother's clock that's running, not mine.");
        c.Done(); c.AttachTo(heli);
    }
    officer=PawnTag('UCRoofLiaison');
    if (officer==None) return;
    officer.ConListItems=None;
    officer.BindName="UCHKOfficer";
    c=new(Level) class'UCCon';
    c.Begin('UC_RoofLiaison',"UCHKOfficer",False);
    c.Once(); c.Radius(180);
    c.Line("UCHKOfficer","JCDenton","Agent Denton? Hong Kong Operations. Your briefing is downstairs.");
    c.Line("JCDenton","UCHKOfficer","UNATCO?");
    c.Line("UCHKOfficer","JCDenton","Coalition Special Projects.");
    c.Line("JCDenton","UCHKOfficer","Never heard of it.");
    c.Line("UCHKOfficer","JCDenton","Most people haven't. Use the freight lift beyond the checkpoint.");
    c.SetFlag('UC_RoofLiaisonMet',True); c.Done(); c.AttachTo(officer);
}
function YardTalks()
{
    local ScriptedPawn officer;
    local UCCon c;
    officer=PawnTag('UCYardLiaison');
    if (officer==None) return;
    officer.ConListItems=None; officer.BindName="UCHKOfficer";
    c=new(Level) class'UCCon';
    c.Begin('UC_YardBriefing',"UCHKOfficer",False);
    c.Require('UCHongKongRaidStarted',False); c.Once(); c.Radius(200);
    c.Line("UCHKOfficer","JCDenton","We have a convoy moving through the service yard. Your local intelligence package is being transferred with it.");
    c.Line("JCDenton","UCHKOfficer","What's in the shipment?");
    c.Line("UCHKOfficer","JCDenton","Restricted equipment.");
    c.Line("JCDenton","UCHKOfficer","For the Tong operation?");
    c.Line("UCHKOfficer","JCDenton","Among other things.");
    c.Line("JCDenton","UCHKOfficer","You people like that phrase.");
    c.SetFlag('UC_YardBriefingHeard',True); c.Done(); c.AttachTo(officer);
    yardCon=c.con;
    c=new(Level) class'UCCon';
    c.Begin('UC_YardAfter',"UCHKOfficer",False);
    c.Require('UCHongKongRaidResolved',True);
    c.Line("UCHKOfficer","JCDenton","They were going for the secured case. The local investigation is still your assignment.");
    c.Line("JCDenton","UCHKOfficer","What was worth the risk?");
    c.Line("UCHKOfficer","JCDenton","That equipment is restricted. Find Tong. He can explain why his people want it.");
    c.Done(); c.AttachTo(officer);
}
// The checkpoint guard waves JC through: the door opens on its own (JC is authorised).
function RoofTick()
{
    local Actor door;
    local UCTransitGuard guard, best;
    local UCCon c;
    door=FirstTag('UCRoofCheckpoint');
    if (door==None || VSize(Plr().Location-door.Location)>320) return;
    OpenDoor('UCRoofCheckpoint',True);
    if (!bCleared && !Talking())
    {
        bCleared=True;
        foreach AllActors(class'UCTransitGuard',guard,'UCRoofSecurity')
            if (guard.Health>0 && (best==None || VSize(guard.Location-door.Location)<VSize(best.Location-door.Location)))
                best=guard;
        if (best!=None && VSize(best.Location-door.Location)<400)
        {
            c=new(Level) class'UCCon'; c.Begin('UC_CheckpointCleared',best.BindName,True); c.Passive();
            c.Line("UCHKGuard","JCDenton","Denton. You're cleared.");
            c.Done(); c.AttachTo(best);
            Plr().StartConversation(best,IM_Other,c.con,False,False);
        }
    }
    if (!GetF('UC_HK_SimonsBriefing') && !bBriefing && !Talking())
    { bBriefing=True; Spawn(class'UCSceneSimonsBriefing'); }
}
// Simons's call (HUD InfoLink) can still be running when JC reaches the dock: the building is
// small and the lift is a few steps from the checkpoint. Radius conversations do not start under it.
function bool InfoBusy()
{
    local DeusExRootWindow root;
    if (Plr()==None) return False;
    root=DeusExRootWindow(Plr().rootWindow);
    return Plr().dataLinkPlay!=None || (root!=None && root.hud!=None && root.hud.infolink!=None);
}
function bool HasCon(Actor a, name conName)
{
    local ConListItem item;
    for (item=ConListItem(a.ConListItems); item!=None; item=item.next)
        if (item.con!=None && item.con.conName==conName) return True;
    return False;
}
function DockTick()
{
    local UCTransitButton b;
    local ScriptedPawn officer;
    local float d;
    b=LiftButton(True);
    if (b==None || !AtDock()) return;
    d=VSize((Plr().Location-b.Location)*vect(1,1,0));
    // the liaison calls JC over as soon as the InfoLink is finished. The game rebuilds
    // ConListItems (transient): put the lines back first, or StartConversation refuses.
    officer=PawnTag('UCYardLiaison');
    if (officer!=None && !GetF('UC_YardBriefingHeard') && !HasCon(officer,'UC_YardBriefing')) YardTalks();
    if (!GetF('UC_YardBriefingHeard') && !GetF('UCHongKongRaidStarted') && !Talking() && !InfoBusy()
        && officer!=None && yardCon!=None && VSize(Plr().Location-officer.Location)<360 && officer.LineOfSightTo(Plr()))
        Plr().StartConversation(officer,IM_Other,yardCon,False,False);
    // the diversion goes off once JC has stepped out of the cabin: after the briefing,
    // or when he walks past the liaison without stopping (distances for a 1152 x 896 dock)
    if (!GetF('UCHongKongRaidStarted') && !Talking() && !InfoBusy() && d>420 && (GetF('UC_YardBriefingHeard') || d>620))
        StartRaid();
    RaidTick();
}
function BreakDoor(name tagName)
{
    local DeusExMover door;
    foreach AllActors(class'DeusExMover',door,tagName)
        if (!door.bDestroyed)
        {
            door.FragmentClass=class'MetalFragment';
            door.NumFragments=12;
            door.FragmentSpread=48;
            door.FragmentScale=1.5;
            door.bDrawExplosion=True;
            door.BlowItUp(None);
        }
}
function StartRaid()
{
    local UCYardRaider raider;
    local DeusExPlayer P;
    local Actor van;
    local vector spot;
    if (GetF('UCHongKongRaidStarted')) return;
    SetF('UCHongKongRaidStarted',True);
    P=Plr();
    if (P.FindGoal('UCDefendShipment')==None)
        P.GoalAdd('UCDefendShipment',"A raid is targeting the secured shipment in the service yard. Protect it, inspect the cargo or continue into Wan Chai.",False);
    // a small diversion beside the van: no area damage
    van=FirstTag('UCTransportVan');
    spot=CasePoint();
    if (van!=None) spot=van.Location+vect(0,-160,-20);
    Spawn(class'ExplosionLight',,,spot);
    P.PlaySound(Sound'DeusExSounds.Weapons.LAMExplode',SLOT_None,0.7,,2200);
    P.ShakeView(0.6,500,24);
    // the Luminous Path squads blow the doors they wait behind (Gabby, 12 Oct: no door sliding into
    // the walls); the game's own breakable door effect: metal fragments, flash, noise, the door gone
    BreakDoor('UCYardMaintenance');
    BreakDoor('UCYardBackroom');
    BreakDoor('UCYardTrailer');
    foreach AllActors(class'UCYardRaider',raider) raider.ActivateRaid();
    raidTime=0;
    Log("UCHKArrival: cargo raid started in the loading dock");
}
function RaidTick()
{
    local UCYardRaider raider;
    local UCTransitGuard guard;
    local Actor cargo;
    local UCFileCube label;
    local vector casePos;
    local int alive;
    local UCCon c;
    if (!GetF('UCHongKongRaidStarted') || GetF('UCHongKongRaidResolved')) return;
    raidTime+=0.5;
    casePos=CasePoint();
    foreach AllActors(class'UCYardRaider',raider)
    {
        if (raider.Health<=0 || !raider.bInWorld) continue;
        alive++;
        if (raider.Enemy==Plr()) continue; // player retaliation remains meaningful
        foreach AllActors(class'UCTransitGuard',guard,'UCYardSecurity')
            if (guard.Health>0 && guard.bInWorld && raider.LineOfSightTo(guard))
            { raider.SetEnemy(guard); break; }
        if (VSize((raider.Location-casePos)*vect(1,1,0))<130 && !GetF('UCHongKongCaseTaken'))
        {
            SetF('UCHongKongCaseTaken',True);
            foreach AllActors(class'Actor',cargo,'UCHKSecuredCase')
            {
                cargo.bHidden=True;
                cargo.SetCollision(False,False,False);
            }
            // the logistics label falls beside the stolen case and remains readable
            foreach AllActors(class'UCFileCube',label)
                if (label.document=='Shipment') label.SetLocation(vect(1,1,0)*casePos+vect(0,0,8));
        }
    }
    // the diversion can end with survivors: the investigation is never kill-gated
    if (alive==0 || raidTime>=38 || VSize(Plr().Location-casePos)>2200)
    {
        SetF('UCHongKongRaidResolved',True);
        GoalDone('UCDefendShipment');
        foreach AllActors(class'UCYardRaider',raider)
            if (raider.Health>0 && raider.Enemy!=Plr())
                raider.RetreatFromCargo();
        Log("UCHKArrival: raid ended; case taken=" $ GetF('UCHongKongCaseTaken'));
        WoundedTalks();
    }
    // short combat callouts use passive native speech rather than locking the camera
    if (Talking() || bark>=3 || raidTime<2+5*bark) return;
    if (bark==0) raider=UCYardRaider(PawnTag('UCYardRaiderA'));
    else if (bark==1) raider=UCYardRaider(PawnTag('UCYardRaiderB'));
    else raider=UCYardRaider(PawnTag('UCYardRaiderC'));
    bark++;
    if (raider==None) return;
    c=new(Level) class'UCCon'; c.Begin('UC_CargoRaidBark',raider.BindName,True); c.Passive();
    if (bark==1) c.Line("UCYardRaider1","JCDenton","Get the container!");
    else if (bark==2) c.Line("UCYardRaider2","JCDenton","It's Denton! Take him down!");
    else c.Line("UCYardRaider3","JCDenton","Don't waste time on the guards!");
    c.Done(); c.AttachTo(raider);
    Plr().StartConversation(raider,IM_Other,c.con,False,False);
}
function WoundedTalks()
{
    local UCYardRaider raider;
    local UCCon c;
    foreach AllActors(class'UCYardRaider',raider)
    {
        if (raider.Health<=0 || raider.Health>35 || !raider.bInWorld) continue;
        c=new(Level) class'UCCon';
        c.Begin('UC_WoundedRaider',raider.BindName,False); c.Once();
        c.Line("UCYardRaider1","JCDenton","Ask your employers.");
        c.Line("JCDenton","UCYardRaider1","Which one?");
        c.Line("UCYardRaider1","JCDenton","Exactly.");
        // one consistent binding for this optional survivor's conversation
        raider.BindName="UCYardRaider1"; raider.ConBindEvents();
        c.con.conOwnerName="UCYardRaider1";
        c.Done(); c.AttachTo(raider);
        return;
    }
}
// Called by UCTransitButton: only a passenger standing inside the cabin can depart.
function UseLift(DeusExPlayer P, bool bToRoof)
{
    local UCTransitButton b;
    if (P==None || bLiftBusy || Talking()) return;
    b=LiftButton(bToRoof);
    if (b==None || VSize((P.Location-b.Location)*vect(1,1,0))>300 || Abs(P.Location.Z-b.Location.Z)>140) return;
    bLiftBusy=True;
    if (bToRoof) GotoState('LiftUp'); else GotoState('LiftDown');
}
// The freight lift is a real platform in a shaft. Roof and dock are far apart in the map, so each
// has its own identical shaft: at the end of the first platform's ride JC passes to the same spot of
// the other platform, waiting at the corresponding height, which goes on moving.
function Mover LiftPlatform(bool bDock)
{
    local Mover M;
    local name tagName;
    tagName='UCRoofLift';
    if (bDock) tagName='UCDockLift';
    foreach AllActors(class'Mover',M,tagName) return M;
    return None;
}
function MovePlatform(bool bDock, int key, float seconds)
{
    local Mover M;
    M=LiftPlatform(bDock);
    if (M!=None && (M.KeyNum!=key || M.bInterpolating)) M.InterpolateTo(key,seconds);
}
function LiftLog(string phase)
{
    local DeusExPlayer P;
    P=Plr();
    if (P!=None)
        Log("UCHKArrival lift" @ phase @ "JC" @ P.Location @ "base" @ P.Base @ "phys" @ P.Physics @ "roof" @ LiftPlatform(False).Location @ "dock" @ LiftPlatform(True).Location);
}
function RideTo(bool bToDock)
{
    local Mover from, dest;
    local DeusExPlayer P;
    P=Plr();
    from=LiftPlatform(!bToDock);
    dest=LiftPlatform(bToDock);
    if (P==None || from==None || dest==None) return;
    P.SetLocation(P.Location+(dest.Location-from.Location));
    P.SetBase(dest);
    P.Velocity=vect(0,0,0);
}
state Playing
{
Begin:
    if (Plr()==None || Plr().FlagBase==None) { Sleep(0.5); Goto('Begin'); }
    Friendly();
    RoofTalks();
    YardTalks();
    Plr().FlagBase.SetName('MusicPackageTrack','HongKong_Music');
    Plr().UpdateDynamicMusic(5);
    class'UCSceneHongKong'.static.TongGoal(Plr());
    if (!GetF('UC_RooftopIntroduced'))
    {
        SetF('UC_RooftopIntroduced',True); TitleCard("HONG KONG");
        if (Plr().FindGoal('UCMeetLiaison')==None)
            Plr().GoalAdd('UCMeetLiaison',"Meet the Special Projects liaison and take the freight lift down to Wan Chai.",False);
    }
    // only the landing where the platforms wait is open: the other door stays shut
    MovePlatform(False,0,0.05);
    MovePlatform(True,0,0.05);
    OpenDoor('UCRoofLiftDoor',!AtDock());
    OpenDoor('UCDockLiftDoor',AtDock());
Loop:
    if (Plr()==None) { Sleep(0.5); Goto('Loop'); }
    if (!bLiftBusy)
    {
        if (AtDock()) DockTick();
        else RoofTick();
    }
    Sleep(0.5); Goto('Loop');
}
function LiftSound(string soundName)
{
    local Sound s;
    s=Sound(DynamicLoadObject("MoverSFX.Elevator."$soundName,class'Sound',True));
    if (s!=None && Plr()!=None) Plr().PlaySound(s,SLOT_None,1.0,,800);
}
state LiftDown
{
Begin:
    LiftLog("start");
    OpenDoor('UCRoofLiftDoor',False);
    OpenDoor('UCDockLiftDoor',False);
    MovePlatform(True,1,0.05);          // the dock platform waits at the top of its shaft
    Sleep(1.3);
    LiftSound("LargeElevStart");
    Plr().ShakeView(0.5,60,4);
    Sleep(0.5);
    LiftSound("LargeElevMove");
    MovePlatform(False,1,4.0);     // down the roof shaft
    Plr().ShakeView(8.0,15,1);
    Sleep(4.0);
    LiftLog("before swap");
    RideTo(True);
    LiftLog("after swap");
    MovePlatform(True,0,4.0);      // on down the dock shaft
    Sleep(4.0);
    MovePlatform(False,0,0.05);         // back at the roof landing, behind its closed door
    LiftLog("arrived");
    LiftSound("SmallElevStop");
    Plr().ShakeView(0.4,60,4);
    Sleep(0.8);
    SetF('UCHongKongRooftopArrival',True);
    GoalDone('UCMeetLiaison');
    OpenDoor('UCDockLiftDoor',True);
    bLiftBusy=False;
    GotoState('Playing','Loop');
}
state LiftUp
{
Begin:
    LiftLog("start");
    OpenDoor('UCDockLiftDoor',False);
    OpenDoor('UCRoofLiftDoor',False);
    MovePlatform(False,1,0.05);         // the roof platform waits at the bottom of its shaft
    Sleep(1.3);
    LiftSound("LargeElevStart");
    Plr().ShakeView(0.5,60,4);
    Sleep(0.5);
    LiftSound("LargeElevMove");
    MovePlatform(True,1,4.0);      // up the dock shaft
    Plr().ShakeView(8.0,15,1);
    Sleep(4.0);
    LiftLog("before swap");
    RideTo(False);
    LiftLog("after swap");
    MovePlatform(False,0,4.0);     // on up the roof shaft
    Sleep(4.0);
    MovePlatform(True,0,0.05);
    LiftLog("arrived");
    LiftSound("SmallElevStop");
    Plr().ShakeView(0.4,60,4);
    Sleep(0.8);
    OpenDoor('UCRoofLiftDoor',True);
    bLiftBusy=False;
    GotoState('Playing','Loop');
}
defaultproperties
{
    bHidden=True
}
