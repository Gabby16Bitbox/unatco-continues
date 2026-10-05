//=============================================================================
// UCBlocker - muro invisibile per i posti di blocco (BlockPlayer della mappa e'
// statico e non si puo' creare in gioco). Blocca giocatore e PNG, non si vede.
// Resta salvato con la mappa (Tag 'UCBarricade' = gia' costruito).
//=============================================================================
class UCBlocker extends Actor;

defaultproperties
{
     bHidden=True
     bCollideActors=True
     bCollideWorld=False
     bBlockActors=True
     bBlockPlayers=True
     CollisionRadius=34.000000
     CollisionHeight=120.000000
}
