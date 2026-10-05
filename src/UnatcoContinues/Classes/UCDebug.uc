//=============================================================================
// UCDebug - base dei comandi di debug (salti nella storia).
// Ogni sottoclasse si usa con:  summon UnatcoContinues.<Nome>
// Imposta i flag come se il giocatore fosse arrivato fin li' e cambia mappa.
//=============================================================================
class UCDebug extends Actor
	abstract
	transient;

var DeusExPlayer Player;
var FlagBase flags;
var bool bKeepTour;   // non spegne la presentazione per il video (UCTour)

event Destroyed()
{
	Player = None;
	flags = None;
	Super.Destroyed();
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	Player = DeusExPlayer(GetPlayerPawn());
	if (Player != None)
		flags = Player.FlagBase;
	if (flags == None)
	{
		Log("UnatcoContinues: debug senza giocatore/flag.");
		Destroy();
		return;
	}
	EnsureMod();
	// un salto di debug normale mette fine alla presentazione per il video
	if (!bKeepTour && flags.GetBool('UC_Tour'))
		flags.SetBool('UC_Tour', False,, 99);
	Run();
}

// Aprire il menu di debug (o un qualunque comando UCDbg*) rimette in moto la mod
// se in questa mappa non era partita (salvataggi fatti prima di UCTraveler).
function EnsureMod()
{
	local UCMod m;

	foreach AllActors(class'UCMod', m)
		if (!m.bDeleteMe)
			return;
	Spawn(class'UCMod');
	Log("UnatcoContinues: gestore route avviato dal menu di debug");
}

// Da ridefinire nelle sottoclassi.
function Run()
{
}

function SetF(Name flagName, bool value)
{
	flags.SetBool(flagName, value,, 99);
}

