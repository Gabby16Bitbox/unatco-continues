//=============================================================================
// UCNavMesh - the walkable area of the map for the game's scripts (Gabby, 17 Oct 2026). The map editor makes
// it with Recast (View > Walkable area) and bakes it at Rebuild, as polygons, when characters of the map are
// sent somewhere "on the walkable area" (Walk / Run to a place). Plain UnrealScript, no native code: it works
// the same in Revision and in the original Deus Ex.
//
// Route(from, to): A* over the polygons, then the funnel (the straight line that cuts the corners, as Detour
// does): Corner[0..NumCorners-1], the last one is "to". UCNavRoute walks a character through them with the
// game's own GoingTo / RunningTo, so it opens doors, turns and animates as the game does.
//
// Each Poly is "nv x y z ... n ...": its nv corners (Unreal units, on the floor), then, for each edge (corner
// k to k+1), the polygon across it or -1. For scripts:
//     class'UCNavRoute'.static.Send(somePawn, aPlace, bRun)
//     M = class'UCNavMesh'.static.Of(self); if (M != None && M.Route(a, b)) ... M.CornerAt(i) ...
//=============================================================================
class UCNavMesh extends Info;

var() string Poly[2048];
var() int NumPolys;

var transient bool bLoaded;
var transient int NV[2048];
var transient float VX[12288], VY[12288], VZ[12288];     // corners: polygon p, corner k at p * 6 + k
var transient int NB[12288];
var transient float CX[2048], CY[2048], CZ[2048];
var transient float MinX[2048], MinY[2048], MaxX[2048], MaxY[2048], MinZ[2048], MaxZ[2048];
// the search
var transient float G[2048], F[2048];
var transient int From[2048], Seen[2048], Done[2048], Heap[2048], HeapPos[2048];
var transient int HeapN, Search;
var transient int Way[2048];
var transient int NumWay;
// the portals between the polygons of the way, and the route
var transient float LX[2049], LY[2049], LZ[2049], RX[2049], RY[2049], RZ[2049];
var transient vector Corner[64];
var transient int NumCorners;

// The map's walkable area, or None.
static function UCNavMesh Of(Actor anyone)
{
	local UCNavMesh M;

	if (anyone == None)
		return None;
	foreach anyone.AllActors(class'UCNavMesh', M)
		break;
	return M;
}

// the next integer of s (space separated); s keeps the rest
function int NextInt(out string s)
{
	local int i;
	local string t;

	i = InStr(s, " ");
	if (i < 0)
	{
		t = s;
		s = "";
	}
	else
	{
		t = Left(s, i);
		s = Mid(s, i + 1);
	}
	return int(t);
}

function bool Load()
{
	local int p, k, n, b;
	local string s;

	if (bLoaded)
		return NumPolys > 0;
	bLoaded = True;
	if (NumPolys > 2048)
		NumPolys = 2048;
	for (p = 0; p < NumPolys; p++)
	{
		s = Poly[p];
		n = NextInt(s);
		NV[p] = 0;
		if (n < 3 || n > 6)
			continue;
		NV[p] = n;
		b = p * 6;
		CX[p] = 0;
		CY[p] = 0;
		CZ[p] = 0;
		for (k = 0; k < n; k++)
		{
			VX[b + k] = NextInt(s);
			VY[b + k] = NextInt(s);
			VZ[b + k] = NextInt(s);
			CX[p] += VX[b + k];
			CY[p] += VY[b + k];
			CZ[p] += VZ[b + k];
			if (k == 0 || VX[b + k] < MinX[p]) MinX[p] = VX[b + k];
			if (k == 0 || VX[b + k] > MaxX[p]) MaxX[p] = VX[b + k];
			if (k == 0 || VY[b + k] < MinY[p]) MinY[p] = VY[b + k];
			if (k == 0 || VY[b + k] > MaxY[p]) MaxY[p] = VY[b + k];
			if (k == 0 || VZ[b + k] < MinZ[p]) MinZ[p] = VZ[b + k];
			if (k == 0 || VZ[b + k] > MaxZ[p]) MaxZ[p] = VZ[b + k];
		}
		for (k = 0; k < n; k++)
			NB[b + k] = NextInt(s);
		CX[p] /= n;
		CY[p] /= n;
		CZ[p] /= n;
	}
	Log("UCNavMesh:" @ NumPolys @ "polygons");
	return NumPolys > 0;
}

