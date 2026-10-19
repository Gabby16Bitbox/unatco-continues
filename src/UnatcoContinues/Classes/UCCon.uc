//=============================================================================
// UCCon - costruisce una conversazione NATIVA di Deus Ex da codice.
// Le battute senza audio (soundID = -1) vengono mostrate come testo dal
// sistema di conversazioni del gioco (telecamere, nomi, clic per continuare).
//
// IMPORTANTE: creare UCCon con new(Level) e tutti i suoi oggetti con new(Outer).
// Oggetti creati senza Outer non appartengono a nessun pacchetto e il gioco va in
// crash quando salva la mappa al cambio livello (SaveExports: PackageIndex>0).
//
// Uso (sempre in una variabile LOCALE, mai membro di un Actor):
//   c = new(Level) class'UCCon';   // Outer = la mappa: gli oggetti appartengono al livello
//   c.Begin('UC_M1_Alex', "AlexJacobson", False);
//   c.Line("AlexJacobson", "JCDenton", "I went through Paul's access logs.");
//   c.SetFlag('UC_M1_AlexDone', True);
//   c.Done();
//=============================================================================
class UCCon extends Object;

var Conversation con;
var ConEvent last;
var string lastSpeakerName, lastSpeakingToName;
var string pendingLabel;   // etichetta per il prossimo evento (destinazione di scelte e salti)
var bool bFixedCamera;     // un'unica inquadratura (FixedShot): niente primi piani a ogni battuta
var ConChoice lastAnswer;
var UCConRandom randomBranch;

function Begin(Name conName, string ownerName, bool bFirstPerson)
{
	con = new(Outer) class'Conversation';
	con.conName = conName;
	con.conOwnerName = ownerName;
	con.bFirstPerson = bFirstPerson;
	con.bRandomCamera = False;
	con.bDisplayOnce = False;
	con.bInvokeFrob = True;
	con.bCannotBeInterrupted = True;
	con.audioPackageName = "";
	last = None;
	lastSpeakerName = "";
	lastSpeakingToName = "";
	pendingLabel = "";
	bFixedCamera = False;
}

// Parte anche quando JC si avvicina (distanza dal centro dell'attore).
function Radius(int dist)
{
	con.bInvokeRadius = True;
	con.radiusDistance = dist;
}

// Non parte cliccando (solo per vicinanza).
function NoFrob()
{
	con.bInvokeFrob = False;
}

// Inquadratura unica di lato e dall'alto, come le conversazioni vanilla con Jock
// nell'elicottero (i primi piani di un elicottero non hanno senso).
function FixedShot()
{
	local ConEventMoveCamera shot;

	shot = new(Outer) class'ConEventMoveCamera';
	shot.eventType = ET_MoveCamera;
	shot.cameraType = CT_Predefined;
	shot.cameraTransition = TR_Jump;
	shot.cameraPosition = CP_SideAbove45;
	Add(shot);
	bFixedCamera = True;
}

// Inquadratura unica larga, di lato e appena dall'alto (circa 15 gradi), a distanza
// moderata: per spazi chiusi col soffitto basso rispetto alla scena (l'hangar di Hong
// Kong), dove la SideAbove45 di FixedShot sbatte nel tetto e il gioco la avvicina fino a
// metterla dentro l'elicottero.
function WideShot()
{
	local ConEventMoveCamera shot;

	shot = new(Outer) class'ConEventMoveCamera';
	shot.eventType = ET_MoveCamera;
	shot.cameraType = CT_Speakers;
	shot.cameraTransition = TR_Jump;
	shot.rotation = rot(62806, 16788, 0);
	shot.heightModifier = 20.0;
	shot.centerModifier = 0.0;
	shot.distanceMultiplier = 1.5;
	Add(shot);
	bFixedCamera = True;
}

// Il prossimo evento si chiama cosi' (per Choice e Jump).
function Label(string l)
{
	pendingLabel = l;
	lastSpeakerName = "";      // dopo un salto la camera va rimessa su chi parla
	lastSpeakingToName = "";
}

