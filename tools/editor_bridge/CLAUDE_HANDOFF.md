# Coordinamento per il lavoro sulle mappe

Codex ha preparato un ponte CLI/MCP in questa cartella, su richiesta dell'utente. Le prove lavorano su copie private; non modificano `src`, `maps`, `dist`, `build.ps1`, le classi delle camere, lo strumento screenshot o l'installazione del gioco. Il ponte è stato verificato su una copia dell'eliporto che include già la recente correzione alle ombre, e sull'Hotel.

Il server `deus-ex-map-bridge` è registrato nella configurazione utente di Claude Code. Una sessione già aperta potrebbe dover riconnettere MCP; la CLI `bridge.ps1` funziona subito. La guida è in `README.md`, le prove in `verification.json`, la configurazione portabile in `mcp-config.json`.

Per trovare gli oggetti: `checkout`, `search_objects`, `inspect_object`; per i nuovi NPC creati a Hong Kong: `runtime_snapshot` con `mode=hk_setup`, poi `map_preview` con `include_runtime=true`. Lo snapshot usa i pacchetti già compilati di `dist` e non simula il salvataggio del giocatore. `mod_source` aiuta a trovare dove sono definiti gli spawn.

Le modifiche a proprietà hanno un diff, SHA/valore precedente e undo; ogni export estraneo alla modifica viene verificato byte per byte. Il backend SDK aggiunge ricette specifiche per mover (vedi sotto); BSP statico, riferimenti/array generici e creazione/eliminazione di attori restano fuori dal flusso.

Questo file serve da passaggio di consegne sugli strumenti; non assegna nuove modifiche alla campagna.

## Assegnazione confermata dall'utente

L'utente ha affidato a Codex il ponte e il backend dell'editor. Claude può continuare sulla mod; eventuali interventi comuni su mappe, compilazione o strumenti del fotografo richiedono coordinamento. Codex lavora in `tools/editor_bridge`, con processi e mappe private.

Disponibile il collegamento SDK nativo: `editor-check WORKSPACE SHA256`, oppure `native_editor_check` via MCP. Esegue carica/esporta/salva/ricarica/esporta, confronta il T3D, tutti i modelli e i dati luce e non seleziona il risultato. Verificato sull'eliporto via CLI e sull'Hotel via client MCP SDK indipendente.

Disponibili anche `inspect-mover`, `plan-movers`, `apply-movers`: traslazione con BasePos e keyframe preservati, ridimensionamento di brush convessi con luce dinamica e superfici corrette tramite il tuo fixer. Il piano salva già il risultato privato, confronta tutti i modelli e le luci e produce un diff T3D. L'applicazione rifiuta modifiche concorrenti ai pacchetti compilati; l'undo recupera i byte precedenti. Sono 18 strumenti MCP totali. Non c'è una console generica o ricostruzione globale. Dettagli e limiti in `EDITOR_BACKEND.md`, prove in `geometry-verification.json`.

## Aggiornamento dopo la tua prova CLI

Implementati `try WORKSPACE` e `objects WORKSPACE --near X Y Z RADIUS`, disponibili anche via MCP (`try_map`, filtro `near` in `search_objects`). `try` riusa il tuo fotografo, risolve la mappa tramite i Paths di Revision.ini (UnatcoMaps ha precedenza), conserva mappa, configurazioni fotografiche e Save/Current e ripristina gli originali. Un conflitto con una nuova mappa installata da altri viene preservato e segnalato. `recover-try TRIAL` recupera un'interruzione a gioco chiuso.

Prova reale riuscita: SecurityCamera3 spostata di 16 unità e ritaggata sulla copia; il gioco ha registrato la nuova posizione tramite `where`, scattato una foto e chiuso. Mappa installata, preferenze, stato temporaneo e workspace sono tornati agli hash originali. Risultato in `real-trial-verification.json`; dieci scenari simulati di ripristino e handshake MCP sono verificati da `verify_trial.py`.

I tuoi vincoli su luci e origini dei poligoni sono registrati in `EDITOR_BACKEND_RULES.md`. Il codice del fotografo, lightbits e fix_brush_surfs è rimasto invariato.

MCP: il server è definito sia nella configurazione utente Code sia nel file Desktop della versione Store. La sessione aperta non lo ha ancora caricato: il menu Connectors non lo elenca e Developer mostrava "No servers added". Non è stato riavviato Claude, per rispettare le altre sessioni e la bozza presente. Dopo un riavvio dell'app verificare il collegamento dalla UI e con una chiamata a `maps`; il solo test SDK non prova il collegamento della tua sessione.
