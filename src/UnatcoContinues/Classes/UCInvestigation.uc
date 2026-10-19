// Persistent quest state lives in FlagBase, never in transient scene timing.
class UCInvestigation extends UCScene;

var string mapName;
var bool bSetup, bCloseTerminal;

function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(0.25, True);
}

static function bool YuenCorroborated(bool transcriptRead, bool deathReportRead)
{
    return transcriptRead && deathReportRead;
}

static function bool CanReport(FlagBase f)
{
    return f != None && (f.GetBool('TongMeetingComplete') || f.GetBool('UC_VLManifestRead'));
}

static function bool CanOpen(FlagBase f)
{
    return f != None && f.GetBool('UC_TongLocationReported') && f.GetBool('UC_TransferOrderReceived');
}

static function bool CanAssault(FlagBase f, bool entryObserved)
{
    return CanOpen(f) && f.GetBool('UC_NorthAccessRequested')
        && f.GetBool('UC_NorthAccessOpened') && f.GetBool('UC_SPEntryAuthorized') && entryObserved;
}

static function string DocumentText(name document)
{
    switch (document)
    {
        case 'Paul':
        case 'PaulCopy':
            return "AMBROSIA - TRANSFER EXTRACT|nCopy obtained by P. Denton|n|n"
                $ "AMB-2219-A / diverted after UNATCO clearance|nAMB-2219-B / onward destination: HONG KONG|n"
                $ "AMB-2231-C / receiving facility: [REDACTED]|nDestination authorizations absent from this copy.";
        case 'Helibase':
            return "SPECIAL PROJECTS - HONG KONG FIELD SERVICES|nAgent: J.C. Denton / UNATCO / ACTIVE|n"
                $ "Flight reception: AUTHORIZED|nField authorization: SP-HK-0614|nIssuing office: WALTON SIMONS|n"
                $ "Support request: submit target location from a secure terminal";
        case 'Shipment':
            return "VL-HK / RESTRICTED TRANSFER|nDestination: [CLASSIFIED]|n"
                $ "Handling authority: SPECIAL PROJECTS|nLogistics contractor: VersaLife Hong Kong|n"
                $ "Seal SP-HK-06. Contents withheld from local handling staff.";
        case 'Manifest':
            return "VERSALIFE LOGISTICS - LABORATORY TRANSFER INDEX|n|n"
                $ "AMB-2219-A -> subsidiary 4 -> LEVEL 2 receiving account|n"
                $ "AMB-2219-B -> Hong Kong logistics -> LEVEL 2 receiving account|n"
                $ "AMB-2231-C -> destination withheld|n|n"
                $ "Facility: LEVEL 2 / restricted nanotechnology research|n"
                $ "External authorization: SP-HK-0614 / laboratory annex L2|n"
                $ "Issuing office: SPECIAL PROJECTS|nProject directory: [INCOMPLETE]";
        case 'LabAccess':
            return "LUMINOUS PATH - LOCAL MAINTENANCE COPY|nLaboratory door, sparring room: 1997.|n"
                $ "This is an access record, not permission from Gordon Quick. Unauthorized entry may meet resistance.";
        case 'TerminalAccess':
            return "LUMINOUS PATH - LABORATORY ACCESS|nArchive terminal: TONG / 1997|n"
                $ "Rear storage service console: MAINT / 1997|n|nThe loading access is normally kept closed."
                $ " The archive terminal can copy records or transmit a target location to Special Projects.";
    }
    return "";
}