// Due risposte per JC; ognuna salta alla sua etichetta.
function Choice(string text1, string label1, string text2, string label2)
{
	local ConEventChoice e;
	local ConChoice c1, c2;

	c1 = new(Outer) class'ConChoice';
	c1.choiceText = text1;
	c1.choiceLabel = label1;
	c1.soundID = -1;
	c2 = new(Outer) class'ConChoice';
	c2.choiceText = text2;
	c2.choiceLabel = label2;
	c2.soundID = -1;
	c1.nextChoice = c2;

	e = new(Outer) class'ConEventChoice';
	e.eventType = ET_Choice;
	e.bClearScreen = True;
	e.ChoiceList = c1;
	Add(e);
}

// Una scelta con quante risposte si vuole (come le armi di Paul a Liberty Island): Choices()
// la apre, ogni Answer() aggiunge una risposta che salta alla sua etichetta. Con un flag la
// risposta compare solo se il flag ha quel valore.
function Choices()
{
	local ConEventChoice e;

	e = new(Outer) class'ConEventChoice';
	e.eventType = ET_Choice;
	e.bClearScreen = True;
	Add(e);
}

function Answer(string text, string l, optional Name flagName, optional bool value)
{
	local ConEventChoice e;
	local ConChoice c, tail;

	e = ConEventChoice(last);
	if (e == None)
	{
		Choices();
		e = ConEventChoice(last);
	}
	c = new(Outer) class'ConChoice';
	c.choiceText = text;
	c.choiceLabel = l;
	c.soundID = -1;
	if (flagName != '')
	{
		c.flagRef = new(Outer) class'ConFlagRef';
		c.flagRef.flagName = flagName;
		c.flagRef.value = value;
	}
	if (e.ChoiceList == None)
	{
		e.ChoiceList = c;
		return;
	}
	tail = e.ChoiceList;
	while (tail.nextChoice != None)
		tail = tail.nextChoice;
	tail.nextChoice = c;
}

// JC riceve un oggetto (arma, munizioni, oggetto; "DeusEx.WeaponGEPGun") creato dal nulla: chi
// parla tiene il suo. Il gioco lo mostra nella conversazione; se l'inventario e' pieno la
// conversazione va a failLabel (o prosegue).
function Give(string className, optional int count, optional string failLabel)
{
	local ConEventTransferObject e;

	e = new(Outer) class'ConEventTransferObject';
	e.eventType = ET_TransferObject;
	e.objectName = className;
	e.giveObject = class<Inventory>(DynamicLoadObject(className, class'Class', True));
	e.transferCount = Max(count, 1);
	e.toName = "JCDenton";
	e.failLabel = failLabel;
	Add(e);
}

// Salta a un'etichetta della stessa conversazione.
function Jump(string l)
{
	local ConEventJump e;

	e = new(Outer) class'ConEventJump';
	e.eventType = ET_Jump;
	e.jumpLabel = l;
	Add(e);
}

function JumpOriginal(Actor context, string path)
{
	local Conversation original;
	local Actor A;
	local ConListItem item;
	original=Conversation(DynamicLoadObject(path,class'Conversation',True));
	if (original==None) return;
	foreach context.AllActors(class'Actor',A)
		for (item=ConListItem(A.ConListItems); item!=None; item=item.next)
			if (item.con!=None && item.con.conName==original.conName
				&& item.con.conOwnerName==original.conOwnerName && Left(item.con.CreatedBy,9)=="DeusEdix:")
			{
				ConEventJump(last).jumpCon=item.con;
				return;
			}
	ConEventJump(last).jumpCon=original;
}

// Se il flag ha quel valore salta all'etichetta, altrimenti prosegue.
function IfFlag(Name flagName, bool value, string l)
{
	local ConEventCheckFlag e;
	local ConFlagRef r;

	r = new(Outer) class'ConFlagRef';
	r.flagName = flagName;
	r.value = value;

	e = new(Outer) class'ConEventCheckFlag';
	e.eventType = ET_CheckFlag;
	e.flagRef = r;
	e.setLabel = l;
	Add(e);
}

