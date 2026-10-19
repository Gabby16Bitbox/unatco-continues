# Hong Kong — accesso, prove e assalto MJ12

Revisione del 6 ottobre 2026, integrata nei sorgenti e nella copia modificata della base di Tong. Sostituisce il tracciamento automatico. Il [copione completo](CAMPAIGN_REWRITE_2026_10_06.md) contiene le battute; questo documento descrive il contratto di gameplay. Copertura delle prove e lavoro rinviato sull'helipad: [STATUS.md](STATUS.md).

## Il contratto della scena

L'assalto parte quando JC autorizza l'ingresso della squadra e apre materialmente l'accesso. Aver trovato Tong, aver ascoltato il dialogo o possedere il manifest non basta.

Prima dell'apertura JC è un investigatore ammesso con riluttanza. Dopo l'apertura ha contribuito all'operazione di Special Projects. La squadra riceve ordini diversi dai suoi, prende il controllo del laboratorio e distrugge selettivamente archivi. Il dubbio emerge dalle azioni visibili.

Gli InfoLink restano a senso unico. I rapporti sono comandi espliciti dei terminali. Simons non confessa il complotto e Tong non dimostra già la produzione della Gray Death.

## Punti sostituiti nella versione precedente

- `UCSceneTongLab.SetupBase` imposta `JCLedMJ12ToTong` all'arrivo.
- Il percorso `Playing` passa dalle prove all'allarme e all'assalto senza input sulla sicurezza.
- La morte di Tong può saltare direttamente ad `Assault`.
- `TongFlees` e il blocco `Assault` avviano l'operazione; `Wave1` crea la squadra.
- `UCHKStory.AssaultOffscreen` completa un'operazione già iniziata fuori campo.
- `ShowTerminal` e `AddFragment` forniscono già identificativi Ambrosia, ma manca il confronto con un documento indipendente dell'helibase.
- La base attuale non contiene un ingresso settentrionale verificato per la squadra. Non va presentato come un asset esistente.

Questo elenco registra il comportamento precedente, ora sostituito. `UCInvestigation` gestisce documenti, custodia effettiva, rapporti e attraversamento. `UCSceneSPTransfer` comunica l'ordine; `UCSceneTongLab` avvia il raid solo dopo il passaggio osservato. La mappa aggiunge una porta sul retro del magazzino e una corsia di servizio esterna, conservando le lightmap originali. `UCNorthAccess` e `UCNorthConsole` restano nomi interni per compatibilità; l'accesso giocabile non è più al poligono. Leggere il manifest non salva automaticamente la copia; terminare il sweep non trasmette il rapporto finale.

## Macchina degli stati

```text
TONG LOCATED
    -> incontro o lettura degli archivi
    -> manifest disponibile
    -> JC seleziona REPORT LOCATION / REQUEST TRANSFER TEAM
LOCATION REPORTED
    -> InfoLink di Simons e obiettivo sulla porta
TRANSFER ORDER RECEIVED
    -> console di sicurezza raggiungibile, codice o hacking
    -> JC seleziona OPEN REAR LOADING ACCESS / ADMIT TEAM
OPENING REQUESTED
    -> porta si muove
    -> verifica varco percorribile e autorizzazione alla squadra
ACCESS OPEN / ENTRY AUTHORIZED
    -> squadra attraversa il varco
    -> allarme, resistenza delle guardie, assalto
ASSAULT STARTED
    -> fuga di Tong se vivo
    -> controllo dei server, prigioniero, eventuale obiezione di JC
    -> debriefing, incarico VersaLife
ASSAULT RESOLVED
```

In qualsiasi stato precedente all'apertura, uscire dalla mappa conserva lo stato e non genera un raid fuori campo. La morte di Tong cambia il bersaglio in “archivi”, non elimina il requisito di accesso.

Il manifest si può leggere e copiare senza inviare il rapporto. L'ordine di lettura dei documenti non è imposto; la richiesta di trasferimento richiede che JC abbia localizzato Tong o verificato i suoi archivi. L'ordine di aprire la porta arriva soltanto dopo il rapporto esplicito.

Se il varco è stato aperto prima del rapporto, la console richiede comunque un comando esplicito di autorizzazione all'ingresso. Non attribuire a JC un'intenzione retroattiva e non far partire la squadra da un semplice `Mover` in posizione aperta.

## Documenti e conoscenze

Gli identificativi `AMB-2219-A`, `AMB-2219-B` e `AMB-2231-C` vengono conservati dal terminale attuale. Il codice di campo `SP-HK-0614` e il suo allegato `L2` sono nuove aggiunte narrative.