// Azzera i flag della nostra route (i salti sono ripetibili).
function ResetRoute()
{
	SetF('UNATCORouteActive', False);
	SetF('UNATCORouteCommitted', False);
	SetF('UNATCORoute_EvidenceFound', False);
	SetF('PaulRejectedByJC', False);
	SetF('PaulEscapedTon', False);
	SetF('PaulFugitive', False);
	SetF('PaulLocationUnknown', False);
	SetF('JCDefectedFromUNATCO', False);
	SetF('M04PlayerLikesUNATCO_Played', False);
	SetF('NSFSignalSent', False);
	SetF('UNATCORoute_ReturnToHQ', False);
	SetF('UC_Scene_PaulExit', False);
	SetF('UC_Scene_Alex', False);
	SetF('UC_Scene_Jock', False);
	SetF('UC_Scene_Arrive', False);
	SetF('UC_SendSignalText', False);
	SetF('UC_GG_Saved', False);
	SetF('UC_Prologue_Done', False);
	SetF('UC_DbgAutoConv', False);
	SetF('UC_M1_JockPark_Played', False);
	SetF('UC_HotelSearch', False);
	SetF('UC_HotelRaid', False);
	SetF('UC_MIBTalk', False);
	SetF('UC_SubGateNote', False);
	SetF('UC_BP_Started', False);
	SetF('UC_BP_Met', False);
	SetF('UC_M1_BatteryPark_Played', False);
	SetF('UC_Scene_Takeoff_Started', False);
	SetF('UC_Scene_Takeoff', False);
	SetF('UC_BP_AnnaDone', False);
	SetF('UC_M1_AnnaBP_Played', False);
	SetF('UC_M1_GuntherBP_Played', False);
	SetF('UC_WalkOff_Started', False);
	SetF('PaulLeftTonHotel', False);
	SetF('UC_JockGoal', False);
	SetF('UC_JockGo', False);
	SetF('UC_Takeoff_Started', False);
	SetF('UNATCORoute_DepartedNYC', False);
	SetF('UC_JockBP_Played', False);
	SetF('UC_JockBPReady_Played', False);
	SetF('UC_PaulAfter1_Played', False);
	SetF('UC_PaulAfter2_Played', False);
	SetF('UC_PaulAfter3_Played', False);
	SetF('UC_PaulAfter4_Played', False);
	SetF('UC_GreeterTalk_Played', False);
	SetF('UC_GreeterHello_Played', False);
	// Hong Kong (HK-3..HK-8): conversazioni e catena della tregua
	SetF('UC_Messenger_Played', False);
	SetF('RedArrowMessengerContacted', False);
	SetF('MaxChenMeetingAvailable', False);
	SetF('UC_MaxMeet_Played', False);
	SetF('UC_MaxEscort_Played', False);
	SetF('UC_MaxEscortDoor_Played', False);
	SetF('UC_MaxEscortDone', False);
	SetF('PaidForLuckyMoney', False);
	SetF('ClubTriadBackroomMeet_Played', False);
	SetF('UC_MaxEvidence_Played', False);
	SetF('MeetMaxChen_Played', False);
	SetF('UC_MaggieMeet_Played', False);
	SetF('MeetMaggie_Played', False);
	SetF('UC_GordonMeet_Played', False);
	SetF('UC_GordonEvidence_Played', False);
	SetF('UC_GordonFinal_Played', False);
	SetF('Gate_Guard2_Played', False);
	SetF('Have_Evidence', False);
	SetF('UC_SwordFound', False);
	SetF('MaxChenConvinced', False);
	SetF('QuickConvinced', False);
	SetF('QuickLetPlayerIn', False);
	SetF('M06WaltonHolo_Played', False);
	SetF('UC_SimonsSwordCall', False);
	SetF('DragonToothEvidenceFound', False);
	SetF('SimonsMaggieRecordingSeen', False);
	SetF('ChowEvidenceReportSent', False);
	SetF('UC_LMForeshadow_Played', False);
	SetF('UC_LMForeshadowDone', False);
	SetF('UC_NoteTongLab', False);
	SetF('UC_PaulTalkClosed', False);
	SetF('GuntherTonEncounterPlayed', False);
	SetF('GuntherTonSkipped', False);
	SetF('GuntherTonSearchStarted', False);
	SetF('GuntherTonSearchComplete', False);
	SetF('GuntherFailedToCapturePaul', False);
	SetF('SpecialAgentsSeenAtTon', False);
	SetF('SimonsConnectionHinted', False);
	SetF('PaulLocationLeakConfirmed', False);
	SetF('GuntherSuspiciousOfJC', False);
	SetF('GuntherTrustsJCLoyalty', False);
	SetF('JCBrokeWithUNATCO', False);
	SetF('UC_GuntherTon1_Played', False);
	SetF('UC_GuntherTon2_Played', False);
	SetF('UC_JockBPExtra_Played', False);
	SetF('UC_GuntherLobby_Played', False);
	SetF('UC_GuntherRoom_Played', False);
	SetF('UC_GuntherQuestions_Played', False);
	SetF('UC_GuntherPrivate_Played', False);
	SetF('UC_GuntherReproach_Played', False);
	SetF('GuntherReportedJCConduct', False);
	// varianti Gunther / Anna alla metro / ufficiale (specifica "Dialoghi e varianti")
	SetF('GuntherKnowsJCMetPaul', False);
	SetF('UC_GilbertAtDesk', False);
	SetF('UC_PaulContactReportSent', False);
	SetF('UC_AnnaPaulReportReceived', False);
	SetF('UC_AnnaKnowsJCMetPaul', False);
	SetF('UC_AnnaMetroOpened', False);
	SetF('UC_AnnaMetroSpawned', False);
	SetF('UC_GateGuardSpawned', False);
	SetF('UC_GateGuard_Played', False);
	SetF('UC_GuntherLobbyAgent', False);
	SetF('UC_LobbyAgentPosted', False);
	SetF('UC_LobbyChat_Played', False);
	SetF('UC_GuntherNotNowCD', False);
	SetF('UC_GuntherG07_Played', False);
	SetF('UC_GuntherG11_Played', False);
	SetF('UC_GuntherG12_Played', False);
	SetF('UC_GuntherG13_Played', False);
	SetF('UC_GuntherG14_Played', False);
	SetF('UC_GuntherG15_Played', False);
	SetF('UC_GuntherG16_Played', False);
	SetF('UC_AnnaA01_Played', False);
	SetF('UC_AnnaA02_Played', False);
	SetF('UC_AnnaA03_Played', False);
	SetF('UC_AnnaA04_Played', False);
	SetF('UC_AnnaA05_Played', False);
	SetF('UC_AnnaA06_Played', False);
	SetF('UC_AnnaA10_Played', False);
	SetF('UC_AnnaA11_Played', False);
	SetF('UC_AnnaA12_Played', False);
	SetF('UC_HeardLebedevMJ12', False);
	SetF('UC_MJ12NameKnown', False);
	SetF('UC_HK_SimonsOpen', False);
	SetF('UC_HK_SimonsDone', False);
	SetF('UC_GuntherRadio_Played', False);
	SetF('UC_GuntherMutter1_Played', False);
	SetF('UC_GuntherMutter2_Played', False);
	SetF('UC_GuntherMutter3_Played', False);
	SetF('UC_PaulEvidenceItems', False);
	SetF('UC_JockHK_Played', False);
	SetF('UC_HK_Started', False);
	SetF('UC_HKOfficer_Played', False);
	SetF('UC_HK_SimonsDue', False);
	SetF('UC_HK_SimonsBriefing', False);
}

// Stato canonico all'inizio di Mission 04, prima del segnale.
function BaseMission04()
{
	ResetRoute();
	SetF('PlayerKilledLebedev', True);
	SetF('AnnaKilledLebedev', False);
	SetF('AnnaNavarre_Dead', False);
	SetF('M03PlayerKilledAnna', False);
	SetF('M03LebedevParentsClaim', False);
	SetF('PaulDenton_Dead', False);
	SetF('ManderleyDebriefing03_Played', True);
	SetF('JockTellsAboutPaul_Played', True);
	SetF('M04PlayerLeftUNATCO', True);
	SetF('DL_JockParkStart_Played', True);
	SetF('PaulInjured_Played', True);
	SetF('GatesOpen', True);
}

