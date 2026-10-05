# Deus Ex UE1 Map Bridge

Ponte per ispezionare e modificare gli attori delle mappe di Deus Ex Revision tramite CLI o MCP. Le modifiche lavorano in `tools/editor_bridge/workspaces`: ogni mappa ha una copia originale, versioni, piani di modifica e annullamento. `try` è l'eccezione esplicita: installa temporaneamente la versione scelta nel gioco, richiama il fotografo e ripristina la mappa originale. Il ponte non pilota l'UnrealEd aperto e non compila i sorgenti della campagna. `editor-check` usa un processo SDK privato per verificare carica/salva/ricarica: dettagli in [EDITOR_BACKEND.md](EDITOR_BACKEND.md).

## Cosa è disponibile

- Ricerca per nome, classe, Tag, proprietà, quota e vicinanza 3D (`--near X Y Z RADIUS`); risultati ordinati per distanza, in unità Unreal.
- Collegamenti Tag/Event e ricerca nei sorgenti della mod.
- Modifica di Location, Rotation, Tag, Event, booleani, numeri e stringhe supportate. Ogni operazione richiede SHA256 della mappa e valore precedente, produce un diff e una nuova versione privata.
- Verifica di tutti gli export non modificati; undo che recupera esattamente i byte precedenti.
- Pianta HTML interattiva: geometria BSP, pan/zoom, filtro per quota e oggetti selezionabili.
- Snapshot nel motore originale, su mappa privata e server locale temporaneo, senza aprire una finestra di gioco. `hk_setup` esegue esplicitamente il setup Hong Kong per vedere anche gli NPC creati dalla mod.
- Backend SDK nativo per traslare mover conservando i keyframe e ridimensionare brush convessi con luce dinamica. Il piano produce già una mappa privata verificata e un diff T3D; l'applicazione seleziona quei byte esatti come nuova versione.
- 18 strumenti MCP, stesso comportamento della CLI, SDK Python ufficiale 1.30.0 e trasporto stdio; inclusi gli strumenti nativi per i mover.

## Limiti

Questa versione non crea/elimina attori, non modifica il BSP statico o il pathfinding e non espone cambiamenti generici ad array o riferimenti. Il backend nativo ricostruisce soltanto il modello del mover interessato. Il ridimensionamento richiede un brush chiuso e convesso, modello non condiviso, `bDynamicLightMover=True` esplicito e nessuna lightmap attiva, maschera o riferimento luce. Non esiste ancora un pulsante di pubblicazione delle mappe.

Il backend rispetta `EDITOR_BACKEND_RULES.md`: nessun ricalcolo luci globale; dopo il ridimensionamento richiama `fix_brush_surfs.py` solo sul modello interessato e verifica piani, vertici, texture e dati estranei. Tutti i dati luce restano identici, comprese le eventuali voci lightmap inutilizzate. Le ombre statiche preesistenti non vengono rigenerate: eventuali interventi mirati richiedono ancora il flusso `lightbits.py unshadow` e confronto in gioco.

Il JSON statico contiene solo gli override salvati: un valore `null` può essere ereditato. Per conoscere i valori risolti e la posizione dopo il setup usa lo snapshot. È una mappa fresca senza giocatore, flag del salvataggio o progressione completa; non rappresenta la partita attualmente aperta. Lo snapshot registra gli hash dei pacchetti **già compilati** in `dist`; le modifiche ai `.uc` devono prima essere compilate dal normale processo del progetto. Le relazioni Tag/Event non includono tutti i collegamenti creati dagli script.

Gli oggetti nati a runtime sono visibili nello snapshot, ma non diventano attori salvati modificabili: le loro posizioni vanno cambiate nei rispettivi sorgenti, dopo coordinamento con chi ci sta lavorando.

## CLI

Da PowerShell, nella cartella del progetto:

