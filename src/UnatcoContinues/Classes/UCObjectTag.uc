// Sparse manual overrides for logical scripting tags. Native Tag/Event are untouched.
// Automatic tags are computed at action execution, including later faction changes.
class UCObjectTag extends Info;

var() name TargetName;
var() string Value;
var() bool bAuto;
var() bool bOriginal;

static function string Automatic(Actor A)
{
	local ScriptedPawn S;
	local int h, i, anchor, d, best;
	local string color;
	if (A == None) return "";
	if (Light(A) != None)
	{
		if (A.LightSaturation >= 220) return "white";
		h = A.LightHue;
		best = 999;
		for (i=0; i<9; i++)
		{
			switch (i)
			{
				case 0: anchor=0; break;
				case 1: anchor=21; break;
				case 2: anchor=43; break;
				case 3: anchor=85; break;
				case 4: anchor=128; break;
				case 5: anchor=170; break;
				case 6: anchor=191; break;
				case 7: anchor=213; break;
				case 8: anchor=234; break;
			}
			d = Abs(h-anchor);
			d = Min(d,255-d);
			if (d < best)
			{
				best = d;
				switch (i)
				{
					case 0: color="red"; break;
					case 1: color="orange"; break;
					case 2: color="yellow"; break;
					case 3: color="green"; break;
					case 4: color="cyan"; break;
					case 5: color="blue"; break;
					case 6: color="purple"; break;
					case 7: color="magenta"; break;
					case 8: color="pink"; break;
				}
			}
		}
		return color;
	}
	S = ScriptedPawn(A);
	if (S != None)
	{
		if (S.GetAllianceType('Player') == ALLIANCE_Hostile) return "enemy";
		if (S.GetAllianceType('Player') == ALLIANCE_Friendly || S.Alliance == 'Player') return "friendly";
		return "neutral";
	}
	if (PlayerPawn(A) != None) return "player";
	if (Mover(A) != None) return "door";
	if (A.IsA('Button1') || A.IsA('Switch1')) return "button";
	if (A.IsA('SecurityCamera')) return "camera";
	if (A.IsA('Trigger')) return "trigger";
	if (A.IsA('PathNode') || A.IsA('PatrolPoint')) return "path";
	if (Inventory(A) != None) return "item";
	if (Decoration(A) != None) return "object";
	return string(A.Class.Name);
}

static function string Of(Actor A)
{
	local UCObjectTag T;
	if (A == None) return "";
	foreach A.AllActors(class'UCObjectTag',T)
		if (T.TargetName == A.Name && !T.bDeleteMe)
		{
			if (T.bAuto) return Automatic(A);
			if (T.bOriginal) return InheritedTag(A);
			return T.Value;
		}
	return InheritedTag(A);
}

static function string InheritedTag(Actor A)
{
	// Untouched original actors keep their authored tags; new actors normally have class tags.
	if (A.Tag != '' && A.Tag != 'None' && A.Tag != A.Class.Name) return string(A.Tag);
	return Automatic(A);
}

static function bool Matches(Actor A, string wanted)
{
	return wanted == "" || Of(A) ~= wanted;
}

defaultproperties
{
	bHidden=True
	bStatic=False
}
