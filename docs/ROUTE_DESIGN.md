# UNATCO Route — biforcazione Mission 04

Fonte: documento di design di Gabby (2 ott 2026). Regola d'oro: **non inventare da zero**. Intercettare
`InvestigateNSF completo + NSFSignalSent == FALSE + ritorno da Paul`, usare la conversazione originale
`M04PlayerLikesUNATCO`, e da lì sostituire l'intera catena vanilla successiva con la nostra.
Riusare il più possibile eventi, mappe e conversazioni originali.

## Obiettivo
JC (1) resta fedele a UNATCO, (2) ascolta Paul, (3) indaga comunque sull'NSF, (4) NON invia il distress signal,
(5) torna al 'Ton Hotel, (6) rifiuta definitivamente Paul, (7) Paul fugge, (8) JC torna a Liberty Island,
(9) inizia la nuova campagna UNATCO.

## Continuity prima della biforcazione (Mission 03 / LaGuardia)
`PlayerKilledLebedev = TRUE`, `AnnaNavarre_Dead = FALSE`, `PaulDenton_Dead = FALSE`.

## Sequenza canonica (resta VANILLA fino al bivio)
1. **ManderleyDebriefing03** (Manderley si congratula per Lebedev). `GoalCompleted: SeeManderley`, `NewGoal: GoToHelipad`.
   Paul ha disertato, killswitch attivo, nemico. Ordine: Hong Kong, eliminare Tracer Tong.