```powershell
.\tools\editor_bridge\bridge.ps1 maps
.\tools\editor_bridge\bridge.ps1 checkout 06_HongKong_Helibase
.\tools\editor_bridge\bridge.ps1 objects WORKSPACE --query UCHK
.\tools\editor_bridge\bridge.ps1 objects WORKSPACE --near -1600 60 434 200 --limit 20
.\tools\editor_bridge\bridge.ps1 inspect WORKSPACE Light16
.\tools\editor_bridge\bridge.ps1 snapshot WORKSPACE --mode hk_setup
.\tools\editor_bridge\bridge.ps1 editor-check WORKSPACE SHA256
.\tools\editor_bridge\bridge.ps1 preview WORKSPACE --runtime
```

`WORKSPACE` è l'ID restituito da checkout. La CLI stampa JSON e restituisce exit code 1 in caso di errore. La pianta è un HTML autonomo apribile direttamente nel browser.

Esempio `changes.json` per cambiare un Tag (verificare prima il valore reale):

```json
[
  {"actor": "Light16", "property": "Tag", "expected": "Light", "value": "MyNewLightTag"}
]
```

```powershell
.\tools\editor_bridge\bridge.ps1 plan WORKSPACE SHA256 changes.json
.\tools\editor_bridge\bridge.ps1 apply WORKSPACE PLAN
.\tools\editor_bridge\bridge.ps1 undo WORKSPACE SHA256_DOPO_LA_MODIFICA
```

Un override assente richiede `"expected": {"unset": true}`. Si possono aggiungere solo campi Actor di base conosciuti e già presenti nella tabella nomi della mappa. SHA256 e valore precedente impediscono di applicare una modifica a una copia diversa da quella ispezionata; le operazioni concorrenti sullo stesso workspace sono bloccate. `status` segnala se nel frattempo è cambiata la mappa sorgente, senza incorporare automaticamente le modifiche altrui.

## Mover e geometria nativa

```powershell
.\tools\editor_bridge\bridge.ps1 inspect-mover WORKSPACE DeusExMover14
.\tools\editor_bridge\bridge.ps1 inspect-mover WORKSPACE UCWallSoffitto0
.\tools\editor_bridge\bridge.ps1 plan-movers WORKSPACE SHA256 tools\editor_bridge\examples\mover-translate.json
.\tools\editor_bridge\bridge.ps1 apply-movers WORKSPACE PLAN
.\tools\editor_bridge\bridge.ps1 undo WORKSPACE SHA256_DOPO_LA_MODIFICA
```

Gli esempi valgono per la versione dell'eliporto usata nelle prove: leggere sempre `inspect-mover` prima di riutilizzarli. `mover-scale.json` contiene il ridimensionamento del pannello del soffitto. Un file può contenere fino a 16 operazioni `translate`/`scale`; i valori attesi si riferiscono alla mappa iniziale. La traslazione aggiorna `Location` e `BasePos`, lasciando i keyframe relativi invariati. Il ridimensionamento usa gli assi locali attorno a `PrePivot`, senza cambiare posizione, rotazione o keyframe; adatta gli assi della texture alla scala.

`plan-movers` apre un editor SDK privato, esegue la ricetta, salva, corregge le superfici dei modelli ridimensionati e ricarica. Verifica il T3D degli attori estranei, tutti i modelli con dati di collisione e tutti i dati luce. Restituisce il diff e il report senza selezionare il risultato. `apply-movers` rifiuta piani con mappa, output, backend, DLL SDK o pacchetti compilati cambiati. Se Claude ricompila la mod fra piano e applicazione, creare un nuovo piano. `undo` recupera i byte della versione precedente, anche dopo il salvataggio nativo.

Il salvataggio SDK riserializza la mappa e omette le camere delle viste editor; questo comportamento è documentato in [EDITOR_BACKEND.md](EDITOR_BACKEND.md). Dopo una modifica, controllare anche una prova in gioco: il confronto automatico non valuta ombre residue, accessibilità o significato del percorso di una porta.