// x, y inside polygon i (seen from above; either winding)
function bool Inside(int i, float x, float y)
{
	local int k, k2, b, n, pos, neg;
	local float c;

	b = i * 6;
	n = NV[i];
	for (k = 0; k < n; k++)
	{
		k2 = k + 1;
		if (k2 == n)
			k2 = 0;
		c = (VX[b + k2] - VX[b + k]) * (y - VY[b + k]) - (VY[b + k2] - VY[b + k]) * (x - VX[b + k]);
		if (c > 0.5)
			pos++;
		else if (c < -0.5)
			neg++;
	}
	return pos == 0 || neg == 0;
}

// How far x, y is from polygon i, seen from above (0: inside it).
function float PolyDist(int i, float x, float y)
{
	local int k, k2, b, n;
	local float ex, ey, f, dx, dy, d, best;

	if (Inside(i, x, y))
		return 0;
	b = i * 6;
	n = NV[i];
	best = 100000000;
	for (k = 0; k < n; k++)
	{
		k2 = k + 1;
		if (k2 == n)
			k2 = 0;
		ex = VX[b + k2] - VX[b + k];
		ey = VY[b + k2] - VY[b + k];
		f = ex * ex + ey * ey;
		if (f > 0)
			f = FClamp(((x - VX[b + k]) * ex + (y - VY[b + k]) * ey) / f, 0, 1);
		dx = VX[b + k] + ex * f - x;
		dy = VY[b + k] + ey * f - y;
		d = dx * dx + dy * dy;
		if (d < best)
			best = d;
	}
	return Sqrt(best);
}

// The polygon under p (a character's location, or a place: up to 140 units over its floor), or -1. Just off
// the mesh (it keeps 20 units from the walls: a place by a wall), the nearest polygon within 200 units.
function int FindPoly(vector p)
{
	local int i, best, near;
	local float d, bestD, nearD;

	best = -1;
	near = -1;
	bestD = 1000000;
	nearD = 200;
	for (i = 0; i < NumPolys; i++)
	{
		if (NV[i] == 0 || p.Z < MinZ[i] - 40 || p.Z > MaxZ[i] + 140)
			continue;
		if (p.X < MinX[i] - nearD || p.X > MaxX[i] + nearD || p.Y < MinY[i] - nearD || p.Y > MaxY[i] + nearD)
			continue;
		d = PolyDist(i, p.X, p.Y);
		if (d == 0)
		{
			d = Abs(p.Z - (CZ[i] + 45));
			if (d < bestD)
			{
				bestD = d;
				best = i;
			}
		}
		else if (best < 0 && d < nearD)
		{
			nearD = d;
			near = i;
		}
	}
	if (best >= 0)
		return best;
	return near;
}

// ---------------------------------------------------------------- A* over the polygons
function HeapUp(int i)
{
	local int par, p;

	p = Heap[i];
	while (i > 0)
	{
		par = (i - 1) / 2;
		if (F[Heap[par]] <= F[p])
			break;
		Heap[i] = Heap[par];
		HeapPos[Heap[i]] = i;
		i = par;
	}
	Heap[i] = p;
	HeapPos[p] = i;
}

function HeapPush(int p)
{
	Heap[HeapN] = p;
	HeapPos[p] = HeapN;
	HeapN++;
	HeapUp(HeapN - 1);
}

function int HeapPop()
{
	local int top, p, i, c;

	top = Heap[0];
	HeapN--;
	if (HeapN > 0)
	{
		p = Heap[HeapN];
		i = 0;
		while (True)
		{
			c = i * 2 + 1;
			if (c >= HeapN)
				break;
			if (c + 1 < HeapN && F[Heap[c + 1]] < F[Heap[c]])
				c++;
			if (F[Heap[c]] >= F[p])
				break;
			Heap[i] = Heap[c];
			HeapPos[Heap[i]] = i;
			i = c;
		}
		Heap[i] = p;
		HeapPos[p] = i;
	}
	return top;
}

