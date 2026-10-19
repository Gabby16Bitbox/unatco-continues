//=============================================================================
// UCUsable - an object of the map that JC can use, made in the map editor (Properties > Usable): any
// decoration (a model of the Models tab, an object of the palette). The editor places one per usable
// object (editor\links.py, edits['usable']); it hooks itself to the object when the map starts (the
// object's Event becomes this actor's Tag; the event the object had is still triggered), and gives it
// the use text JC reads when he looks at it ("Defuse").
//   UseTime 0: used at once. More: JC is busy that long (a bar on the screen), crouching if bCrouch;
//   walking away, a conversation or the object vanishing cancels it.
//   NeedItem: the class of an item JC must carry (DeusEx.Multitool); bConsume uses one up.
//   Uses: how many times (0 = always); after the last one the object is an ordinary object again.
//   bHiddenAtStart: the object is not there until an interaction shows it ("Appear again").
// When JC has finished using it, the interactions "When JC uses it" of the object run (UseEvent,
// UCL_<object>_Used: their UCLink does not hook the object itself).
//=============================================================================
class UCUsable extends UCEditorStory;

var() string Target;        // the object (its name in the map)
var() string UseText;       // what JC reads when he looks at it
var() float  UseTime;       // seconds JC is busy (0 = at once)
var() bool   bCrouch;       // JC crouches while he uses it
var() string NeedItem;      // class of an item JC must carry ("" = nothing)
var() string NeedText;      // what JC is told when he has not got it ("" = "You need ...")
var() bool   bConsume;      // the item is used up (one of it)
var() int    Uses;          // times it can be used (0 = always)
var() bool   bHiddenAtStart;
var() name   UseEvent;      // the interactions of "JC uses it"

var name   PassEvent;       // the object's own event before this took it
var bool   bReady;          // hooked and set up (once: a loaded game keeps it)
var bool   bSpent;          // used as many times as it could
var int    UsedCount;
var string OrigName;        // the object's name before the use text
var bool   OrigHighlight;
var DeusExPlayer User;      // JC while he is using it
var float  Busy;            // seconds of the use done
var vector BusyFrom;        // where JC stood when he began
var bool   bDucked;         // this made JC crouch
var transient UCUseWindow Win;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0, False);
	Setup();
}

function Actor Obj()
{
	local Actor A;

	if (Target == "")
		return None;
	foreach AllActors(class'Actor', A)
		if (string(A.Name) ~= Target && !A.bDeleteMe)
			return A;
	return None;
}

function Setup()
{
	local Actor A;
	local DeusExDecoration D;

	if (bReady)
		return;
	A = Obj();
	if (A == None)
	{
		Log("UCUsable" @ Name @ "- its object" @ Target @ "is not in the map");
		return;
	}
	bReady = True;
	if (A.Event != Tag)
	{
		PassEvent = A.Event;
		A.Event = Tag;
	}
	D = DeusExDecoration(A);
	if (D != None)
	{
		OrigName = D.ItemName;
		OrigHighlight = D.bHighlight;
		D.bHighlight = True;
		D.bPushable = False;            // (a pushable object would be picked up instead of used)
		D.ItemName = Shown(OrigName);
	}
	if (bHiddenAtStart)
	{
		A.bHidden = True;
		A.SetCollision(False, False, False);
	}
}

// what JC reads: the use text, after the object's own name when it has one
function string Shown(string itemName)
{
	if (UseText == "")
		return itemName;
	if (itemName == "" || itemName ~= "Object" || itemName ~= "DEFAULT DECORATION NAME - REPORT THIS AS A BUG")
		return UseText;
	return itemName $ ": " $ UseText;
}

function bool CanUse(Actor A)
{
	return bReady && !bSpent && A != None && !A.bHidden && !A.bDeleteMe;
}

// the object was used (JC's click: DeusExDecoration.Frob triggers its Event)
function Trigger(Actor Other, Pawn EventInstigator)
{
	local Actor A;
	local DeusExPlayer P;

	if (PassEvent != '')
		foreach AllActors(class'Actor', A, PassEvent)
			A.Trigger(Other, EventInstigator);
	A = Obj();
	P = DeusExPlayer(EventInstigator);
	if (P == None || Other != A || !CanUse(A) || User != None)
		return;
	if (!HasNeed(P))
		return;
	if (UseTime <= 0)
		Done(P);
	else
		StartUse(P);
}

