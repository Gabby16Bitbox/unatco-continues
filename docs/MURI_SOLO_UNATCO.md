# Muri e macerie solo nella variante UNATCO (UnrealEd dell'SDK)

Le mappe modificate in `maps\` valgono per TUTTE le partite (anche la route vanilla). Per cambiare qualcosa
solo nella variante UNATCO si usano due etichette (Tag) che la mod riconosce in ogni mappa:

| Tag che inizia con | Nel gioco normale | Nella variante UNATCO |
|---|---|---|
| `UCWall...` (es. `UCWallPorta1`) | invisibile e attraversabile | muro vero: visibile, solido, non si apre |
| `UCWallLuce...` | invisibile | visibile ma SENZA collisione (decorazioni, es. strisce di luce) |
| `UCVanilla...` (es. `UCVanillaMacerie`) | visibile e solido (lo mostra la mod) | resta nascosto |

Lo fanno `UCMod.RaiseRouteWalls()` (route UNATCO) e `UCMod.ShowVanillaOnly()` (gioco normale) a ogni
caricamento di mappa. Verificato senza gioco in `tools\check-hongkong.ps1`.

**Regole imparate in gioco (4 ott 2026):**
- Nella mappa TUTTI questi mover vanno salvati **nascosti e senza collisione** (`bHidden=True`, `bCollideActors`,
  `bBlockActors`, `bBlockPlayers` = False). Mostrarli a gioco in corso funziona; **toglierli dalla vista no**: un
  mover gia' visibile resta disegnato al suo posto anche nascosto e spostato. Per questo anche gli `UCVanilla`
  nascono nascosti e li mostra il codice.
- Luce: `bDynamicLightMover=False` e luci ricalcolate (`LIGHT APPLY`) con i mover **visibili**, poi rimessi
  nascosti. Con la luce "dinamica" restano neri o a pezzi e la torcia non li illumina.
- Le proprieta' si possono cambiare senza editor: `python tools\set_actor_props.py <mappa.dx> <Attore>
  bHidden=True bCollideActors=False ...` (riscrive l'attore in fondo al file; la geometria non cambia).
- Decorazioni sottili (strisce di luce): mai solide, diventano muri invisibili.
- Prova in gioco del 4 ott, sera: i mover con `bDynamicLightMover=True` restano disegnati DOVE SONO AL
  CARICAMENTO, anche nascosti (nella mappa o da codice) e spostati a gioco in corso. Quindi: un pezzo che non
  deve esistere si sposta lontano GIA' NEL FILE (`set_actor_props.py ... "Location=(x,y,z+20000)"
  "BasePos=(...)"`); lamiera/macerie dell'eliporto e le lastre di luce sono stati tolti cosi'.
- Superfici della geometria si cambiano sul posto con `tools\set_surf_flags.py <mappa> <Brush> <flag> [nz]`
  (es. `00c00000` = Unlit, sempre luminosa): cosi' sono state riaccese le due strisce rovinate dell'atrio.
- `LIGHT APPLY` con l'editor dell'SDK ha spento passaggio e atrio dell'eliporto: per ora NON ricalcolare le
  luci di questa mappa (backup del tentativo: `maps\backup\06_HongKong_Helibase.luci_ricalcolate_buio.dx`).
- Ombre nere lasciate da geometria tolta (macerie che erano BSP quando furono calcolate le luci): si tolgono
  senza ricalcolare con `tools\lightbits.py <mappa> unshadow <mappa_con_la_geometria_vecchia> x1 y1 x2 y2 z1 z2
  [prova]`. Traccia i raggi punto-luce nelle due geometrie e accende solo i punti in ombra prima e liberi ora
  (bordi a filo dei muri esclusi). Usato per l'eliporto con `prima_dei_muri` come geometria vecchia, riquadro
  `-1900 -450 -1000 200 370 700`: 188 punti, macchia davanti alla porta sparita (foto `shots\*-ombre`).
  Backup prima: `maps\backup\06_HongKong_Helibase.prima_delle_ombre.dx`.
- Mover importati da T3D: l'`Origin` di ogni poligono deve stare sul piano della faccia (l'editor la usa
  anche come punto del piano). Le coperture UCWallSud/UCWallSoffitto avevano l'origine fuori: BSP del mover
  costruito su piani sbagliati, facce visibili con la normale della faccia nascosta (scure, la torcia non le
  illuminava), texture perse (meta' bassa di UCWallSud) e texture "tirata" sul soffitto. Sistemate senza
  editor con `tools\fix_brush_surfs.py <mappa> <NomeBrush> [prova]` (una superficie per poligono, piani e
  albero BSP rifatti per un solido convesso); il generatore `maps\editing\helibase_porta_mover.py` ora
  proietta l'origine sul piano. Verificato con le foto `shots\*-muri` (azione `torch;1` del fotografo):
  la torcia illumina entrambe le coperture. Backup prima: `...prima_delle_facce.dx`. Le lastre
  `UCWallLuce*` hanno lo stesso difetto ma sono spente e spostate fuori mappa.
- Il gioco legge `UnatcoMaps` solo se e' anche in `[RevisionInternal.LaunchSystem]` di `Revision.ini`
  (lo aggiunge `install.ps1`): senza, carica le mappe originali.

## Editor da usare
**UnrealEd dell'SDK** (`Apri UnrealEd - Eliporto.bat`, `... - Hotel.bat`, `... - Strade.bat`, oppure
`.\edit-map.ps1 <mappa>`). Le viste rispondono al mouse grazie al rattoppo `tools\patch-windrvlite.ps1`
(applicato da solo dai `.bat`). UnrealEd 2.2 (`UED22Dev\`, versione 18 maggio 2025) NON apre le mappe di Revision:
gira sul motore di UT 469 e i pacchetti di Revision dipendono dal motore di Deus Ex (prova del 4 ottobre 2026:
`RevisionDeco` / `ConSys` non si caricano). Va bene per le mappe di Deus Ex normale.

## Chiudere una porta con un muro (solo UNATCO)
1. Apri la mappa (es. `Apri UnrealEd - Eliporto.bat`), poi File > Open > `maps\<mappa>.dx`.
2. Trova la porta nella vista dall'alto (Overhead). Le coordinate di una porta si leggono nelle sue proprieta'
   (doppio clic sulla porta > Movement > Location).
3. **Forma del muro**: tasto destro sul pulsante del *Cube* (barra a sinistra) e scrivi Height / Width / Breadth
   un po' piu' grandi del vano (es. porta 128 x 256: Width 136, Height 264, Breadth 16) > Build.
   Il pennello rosso prende quella forma.
4. **Posizione**: trascina il pennello rosso nel vano della porta nelle viste 2D (Overhead e laterali). Tienilo
   sulla griglia; deve coprire il vano senza sporgere troppo nei muri.
5. **Texture**: nel browser a destra (Browse: Textures) scegli una texture di muro e cliccala (resta selezionata).
6. **Aggiungi come mover**: pulsante *Add Mover Brush* (barra a sinistra, quello con l'ascensore). Compare un
   brush viola: e' il muro-mover. NON usare *Add* (quello diventa geometria fissa, valida anche nel gioco normale).
7. **Proprieta' del mover** (doppio clic sul brush viola):
   - Events > Tag = `UCWallPorta1` (qualunque nome che inizi con `UCWall`);
   - Advanced > bHidden = True;
   - Collision > bCollideActors = False, bBlockActors = False, bBlockPlayers = False.
8. Non serve ricostruire la mappa (un mover non e' geometria). File > Save, chiudi UnrealEd.
9. `Installa nel gioco.bat`. Prova da un salvataggio fatto PRIMA di entrare in quella mappa (una mappa gia'
   visitata viene ricaricata dal salvataggio, senza le modifiche).

## Macerie che devono sparire solo nella variante UNATCO (avanzato)
Le macerie fatte di geometria fissa non si possono nascondere: vanno trasformate in mover.
1. Seleziona il brush delle macerie (clic sulla sua linea nelle viste 2D).
2. Brush > *Get* (o tasto destro > "Copy to builder brush"): il pennello rosso prende la stessa forma e posizione.
3. Scegli la texture delle macerie e premi *Add Mover Brush*; nelle proprieta': Tag = `UCVanillaMacerie`.
   (Qui bHidden e la collisione restano normali: nel gioco normale le macerie devono vedersi.)
4. Cancella il brush originale (Delete) e fai Build > Rebuild All. **Salva prima una copia della mappa**: una
   ricostruzione sbagliata puo' aprire buchi nella geometria.

## Eliporto di Hong Kong: porta blindata sistemata (4 ott 2026)
Passaggio fra l'hangar e l'atrio dell'ascensore: x da -1152 a -1328, y da -256 a 0, z da 384 a 640.
- Scintille e fumo (3 `ElectricityEmitter` 'LibElectric' + 1 `ParticleGenerator`): tolti da script nella variante
  UNATCO (`UCMod.ClearBlastDebris`), insieme al quadro elettrico storto contro il muro sud (`ControlPanel1`,
  inclinato). Porta blindata e rottami (`Blast_doors`, `DoorWreckage`): spostati via da script.
- Nella copia della mappa (`maps\06_HongKong_Helibase.dx`, originale in `maps\backup\`):
  - `UCWallSoffitto0` (mover, Tag `UCWallSoffitto`): lastra 2 unita' sotto il soffitto, sopra lo squarcio (Brush233);
  - `UCWallSud0` (Tag `UCWallSud`): pannello davanti alla rientranza sfondata del muro sud (Brush235), texture
    HelibaseWall_E sotto e DrtyBrwnWall_A sopra, come il muro;
  - `UCVanillaLamiere0` / `UCVanillaMacerie0`: copie identiche delle lamiere strappate (Brush234) e delle macerie a
    terra (Brush236), che sono state tolte dalla geometria; esistono solo nel gioco normale.
  - Geometria e luci ricostruite (MAP REBUILD + LIGHT APPLY). Sorgente dei mover: `maps\editing\helibase_porta_mover.*`.
- La scritta "LOCKDOWN" sopra la porta (`HK_Helibase.Sn_HBLkdwn`) diventa "ELEVATORS"
  (`UnatcoContinues.UCSignElevators`, `src\UnatcoContinues\Textures\UCSignElevators.pcx`) solo nella variante UNATCO
  (`UCMod.SwapHelibaseSign`: la texture originale "si anima" sulla nuova).
- I 3 pulsanti della piattaforma di sinistra (`Switch1`, Event `Helipad_Lifter`: alzano la piattaforma e aprono
  il suo tetto) sono spenti nella variante UNATCO (`UCMod.LockHelipadLift`): il tetto sopra Jock lo apre la scena
  (`hangar_open`) e il pulsante, che non lo sapeva, ripartiva da "chiuso". Se la piattaforma era su, si riabbassa.
- Verificato senza gioco: `tools\check-hongkong.ps1` (usa le mappe di `maps\` se ci sono), eliporto 42 controlli.

## Comandi dell'editor utili (riga dei comandi della finestra Log: Window > Log)
- `MAP EXPORT FILE=C:\percorso\senza_spazi.t3d`  esporta tutto in testo (sola lettura)
- `MAP IMPORTADD FILE=...t3d`  aggiunge gli attori di un file T3D (mover con poligoni, proprieta', Tag)
- `ACTOR SELECT NONE` poi `SELECTNAME NAME=Brush234` poi `ACTOR DELETE`  cancella un attore per nome
  (scrive "Unrecognized command" ma seleziona lo stesso)
- `MAP REBUILD`, `LIGHT APPLY`, `MAP SAVE FILE=...`
- Le luci (LIGHT APPLY) funzionano solo con il secondo rattoppo di `tools\patch-windrvlite.ps1`.