function ReadDocument(name document, bool bShow)
{
    local name readFlag;
    local string text, title;
    local DeusExPlayer P;
    local DeusExRootWindow root;
    local UCDocumentWindow viewer;
    P = Plr();
    if (P == None || P.FlagBase == None)
        return;
    text = DocumentText(document);
    if (text == "")
        return;
    switch (document)
    {
        case 'Paul': readFlag = 'UC_PaulManifestRead'; title = "Paul's NSF records"; break;
        case 'PaulCopy': readFlag = 'UC_TongPaulCopyRead'; title = "Paul copy in Tong's archive";
            text = "Source: copy supplied by Tong; not collected by JC in New York.|n|n" $ text; break;
        case 'Helibase': readFlag = 'UC_SPHelibaseAuthRead'; title = "Field authorization"; break;
        case 'Shipment': readFlag = 'HongKongShipmentInspected'; title = "Secured cargo label"; break;
        case 'Manifest': readFlag = 'UC_VLManifestRead'; title = "Tong's VersaLife manifest"; break;
        case 'LabAccess': readFlag = 'UC_AlternateLabAccess'; title = "Local maintenance record"; break;
        case 'TerminalAccess': readFlag = 'UC_LabCredentialsRead'; title = "Laboratory access"; break;
    }
    if (!GetF(readFlag))
    {
        SetF(readFlag, True);
        if (document=='Manifest')
            P.AddNote("Inspected Tong's laboratory transfer index. Source: Tong archive. No independent field copy saved by this reading; use the explicit copy command to preserve the source identifiers.",False,True);
        else P.AddNote(title $ ": " $ text, False, True);
    }
    if (document=='Manifest' && P.FindGoal('UCCopyVLManifest')==None)
        P.GoalAdd('UCCopyVLManifest',"Optional: copy Tong's transfer index before the archive is sanitized. Preserve the original shipment and authorization identifiers for comparison at VersaLife.",False);
    if (bShow)
    {
        root = DeusExRootWindow(P.rootWindow);
        if (root != None)
        {
            viewer=UCDocumentWindow(root.PushWindow(class'UCDocumentWindow',False,P.GetPropertyText("bRealTimeUI")=="True"));
            if (viewer!=None)
            {
                viewer.SetTitle(title);
                viewer.SetMessageText(text);
                viewer.SetMode(1);
            }
        }
    }
}

function EnsureAction(name tagName, name operation)
{
    local UCMissionAction handler;
    foreach AllActors(class'UCMissionAction', handler, tagName)
        return;
    handler = Spawn(class'UCMissionAction',, tagName);
    if (handler != None)
        handler.operation = operation;
}

function Cube(name tagName, name document, vector spot)
{
    local UCFileCube cube;
    foreach AllActors(class'UCFileCube', cube, tagName)
        return;
    cube = Spawn(class'UCFileCube',, tagName, spot);
    if (cube != None)
    {
        cube.document = document;
        cube.SpecialText = DocumentText(document);
        cube.SetPhysics(PHYS_None);
    }
}

function SetupRecords()
{
    local ComputerPersonal pc;
    local DataCube ref;
    local UCSceneSPTransfer call;
    if (mapName == "04_NYC_NSFHQ")
    {
        // Place the independent extract beside the existing NSF uplink record.
        foreach AllActors(class'DataCube', ref)
            if (InStr(Caps(string(ref.textTag)), "04_DATACUBE") != -1)
            {
                Cube('UC_PaulRecord', 'Paul', ref.Location + vect(20, 0, 3));
                break;
            }
    }
    if (mapName == "06_HONGKONG_TONGBASE")
        Cube('UC_LabAccessRecord', 'TerminalAccess', vect(302, -38, 56));

    EnsureAction('UC_GiveSwordMax', 'GiveSwordMax');
    EnsureAction('UC_GiveSwordGordon', 'GiveSwordGordon');
    EnsureAction('UC_ReadVLManifest', 'ReadManifest');
    EnsureAction('UC_CopyVLManifest', 'CopyManifest');
    EnsureAction('UC_ReadPaulCopy', 'ReadPaulCopy');
    EnsureAction('UC_ReportTong', 'ReportTong');
    EnsureAction('UC_ReportChow', 'ReportChow');
    EnsureAction('UC_OpenNorthAccess', 'OpenNorth');
    EnsureAction('UC_ReportOperation', 'ReportOperation');
}

function Option(Computers pc, int index, string label, name action)
{
    pc.specialOptions[index].Text = label;
    pc.specialOptions[index].userName = "";
    pc.specialOptions[index].TriggerEvent = action;
    pc.specialOptions[index].UnTriggerEvent = '';
    pc.specialOptions[index].bTriggerOnceOnly = False;
    pc.specialOptions[index].bAlreadyTriggered = False;
    pc.specialOptions[index].TriggerText = "Records are saved to Notes. Transmissions require a separate command.";
}

