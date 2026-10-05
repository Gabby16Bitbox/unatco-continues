# Presentazione per il video (5 ottobre 2026)

Modalità a parte, solo per registrare il video: non fa parte della mod giocata. Porta da una novità
all'altra e mette a schermo una riga breve in inglese che dice cosa succede. I dialoghi non vengono
mai saltati né tagliati.

## Come si usa
- **Avvio**: in gioco, console `uctour` (oppure tasto **Home** → *VIDEO* → capitolo). Va bene partire
  da una partita qualsiasi, anche nuova.
- **PagSu** (o `ucnext`) = passo successivo. Non va mai avanti da sola: decidi tu quando.
- **PagGiù** (o `uchide`) = togli la scritta. Compare in dissolvenza (circa 2 secondi) e resta
  finché non la togli tu; la sostituisce solo la scritta del momento dopo, quando arriva.
- `ucagain` = rifai il passo. `ucstop` = ferma. Un salto di debug normale la spegne.
- JC parte equipaggiato: pistola carica in mano, manganello, 2 granate LAM, 3 medikit, una lattina,
  2 confezioni di soia (solo quello che non ha già).
- Ogni passo carica la mappa da zero: si può rifare quante volte serve. I salvataggi veri non vengono
  toccati, ma **non salvare** durante la presentazione sopra una partita che ti interessa.
- Comandi e tasti si mettono con `tools\tour-keys.ps1` (gioco chiuso; già fatto il 5 ottobre).
  PagGiù prima era "guarda in basso": l'originale è in `RevisionUser.ini.bak_tour`.

## Scaletta (13 passi: 9 capitoli + 4 varianti)
| # | Dove | Cosa devi fare tu | Scritta a schermo |
|---|---|---|---|
| 1 | 'Ton, da Paul | parti nell'appartamento, a qualche passo da Paul: vai da lui e parlagli | If you go back to Paul without sending the NSF signal, this dialogue happens: / JC stays with UNATCO. From here the story is new. |
| 2 | Fuori dal 'Ton | scendi la scalinata verso Gunther | If you leave the hotel, you find Gunther: / They go in to search Paul's room. |
| 3 | *variante* | scendi la scalinata | If Anna Navarre died on the 747, Gunther says this instead: |
| 4 | Dentro l'hotel | segui Gunther fino alla camera di Paul; poi, se vuoi, cliccalo per le domande | If you go back inside, you can follow the search: / Paul is already gone. / Afterwards you can question Gunther. |
| 5 | Scale della metro | niente: Anna parla appena arrivi | At the subway, Anna Navarre is on guard. If you killed Lebedev: |
| 6 | *variante* | niente | If Anna had to kill Lebedev herself, she says this instead: |
| 7 | *variante* | niente | If Anna is dead, a trooper guards the gate: |
| 8 | Battery Park | vai da Jock all'elicottero, parla, scegli di partire: il decollo porta al passo 9 | At Battery Park, Jock is waiting to take you to Hong Kong: / Next stop: Hong Kong. |
| 9 | Eliporto di Hong Kong | niente: Jock, l'ufficiale e Simons arrivano da soli | In Hong Kong the MJ12 helibase is not a trap any more: / An officer comes to welcome you: / Then Simons gives you the mission: |
| 10 | *variante* | niente: solo l'ufficiale | If you listened to Lebedev, JC asks about Majestic 12: |
| 11 | Mercato di Wan Chai | esci dall'ascensore e cammina nel corridoio | In the Wan Chai market, a Red Arrow messenger stops you: |
| 12 | Lucky Money | avvicinati all'ingresso, segui il Red Arrow, attraversa il ponticello fino a Max | At the Lucky Money, government agents are talking to the Red Arrow: / You are expected. He takes you to Max Chen: / Max Chen tells you why he sent for you: |
| 13 | Laboratorio di Tracer Tong | vai da Tong e parlagli; guarda il terminale; poi arriva l'assalto: resta, parla col comandante, aspetta la chiamata di Simons | Later, Tracer Tong agrees to see you: / He shows you what Paul found: / Then Special Projects arrives. You led them here: / UNATCO CONTINUES - To be continued. |

Se da un capitolo esci giocando (per esempio dal 'Ton in strada, o da Battery Park col decollo) la
presentazione riprende dal capitolo di quella mappa; alle varianti si arriva solo con PagSu.

## Dove sta nel codice
`UCTour` (passi e scritte: i testi sono nella funzione `Cue`), `UCCaptionWindow` (la targhetta e la
dissolvenza: `fadeTime`; il fondo usa la texture `UCFade`, rifatta da `tools\make_fade_texture.py`),
`UCDbgTour` e sottoclassi (salti e stato della partita per ogni passo), `UCTourMenu` (menu).
`UCMod` crea `UCTour` finché il flag `UC_Tour` è acceso; durante la presentazione i messaggi di
servizio `[UC]` non compaiono. Prova automatica: `tools\shots.ps1 -Setup UCDbgTour2` con passi
`console;summon UnatcoContinues.UCDbgTourNext` (le foto riprendono dopo ogni cambio di mappa).
