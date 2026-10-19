//=============================================================================
// UCHeliBlock - an invisible piece of a landed helicopter where its collision does not reach (Gabby, 18 Oct
// 2026: JC walked through Eva's helicopter). A BlackHelicopter's collision is one cylinder round its middle,
// the fuselage is long: the tail boom sticks out of it at JC's height. A row of these along the boom, placed
// and removed with the helicopter (Follow: when it lands, when it takes off). They only block: the
// crosshair goes through them (not frobbable), so a click still reaches the helicopter and Eva.
//=============================================================================
class UCHeliBlock extends Actor;

var BlackHelicopter Heli;

// bOn: a row along the tail boom of h as it stands now (the old row removed); off: none
static function Follow(BlackHelicopter h, bool bOn)
{
	local UCHeliBlock b;
	local vector X, Y, Z;
	local float s, d;

	if (h == None)
		return;
	foreach h.AllActors(class'UCHeliBlock', b)
		if (b.Heli == h)
			b.Destroy();
	if (!bOn)
		return;
	s = h.DrawScale;
	GetAxes(h.Rotation, X, Y, Z);
	X.Z = 0;
	X = Normal(X);
	// the boom runs back from the middle to about 450 units (at DrawScale 1), 30 to 70 units under the
	// middle; the tail fin rises a little above it
	for (d = h.CollisionRadius + 16; d < 450 * s; d += 30)
	{
		b = h.Spawn(class'UCHeliBlock', h,, h.Location - X * d - vect(0,0,30) * s);
		if (b == None)
			continue;
		b.Heli = h;
		b.SetCollisionSize(18, 42 * s);
		b.SetCollision(True, True, True);
	}
}

defaultproperties
{
     bHidden=True
     RemoteRole=ROLE_None
     CollisionRadius=18.000000
     CollisionHeight=42.000000
}
