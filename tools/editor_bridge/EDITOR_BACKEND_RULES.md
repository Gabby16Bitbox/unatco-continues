# Vincoli del backend editor per Revision

Derivano dalle prove in gioco del progetto, riportate dall'utente il 4 ottobre 2026. Il backend nativo dei mover applica già i controlli sui poligoni, preservazione delle luci e prova tramite il fotografo; restano vincoli anche per le future operazioni CSG.

## Luci

Il comando `LIGHT APPLY` dell'editor SDK ha scurito l'eliporto Revision. Non ricalcolare automaticamente l'illuminazione di una mappa intera. Un ricalcolo globale deve essere provato su una copia e accompagnato da un confronto prima/dopo dell'illuminazione nelle zone interessate e nelle zone che devono restare invariate.

Per le ombre rimaste dopo la rimozione di geometria, usare il flusso mirato esistente `tools/lightbits.py unshadow`: richiede la mappa vecchia e un volume delimitato. Prima eseguire la modalità `prova`, poi applicare sulla copia e confrontare le immagini in gioco. Non sostituirlo con `clear` indiscriminato.

## Brush importati da T3D e ricostruzioni

L'origine `Base` di ciascun poligono deve stare sul piano della faccia. Controllare la distanza dal piano e la corrispondenza fra normali, texture e superfici dopo ogni importazione/ricostruzione. Per i modelli supportati esiste già `tools/fix_brush_surfs.py`, con modalità `prova`; la correzione va applicata solo ai modelli interessati su una copia privata.

Il successo del comando dell'editor non basta: ricontrollare la geometria salvata, caricarla nel motore originale e fotografare le facce problematiche, anche con la torcia. Preservare i dati estranei all'intervento.

## Fotografo

Riutilizzare `tools/shots.ps1` e `UCShotRunner`: camera libera, giocatore, torcia, inseguimento, posizione del personaggio nel log, attese e comandi console. Il ponte li richiama con `try`/`try_map`; non duplica il fotografo né modifica le classi della campagna.
