// Readable mod records use the native datacube window and permanent Notes.
class UCFileCube extends DataCube;

//#if vanilla
//var string SpecialText;     // Revision's InformationDevices has it: the original game reads it through UCTextBlock.UseText
//#endif

var name document;

function Frob(Actor Frobber, Inventory frobWith)
{
    local DeusExPlayer P;
    local UCInvestigation manager;
    // Native SpecialText otherwise creates an empty note under the empty tag.
    bAddToVault = False;
    //#if vanilla
    //if (textTag == '')
    //    class'UCTextBlock'.static.UseText(self, SpecialText);
    //#endif
    Super.Frob(Frobber, frobWith);
    P = DeusExPlayer(Frobber);
    if (P == None || infoWindow == None)
        return;
    foreach AllActors(class'UCInvestigation', manager)
    {
        manager.ReadDocument(document, False);
        return;
    }
}

defaultproperties
{
    ItemName="Field record"
    bAddToVault=False
    bUnmovable=True
    bInvincible=True
    bPushable=False
}