| Documento | Provenienza | Evento di conoscenza |
| --- | --- | --- |
| Estratto Ambrosia di Paul | Indagine NSF prima del rifiuto; copia separata disponibile da Tong per vecchi salvataggi | Lettura effettiva della nota. |
| Autorizzazione Special Projects | Terminale o datacube dell'helibase | Lettura effettiva; non soltanto ingresso nella mappa. |
| Manifest VersaLife | Terminale del laboratorio di Tong | Lettura; copia manuale distinta. |
| Spada a Queen's Tower | Teca, esame o acquisizione | Posizione verificata, distinta dalla custodia dell'arma. |
| Trascrizione di Yuen Kong | `06_Datacube06` | Documento letto; non il semplice possesso della spada. |
| Rapporto sulla morte | `06_Datacube22` o copia con provenienza indicata | Documento letto; il sospetto della polizia resta distinto dalla prova aggiuntiva. |

Non completare il caso Yuen per `Have_Evidence` o `NoticedMJ12ChowConnection`. Non dichiarare “hai visto il codice all'helibase” se manca il relativo evento. Il dossier può essere consultato nelle note anche dopo la scena; non è una finestra automatica di nove secondi.

I vecchi salvataggi non devono ricevere retroattivamente conoscenze. Una nota di recupero deve dire da dove arriva. Se JC non copia gli archivi prima della distruzione, può continuare con il materiale consegnato dalla squadra; quella provenienza resta esplicita e manca la sua copia indipendente.

## Flag proposti

Flag introdotti nel runtime per questa revisione.

| Flag | Significato |
| --- | --- |
| `UC_PaulManifestRead` | JC ha letto la copia di Paul durante l'indagine iniziale. |
| `UC_SPHelibaseAuthRead` | JC ha letto il documento amministrativo dell'helibase. |
| `UC_ChowSwordVerified` | La posizione della spada è stata verificata. |
| `UC_YuenTranscriptRead` | Trascrizione nella stanza segreta letta. |
| `UC_YuenDeathReportRead` | Rapporto sulla morte di Yuen letto. |
| `UC_YuenCaseCorroborated` | La trascrizione è stata confrontata con il rapporto di morte. |
| `UC_MaxDealOffered` | Max ha proposto lo scambio. |
| `UC_SwordGivenMax` | Consegna volontaria riuscita; arma trasferita realmente. |
| `UC_SwordGivenGordon` | Eventuale consegna riuscita a Gordon. |
| `UC_ChowEvidenceSentGordon` | Gordon ha ricevuto una copia dei reperti raccolti. |
| `UC_LPMeetingGranted` | Il colloquio sorvegliato è stato autorizzato. |
| `UC_VLManifestRead` | Manifest di Tong consultato. |
| `UC_VLManifestCopied` | Copia indipendente salvata prima della distruzione. |
| `UC_TongLocationReported` | Posizione o archivi verificati inviati dal terminale. |
| `UC_TransferOrderReceived` | Chiamata di Simons consegnata; obiettivo creato. |
| `UC_NorthAccessRequested` | JC ha attivato il comando di apertura autorizzata. |
| `UC_NorthAccessOpened` | Movimento concluso, varco percorribile. |
| `UC_SPEntryAuthorized` | Squadra autorizzata ad attraversare quel varco. |

`UC_SwordGivenMax` e `UC_SwordGivenGordon` sono incompatibili per la stessa consegna. Il resto della custodia deriva dall'inventario e dallo stato persistente della spada: non è sufficiente un flag generico “arma trovata”. Se JC la perde, il dialogo non dice che l'ha ancora con sé.

Riusare i flag esistenti per assalto, prigioniero, fuga e rapporto disciplinare quando il loro significato resta corretto. `MJ12AssaultStarted` si imposta una sola volta dopo il passaggio autorizzato. `JCLedMJ12ToTong` può documentare l'operazione dopo il rapporto, ma non deve essere un trigger.

## Compatibilità con le Triadi e il vanilla

`Have_Evidence` ha un significato troppo ampio per governare la nuova missione. Può rimanere come compatibilità circoscritta, senza diventare prova di omicidio, trasferimento dell'arma o permesso al laboratorio.

`MaxChenConvinced` va usato solo per gli effetti vanilla che si vogliono davvero: accordo con Max e tregua pertinente. Il percorso Gordon senza Max non deve falsificare questo flag per aprire una porta.

`QuickLetPlayerIn` può applicare il codice 1997 per il percorso con permesso, dopo `UC_LPMeetingGranted`. Non rende tutti i Luminous Path amici. Se Gordon è morto, una via alternativa di infiltrazione non deve fingere che abbia concesso il colloquio.

Il raid vanilla al Lucky Money resta disabilitato. La nuova politica sulle alleanze deve sopravvivere a un ricaricamento senza cancellare una reazione locale a un attacco reale.

Consegna della spada: verificare l'oggetto in inventario, presentare la scelta, effettuare il trasferimento, quindi impostare il flag e chiudere il goal. Il solo `Have_Evidence` non può togliere una spada mai presa. Gestire ritorno da un'altra mappa e tentativi ripetuti senza duplicazioni.