function ConfigureComputers()
{
    local Computers pc;
    if (mapName == "06_HONGKONG_TONGBASE")
    {
        foreach AllActors(class'Computers', pc)
            if (VSize(pc.Location - vect(274, -28, 49)) < 90)
            {
                pc.UserList[0].userName = "TONG";
                pc.UserList[0].password = "1997";
                Option(pc, 0, "Read VersaLife manifest", 'UC_ReadVLManifest');
                Option(pc, 1, "Copy manifest to field archive", 'UC_CopyVLManifest');
                if (!GetF('UC_SweepComplete'))
                    Option(pc, 2, "Report location / request team", 'UC_ReportTong');
                else
                    Option(pc, 2, "Upload operation report", 'UC_ReportOperation');
                Option(pc, 3, "Read Paul's archive copy", 'UC_ReadPaulCopy');
            }
        foreach AllActors(class'Computers', pc, 'UCNorthConsole')
        {
            pc.ComputerNode=CN_HKNet;
            pc.titleString="LABORATORY / REAR SERVICE ACCESS";
            pc.UserList[0].userName = "MAINT";
            pc.UserList[0].password = "1997";
            Option(pc, 0, "Open rear loading access / admit team", 'UC_OpenNorthAccess');
        }
    }
    if (mapName == "06_HONGKONG_WANCHAI_STREET")
        foreach AllActors(class'Computers', pc)
            if (Abs(pc.Location.Z - 2052) < 500 && pc.Location.X < -800)
                Option(pc, 3, "Transmit Queen's Tower evidence report", 'UC_ReportChow');
    // Leaving the base never submits a report. Existing secure terminals remain usable.
    if (GetF('UC_SweepComplete'))
        foreach AllActors(class'Computers',pc)
            if ((mapName=="06_HONGKONG_WANCHAI_COMPOUND" && VSize(pc.Location-vect(2640,5054,200))<90)
                || (mapName=="06_HONGKONG_WANCHAI_MARKET" && VSize(pc.Location-vect(-385,813,65))<90)
                || (mapName=="06_HONGKONG_WANCHAI_STREET" && Abs(pc.Location.Z-2052)<500 && pc.Location.X<-800))
                Option(pc,3,"Upload Special Projects operation report",'UC_ReportOperation');
}

function bool GiveSword(name who)
{
    local DeusExPlayer P;
    local ScriptedPawn recipient;
    local Inventory sword;
    local name custodyFlag;
    P = Plr();
    if (P == None || GetF('UC_SwordGivenMax') || GetF('UC_SwordGivenGordon'))
        return False;
    sword = P.FindInventoryType(class'WeaponNanoSword');
    if (sword == None || !GetF('UC_ChowSwordVerified'))
    {
        Msg("You do not have the verified weapon to deliver.");
        return False;
    }
    foreach AllActors(class'ScriptedPawn', recipient)
        if (recipient.IsA(who) && recipient.bInWorld && recipient.Health > 0 && JCNear(recipient, 400))
            break;
    if (recipient == None || !recipient.IsA(who) || recipient.Health <= 0 || !JCNear(recipient, 400))
        return False;
    if (P.inHand == sword) P.PutInHand(None);
    P.DeleteInventory(sword);
    sword.GiveTo(recipient);
    if (sword.Owner != recipient)
    {
        sword.GiveTo(P);
        return False;
    }
    custodyFlag = 'UC_SwordGivenGordon';
    if (who == 'MaxChen')
    {
        custodyFlag = 'UC_SwordGivenMax';
        SetF('MaxChenConvinced', True);
        SetF('UC_RedArrowCeasefire', True);
    }
    SetF(custodyFlag, True);
    SetF('UC_HasSword', False);
    SetF('UC_SwordAtChow', False);
    P.AddNote("Dragon's Tooth voluntarily transferred to " $ recipient.FamiliarName $ ". Weapon custody is separate from the Yuen Kong case.", False, True);
    Msg("Weapon transfer recorded.");
    return True;
}

function bool JCNear(Actor A, float distance)
{
    return Plr() != None && A != None && VSize(Plr().Location - A.Location) < distance;
}

