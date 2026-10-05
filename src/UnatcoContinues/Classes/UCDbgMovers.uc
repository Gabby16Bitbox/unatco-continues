//=============================================================================
// UCDbgMovers - scrive nel log i mover vicini a JC (nome, Tag, posizione, nascosto,
// collisione, stato) per capire cosa si vede davvero in una scena.
//   summon UnatcoContinues.UCDbgMovers
//=============================================================================
class UCDbgMovers extends Actor
	transient;

function PostBeginPlay()
{
	local DeusExPlayer P;
	local Mover m;
	local int n;

	Super.PostBeginPlay();
	P = DeusExPlayer(GetPlayerPawn());
	if (P != None)
	{
		Log("UCDbgMovers: JC a" @ P.Location);
		foreach AllActors(class'Mover', m)
		{
			if (VSize(m.Location - P.Location) > 900 && VSize(m.BasePos - P.Location) > 900)
				continue;
			Log("UCDbgMovers:" @ m.Name @ "Tag=" $ m.Tag @ "Loc=" $ m.Location @ "BasePos=" $ m.BasePos
				@ "bHidden=" $ m.bHidden @ "coll=" $ m.bCollideActors @ "state=" $ m.GetStateName()
				@ "phys=" $ m.Physics @ "dyn=" $ m.bDynamicLightMover);
			n++;
		}
		P.ClientMessage("[UC] mover vicini scritti nel log (" $ n $ ")");
	}
	Destroy();
}

defaultproperties
{
     bHidden=True
}
