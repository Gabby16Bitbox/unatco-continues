# Backend SDK nativo: verifiche e mover

Codex gestisce il ponte e il backend editor; Claude puo continuare sulla campagna. Il backend usa le DLL originali dell'SDK in un processo privato a 32 bit, con configurazioni e mappe separate. Non controlla le finestre dell'UnrealEd aperto.

## Comando disponibile

Da PowerShell, nella cartella del progetto:

```powershell
.\tools\editor_bridge\bridge.ps1 checkout 06_HongKong_Helibase
.\tools\editor_bridge\bridge.ps1 editor-check WORKSPACE SHA256
```

`WORKSPACE` e `SHA256` sono restituiti da checkout/status. Lo stesso controllo e esposto tramite MCP come `native_editor_check`. Esegue carica, esporta T3D, salva, ricarica ed esporta nuovamente. Il report e le due esportazioni restano in `editor_lab/runs/RUN`.

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

Disponibili `inspect-mover`, `plan-movers` e `apply-movers` (MCP: `inspect_mover`, `plan_mover_changes`, `apply_mover_plan`). Gli esempi JSON e il flusso completo sono in `README.md`.

La ricetta `translate` modifica insieme Location e BasePos. I keyframe relativi, le rotazioni e le proprietà della porta restano uguali: `Mover.BeginPlay` usa BasePos + KeyPos per riposizionare l'attore, quindi cambiare soltanto Location non sarebbe sufficiente.

La ricetta `scale` ridimensiona i poligoni locali attorno a PrePivot, ricalcola normali e origini sul piano della faccia e adatta gli assi UV. Richiede un modello chiuso, convesso e non condiviso con altri attori, con luce dinamica esplicita e senza dati luce attivi. Alcuni mover mantengono voci LightMap non referenziate: l'host conserva anche queste. Ricostruisce soltanto quel modello con `csgPrepMovingBrush`, poi richiama `fix_brush_surfs.py` sulla copia e ricarica nel motore editor.

Il piano contiene l'output concreto, hash, diff T3D e report. Il controllo confronta gli attori estranei, tutti i modelli (anche piani, nodi completi, zone, limiti di collisione e foglie) e tutti i dati luce. L'applicazione seleziona l'output verificato senza rieseguire la ricetta; rifiuta una mappa o dipendenze cambiate. L'undo torna alla precedente versione immutabile. Le verifiche MCP/native e le foto prima/dopo sono registrate da `verify_geometry.py --game`.

Aggiunta/rimozione di attori, CSG statico e pathfinding restano da implementare. Non viene esposta una console editor generica tramite MCP.

Restano obbligatori i vincoli in `EDITOR_BACKEND_RULES.md`: nessun `LIGHT APPLY` globale automatico, `unshadow` mirato per ombre residue, controllo/correzione delle superfici tramite lo strumento esistente dopo ricostruzioni e riuso del fotografo tramite `try`.