function Action(name operation)
{
    local DeusExPlayer P;
    local DeusExMover door;
    P = Plr();
    if (P == None || P.FlagBase == None)
        return;
    switch (operation)
    {
        case 'GiveSwordMax': GiveSword('MaxChen'); return;
        case 'GiveSwordGordon': GiveSword('GordonQuick'); return;
        case 'ReadManifest':
            if (GetF('UC_TongPCWiped') && !GetF('UC_VLManifestCopied'))
            {
                Msg("The source archive has been sanitized. No independent copy was saved.");
                return;
            }
            ReadDocument('Manifest', True); return;
        case 'ReadPaulCopy': ReadDocument('PaulCopy', True); return;
        case 'CopyManifest':
            if (!GetF('UC_VLManifestRead') || GetF('UC_TongPCWiped'))
            {
                Msg("Read the source manifest before copying it. Sanitized archives cannot be recovered here.");
                return;
            }
            if (!GetF('UC_VLManifestCopied'))
                P.AddNote("Independent field copy, saved before the sweep: " $ DocumentText('Manifest'), False, True);
            SetF('UC_VLManifestCopied', True);
            if (P.FindGoal('UCCopyVLManifest')!=None) P.GoalCompleted('UCCopyVLManifest');
            SetF('VersaLifeEvidenceFragment', True);
            Msg("Independent manifest copy preserved."); return;
        case 'ReportChow':
            if (!(GetF('UC_ChowSwordVerified') || GetF('UC_YuenTranscriptRead') || GetF('UC_HoloSeen')))
            {
                Msg("No verified Queen's Tower findings to transmit."); return;
            }
            SetF('ChowEvidenceReportSent', True);
            SetF('SimonsMaggieRecordingSeen', GetF('UC_HoloSeen'));
            Msg("Queen's Tower findings transmitted. Awaiting command response.");
            bCloseTerminal = True; return;
        case 'ReportTong':
            if (!CanReport(P.FlagBase))
            {
                Msg("Locate Tong or inspect his laboratory records before requesting a transfer."); return;
            }
            SetF('UC_TongLocationReported', True);
            SetF('JCLedMJ12ToTong', True);
            Msg("Location transmitted to Special Projects. Transfer team requested.");
            bCloseTerminal = True; return;
        case 'OpenNorth':
            if (!CanOpen(P.FlagBase))
            {
                Msg("Report the location and receive the transfer order before authorizing team entry."); return;
            }
            foreach AllActors(class'DeusExMover', door, 'UCNorthAccess')
                break;
            if (door == None)
            {
                Msg("Rear service access hardware unavailable. The operation remains on hold."); return;
            }
            SetF('UC_NorthAccessRequested', True);
            door.bLocked = False;
            if (door.KeyNum == 0 && !door.bInterpolating)
                door.Trigger(Self, P);
            Msg("Rear loading door opening. Team entry authorized when the passage is clear.");
            bCloseTerminal = True; return;
        case 'ReportOperation':
            if (!GetF('UC_SweepComplete'))
                return;
            SetF('UC_FinalReportRequested', True);
            Msg("Operation report submitted with collected attachments.");
            bCloseTerminal = True; return;
    }
}

function ObserveRecords()
{
    local DataCube cube;
    local WeaponNanoSword sword;
    local DeusExPlayer P;
    local DeusExNote note;
    P = Plr();
    if (P == None)
        return;
    foreach AllActors(class'DataCube', cube)
        if (cube.GetPropertyText("bRead") == "True")     // Revision's DataCube.bRead (the original game: the notes below)
        {
            if (cube.textTag == '06_Datacube06') SetF('UC_YuenTranscriptRead', True);
            if (cube.textTag == '06_Datacube22') SetF('UC_YuenDeathReportRead', True);
        }
    // Reading in an earlier map already left a tagged native note.
    for (note = P.firstNote; note != None; note = note.next)
    {
        if (note.textTag == '06_Datacube06') SetF('UC_YuenTranscriptRead', True);
        if (note.textTag == '06_Datacube22') SetF('UC_YuenDeathReportRead', True);
    }
    SetF('UC_YuenCaseCorroborated', YuenCorroborated(GetF('UC_YuenTranscriptRead'), GetF('UC_YuenDeathReportRead')));
    SetF('UC_HasSword', P.FindInventoryType(class'WeaponNanoSword') != None);
    if (mapName == "06_HONGKONG_WANCHAI_STREET")
    {
        SetF('UC_SwordAtChow', False);
        foreach AllActors(class'WeaponNanoSword', sword)
            if (sword.Owner == None && VSize(sword.Location - vect(-1858, -159, 2052)) < 300)
            {
                SetF('UC_SwordAtChow', True);
                if (JCNear(sword, 450) && P.LineOfSightTo(sword))
                    SetF('UC_ChowSwordVerified', True);
            }
        if (GetF('UC_HasSword') && (GetF('UC_SwordCaseOpened') || GetF('UC_SwordFound')))
            SetF('UC_ChowSwordVerified', True);
    }
}

// The recovery team approaches from the service road behind storage.
function StageOne(name tagName, string bind, vector spot)
{
    local UCSPCommando sp;
    foreach AllActors(class'UCSPCommando', sp, tagName) return;
    sp=Spawn(class'UCSPCommando',,tagName,spot);
    if (sp==None) return;
    // Immediate orders bypass the native startup state; create its inventory first.
    sp.InitializePawn();
    sp.BindName=bind; sp.ConBindEvents();
    sp.FamiliarName="Special Projects"; sp.UnfamiliarName=sp.FamiliarName;
    sp.Alliance='mj12'; sp.ChangeAlly('Player',1.0,True);
    sp.ChangeAlly('Triad',0.0,True); sp.ChangeAlly('LumPath',0.0,True);
    sp.ChangeAlly('triad_lum',0.0,True); sp.ChangeAlly('LumPathTech',0.0,True);
    sp.ChangeAlly('LumPathPrisoner',0.0,True);
    sp.SetOrders('Standing','',True);
}