// Fine della conversazione a meta' lista (dopo un ramo di una scelta).
function EndHere()
{
	local ConEventEnd e;

	e = new(Outer) class'ConEventEnd';
	e.eventType = ET_End;
	Add(e);
}

// Requisito: la conversazione parte solo se il flag ha quel valore.
function Require(Name flagName, bool value)
{
	local ConFlagRef r;

	r = new(Outer) class'ConFlagRef';
	r.flagName = flagName;
	r.value = value;
	r.nextFlagRef = con.flagRefList;
	con.flagRefList = r;
}

// Si puo' sentire una volta sola (flag <nome>_Played).
function Once()
{
	con.bDisplayOnce = True;
}

// Aggiunge la conversazione in testa alla lista del PNG: cliccandolo parte
// questa (se i requisiti sono soddisfatti) al posto di quelle vanilla.
function AttachTo(Actor npc)
{
	local ConListItem item;

	if (npc == None)
		return;
	// PlayConv may retry while the player is busy. Do not attach duplicates.
	for (item = ConListItem(npc.ConListItems); item != None; item = item.next)
		if (item.con == con)
			return;
	item = new(Outer) class'ConListItem';
	item.con = con;
	item.next = ConListItem(npc.ConListItems);
	npc.ConListItems = item;
}

// Conversazione senza scelte che scorre da sola (niente clic).
function Passive()
{
	con.bNonInteractive = True;
}

function Add(ConEvent e)
{
	e.conversation = con;
	if (pendingLabel != "")
	{
		e.label = pendingLabel;
		pendingLabel = "";
	}
	if (last == None)
		con.eventList = e;
	else
		last.nextEvent = e;
	last = e;
}

function Line(string speaker, string speakingTo, string text)
{
	local ConEventSpeech e;
	local ConSpeech s;
	local ConEventMoveCamera shot;

	// Native camera events cut to the person speaking, before the text/audio.
	// Keep the shot for consecutive sentences by the same pair of actors.
	if (!con.bFirstPerson && !bFixedCamera && (speaker != lastSpeakerName || speakingTo != lastSpeakingToName))
	{
		shot = new(Outer) class'ConEventMoveCamera';
		shot.eventType = ET_MoveCamera;
		shot.cameraType = CT_Predefined;
		shot.cameraTransition = TR_Jump;
		if (speaker == "JCDenton")
			shot.cameraPosition = CP_HeadShotSlightRight;
		else
			shot.cameraPosition = CP_HeadShotSlightLeft;
		Add(shot);
	}
	lastSpeakerName = speaker;
	lastSpeakingToName = speakingTo;

	s = new(Outer) class'ConSpeech';
	s.speech = text;
	s.soundID = -1;

	e = new(Outer) class'ConEventSpeech';
	e.eventType = ET_Speech;
	e.speakerName = speaker;
	e.speakingToName = speakingTo;
	e.conSpeech = s;
	Add(e);
}

function SetFlag(Name flagName, bool value)
{
	local ConEventSetFlag e;
	local ConFlagRef r;

	r = new(Outer) class'ConFlagRef';
	r.flagName = flagName;
	r.value = value;
	r.expiration = 0;
	if (Left(string(flagName), 3) == "UC_")
		r.expiration = 99;

	e = new(Outer) class'ConEventSetFlag';
	e.eventType = ET_SetFlag;
	e.flagRef = r;
	Add(e);
}

function Goal(Name goalName, string text, bool bCompleted, optional bool bSecondary)
{
	local ConEventAddGoal e;

	e = new(Outer) class'ConEventAddGoal';
	e.eventType = ET_AddGoal;
	e.goalName = goalName;
	e.goalText = text;
	e.bGoalCompleted = bCompleted;
	e.bPrimaryGoal = !bSecondary;
	Add(e);
}