function float CentreDist(int a, int b)
{
	return Sqrt((CX[a] - CX[b]) * (CX[a] - CX[b]) + (CY[a] - CY[b]) * (CY[a] - CY[b]) + (CZ[a] - CZ[b]) * (CZ[a] - CZ[b]));
}

// The polygons from s to t (Way[0..NumWay-1]), or False when t cannot be reached from s.
function bool FindWay(int s, int t)
{
	local int p, q, k, b, n, steps;
	local float cost;

	Search++;
	HeapN = 0;
	G[s] = 0;
	F[s] = CentreDist(s, t);
	From[s] = -1;
	Seen[s] = Search;
	HeapPush(s);
	while (HeapN > 0 && steps < 4096)
	{
		steps++;
		p = HeapPop();
		if (p == t)
			break;
		Done[p] = Search;
		b = p * 6;
		n = NV[p];
		for (k = 0; k < n; k++)
		{
			q = NB[b + k];
			if (q < 0 || q >= NumPolys || NV[q] == 0 || Done[q] == Search)
				continue;
			cost = G[p] + CentreDist(p, q);
			if (Seen[q] != Search)
			{
				Seen[q] = Search;
				G[q] = cost;
				F[q] = cost + CentreDist(q, t);
				From[q] = p;
				HeapPush(q);
			}
			else if (cost < G[q])
			{
				G[q] = cost;
				F[q] = cost + CentreDist(q, t);
				From[q] = p;
				HeapUp(HeapPos[q]);
			}
		}
	}
	if (Seen[t] != Search)
		return False;
	NumWay = 0;
	for (p = t; p >= 0 && NumWay < 2048; p = From[p])
	{
		Way[NumWay] = p;
		NumWay++;
	}
	for (k = 0; k < NumWay / 2; k++)              // start first
	{
		p = Way[k];
		Way[k] = Way[NumWay - 1 - k];
		Way[NumWay - 1 - k] = p;
	}
	return True;
}

// ---------------------------------------------------------------- the funnel
// twice the signed area of a, b, c (seen from above)
function float Area2(float px, float py, float qx, float qy, float sx, float sy)
{
	return (sx - px) * (qy - py) - (qx - px) * (sy - py);
}

// portal i: the edge shared by Way[i - 1] and Way[i], its left and right ends as one walks through it
function bool Portal(int i)
{
	local int a, c, k, k2, b, n;
	local float dx, dy, mx, my;

	a = Way[i - 1];
	c = Way[i];
	b = a * 6;
	n = NV[a];
	for (k = 0; k < n; k++)
		if (NB[b + k] == c)
			break;
	if (k == n)
		return False;
	k2 = k + 1;
	if (k2 == n)
		k2 = 0;
	dx = CX[c] - CX[a];
	dy = CY[c] - CY[a];
	mx = (VX[b + k] + VX[b + k2]) / 2;
	my = (VY[b + k] + VY[b + k2]) / 2;
	if (dx * (VY[b + k] - my) - dy * (VX[b + k] - mx) > 0)     // corner k on the left
	{
		LX[i] = VX[b + k];  LY[i] = VY[b + k];  LZ[i] = VZ[b + k];
		RX[i] = VX[b + k2]; RY[i] = VY[b + k2]; RZ[i] = VZ[b + k2];
	}
	else
	{
		LX[i] = VX[b + k2]; LY[i] = VY[b + k2]; LZ[i] = VZ[b + k2];
		RX[i] = VX[b + k];  RY[i] = VY[b + k];  RZ[i] = VZ[b + k];
	}
	return True;
}