function GateTick()
{
    local DeusExMover gate;
    local UCSPCommando sp;
    local DeusExPlayer P;
    if (mapName!="06_HONGKONG_TONGBASE" || GetF('MJ12AssaultStarted') || !GetF('UC_TongLocationReported')) return;
    P=Plr();
    StageOne('UCSPCommander',"UCSPCommander",class'UCServiceAccess'.static.Stage(0));
    StageOne('UCSPEntry2',"UCSPCommando",class'UCServiceAccess'.static.Stage(1));
    StageOne('UCSPEntry3',"UCSPCommando",class'UCServiceAccess'.static.Stage(2));
    StageOne('UCSPEntry4',"UCSPCommando",class'UCServiceAccess'.static.Stage(3));
    foreach AllActors(class'DeusExMover',gate,'UCNorthAccess') break;
    if (gate==None || !CanOpen(P.FlagBase) || !GetF('UC_NorthAccessRequested')) return;
    // KeyNum changes when interpolation starts; position and completion matter.
    if (gate.bInterpolating || gate.Location.Z > gate.BasePos.Z-116) return;
    SetF('UC_NorthAccessOpened',True);
    SetF('UC_SPEntryAuthorized',True);
    if (P.FindGoal('UCOpenNorthAccess')!=None) P.GoalCompleted('UCOpenNorthAccess');
    foreach AllActors(class'UCSPCommando',sp)
    {
        if (!sp.bInWorld || sp.Health<=0) continue;
        if (class'UCServiceAccess'.static.Inside(sp.Location)
            && CanAssault(P.FlagBase,True))
        {
            SetF('UC_SPEntryCrossed',True);
            SetF('MJ12AssaultStarted',True);
            Log("UCRW|rear-loading-crossed|" $ sp.Name $ "|" $ sp.Location);
        }
        if (class'UCServiceAccess'.static.Outside(sp.Location) && !sp.IsInState('UCEntry')) sp.GotoState('UCEntry');
    }
}

function FallbackAccess()
{
    local Keypad pad;
    if (mapName!="06_HONGKONG_WANCHAI_COMPOUND" || !GetF('GordonQuick_Dead')) return;
    // Ground beside the dead gate guard, outside the compound, verified in Revision.
    Cube('UC_CompoundMaintenanceRecord','LabAccess',vect(650,5520,16));
    if (!GetF('UC_AlternateLabAccess')) return;
    foreach AllActors(class'Keypad',pad)
        if (pad.Tag=='GateKeypad' || pad.Tag=='BasementKeypad')
        { pad.bHidden=False; pad.SetCollision(True,False,False); }
        else if (pad.Tag=='DummyKeypad01')
        { pad.bHidden=True; pad.SetCollision(False,False,False); }
}

function Migrate()
{
    if (GetF('UC_RewriteInitialized'))
        return;
    // Grandfather only actual old progress, never unread documents or custody.
    if (GetF('QuickLetPlayerIn'))
        SetF('UC_LPMeetingGranted', True);
    if (GetF('MJ12AssaultStarted'))
        SetF('UC_LegacyAssault', True);
    SetF('UC_RewriteInitialized', True);
}

function Timer()
{
    local DeusExPlayer P;
    local DeusExLevelInfo info;
    local Computers pc;
    local UCSceneSPTransfer call;
    P = Plr();
    if (P == None || P.FlagBase == None)
        return;
    if (mapName == "")
        foreach AllActors(class'DeusExLevelInfo', info)
            mapName = Caps(info.mapName);
    if (!bSetup)
    {
        bSetup = True;
        Migrate();
        SetupRecords();
    }
    ObserveRecords();
    ConfigureComputers();
    FallbackAccess();
    GateTick();
    if (bCloseTerminal)
    {
        bCloseTerminal = False;
        foreach AllActors(class'Computers', pc)
            if (pc.termwindow != None)
                pc.termwindow.CloseScreen("EXIT");
    }
    if (GetF('UC_TongLocationReported') && !GetF('UC_TransferOrderReceived'))
    {
        foreach AllActors(class'UCSceneSPTransfer', call)
            break;
        if (call == None)
            Spawn(class'UCSceneSPTransfer');
    }
}

defaultproperties
{
    bHidden=True
    InitialState=""
}