function Trigger(Name tagName)
{
	local ConEventTrigger e;

	e = new(Outer) class'ConEventTrigger';
	e.eventType = ET_Trigger;
	e.triggerTag = tagName;
	Add(e);
}

function Done()
{
	local ConEventEnd e;

	e = new(Outer) class'ConEventEnd';
	e.eventType = ET_End;
	Add(e);
}

// Original conversation copies retain native conditions and event properties.
function LastProp(string propertyName, string value)
{
	if (last != None) last.SetPropertyText(propertyName, value);
}

function ConProp(string propertyName, string value)
{
	con.SetPropertyText(propertyName, value);
}

function NativeEvent(name kind)
{
	local ConEvent e;
	switch(kind)
	{
		case 'Comment': e=new(Outer) class'ConEventComment'; e.eventType=ET_Comment; break;
		case 'AddNote': e=new(Outer) class'ConEventAddNote'; e.eventType=ET_AddNote; break;
		case 'AddCredits': e=new(Outer) class'ConEventAddCredits'; e.eventType=ET_AddCredits; break;
		case 'AddSkillPoints': e=new(Outer) class'ConEventAddSkillPoints'; e.eventType=ET_AddSkillPoints; break;
		case 'CheckObject': e=new(Outer) class'ConEventCheckObject'; e.eventType=ET_CheckObject; break;
		case 'CheckPersona': e=new(Outer) class'ConEventCheckPersona'; e.eventType=ET_CheckPersona; break;
		case 'Animation': e=new(Outer) class'ConEventAnimation'; e.eventType=ET_Animation; break;
		case 'Trade': e=new(Outer) class'ConEventTrade'; e.eventType=ET_Trade; break;
	}
	if (e != None) Add(e);
}

function LastFlags(name flagName, bool value, int expiration, optional bool first)
{
	local ConFlagRef f;
	f=new(Outer) class'ConFlagRef'; f.flagName=flagName; f.value=value; f.expiration=expiration;
	if (ConEventSetFlag(last) != None)
	{
		if (!first) f.nextFlagRef=ConEventSetFlag(last).flagRef;
		ConEventSetFlag(last).flagRef=f;
	}
	else if (ConEventCheckFlag(last) != None)
	{
		if (!first) f.nextFlagRef=ConEventCheckFlag(last).flagRef;
		ConEventCheckFlag(last).flagRef=f;
	}
}

function AnswerDetails(string skillName, int skillLevel, bool displaySpeech)
{
	lastAnswer=ConEventChoice(last).ChoiceList;
	while (lastAnswer != None && lastAnswer.nextChoice != None) lastAnswer=lastAnswer.nextChoice;
	if (lastAnswer == None) return;
	if (skillName != "") lastAnswer.skillNeeded=class<Skill>(DynamicLoadObject(skillName,class'Class',True));
	lastAnswer.skillLevelNeeded=skillLevel;
	lastAnswer.bDisplayAsSpeech=displaySpeech;
}

function AnswerFlag(name flagName, bool value, int expiration)
{
	local ConFlagRef f;
	if (lastAnswer == None) return;
	f=new(Outer) class'ConFlagRef'; f.flagName=flagName; f.value=value; f.expiration=expiration;
	f.nextFlagRef=lastAnswer.flagRef; lastAnswer.flagRef=f;
}

function RandomBegin(Actor context, bool cycle, bool once, bool shuffle)
{
	randomBranch=context.Spawn(class'UCConRandom',context);
	randomBranch.Tag=randomBranch.Name;
	randomBranch.cycle=cycle; randomBranch.once=once; randomBranch.shuffle=shuffle;
	Trigger(randomBranch.Tag);
	Jump("");
	randomBranch.target=ConEventJump(last);
}

function RandomLabel(string labelName)
{
	if (randomBranch != None) randomBranch.AddLabel(labelName);
}

defaultproperties
{
}
