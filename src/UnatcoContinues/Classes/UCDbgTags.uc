//=============================================================================
// UCDbgTags - scrive nel log (Revision.log) cosa c'e' con certi tag vanilla.
//   summon UnatcoContinues.UCDbgTags
//=============================================================================
class UCDbgTags extends UCDebug;

function Dump(Name tagName)
{
	local Actor A;
	local int n;

	foreach AllActors(class'Actor', A, tagName)
	{
		n++;
		Log("UnatcoContinues: tag" @ tagName @ ":" @ string(A.Class) @ "@" @ int(A.Location.X) $ "," $ int(A.Location.Y) $ "," $ int(A.Location.Z) @ "event:" @ A.Event);
	}
	Player.ClientMessage("[UC] tag " $ tagName $ ": " $ n);
}

function Run()
{
	Dump('SetPaulGoing');
	Dump('PaulLeaves');
	Dump('PaulExit');
	Dump('BedroomWindow');
	Dump('BailedOutWindow');
	Dump('ShowerPaul');
	Dump('PaulDenton');
	Dump('Jock');
	Dump('JockTakesOff');
	Dump('MadeItToHelicopter');
	Destroy();
}

defaultproperties
{
     bKeepTour=True
}