Via MCP: `inspect_mover` → `plan_mover_changes` → lettura del diff → `apply_mover_plan` → `runtime_snapshot`/`try_map` → `undo_property_changes`. Quest'ultimo annulla anche i piani dei mover.

## Prova temporanea in gioco

```powershell
.\tools\editor_bridge\bridge.ps1 try WORKSPACE --setup UCDbgHeliDoor --shot 'atrio;cam;-1100;-60;560;-1600;-120;470' --timeout 90
```

Usare `--setup` solo se occorre il setup di una route. Senza setup il gioco parte direttamente dalla mappa del workspace. Per più azioni ripetere `--shot`, oppure usare `--shots-file file.json` con un array JSON di stringhe. Sono supportate tutte le azioni del fotografo: `cam`, `view`, `player`, `wait`, `console`, `torch`, `follow`, `where`. `where` riporta le posizioni nel log senza scattare foto.

`try` verifica che Deus Ex e Revision siano chiusi e che la mappa sorgente del workspace sia ancora aggiornata. Risolve il file attivo seguendo i `Paths` di `Revision.ini`, inclusa la precedenza di `UnatcoMaps` su `Maps`. Salva una copia dell'originale installato, verifica gli hash, mette da parte `Save/Current` e conserva `RevisionUser.ini` e le due configurazioni fotografiche legacy. Stagia il `.dx` selezionato e chiama lo script esistente senza modificare i sorgenti o i pacchetti `.u`.

Alla fine controlla la mappa vista nel nuovo log, `UCShot fine`, il numero di foto attese e gli attori richiesti con `where`/`follow`. Il ripristino viene tentato anche se il fotografo fallisce o va in timeout. Le foto, il log e `report.json` restano disponibili in `trials/TRIAL`; il report contiene i percorsi delle immagini e le posizioni registrate. `--expected-sha256` e `--expected-game-sha256` consentono di fissare anche gli hash attesi esplicitamente.

Le prove sono serializzate. Se un altro autore cambia la mappa installata durante la prova, il ponte preserva quella modifica e il backup, segnala il conflitto e mantiene il journal per il recupero. Dopo un'interruzione del processo, a gioco chiuso:

```powershell
.\tools\editor_bridge\bridge.ps1 recover-try TRIAL
```

Il recupero rifiuta una mappa modificata da altri: risolvere quel conflitto prima di riprovare, mantenendo il backup. Uno stato del gioco ancora aperto impedisce il ripristino. Il fotografo normalmente chiude il proprio gioco; la pulizia del ponte può chiudere soltanto un nuovo processo identificato come avviato da questa prova. `Save/Current` deve essere sullo stesso volume del ponte per consentire lo spostamento e il ripristino senza eliminazioni recursive.

Le opzioni Steam personalizzate che forzano un altro file INI non sono supportate: `try` usa `Revision.ini`. L'esito verifica la mappa caricata e le azioni richieste, non ogni proprietà di ogni attore: gli script della mod possono ancora sovrascrivere una modifica statica, da controllare nelle foto e nel log.

## MCP e Claude

Il server `deus-ex-map-bridge` è registrato nella configurazione utente di Claude Code e Codex. **Registrazione e collegamento nella sessione sono due verifiche diverse**: il test SDK conferma protocollo e strumenti, ma non dimostra che una sessione aperta li abbia caricati. La CLI è disponibile immediatamente. Controllare il menu MCP/Connectors della sessione e riconnettere il server; se non è elencato, la sessione può richiedere un nuovo avvio. Non sono state riavviate le sessioni altrui.

