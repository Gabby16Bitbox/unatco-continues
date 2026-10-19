//=============================================================================
// UCSoundFX - un effetto sonoro messo nell'editor delle mappe.
// - Zona (bOnTouch): suona quando JC ci entra (il cilindro CollisionRadius / CollisionHeight, come
//   un Trigger: TriggerType, bTriggerOnceOnly, ReTriggerDelay valgono come sempre), e fa anche
//   partire il suo Event, come un Trigger qualsiasi.
// - Attivato (Tag): suona quando qualcosa lo attiva: l'Event di una porta (quando ha finito di
//   aprirsi), di un pulsante, di un tastierino, di un altro trigger, un'azione della storia.
// FXSound si sente da dove sta l'oggetto fino a FXRadius unita' (bAtPlayer: nella testa di JC,
// alla stessa altezza ovunque sia: una voce, un allarme del comunicatore).
//=============================================================================
class UCSoundFX extends Trigger;

var() sound FXSound;
var() float FXVolume;          // 1 = normale
var() float FXRadius;          // fin dove si sente (unita')
var() float FXPitch;           // 1 = come registrato
var() bool  bAtPlayer;         // si sente "in testa" a JC, non da qui
var() bool  bOnTouch;          // suona quando JC ci entra (se no, solo quando e' attivato)
var bool bPlayed;

function PlayFX(Actor Who)
{
    local Pawn P;

    if (FXSound == None || (bTriggerOnceOnly && bPlayed))
        return;
    bPlayed = true;
    if (bAtPlayer)
    {
        P = Pawn(Who);
        if (P == None || !P.IsA('PlayerPawn'))
            P = GetPlayerPawn();
        if (P != None)
        {
            P.PlaySound(FXSound, SLOT_None, FXVolume,, 100000, FXPitch);
            Log("UCSoundFX" @ Name @ "played" @ FXSound @ "for JC");
            return;
        }
    }
    PlaySound(FXSound, SLOT_None, FXVolume,, FXRadius, FXPitch);
    Log("UCSoundFX" @ Name @ "played" @ FXSound);
}

function Touch(Actor Other)
{
    if (!bOnTouch)
        return;
    if (IsRelevant(Other) && (ReTriggerDelay <= 0 || Level.TimeSeconds - TriggerTime >= ReTriggerDelay))
        PlayFX(Other);
    Super.Touch(Other);          // il suo Event e il messaggio, come ogni trigger
}

function Trigger(Actor Other, Pawn EventInstigator)
{
    if (EventInstigator != None)
        PlayFX(EventInstigator);
    else
        PlayFX(Other);
}

defaultproperties
{
     FXVolume=1.000000
     FXRadius=1024.000000
     FXPitch=1.000000
     bOnTouch=True
     CollisionRadius=64.000000
     CollisionHeight=64.000000
}