## Il varco sul retro del magazzino

La ricerca in `HK_WORLD_RESEARCH.md` documenta:

- ingresso vanilla dalla parte meridionale e porta `Secretdoor01` fra atrio e laboratorio;
- ala ovest con `hatch01` e `hatch02`, adatta alla fuga separata di Tong;
- corridoio settentrionale senza uscita, nella fascia x -650..-400, y 800..1650.

La versione del poligono è stata scartata dopo la richiesta di Gabby. Il checkout parte dalla mappa originale: il banco e il corridoio del poligono rimangono intatti. La sola cassa `BoxMedium1`, che ostruiva il nuovo varco, è spostata accanto agli altri colli nel magazzino mediante un piano separato del ponte. La porta è centrata a (128,-1152,56), con apertura verso il basso di 120 unità. Il passaggio è largo 128 unità (x 64..192) e profondo 160 (y -1264..-1104), collegato al vano di carico x -128..448, y -1600..-1232. A destra la scala sale fino al cancello (944,-1488,248), con resistenza infinita e senza comando di apertura. La console è del laboratorio, su HKNet; non è attrezzatura UNATCO. Le lightmap e le proprietà degli attori dell'input sono confrontate prima della pubblicazione; non si esegue `LIGHT APPLY`.

La porta di carico ha il rivestimento del muro, è appena incassata e scompare nel pavimento quando si apre. Il vano riprende il legno grigio scuro e il soffitto del magazzino, con casse ai lati del passaggio, uno scaffale carico, un carrello e un bidone. A destra otto gradini salgono al cancello INF: dietro si trova un collegamento di caricamento alla mappa del complesso esterno. La squadra scende dalla scala, attraversa il vano e la porta, poi usa la navigazione del magazzino per raggiungere il laboratorio. Eventuali rinforzi e la scorta usano lo stesso percorso fisico. Il passaggio di Tong verso ovest resta distinto.

Usare il ponte con checkout, inspect, plan, apply e undo. Dopo una ricostruzione, controllare i piani delle facce con `tools/fix_brush_surfs.py`. Non fare `LIGHT APPLY` su tutta la mappa: la precedente prova ha scurito l'eliporto. Confrontare prima/dopo; per ombre di geometria rimossa usare la procedura mirata `tools/lightbits.py unshadow` dove applicabile.

Questo requisito di geometria è necessario per il nuovo climax: una finestra narrativa con “porta aperta” non lo sostituisce.

## Salvataggi, interruzioni e fuori campo

Persistenza degli stati, non una catena di pause temporali:

- Save/load dopo il briefing: nessun goal duplicato e testo disponibile nella cronologia.
- Save/load mentre la porta si muove: riprendere o verificare il mover, senza generare più squadre.
- Ritorno al laboratorio prima dell'apertura: squadra ancora in attesa.
- Uscita dopo l'apertura: solo allora è lecita una risoluzione fuori campo.
- Tong morto: nessun suo monologo o ordine di fuga; archivi e accesso restano giocabili.
- Conversazione o combattimento in corso: ritardare le battute, senza bloccare il controllo e senza saltare l'evento materiale.
- Salvataggi con l'assalto già iniziato nella versione precedente: riconoscere lo stato legacy e terminarlo; non far riaprire una porta retroattivamente.

Una chiamata interrotta non deve far sparire l'ordine dal diario. I flag del rapporto e dell'apertura sono distinti dall'esito audio.

## Verifiche richieste all'integrazione

1. Due minuti nel laboratorio dopo le prove, senza rapporto o apertura: nessun raid.
2. Rapporto inviato e ordine ascoltato, porta chiusa: nessun raid.
3. Apertura fisica con autorizzazione: la squadra entra dal varco una sola volta.
4. Porta aperta prima del rapporto: nessuna autorizzazione implicita; il comando esplicito successivo funziona.
5. Tong morto prima delle prove: consultazione archivi, ordine e apertura ancora richiesti.
6. Save/load prima, durante e dopo l'apertura; attraversamento mappe in ciascun punto.
7. Spada a Max, prove a Gordon, arma tenuta, arma lasciata nella teca, inventario pieno.
8. Max, Maggie, Gordon o messaggero saltati o morti: nessun blocco e nessuna falsa conoscenza.
9. Helibase documento letto / non letto, note di Paul presenti / assenti: varianti corrette.
10. Prigioniero salvato / ignorato, JC lontano / vicino alla porta: conseguenze e dialoghi pertinenti.

Usare i commandlet per gli stati e il fotografo del ponte per geometria e ingresso. `UCRWPlayCheck`, evocato solo nella prova privata, usa login e pulsanti nativi, inventario reale e attraversamento fisico. Le verifiche di stato non sostituiscono un playthrough di tutti i rami e dei salvataggi.