2. **JockTellsAboutPaul**: Jock porta JC a New York (Paul ferito a Hell's Kitchen). Setta `M04PlayerLeftUNATCO`,
   `GoalCompleted: GoToHelipad`, trigger `TimeToGo`.
   > `M04PlayerLeftUNATCO` **NON** significa defezione (è settato prima della scelta morale). Non usarlo per decidere la route.
   > Nuovi flag a FALSE: `UNATCORouteActive`, `UNATCORouteCommitted`, `JCDefectedFromUNATCO`.
3. **Battery Park**: `DL_JockParkStart` → `NewGoal: CheckOnPaul`.
4. **'Ton Hotel, PaulInjured**: `GoalCompleted: CheckOnPaul`, `NewGoal: InvestigateNSF`. JC non accetta ancora di tradire UNATCO.
5. **04_NYC_NSFHQ**: `DL_GotUplinkCode` → `GoalCompleted: InvestigateNSF`, `NewGoal: SendSignal`.
   Aggiungere flag nostro `UNATCORoute_EvidenceFound = TRUE` quando JC trova/legge le info principali nel basement.
   Riscrivere il testo del goal SendSignal: *"Investigate the NSF transmitter and decide whether to send Paul's distress signal."*

## Bivio
| Route | Condizione | Esito |
|---|---|---|
| Vanilla | JC usa il trasmettitore → `NSFSignalSent = TRUE` | ReturnToPaul, TalkedToPaulAfterMessage, UNATCO ostile, MiB, RaidBegin, JC fuggitivo |
| UNATCO | `UNATCORoute_EvidenceFound == TRUE AND NSFSignalSent == FALSE AND PaulDenton_Dead == FALSE` e JC parla di nuovo con Paul | trigger conversazione `M04PlayerLikesUNATCO` |

## Conversazione (originale, M04PlayerLikesUNATCO)
JC: *I checked it out. Sorry, Paul. UNATCO isn't perfect, but I'm not a terrorist.*
Paul: *Then I guess we go our separate ways. Too bad it had to be this way.*
JC: *Yeah. The offer still stands... if you want to go to Hong Kong.*
Paul: *No... No, I'll be fine on my own. JC, if you'd only open your eyes for one second... I wish I knew how to convince you.*
→ **alla fine** parte il nostro scripting.

## Commit (subito dopo l'ultima battuta)
SET `UNATCORouteActive`, `UNATCORouteCommitted`, `PaulRejectedByJC`, `PaulFugitive` = TRUE.
KEEP `PaulDenton_Dead`, `NSFSignalSent`, `JCDefectedFromUNATCO` = FALSE.
**NON eseguire**: `TalkedToPaulAfterMessage`, `RaidBegin`, `AnnaBadMama`, `DL_SimonsPissed`. Non attivare il killswitch di JC.
Chiudere il goal `SendSignal` (`GoalCompleted: SendSignal` o goal custom equivalente).

## Paul se ne va (nuovo evento)
```
M04PlayerLikesUNATCO END → delay 0.3–0.5s → Paul in stato di movimento scriptato
→ si volta → cammina verso camera/finestra
```
- Nella mappa creare `PaulUNATCOExit_01`, `PaulUNATCOExit_02`, `PaulUNATCODespawn`, trigger `PaulEscapeTrigger` vicino alla finestra
  (la stessa finestra usata nel raid vanilla).
- Paul → Exit_01 → si volta verso la finestra → Exit_02 → nel trigger: `PaulEscapedTon = TRUE`, `PaulLocationUnknown = TRUE`,
  collisione off, hidden, despawn dell'attore **locale**.
- **NON** settare `PaulDenton_Dead`: Paul deve poter ricomparire nelle missioni successive.
- Niente teletrasporto davanti al giocatore: se il pathing alla finestra è brutto, despawn dove JC non vede il punto
  (animazione/jump, poi `bHidden`, collisione off, remove). Basta che si percepisca "Paul è fuggito".

## InfoLink di Alex (1–2 s dopo l'uscita di Paul)
ALEX: *JC. I just lost Paul's position.* — JC: *He wouldn't come with me.* — ALEX: *I figured.* [pausa]
ALEX: *UNATCO teams are moving into Hell's Kitchen. Manderley wants you back at headquarters.*
JC: *What about Paul?* — ALEX: *They're looking for him.* — JC: *And Jock?*
ALEX: *Battery Park. Same place he dropped you off.* — JC: *I'm on my way.*
Nuovo goal `ReturnToUNATCO`: *Meet Jock in Battery Park and return to UNATCO Headquarters.*

## Stato delle mappe dopo la scelta
- UNATCO **non** è ostile: tutti gli NPC UNATCO `Alliance = friendly` verso JC. Si possono aggiungere soldati nelle strade
  alla ricerca di Paul/NSF. Bark: *"UNATCO's locking down the district."* / *"Orders are to bring Paul Denton in alive."* /
  *"I heard your brother slipped through the perimeter."* / *"Glad one Denton still remembers which side he's on."*
- `NSFSignalSent == FALSE` ⇒ **`RaidBegin` non deve partire**. Il 'Ton non è un'arena contro UNATCO; JC esce normalmente.
- Percorso: `04_NYC_Hotel → 04_NYC_Street → 04_NYC_BatteryPark`, soldati amici (riuso NPC/perimetri originali).

## Jock a Battery Park (nuova conversazione)
JOCK: *So?* — JC: *Paul made his choice.* — JOCK: *And you?* — JC: *Take me back to Liberty Island.* [pausa]
JOCK: *You sure?* — JC: *I'm sure.* — JOCK: *All right. Get in.*

## Transizione e inizio campagna
- JC sale sull'elicottero: `GoalCompleted: ReturnToUNATCO`, trigger `UNATCORoute_ReturnToHQ`, carica **`04_NYC_UNATCOIsland`**
  (preferita a `04_NYC_UNATCOHQ`: Jock atterra normalmente e JC attraversa l'isola).
- Le mappe `04_NYC_UNATCOIsland/HQ/Street/Hotel/NSFHQ/BatteryPark` esistono già; vanilla impedisce solo di tornare alla base: la route lo riabilita.
- Con `UNATCORouteActive == TRUE` parte il contenuto custom. Goal `ReportToManderley` → **UNATCO ROUTE — MISSION 1**:
  debriefing Manderley → Paul dichiarato ostile → Simons osserva JC → nuovo incarico → caccia alla cellula NSF / Paul.

## Flag minimi
`UNATCORouteActive`, `UNATCORouteCommitted`, `UNATCORoute_EvidenceFound`, `PaulRejectedByJC`, `PaulEscapedTon`,
`PaulLocationUnknown`, `JCDefectedFromUNATCO`.

Stato dopo la scena: Active/Committed/EvidenceFound/PaulRejectedByJC/PaulEscapedTon/PaulLocationUnknown = TRUE;
`JCDefectedFromUNATCO`, `NSFSignalSent`, `PaulDenton_Dead` = FALSE.

## Eventi vanilla da bloccare se `UNATCORouteActive == TRUE`
`TalkedToPaulAfterMessage`, `RaidBegin`, `AnnaBadMama`, `DL_SimonsPissed`, `GuntherShowdown` — non nelle condizioni vanilla;
eventuali versioni future vanno riscritte per la nuova campagna.

## State machine
```
M03 Lebedev ucciso → ManderleyDebriefing03 → ordini HK/Tong → JockTellsAboutPaul (M04PlayerLeftUNATCO ≠ defezione)
→ Battery Park → CheckOnPaul → PaulInjured → InvestigateNSF → NSF HQ → EvidenceFound → goal SendSignal
   ├─ invia segnale → NSFSignalSent=TRUE → route vanilla
   └─ NON invia → torna da Paul → M04PlayerLikesUNATCO → UNATCORouteActive
        → Paul si allontana → fuga dal 'Ton → InfoLink Alex → ReturnToUNATCO → Battery Park → Jock
        → 04_NYC_UNATCOIsland → NUOVA CAMPAGNA UNATCO
```

## Implicazioni tecniche (note di Claude)
- Il blocco degli eventi vanilla vive nelle **mappe** (trigger/flag/conversation events) e nei **flag** (`DeusExPlayer.flagBase`), non solo nel codice:
  serve UnrealEd per modificare `04_NYC_*.dx` e ConEdit/sorgenti `.con` per le conversazioni; lo script (`UCMod` e simili) gestisce flag e stato.
- Le conversazioni di Revision stanno in `RevisionConversations*.u` / `FRevisionConversations*.u` (non nei `.con` dell'SDK, che sono quelli vecchi).
