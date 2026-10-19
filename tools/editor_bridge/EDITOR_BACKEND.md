# Backend SDK nativo: verifiche e mover

Il backend usa le DLL originali dell'SDK in un processo privato a 32 bit, con configurazioni e mappe separate. Non controlla le finestre dell'UnrealEd aperto.

## Comando disponibile

Da PowerShell, nella cartella del progetto:

```powershell
.\tools\editor_bridge\bridge.ps1 checkout 06_HongKong_Helibase
.\tools\editor_bridge\bridge.ps1 editor-check WORKSPACE SHA256
```

`WORKSPACE` e `SHA256` sono restituiti da checkout/status. Esegue carica, esporta T3D, salva, ricarica ed esporta nuovamente. Il report e le due esportazioni restano in `editor_lab/runs/RUN`.

Confronta i nomi degli attori di gioco, il T3D nativo prima/dopo, tutti i modelli letti da lightbits, lightmap, riferimenti alle luci e hash delle maschere delle ombre. Un errore nel log, un'esportazione assente o una differenza non ammessa fa fallire la verifica. I filename passati al vecchio parser SDK sono corti e relativi alla cartella privata: i nomi assoluti lunghi vengono troncati dall'editor.

Il risultato e diagnostico: non seleziona una nuova versione del workspace e non installa la mappa nel gioco. Il salvataggio dell'editor riscrive le tabelle, puo esplicitare default ereditati e rimuove le `Engine.Camera` delle viste editor. Il report conserva queste differenze: un risultato `passed` conferma le verifiche indicate, non l'identita di tutti i byte o la compatibilita di ogni futura modifica.

La prima prova sull'eliporto ha conservato il T3D esattamente e tutti i modelli e dati luce confrontati. Cinque camere dell'editor vengono omesse dal salvataggio; gli attori di gioco rimangono presenti. Le differenze in array opachi del lettore statico derivano anche dai nuovi indici delle tabelle e non sono trattate come una prova di modifiche ai dialoghi o alle alleanze.

## Ricostruzione dell'host

Serve Visual Studio Build Tools con compilatore x86 e Windows SDK, gia presenti su questa macchina, piu l'archivio degli header ufficiali in `tools/sdk_extract/ReleaseSDK1112f/Headers/DxHeaders.zip`.

```powershell
.\tools\editor_bridge\.venv\Scripts\python.exe tools\editor_bridge\setup_editor_sdk.py
.\tools\editor_bridge\build_editor_host.ps1
```

Gli header sono estratti solo nel laboratorio. Le librerie di importazione sono ricavate dalle DLL locali; l'host registra hash del sorgente, dell'eseguibile e delle quattro DLL principali e rifiuta versioni cambiate. Gli adattamenti di sintassi per MSVC moderno riguardano le copie private degli header. Non viene compilato o modificato il codice della campagna.

## Operazioni di geometria

Disponibili `inspect-mover`, `plan-movers` e `apply-movers`. Gli esempi JSON e il flusso completo sono in `README.md`.

La ricetta `translate` modifica insieme Location e BasePos. I keyframe relativi, le rotazioni e le proprietÃ  della porta restano uguali: `Mover.BeginPlay` usa BasePos + KeyPos per riposizionare l'attore, quindi cambiare soltanto Location non sarebbe sufficiente.

La ricetta `scale` ridimensiona i poligoni locali attorno a PrePivot, ricalcola normali e origini sul piano della faccia e adatta gli assi UV. Richiede un modello chiuso, convesso e non condiviso con altri attori, con luce dinamica esplicita e senza dati luce attivi. Alcuni mover mantengono voci LightMap non referenziate: l'host conserva anche queste. Ricostruisce soltanto quel modello con `csgPrepMovingBrush`, poi richiama `fix_brush_surfs.py` sulla copia e ricarica nel motore editor. Dopo la correzione delle facce, UC_MOVER bounds ricostruisce gli scafi nativi di collisione prima del salvataggio: il correttore elimina quelli obsoleti e non devono restare mancanti.

Il piano contiene l'output concreto, hash, diff T3D e report. Il controllo confronta gli attori estranei, tutti i modelli (anche piani, nodi completi, zone, limiti di collisione e foglie) e tutti i dati luce. L'applicazione seleziona l'output verificato senza rieseguire la ricetta; rifiuta una mappa o dipendenze cambiate. L'undo torna alla precedente versione immutabile.

