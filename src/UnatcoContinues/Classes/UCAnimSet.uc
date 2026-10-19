//=============================================================================
// UCAnimSet - cosa fa un personaggio quando non e' impegnato, deciso nell'editor delle mappe.
// - Con PawnName (il nome del personaggio nella mappa): l'animazione che fa da fermo (Orders
//   Standing) al posto del respiro, e (bOwnModel) il suo modello con le animazioni fatte
//   nell'Animation Studio: UCAnims.<modello che ha adesso>, stesse sequenze del gioco piu' le nuove.
//   Il modello e' quello che il gioco gli ha messo: con HDTP i soldati passano a HDTPCharacters.*
//   (Facelift), e UCAnims ha una copia per ciascuno; se il gioco lo cambia ancora, si rimette.
// - Senza PawnName: le animazioni dei punti di pattuglia per tutti i personaggi. PatrolPoint ha un
//   campo PatrolAnim che il gioco non usa mai: chi pattuglia e si ferma su quel punto (PauseTime)
//   la fa al posto del respiro.
// L'IA del gioco rimette il respiro solo ogni tanto (fine di un ciclo, gesti casuali): il Tick lo
// riporta all'animazione scelta. In conversazione, in combattimento o in fuga non tocca niente.
// - bStayPut (editor: Inspector > Behaviour > Stays put; Gabby, 18 Oct 2026): never turns, not even to talk.
//   While standing or talking the body keeps the way it faced at the start (no turning speed: the game's
//   turns only ask for a rotation) and its animation; the head alone follows JC (the game's head turn,
//   played on its own channel). Fighting, fleeing or sent somewhere, the AI turns it as always.
//=============================================================================
class UCAnimSet extends Info;

var() name PawnName;
var() name IdleAnim;
var() float IdleRate;
var() bool bOwnModel;
var Mesh Tried;                    // l'ultimo modello per cui si e' cercata la copia

var ScriptedPawn Who;
var bool bReady;
var float Since;

var() bool bStayPut;               // never turns while standing or talking (see above)
var rotator Home;                  // the way it faced at the start
var rotator SavedRate;             // its turning speed, while held still
var bool bHeld;

// Appearance-only instance: apply after the game's initial Facelift/HDTP pass.
// PawnName is the exact object name, never a shared Tag. No AI or collision changes.
var() Mesh AppearanceMesh;
var() Texture AppearanceSkin;
var() Texture AppearanceSkins[8];

function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(0.2, false);          // dopo che tutti gli attori della mappa sono partiti
}

function Timer()
{
    local ScriptedPawn P;
    local Actor A;
    local int i;

    if (AppearanceMesh != None)
    {
        foreach AllActors(class'Actor', A)
            if (A.Name == PawnName)
            {
                A.Mesh = AppearanceMesh;
                A.Skin = AppearanceSkin;
                for (i = 0; i < 8; i++)
                    A.MultiSkins[i] = AppearanceSkins[i];
                break;
            }
        // Startup only. Later gameplay (cloaking, damage, custom animations) keeps control.
        Disable('Tick');
        return;
    }

    if (PawnName != '' && PawnName != 'None')
    {
        foreach AllActors(class'ScriptedPawn', P)
            if (P.Name == PawnName)
            {
                Who = P;
                Home = P.Rotation;
                break;
            }
    }
    bReady = true;
}

// l'animazione che dovrebbe fare adesso ('' = decide il gioco)
function name Wanted(ScriptedPawn P, out float Rate)
{
    local PatrolPoint Point;

    if (P == None || P.bDeleteMe || P.Health <= 0)
        return '';
    Rate = 1.0;
    if (VSize(P.Velocity * vect(1, 1, 0)) > 10)
        return '';
    if (P.IsInState('Patrolling'))
    {
        Point = PatrolPoint(P.destPoint);
        if (Point == None || VSize((P.Location - Point.Location) * vect(1, 1, 0)) > P.CollisionRadius + 24)
            return '';
        if (Point.PatrolAnim != '' && Point.PatrolAnim != 'None')
            return Point.PatrolAnim;
        if (P == Who && Point.PauseTime > 0)
        {
            Rate = IdleRate;
            return IdleAnim;
        }
        return '';
    }
    if (P == Who && (P.IsInState('Standing') || (bStayPut && Talking(P))))
    {
        Rate = IdleRate;
        return IdleAnim;
    }
    return '';
}

function bool Talking(ScriptedPawn P)
{
    return P.IsInState('Conversation') || P.IsInState('FirstPersonConversation');
}

// Stays put: no turning while standing or talking, back to the start's facing if something turned it
function Hold()
{
    local bool bStill;

    bStill = bStayPut && Who != None && !Who.bDeleteMe && Who.Health > 0
        && (Who.IsInState('Standing') || Talking(Who));
    if (bStill)
    {
        if (!bHeld)
        {
            SavedRate = Who.RotationRate;
            bHeld = True;
        }
        Who.RotationRate.Yaw = 0;
        Who.DesiredRotation.Yaw = Home.Yaw;
        if (Who.Rotation.Yaw != Home.Yaw)
            Who.SetRotation(Home);
    }
    else if (bHeld)
    {
        if (Who != None && !Who.bDeleteMe)
            Who.RotationRate = SavedRate;
        bHeld = False;
    }
}

// il modello con le animazioni nuove, copia di quello che ha adesso
function OwnModel()
{
    local Mesh M;

    if (!bOwnModel || Who == None || Who.Mesh == None || Who.Mesh == Tried || Who.Mesh.Outer.Name == 'UCAnims')
        return;
    Tried = Who.Mesh;
    M = Mesh(DynamicLoadObject("UCAnims." $ Who.Mesh.Name, class'Mesh', true));
    if (M != None)
    {
        Who.Mesh = M;
        Tried = M;
    }
}

function Apply(ScriptedPawn P)
{
    local name A;
    local float R;

    A = Wanted(P, R);
    if (A == '' || A == 'None' || P.AnimSequence == A || !P.HasAnim(A))
        return;
    if (R <= 0)
        R = 1.0;
    P.LoopAnim(A, R, 0.25);
}

function Tick(float DeltaTime)
{
    local ScriptedPawn P;

    if (!bReady)
        return;
    if (Who != None)
    {
        OwnModel();
        Apply(Who);
        Hold();
    }
    else if (PawnName == '' || PawnName == 'None')
    {
        Since += DeltaTime;
        if (Since < 0.1)
            return;
        Since = 0;
        foreach AllActors(class'ScriptedPawn', P)
            Apply(P);
    }
}

defaultproperties
{
     IdleRate=1.000000
}
