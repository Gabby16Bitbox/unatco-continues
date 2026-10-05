# Playtest Hong Kong — Messenger -> Max -> Maggie -> Gordon -> tregua -> Tong

Prima di aggiungere l'assalto. Menu di debug: tasto **Home**. Ogni salto azzera i flag della route, ma una mappa gia'
visitata nella partita torna com'era (personaggi spostati, porte aperte...): per una prova pulita partire da un
salvataggio fatto prima di entrare a Hong Kong, o da una partita nuova col salto 5/6.
Verifica automatica gia' passata (senza gioco): `tools\check-hongkong.ps1` (85 controlli, 0 errori).

Se una partita salvata e' gia' a Hong Kong senza che la mod sia partita (niente messaggero, niente Simons):
premere **Home** una volta (apre il menu di debug e rimette in moto la mod), poi chiudere il menu.

## Percorso
| # | Dove | Cosa fare | Cosa deve succedere |
|---|---|---|---|
| 0 | Menu **3** (Hell's Kitchen dopo Paul) o uscendo dal 'Ton | scendere la scalinata | Gunther e i due agenti aspettano sul marciapiede, fermi; parlano solo quando JC arriva vicino; poi salgono in fila indiana dalla corsia nord ed entrano. Nella camera di Paul niente pozza grande, solo le macchie piccole |
| 1 | Menu **6** (mercato), oppure ascensore dell'eliporto | uscire dall'ascensore e camminare nel corridoio | il messaggero Red Arrow e' fermo contro il muro del corridoio e parla solo quando JC gli passa accanto: "Denton?" ... "Ask him." -> goal facoltativo Max Chen; DOPO il messaggero l'InfoLink di Simons (goal Contact Maggie Chow) |
| 2 | Lucky Money (dal mercato), oppure `summon UnatcoContinues.UCDbgLucky` | avvicinarsi all'ingresso | in cima ai gradini 2 "Government Agent" + 1 Red Arrow: "shipment"; i due se ne vanno e spariscono. Il Red Arrow ferma JC ("Mr. Chen is expecting you." ... "This way."), poi fa strada di corsa: le porte del club si aprono senza pagare, attraversa la sala, rallenta nella sala sul retro, apre le porte dell'ufficio di Max e si mette di lato ("Mr. Chen is inside."). Se JC resta indietro lo aspetta |
| 3 | Lucky Money, ufficio di Max | attraversare il ponticello | Max: "Mr. Denton. I wanted to see you before the others do." ... "Yes. That is why I sent for you first." (non l'insulto vanilla, non "MaxPissed") |
| 4 | Menu **7** (Queen's Tower) | ascensore principale fino al piano di Maggie | May Sung accompagna; Maggie: "Mr. J.C. Denton." ... "earn his trust." -> goal Luminous Path + facoltativo Yuen Kong; Maggie va a sedersi |
| 5 | Stanza della spada | codice 718 (o PC MChow / INSURGENT) | la teca si apre; NESSUN InfoLink di Tong; goal "Show Max Chen..." |
| 6 | Stanza della spada | interruttore dell'ologramma | due ologrammi (Simons + Maggie): la registrazione riscritta, poi JC: "Simons..." |
| 7 | (subito dopo) | — | JC chiama Simons: "I also found a recording." ... "Understood." (senza ologramma: versione corta quando si esce dalla torre) |
| 8 | Menu **8** (compound) | parlare con Gordon al cancello | "Paul Denton trusted you." ... "Ask Maggie Chow who killed Yuen Kong." Nessun "loyal to UNATCO" / "12 hours". Nessuno attacca |
| 9 | Lucky Money, Max (con la prova) | avvicinarsi | "Maggie had this?" ... "Is there a difference?" + tregua. Nessun raid MJ12 |
| 10 | Compound, Gordon | parlargli | "Tong will speak with you." ... codice 1997; i tastierini del cancello e del seminterrato compaiono |
| 11 | Menu **9** (laboratorio di Tong) | scendere nella sala, entrare nel laboratorio | le guardie avvertono a parole; Tong: "J.C. Denton." ... "Then show me yours." / "Exactly." (niente killswitch) |
| 12 | Laboratorio | — | Tong va al terminale: finestra con i registri Ambrosia/VersaLife (9 s), poi "These are shipping records Paul obtained..." ... "I'm interested in changing your information."; nota "VersaLife data fragment" |
| 13 | Laboratorio | — | allarme; "What happened?" ... "Your friends." / "You tell me." |
| 14 | (subito dopo) | — | InfoLink di Simons: "Hold your position. A recovery team is entering the facility." ... "Then Tong would have known too." + goal (cooperare con la squadra, mettere al sicuro i dati) |
| 15 | Laboratorio | — | Tong: "There is your answer." ... "You were the authentication." ... "Watch what your people do."; scappa a ovest dai portelli |
| 16 | Laboratorio | aspettare | entra la squadra; il comandante raggiunge JC: "Agent Denton. Special Projects..." ... "Then we have compatible objectives."; poi se ne va. Combattono le guardie, sparano ai tecnici del Luminous Path; NON a JC |
| 17 | Laboratorio | parlare col tecnico al terminale | "Sanitizing the network..." ... "By who?" / "Special Projects."; il terminale salta |
| 18 | Sala operatoria (est) | avvicinarsi | prigioniero "I'm unarmed! I'm not security!": se JC si avvicina -> "Hold your fire." ... "You are now." / "Take him upstairs."; se JC se ne va -> lo giustiziano |
| 19 | Vicino al comandante, dopo la fuga | avvicinarsi | "Tong got out." ... "You weren't part of this operation until you found the door." (se JC non ci va, dopo 40 s si passa oltre) |
| 20 | (dopo) | — | InfoLink di Simons: "Tong escaped during the assault." ... "Very well." / "You'll go in officially." ... "Report when you know something useful." -> goal REPORT TO VERSALIFE + nota col codice 06288 |
| 21 | Uscire durante l'assalto | — | Simons chiama comunque, senza la parte sui dati cancellati se JC non l'ha vista |

## Effetti nascosti del gioco originale da osservare
- Leggere il rapporto della polizia (caveau 87342, `BeenToCops`): Maggie lascia la torre; May Sung grida "Guards!" ma le
  guardie non devono attaccare. Segnalare come si vede.
- Uscendo dalla stanza della spada Maggie se ne va (`NoticedMJ12ChowConnection`): normale.
- Nel compound prima del permesso: i Luminous Path dicono "Leave the compound now!" ma non sparano.
- Dopo la tregua la rissa fra Triadi nel garage (Canal Road) si ferma.
- Uccidere Maggie in qualunque momento: la storia deve proseguire (goal del Luminous Path da Gordon).
- Uccidere/ignorare il messaggero: entrando nel Lucky Money si puo' comunque incontrare Max.

## Da annotare
Battute che non partono o partono due volte, personaggi che diventano ostili, testi vanilla che parlano di killswitch o
del JC fuggitivo, goal che restano aperti o si completano da soli.
