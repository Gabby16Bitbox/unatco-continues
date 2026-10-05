# Mission 1 — SEPARATE WAYS: piano di realizzazione a pezzi

Testo completo della missione (dialoghi, scelte, obiettivi): fornito da Gabby il 3 ott 2026 (vedi conversazione; da copiare qui in `MISSION1_SEPARATE_WAYS.md` quando fissato).
Regola: ogni pezzo si prova in gioco (menu debug, tasto Home) prima di passare al successivo.

| # | Pezzo | Contenuto | Stato |
|---|---|---|---|
| 1 | Prologo + ritorno (v2, 3 ott) | Bivio con Paul (conversazione originale) → **Paul scappa di corsa** → silenzio → InfoLink di Alex (testo M1 + "Hermann e Navarre sono a Battery Park") → title card "DEUS EX / SEPARATE WAYS" → uscito dall'appartamento **entrano UNATCO + MIB e perquisiscono il 'Ton** (battute nuove, il primo MIB parla con JC) → **Hell's Kitchen chiusa da posti di blocco UNATCO** (uscite chiuse tranne la metro, grata aperta) → **Battery Park: Anna e Gunther corrono incontro a JC**, scena concitata a 3 → Anna va a caccia di Paul, Gunther scorta JC al mezzo vicino al forte → battuta di Gunther → **cutscene decollo** → Liberty Island. **Niente Jock.** | **fatto, da provare** |
| 1c | Bivio multilaterale (3 ott) | Ingresso nella route UNATCO da **due** punti: (a) al **trasmettitore NSF** il computer "Broadcast Message" chiede *Send Paul's distress signal / Don't send it / Not yet* (scelta tagliata nel gioco originale) → se rifiuti, InfoLink di Paul e obiettivo "torna da Paul"; (b) torni da Paul senza mandarlo dopo aver trovato la prova. In entrambi i casi parla la conversazione originale `M04PlayerLikesUNATCO`. Con route scelta o segnale rifiutato il trasmettitore è spento. | **fatto, da provare** |
| 1d | Battery Park v3 (3 ott) | Anna da sola corre incontro a JC in stazione (scena), poi prende la metro; **Gunther aspetta di sopra al suo posto**: lo clicchi e fa il discorso ("We have a plane ready past the fort…"); poi **cutscene: JC e Gunther camminano insieme dritto** (robot vicini tolti) → Liberty Island. Niente elicottero. | **fatto, da provare** |
| 2 | Liberty Island / HQ — atmosfera | soldati extra, checkpoint, porte chiuse, foto di Paul sui terminali, barks sulla diserzione; nessuno ostile a JC | da fare |
| 3 | HQ — conversazioni | Troopers (opzionale), Alex (log di Paul, Ambrosia), Carter | da fare |
| 4 | Briefing Manderley | Manderley + Anna + Simons (scena a 4), obiettivi PRIMARY/SECONDARY/OPTIONAL | da fare |
| 5 | Hell's Kitchen di notte | coprifuoco, barricate, civili, 3 vie (assalto con Anna / fogne / tetti), soldati intrappolati (scelta) | da fare |
| 6 | Safehouse | infermeria, Paul via altoparlante, manifesto Ambrosia, Alex e la rete sconosciuta, Special Response Team, scelta nascosta, fuga di Paul, data core (A/B/entrambi) | da fare |
| 7 | Debriefing ed epilogo | Manderley (varianti), Simons, Anna (varianti), Alex/VersaLife, ultima scena (Simons e l'uomo nell'ombra) | da fare |

## Tecnica (come sono fatti i pezzi)
- Direttore `UCMod` (sempre attivo): legge i flag e lancia le scene **in ordine** (ogni scena richiede il flag della precedente).
- Scene `UCScene*`: sequenze con attese; non tengono puntatori fra un tick e l'altro.
- Dialoghi faccia a faccia: `UCCon` costruisce conversazioni **native** di Deus Ex (telecamere, nomi, clic per continuare; testo senza voce).
- InfoLink: finestra InfoLink del gioco con ritratti + suono di trasmissione.
- Cutscene: telecamera `UCCam` (ViewTarget), HUD nascosto, giocatore fermo.
- Debug (tasto Home): ogni voce porta **sul posto** con i flag precedenti già impostati; la scena parte da sola o avvicinandosi.
