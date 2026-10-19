// A report delivers an order; it never starts the assault.
class UCSceneSPTransfer extends UCScene;

var int n;
var float d;

function float InfoLine(int i)
{
    switch (i)
    {
        case 0: return Say("WaltonSimons", "Denton. Special Projects is standing by. Tong's people have locked the loading entrance behind the storeroom.");
        case 1: return Say("WaltonSimons", "Open it and hold your position. The recovery team will take him into custody.");
    }
    return -1;
}

state Playing
{
Begin:
    if (Plr() == None || !Plr().CanStartConversation())
    {
        Sleep(0.25);
        Goto('Begin');
    }
    if (GetF('UC_TransferOrderReceived'))
    {
        Destroy();
        Stop;
    }
    SetF('UC_TransferOrderReceived', True);
    if (Plr().FindGoal('UCOpenNorthAccess') == None)
    {
        if (GetF('TracerTong_Dead'))
            GoalNew('UCOpenNorthAccess', "Use the laboratory service console at the back of the storeroom to open the loading entrance. Tong is dead; secure his remaining records.");
        else GoalNew('UCOpenNorthAccess', "Use the laboratory service console at the back of the storeroom to open the loading entrance for the recovery team. Keep Tong alive pending transfer.");
    }
    InfoStart("WaltonSimons");
    Sleep(1.5);
    n = 0;
Next:
    d = InfoLine(n);
    if (d >= 0)
    {
        Sleep(d);
        n++;
        Goto('Next');
    }
    HideInfo();
    Destroy();
}
