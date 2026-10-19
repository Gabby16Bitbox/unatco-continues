//=============================================================================
// UCBPFlask - Battery Park: Jock's flask, in his inventory: searching his body gives it. It can be
// drunk like the game's liquor (Gabby, 15 Oct): 20 health in all (the liquor gives 2), the same
// blur. Its description is about Jock.
//=============================================================================
class UCBPFlask extends LiquorBottle;

state Activated
{
	// the extra health first: the liquor's own BeginState (2 points, its effect) uses the flask up
	function BeginState()
	{
		local DeusExPlayer player;

		player = DeusExPlayer(Owner);
		if (player != None)
			player.HealPlayer(18, False);
		Super.BeginState();
	}
}

defaultproperties
{
     bBreakable=False
     bCanHaveMultipleCopies=False
     ItemName="Jock's Flask"
     ItemArticle=""
     Description="Jock's hip flask, dented from too many hard landings. He always said a pilot should keep something for after the flight."
     beltDescription="FLASK"
}