// a corner of the route at an end of portal i (bLeft: its left end), 20 units into the portal (off the wall)
function AddCorner(int i, bool bLeft)
{
	local vector c, o;
	local float w;

	if (NumCorners >= 63)
		return;
	if (bLeft)
	{
		c.X = LX[i]; c.Y = LY[i]; c.Z = LZ[i];
		o.X = RX[i]; o.Y = RY[i]; o.Z = RZ[i];
	}
	else
	{
		c.X = RX[i]; c.Y = RY[i]; c.Z = RZ[i];
		o.X = LX[i]; o.Y = LY[i]; o.Z = LZ[i];
	}
	w = VSize((o - c) * vect(1,1,0));
	if (w > 1)
		c += (o - c) * (FMin(20, w / 2) / w);
	Corner[NumCorners] = c;
	NumCorners++;
}

// The corners of the way from a to b (b the last one; the others on the floor).
function MakeCorners(vector a, vector b)
{
	local int n, i, apex, left, right;
	local float apexX, apexY, leftX, leftY, rightX, rightY;

	n = NumWay + 1;                 // portal 0: the start, 1..NumWay-1: the edges, NumWay: the end
	LX[0] = a.X; LY[0] = a.Y; LZ[0] = a.Z; RX[0] = a.X; RY[0] = a.Y; RZ[0] = a.Z;
	LX[NumWay] = b.X; LY[NumWay] = b.Y; LZ[NumWay] = b.Z; RX[NumWay] = b.X; RY[NumWay] = b.Y; RZ[NumWay] = b.Z;
	for (i = 1; i < NumWay; i++)
		if (!Portal(i))
		{
			LX[i] = CX[Way[i]]; LY[i] = CY[Way[i]]; LZ[i] = CZ[Way[i]];
			RX[i] = LX[i]; RY[i] = LY[i]; RZ[i] = LZ[i];
		}
	NumCorners = 0;
	apexX = a.X; apexY = a.Y;
	leftX = LX[0]; leftY = LY[0];
	rightX = RX[0]; rightY = RY[0];
	apex = 0; left = 0; right = 0;
	for (i = 1; i < n && NumCorners < 63; i++)
	{
		// the right side of the funnel
		if (Area2(apexX, apexY, rightX, rightY, RX[i], RY[i]) <= 0)
		{
			if ((apexX == rightX && apexY == rightY) || Area2(apexX, apexY, leftX, leftY, RX[i], RY[i]) > 0)
			{
				rightX = RX[i]; rightY = RY[i];
				right = i;
			}
			else
			{
				AddCorner(left, True);              // the right side crossed the left: turn at the left
				apex = left;
				apexX = leftX; apexY = leftY;
				rightX = apexX; rightY = apexY;
				right = apex;
				i = apex;
				continue;
			}
		}
		// the left side
		if (Area2(apexX, apexY, leftX, leftY, LX[i], LY[i]) >= 0)
		{
			if ((apexX == leftX && apexY == leftY) || Area2(apexX, apexY, rightX, rightY, LX[i], LY[i]) < 0)
			{
				leftX = LX[i]; leftY = LY[i];
				left = i;
			}
			else
			{
				AddCorner(right, False);
				apex = right;
				apexX = rightX; apexY = rightY;
				leftX = apexX; leftY = apexY;
				left = apex;
				i = apex;
				continue;
			}
		}
	}
	if (NumCorners > 0 && VSize(Corner[NumCorners - 1] - b) < 2)
		NumCorners--;                       // the funnel's last turn was at the place itself
	Corner[NumCorners] = b;
	NumCorners++;
}

// corner i of the last route (other objects' code cannot index Corner itself: it is too big)
function vector CornerAt(int i)
{
	return Corner[i];
}

// The route from a to b on the walkable area: Corner[0..NumCorners-1] (b the last). False: no way on it.
function bool Route(vector a, vector b)
{
	local int s, t;

	NumCorners = 0;
	if (!Load())
		return False;
	s = FindPoly(a);
	t = FindPoly(b);
	if (s < 0 || t < 0)
		return False;
	if (s == t)
	{
		Corner[0] = b;
		NumCorners = 1;
		return True;
	}
	if (!FindWay(s, t))
		return False;
	MakeCorners(a, b);
	return NumCorners > 0;
}

defaultproperties
{
     bHidden=True
}