function UnTrigger(Actor Other, Pawn EventInstigator)
{
	local Actor A;

	if (PassEvent != '')
		foreach AllActors(class'Actor', A, PassEvent)
			A.UnTrigger(Other, EventInstigator);
}

function class<Inventory> NeedClass()
{
	if (NeedItem == "")
		return None;
	return class<Inventory>(DynamicLoadObject(NeedItem, class'Class', True));
}

function bool HasNeed(DeusExPlayer P)
{
	local class<Inventory> cls;

	cls = NeedClass();
	if (cls == None || P.FindInventoryType(cls) != None)
		return True;
	if (NeedText != "")
		P.ClientMessage(NeedText);
	else
		P.ClientMessage("You need" @ cls.default.ItemArticle @ cls.default.ItemName $ ".");
	return False;
}

function StartUse(DeusExPlayer P)
{
	local DeusExRootWindow root;

	User = P;
	Busy = 0;
	BusyFrom = P.Location;
	if (bCrouch && P.bDuck == 0)
	{
		P.bDuck = 1;                    // (as if he held the crouch key: PlayerPawn crouches while bDuck)
		bDucked = True;
	}
	root = DeusExRootWindow(P.rootWindow);
	if (root != None)
	{
		Win = UCUseWindow(root.NewChild(class'UCUseWindow'));
		if (Win != None)
		{
			Win.SetPos(0, 0);
			Win.SetSize(root.width, root.height);
			Win.label = UseText;
		}
	}
	Log("UCUsable" @ Name @ "- JC uses" @ Target @ "(" $ UseTime @ "s)");
}

function EndBusy()
{
	if (bDucked && User != None)
	{
		User.bDuck = 0;
		if (User.bToggleCrouch)
		{
			User.bCrouchOn = False;
			User.bWasCrouchOn = False;
		}
	}
	bDucked = False;
	User = None;
	Busy = 0;
	if (Win != None)
		Win.Destroy();
	Win = None;
}

function Cancel(string why)
{
	Log("UCUsable" @ Name @ "- use of" @ Target @ "cancelled:" @ why);
	EndBusy();
}

function Done(DeusExPlayer P)
{
	local class<Inventory> cls;
	local Inventory item;
	local DeusExDecoration D;

	cls = NeedClass();
	if (bConsume && cls != None)
	{
		item = P.FindInventoryType(cls);
		if (DeusExPickup(item) != None)
			DeusExPickup(item).UseOnce();
		else if (item != None)
		{
			if (P.inHand == item)
				P.PutInHand(None);
			P.DeleteInventory(item);
			item.Destroy();
		}
	}
	UsedCount++;
	EndBusy();
	if (Uses > 0 && UsedCount >= Uses)
	{
		bSpent = True;                  // an ordinary object again
		D = DeusExDecoration(Obj());
		if (D != None)
		{
			D.ItemName = OrigName;
			D.bHighlight = OrigHighlight;
		}
	}
	Log("UCUsable" @ Name @ "- JC has used" @ Target @ "(" $ UsedCount $ ")");
	if (UseEvent != '')
		TriggerTag(UseEvent);
}

function Tick(float deltaTime)
{
	local Actor A;

	Super.Tick(deltaTime);
	if (!bReady)
		Setup();
	if (User == None)
		return;
	A = Obj();
	if (User.bDeleteMe || User.Health <= 0 || User.IsInState('Dying'))
		Cancel("JC is down");
	else if (A == None || A.bHidden)
		Cancel("the object is gone");
	else if (VSize((User.Location - BusyFrom) * vect(1,1,0)) > 40)
		Cancel("JC walked away");
	else if (User.conPlay != None || InCutscene())
		Cancel("a conversation");
	else
	{
		if (bDucked)
			User.bDuck = 1;
		Busy += deltaTime;
		if (Win != None)
			Win.progress = FClamp(Busy / UseTime, 0, 1);
		if (Busy >= UseTime)
			Done(User);
	}
}

defaultproperties
{
     UseText="Use"
     bRouteOnly=False
}