È stata aggiunta anche la definizione al file Desktop già esistente della versione Store: `AppData/Local/Packages/Claude_pzs8sxrjxfjjc/LocalCache/Roaming/Claude/claude_desktop_config.json`. La pagina Developer dell'app aperta mostrava ancora "No servers added": il collegamento in quella sessione resta da verificare dopo il riavvio dell'app. La documentazione ufficiale descrive [le configurazioni condivise e i server Desktop](https://code.claude.com/docs/en/desktop#shared-configuration) e la procedura per i server che non si collegano su Windows. Le altre impostazioni sono state preservate, con backup privato.

L'entry è contenuta anche in `mcp-config.json`: comando Python assoluto della `.venv` e `server.py` come argomento. Per altri client può essere aggiunta ai server MCP. Non avviare il server con il Python globale: usa la `.venv` privata. Non mescolare stdout del protocollo con messaggi diagnostici.

Flusso suggerito all'assistente: `maps` → `checkout` → `search_objects` → `inspect_object` → `plan_property_changes` → lettura del diff → `apply_property_plan` → `runtime_snapshot` → `map_preview` → `try_map` → verifica di immagini e log. `try_map` ripristina l'installazione; per annullare anche la modifica nella copia di lavoro usa `undo_property_changes`. Per modifiche successive usa lo SHA aggiornato. Per oggetti che non risultano salvati, cerca in `mod_source` e verifica lo snapshot.

## Verifica e dipendenze

`verification.json` documenta le prove reali più recenti. Per ripeterle (crea solo copie private):

```powershell
.\tools\editor_bridge\.venv\Scripts\python.exe tools\editor_bridge\verify_bridge.py
```

La prova modifica sei proprietà di una luce dell'eliporto, verifica il caricamento nel motore originale, l'integrità degli export estranei, l'undo esatto, i controlli su hash/valore precedente e gli NPC del setup Hong Kong. Verifica inoltre inizializzazione MCP, strumenti e ciclo completo di modifica/undo via stdio, e ispeziona una seconda mappa.

La verifica nativa dei mover e dei controlli di rifiuto usa `verify_geometry.py`. Aggiungere `--game` per le foto prima/dopo tramite il fotografo esistente, con ripristino dell'installazione e della copia di lavoro. Risultato: `geometry-verification.json`.

```powershell
.\tools\editor_bridge\.venv\Scripts\python.exe tools\editor_bridge\verify_geometry.py --game
```

Per ricreare l'ambiente privato usare Python 3.12+ su Windows:

```powershell
python -m venv tools\editor_bridge\.venv
.\tools\editor_bridge\.venv\Scripts\python.exe -m pip install -r tools\editor_bridge\requirements.txt
```

Il laboratorio nativo richiede `DevInstall/System` e i pacchetti compilati in `dist`. Dipendenze originali vengono caricate in un laboratorio privato; configurazioni, log e pacchetto UCMapBridge restano lì. Non occorre installare pacchetti nel gioco o chiudere l'editor aperto.

Per verificare i casi di errore del ripristino senza toccare l'installazione reale:

```powershell
.\tools\editor_bridge\.venv\Scripts\python.exe tools\editor_bridge\verify_trial.py
```

La verifica usa un'installazione simulata isolata per timeout, fotografo incompleto, attori mancanti, precedenza delle mappe, gioco già aperto, conflitti e recupero. Controlla anche ricerca spaziale e protocollo MCP con un client SDK indipendente. `trial-mcp-verification.json` distingue esplicitamente questa prova dal collegamento nella sessione dell'app.

`real-trial-verification.json` documenta inoltre una prova reale sull'eliporto: posizione della telecamera modificata confermata nel log del gioco, foto acquisita, ripristino di mappa/configurazioni/salvataggio temporaneo e undo esatto della copia di lavoro. Il report della prova contiene gli hash e i percorsi delle immagini.

`editor-verification.json` registra la verifica del backend nativo sull'Hotel via MCP con un client SDK indipendente, hash guard e compilazione dello snapshot da laboratorio vuoto. `editor-check` è diagnostico e non seleziona la mappa risalvata: questa riscrive tabelle e può omettere le camere delle viste editor, pur conservando T3D, geometria e dati luce confrontati. Il backend geometria rimane da sviluppare sopra questo collegamento.
