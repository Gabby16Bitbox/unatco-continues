# Playtest Hong Kong — revisione del 6 ottobre

## Percorso corrente

- Per il nuovo arrivo usare un salvataggio prima del volo a Hong Kong, oppure `summon UnatcoContinues.UCDbgHongKong` in un livello fresco. Si arriva sul tetto civile: H su piattaforma rialzata, quattro gradini, liaison, blocco di servizio e ascensore. Jock resta sul tetto; ascoltare il primo scambio e quello facoltativo successivo.
- Avvicinarsi al liaison, poi al checkpoint: Simons dà l'ordine sul Red Arrow senza far rispondere JC. Entrare nella cabina e premere il pulsante: la porta si chiude, la piattaforma scende brevemente e si arriva nel cortile del Market.
- Nel cortile ascoltare la spiegazione evasiva del liaison. Attraversare il disimpegno avvia la diversione; gli aggressori passano dalla porta di manutenzione e dalla passerella. Devono cercare la cassa, non JC. Provare sia intervenire sia uscire verso il mercato senza ucciderli tutti.
- Leggere il cartellino VL-HK soltanto in una delle prove. Anche dopo il furto della cassa rimane a terra: la lettura dà una nota attribuita a VersaLife, non rivela il contenuto. Tong deve distinguere lettura e mancata lettura, intervento e semplice presenza.
- Tornare all'ascensore e risalire al tetto: arrivo nel disimpegno, nessuna compenetrazione con la piattaforma, nessun riavvio del raid al ritorno nel cortile. Verificare il passaggio fisico verso il Market e l'uscita laterale verso Canal Road. Il messaggero propone Max dopo il raid; il percorso resta facoltativo.
- Max offre un accordo facoltativo. Rifiutarlo non chiude l'indagine: Gordon può concedere il colloquio dopo la verifica della spada anche senza Max.
- La spada si consegna soltanto scegliendo il trasferimento, con l'arma verificata realmente in inventario. Il possesso non è una prova dell'omicidio di Yuen: leggere trascrizione di Chow e rapporto della polizia.
- Nel laboratorio leggere il datacube di accesso: archivio `TONG / 1997`, console di servizio dietro il magazzino `MAINT / 1997`.
- Leggere manifest e copia attribuita di Paul. La consultazione del manifest lascia una nota di lettura; il comando separato **Copy** salva gli identificativi originali.
- Attendere senza trasmettere: nessun assalto. Trasmettere la posizione dall'archivio e ricevere Simons: porta ancora chiusa, nessun assalto.
- Provare ad attraversare con JC il muro ancora chiuso: deve fermarlo. Alla console di servizio aprire l'accesso: il muro scende nel pavimento, la squadra scende dalla scala, attraversa il magazzino e solo allora parte l'operazione. Il cancello in cima alla scala rimane INF e impedisce di raggiungere il caricamento esterno; il poligono è originale. La console usa HKNet, senza marchi UNATCO.
- Seguire il comandante nella sala operatoria per intervenire sul prigioniero; allontanarsi per verificare il ramo ignorato. Controllare conseguenze e note di custodia.
- I tecnici lavorano sugli archivi. La copia già salvata rimane; senza copia il rapporto indica l'estrazione di Special Projects.
- Completare il sweep non invia il rapporto. Usare **Upload operation report** all'archivio o ai terminali sicuri esterni: solo quel comando produce l'incarico VersaLife.
- Ripetere con Tong morto, Gordon morto, arma trattenuta o lasciata nella teca; provare save/load e cambio mappa nelle fasi prima e dopo l'apertura.

Il nuovo arrivo civile è descritto in [HONGKONG_ROOFTOP_FLOW.md](HONGKONG_ROOFTOP_FLOW.md). L'eliporto MJ12 originale rimane un sito separato. Per verifiche eseguite e limiti della copertura vedere [STATUS.md](STATUS.md).

Revisione visiva installata alle 23:43: piattaforma 896 × 896, reti basse ai bordi,
zona impianti recintata e cabina con pannelli metallici e pavimento a griglia.
Prova automatica completa: 30 controlli, zero errori, 14 foto; controllo hash delle
otto destinazioni installate. Durante le foto automatiche i comandi manuali sono
disattivati, così il lavoro desktop non sposta JC durante le attese del test.

## Registro storico — versione precedente al 6 ottobre

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