// Stato dopo il dialogo con Paul: route UNATCO scelta, Paul resta al 'Ton.
// (Il goal "Meet Jock in Battery Park" lo da' UCMod all'arrivo.)
function AfterPaul()
{
	BaseMission04();
	EvidenceFound();
	SetF('PaulInjured2_Played', True);
	SetF('M04PlayerLikesUNATCO_Played', True);
	SetF('UNATCORouteActive', True);
	SetF('UNATCORouteCommitted', True);
	SetF('PaulRejectedByJC', True);
}

// Hong Kong, appena scesi dall'eliporto: Jock ripartito, ufficiale MJ12 incontrato.
function HongKongBase()
{
	AfterPaul();
	SetF('UC_JockGoal', True);
	SetF('PaulLeftTonHotel', True);
	SetF('GuntherTonEncounterPlayed', True);
	SetF('GuntherKnowsJCMetPaul', True);
	SetF('GuntherReportedJCConduct', True);
	SetF('GuntherTonSearchComplete', True);
	SetF('UC_BP_Started', True);
	SetF('UC_JockBP_Played', True);
	SetF('UC_JockGo', True);
	SetF('UC_Takeoff_Started', True);
	SetF('UNATCORoute_DepartedNYC', True);
	SetF('UC_JockHK_Played', True);
	SetF('UC_HK_Started', True);
	SetF('UC_HKOfficer_Played', True);
	class'UCMod'.static.PrepareHongKongFlags(flags);
}

// Hong Kong, laboratorio di Tong: tregua fatta, Gordon ha dato il permesso, niente
// ancora successo la' sotto (lo usano UCDbgTongLab e la presentazione per il video).
function TongLabState()
{
	HongKongBase();
	SetF('UC_HK_SimonsDue', True);
	SetF('UC_HK_SimonsBriefing', True);
	SetF('UC_HK_MessengerDone', True);
	SetF('Have_Evidence', True);
	// il rapporto sul Dragon's Tooth e la risposta di Simons sono gia' avvenuti a Queen's
	// Tower: senza questo l'InfoLink partiva qui, all'arrivo nel laboratorio
	SetF('UC_SimonsSwordCall', True);
	SetF('DragonToothEvidenceFound', True);
	SetF('MaxChenConvinced', True);
	SetF('QuickConvinced', True);
	SetF('QuickLetPlayerIn', True);
	SetF('Gate_Guard2_Played', True);
	SetF('UC_GordonFinal_Played', True);
	SetF('TongMeetingStarted', False);
	SetF('TongMeetingComplete', False);
	SetF('TongEvidenceShown', False);
	SetF('TongEvidenceConversationComplete', False);
	SetF('MJ12AssaultStarted', False);
	SetF('MJ12AssaultResolved', False);
	SetF('TongEscapedCompound', False);
	SetF('UC_TongMeet_Played', False);
	SetF('UC_TongEvidence_Played', False);
	SetF('UC_TongAlarm_Played', False);
	SetF('UC_PrisonerTalk_Played', False);
	SetF('UC_SimonsAfterTong', False);
	SetF('UC_TongAssaultCall', False);
	SetF('UC_TongAlarmRang', False);
	SetF('TongEvidenceReportSent', False);
	SetF('VersaLifeEvidenceFragment', False);
	SetF('UC_TongPCWiped', False);
	SetF('UC_TongUnderstands_Played', False);
	SetF('UC_SPCommanderMeet_Played', False);
	SetF('UC_SPCommanderAfter_Played', False);
	SetF('UC_SPTechTalk_Played', False);
	SetF('JCWasTheAuthentication', False);
	SetF('JCSawDataSanitized', False);
	SetF('JCAttackedSpecialProjects', False);
	SetF('VersaLifeInvestigationAuthorized', False);
}

// Prova trovata a NSF HQ (come se avessi preso il codice dell'uplink).
function EvidenceFound()
{
	SetF('GotUplinkCode', True);
	SetF('DL_GotUplinkCode_Played', True);
	SetF('UNATCORoute_EvidenceFound', True);
	SetF('M04MeetGateGuard_Played', True);
}

// Cambia mappa mantenendo giocatore e flag; riattiva il gestore con il mutator.
// arrival: 0 = punto di partenza della mappa, 1 = vicino a Paul (vedi UCMod).
function Jump(string mapName, int arrival)
{
	flags.SetInt('UC_DbgArrival', arrival,, 99);
	Log("UnatcoContinues: salto a" @ mapName);
	Player.ClientTravel(mapName $ Player.BuildOptionString() $ "UnatcoContinues.UCMutator", TRAVEL_Relative, True);
	Player = None;
	flags = None;
}

defaultproperties
{
     bHidden=True
}
