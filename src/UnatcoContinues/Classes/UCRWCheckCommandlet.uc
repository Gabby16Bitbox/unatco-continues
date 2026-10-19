// Exhaustive policy checks for the player's report/order/open/cross sequence.
class UCRWCheckCommandlet extends Commandlet;

var int checked, failed;

function Check(bool ok, string description)
{
    checked++;
    if (!ok) { failed++; Log("UCRWCheck FAIL:" @ description); }
}

function int Main(string Parms)
{
    local FlagBase f;
    local int mask;
    local bool expected;
    f = new(None) class'FlagBase';
    for (mask=0; mask<64; mask++)
    {
        f.SetBool('UC_TongLocationReported',(mask & 1)!=0,,99);
        f.SetBool('UC_TransferOrderReceived',(mask & 2)!=0,,99);
        f.SetBool('UC_NorthAccessRequested',(mask & 4)!=0,,99);
        f.SetBool('UC_NorthAccessOpened',(mask & 8)!=0,,99);
        f.SetBool('UC_SPEntryAuthorized',(mask & 16)!=0,,99);
        // Neither a finished dialogue nor a dead Tong replaces any of these.
        f.SetBool('UC_TongEvidence_Played',True,,99);
        f.SetBool('TracerTong_Dead',True,,99);
        f.SetBool('TongMeetingComplete',True,,99);
        expected=(mask==63);
        Check(class'UCInvestigation'.static.CanAssault(f,(mask & 32)!=0)==expected,
            "assault requires all six real events, combination" @ mask);
        Check(class'UCInvestigation'.static.CanOpen(f)==((mask & 3)==3),
            "gate command requires report and order, combination" @ mask);
    }
    for (mask=0;mask<4;mask++)
    {
        f.SetBool('TongMeetingComplete',(mask & 1)!=0,,99);
        f.SetBool('UC_VLManifestRead',(mask & 2)!=0,,99);
        Check(class'UCInvestigation'.static.CanReport(f)==(mask!=0),
            "dead Tong does not block an actual archive discovery" @ mask);
        Check(class'UCInvestigation'.static.YuenCorroborated((mask & 1)!=0,(mask & 2)!=0)==(mask==3),
            "murder case requires transcript and police death report" @ mask);
    }
    Check(InStr(Caps(class'UCInvestigation'.static.DocumentText('Manifest')),"GRAY")==-1,
        "manifest does not reveal the Gray Death");
    Check(InStr(class'UCInvestigation'.static.DocumentText('Paul'),"AMB-2219-A")!=-1,
        "independent Paul record can actually be compared");
    Check(InStr(class'UCInvestigation'.static.DocumentText('Manifest'),"SP-HK-0614")!=-1,
        "manifest preserves the administrative authorization identifier");
    Check(!class'UCInvestigation'.static.CanOpen(None),"missing player flags cannot open the gate");
    Log("UCRWCheck:" @ checked @ "checked," @ failed @ "failed");
    return failed;
}

defaultproperties
{
    LogToStdout=True
    IsClient=False
    IsEditor=True
    IsServer=False
}