La ricetta specifica `tools/build_tong_access.py` aggiunge un accesso e attori al laboratorio di Tong in un workspace privato. Non viene esposta una console editor generica; aggiunta/rimozione generica e pathfinding restano da implementare.

Restano obbligatori i vincoli in `EDITOR_BACKEND_RULES.md`: nessun `LIGHT APPLY` globale automatico, `unshadow` mirato per ombre residue, controllo/correzione delle superfici tramite lo strumento esistente dopo ricostruzioni e riuso del fotografo tramite `try`.

## Accesso di carico sul retro del magazzino di Tong

La ricetta `tools/build_tong_access.py WORKSPACE --expected-sha256 SHA256` parte dalla mappa originale e aggiunge sul retro del magazzino un passaggio incassato, una porta rivestita come la parete che scende nel pavimento, un vano di carico compatto con pavimento/soffitto del magazzino, legno grigio scuro, casse ai lati, scaffale carico, carrello, bidone e una scala di otto gradini a destra. Dietro il cancello INF superiore si trova un teleporter nativo verso il complesso esterno, protetto dalla porta non apribile. Il poligono rimane intatto. La porta operativa conduce al magazzino; il cancello esterno resta chiuso, INF e senza apertura. La console locale usa HKNet senza marchi UNATCO. Ricostruisce i due modelli dei mover e finalizza zone, visibilita e collisioni con `UC_WORLD finish`. Non richiama `MAP REBUILD` o `LIGHT APPLY`. La finalizzazione delle zone invalida gli indici delle luci nel vecchio SDK: `preserve_baked.py` conserva le maschere e LightMaps originali, ripristina gli indici delle superfici dopo averne confrontato piano e UV, e riordina i riferimenti alle luci separando quelli originali da quelli delle nuove foglie BSP.

La verifica confronta i dati salvati e ricarica la mappa; controlla le proprieta degli attori dell'input, escludendo solo cache Region/FootRegion/HeadRegion, selezione e builder dell'editor. Prima della ricetta, un piano separato del ponte sposta BoxMedium1 accanto agli altri colli per liberare il varco; il report registra questa modifica e gli esatti confronti effettuati. La prova nel motore di gioco resta necessaria: un BSP privo di zone puo superare lettura statica ed esportazione T3D pur perdendo collisioni in gioco.

`tools/try_campaign_build.py --build-system SYSTEM --workspace WORKSPACE --shots-file JSON` prova insieme la mappa privata e una compilazione verificata della campagna. Il ponte ripristina mappa, impostazioni fotografiche e salvataggio temporaneo; il wrapper conserva backup e hash dei due pacchetti e li ripristina alla chiusura della prova. Conserva il log e fa fallire la prova anche se il fotografo termina ma il controllo della missione fallisce. `UCRWPlayCheck` e un attore di verifica opt-in, non viene creato dal gioco normale. Usa login e pulsanti nativi, inventario reale e posizione fisica della squadra. `UCRWIgnoreCheck` prova il percorso senza copia indipendente, con Tong morto e prigioniero ignorato.

`tools/install_tong_access.py --package-trial packages-ID` pubblica la versione esatta provata in `maps` del progetto e `Revision/UnatcoMaps`. Richiede un trial ripristinato con almeno 28 controlli in gioco superati e gli stessi pacchetti gia installati. Rifiuta hash cambiati, conserva un backup e controlla che la mappa Steam originale e l'helipad restino identici.

`tools/refine_service_exit.py WORKSPACE --expected-sha256 SHA256` applica la texture originale `CoreTexMetal.Metal.SemiBackDoor_B` alle due facce della porta INF in cima alla scala. Modifica soltanto i riferimenti alla texture e la sua mappatura nel modello e nei poligoni: tutti gli attori, gli export estranei, i vertici, i piani e gli scafi di collisione restano identici. La nuova versione privata viene caricata e risalvata dall'SDK come controllo diagnostico, poi provata in gioco prima della pubblicazione. Il trial registra separatamente la mappa Steam e la versione personalizzata installata, così anche gli aggiornamenti successivi conservano l'originale.

Per questo solo aggiornamento di materiale, `install_tong_access.py --appearance-base-trial packages-ID` richiede un precedente trial completo superato per la copia di input, pacchetti identici, un nuovo trial mirato ripristinato che registri il cancello ancora alla chiave 0 dopo l'interazione e una nuova verifica strutturale del cambiamento limitato al materiale. Non ammette modifiche agli attori, alla geometria o alla collisione. Eventuali errori delle prove estese rimangono nei journal e nello stato della campagna.
