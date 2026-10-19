// A native Trigger followed by a Jump implements editable random/cyclic branches.
// The helper and its sequence state belong to the level, so saving preserves the cycle.
class UCConRandom extends Info;

var ConEventJump target;
var string labels[64];
var int count, index;
var bool cycle, once, shuffle;

function AddLabel(string labelName)
{
	if (count<ArrayCount(labels)) labels[count++]=labelName;
}

function Trigger(Actor other, Pawn instigator)
{
	local int pick;
	if (target == None || count == 0)
		return;
	// ConSys: cycle-once repeats the last label. Cycle-random walks the list once,
	// then chooses freely (with repetition); it does not shuffle the initial cycle.
	if (!cycle || (shuffle && index>=count)) pick=Rand(count);
	else
	{
		pick=index % count;
		if (!once || index<count-1) index++;
	}
	target.jumpLabel = labels[pick];
}

defaultproperties
{
     bHidden=True
}
