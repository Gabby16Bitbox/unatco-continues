# Mission 1 Hong Kong "THE HUNT" — piano a pezzi

Design: `docs\HONGKONG_DESIGN.md` (punti 1–23). Ricerche sul gioco originale:
`docs\HK_ARRIVAL_RESEARCH.md` (eliporto), `docs\HK_STORY_RESEARCH.md` (personaggi, conversazioni, Dragon's Tooth, Tong),
`docs\HK_WORLD_RESEARCH.md` (fazioni, trigger, sicurezza, passaggi fra mappe).
Come per New York: un pezzo alla volta, provato in gioco prima di passare al successivo.

## Regole di Gabby (3 ott 2026)
- **Fino all'incontro con Tong si riusa il piu' possibile la logica originale**; il primo grande evento davvero nuovo e'
  l'assalto MJ12 al laboratorio di Tong (climax: "Wait... these aren't reinforcements."). Fino ad allora il giocatore deve
  poter razionalizzare tutto (Maggie mente = asset discutibile; Simons la conosce = operazioni clandestine; MJ12 =
  Special Projects; VersaLife = contractor).
- **Nessuna informazione fondamentale solo in bocca a Maggie**: dopo il primo incontro Maggie e' non essenziale. Se muore,
  la storia si ricostruisce dall'appartamento e dai contatti (Dragon's Tooth -> ologramma di Simons -> Max -> Gordon -> Tong).
  Lo stesso vale per il messaggero: utile ma sacrificabile.
- Decisioni: raid MJ12 al Lucky Money **tolto** (al massimo un accenno: due uomini governativi che parlano con un Red Arrow e
  spariscono quando JC si avvicina, nessun combattimento); ologramma di Simons **riusato, riscritto**; messaggero Red Arrow
  **si', facoltativo**; "seguire Maggie" **rinviato**.
- Percorso: arrivo -> messaggero facoltativo -> Max/Maggie -> Gordon -> indagine su Maggie -> ologramma di Simons ->
  tregua -> Tong -> assalto MJ12.

## Come lavoriamo sulle mappe di Hong Kong (regole tecniche)
- **Tutte le mappe 06 sono la missione 6** (`RevisionMission06`); non esistono mappe 07. I flag nostri hanno scadenza 99.
- **Conversazioni riscritte**: non si toccano i pacchetti di Revision. UCMod, a ogni caricamento della mappa, mette le
  nostre conversazioni (UCCon) in testa alla lista del PNG vanilla e toglie quelle originali da sostituire (`RemoveCon`).
  `ConListItems` e' transient: si riattaccano a ogni caricamento (controllo per nome).
- **InfoLink vanilla da zittire**: si imposta prima `<nome>_Played` (scadenza 99) — come gia' fatto per `DL_Jock_*`.
- **La "macchina" vanilla si riusa dove serve**: le nostre conversazioni impostano gli stessi flag vanilla
  (`Have_Evidence`, `MaxChenConvinced`, `QuickLetPlayerIn`) quando vogliamo i loro effetti (tregua, tastierini 1997...).
  Gli effetti che NON vogliamo si bloccano coi flag `MS_*` di guardia o togliendo gli attori (trigger) da UCMod.
- **Nomi dei goal**: niente nomi vanilla (`FindTracerTong` escluso, voluto), perche' eventi vanilla li completerebbero da soli.
- **Fazioni**: i nomi delle alleanze cambiano da mappa a mappa (`RedArrow`/`triad_red`/`Triad`..., `Cops`/`Cop`...):
  si riconoscono per classe + alleanza. Gli AllianceTrigger ignorano la "permanenza": vanno spenti quelli di trama.

## Pezzi

| # | Pezzo | Punti design | Stato |
|---|---|---|---|
| HK-1 | Arrivo all'eliporto: Jock, ufficiale MJ12, porte chiuse tranne l'ascensore, guardia, InfoLink di Simons, goal Contact Maggie Chow | 1–3 | **fatto** (da provare) |
| HK-2 | Wan Chai "cambiata": atteggiamento delle fazioni mappa per mappa, trigger di trama spenti, battute vanilla da fuggitivo zittite, compound chiuso | 4 | **fatto** (`UCHKWorld`, da provare) |
| HK-3 | Max Chen prima di Maggie (messaggero Red Arrow nel mercato, dialogo nel Lucky Money) | 5 | **fatto** (`UCHKStory`, da provare) |
| HK-4 | Maggie Chow riscritta (Queen's Tower) + nuovi obiettivi | 6–7 | **fatto** (`UCHKStory`, da provare) |
| HK-5 | Gordon Quick al cancello del compound ("Ask Maggie Chow who killed Yuen Kong") | 8 | **fatto** (`UCHKStory`, da provare) |
| HK-6 | Indagine: polizia, appartamento di Maggie, computer (testi anti-UNATCO sostituiti) | 9 | in parte: prove vanilla tenute; testi anti-UNATCO dei computer ancora da sostituire |
| HK-7 | Dragon's Tooth + InfoLink di Simons ("Your objective is Tracer Tong") | 10–12 | **fatto** (ologramma riscritto, `UCSwordHook`, `UCSceneSimonsSword`, da provare) |
| HK-8 | Prova a Max Chen, tregua, Gordon: "Tong will speak with you" | 13–14 | **fatto** (tregua vanilla via `MaxChenConvinced`, codice 1997 via `QuickLetPlayerIn`, da provare) |
| HK-9 | Laboratorio di Tong: dialogo, terminale VersaLife/Ambrosia/Gray Death, impulso del communicator, allarme | 15–17 | **fatto** (`UCSceneTongLab`, da provare) |
| HK-10 | Assalto MJ12, Simons, SECURE TRACER TONG, fuga di Tong, distruzione, scelta morale | 18–22 | **fatto** (`UCSceneTongLab`: 2 ondate, tecnici, prigioniero; da provare) |
| HK-11 | Simons fuori dal compound, fine missione, REPORT TO VERSALIFE | 23 | **fatto** (`UCSceneSimonsAfterTong`, anche fuori scena; da provare) |

### Correzioni dopo la prima prova (4 ottobre 2026)
- **La mod non partiva nelle mappe di Hong Kong** raggiunte giocando (niente messaggero, niente Simons): le uscite
  `MapExit` (es. l'ascensore dell'eliporto) ricostruiscono l'URL con `BuildOptionString()` e `?Mutator=` vuoto, e in
  single player i `ServerActors` non vengono creati. Ora JC porta nell'inventario `UCTraveler` (invisibile, fuori da
  inventario e cintura) che ricrea `UCMod` a ogni arrivo e ogni secondo se manca. Per i salvataggi vecchi: premere Home.
- Messaggero spostato nel corridoio dell'ascensore merci (-690,-1280), fermo, girato verso le porte; parla quando JC gli
  passa entro ~180 e lo vede. Simons chiama solo dopo.
- **Da fare in UnrealEd** (rimandato): all'eliporto le porte blindate rotte hanno ancora sopra i pezzi rotti (scintille,
  cavi elettrici) e il muro rotto: chiudere tutto nella copia della mappa (`maps\`), senza toccare l'originale.

### Copione definitivo "FINAL DIALOGUE PASS" (4 ottobre 2026)
Tutte le battute dal rifiuto di Paul fino a REPORT TO VERSALIFE sono quelle del copione di Gabby. Dove il gioco
ha imposto un adattamento:
- **Limite di 256 caratteri** per stringa in UnrealScript: i blocchi lunghi (Gunther "Paul always believed...",
  Maggie "Paul came here..." ed "Everything...") sono divisi in due battute consecutive dello stesso personaggio
  (stessa inquadratura, scorrono di seguito).
- **Gunther al 'Ton, Anna alla metro, ufficiale di Hong Kong, briefing di Simons**: sostituiti dalla specifica
  "Dialoghi e varianti" del 4 ottobre sera (varianti per Anna viva/morta e per chi ha ucciso Lebedev, conoscenze
  dei personaggi, Gilbert al bancone). Testi, regole di stile, flag e stato delle prove: `docs\DIALOGHI_STILE.md`;
  battute da doppiare: `docs\BATTUTE_DA_DOPPIARE.tsv`. Anna non e' piu' a Battery Park.
- **Jock a Battery Park**: dopo "All right. Get in." resta la scelta "Let's go." / "Give me a minute."; le battute
  facoltative ("Paul put a lot on the line...") partono tornando da Jock dopo "Give me a minute".
- **Jock a Hong Kong**: il dialogo "prima dell'atterraggio" parte appena JC e' sull'eliporto (il volo non si vede).
- **Maggie**: "Max Chen says you have contacts with both sides." solo se JC ha incontrato Max; altrimenti
  "Simons says...".
- **Gordon**: "Nineteen ninety-seven. The door in our sparring room." (il copione dice "The north compound", ma
  l'ingresso del laboratorio e' nella sala d'allenamento).
- **Tong**: ordine della scena come nel copione: allarme -> Simons ("Hold your position") -> Tong ("You were the
  authentication") -> fuga -> la squadra entra. Il comandante e' uno solo: entra con la prima ondata, saluta JC, poi va
  nella sala operatoria (episodio del prigioniero) e dopo la fuga parla di nuovo con JC prima della chiamata finale.
- **Varianti** non scritte nel copione: Tong morto prima dell'assalto, JC uscito durante l'assalto, JC che spara alla
  squadra ("I'm told you fired on Coalition personnel."), Maggie morta (niente "What about Maggie?").
- **Voci**: tutte le battute nuove o cambiate sono senza audio finche' non vengono rigenerate
  (`tools\voices\make_voices.py list` le elenca).

### "INFOLINK FIX PASS" (4 ottobre 2026)
Regola per tutti gli InfoLink di gioco: **parla solo chi chiama, JC non risponde**. Le domande di JC (Maggie, Special
Projects, "sanitizing", JC usato per trovare Tong, "Then the records should be easy to disprove") restano per un
confronto di persona con Simons. Se JC deve mandare informazioni, lo fa da solo un rapporto (flag) o un computer.
- **Briefing** (`UCSceneSimonsBriefing`, sempre nel mercato dopo il messaggero): 3 battute di Simons; goal LOCATE TRACER
  TONG (primario) e CONTACT MAGGIE CHOW (ora secondario).
- **Dragon's Tooth** (`UCSceneSimonsSword`): il rapporto parte da solo quando JC esce dalla stanza segreta
  (`UCHKStory.SimonsCall`: a 400 dal punto in cui ha visto finire la registrazione; senza registrazione quando lascia
  l'appartamento o la mappa). Flag `DragonToothEvidenceFound`, `SimonsMaggieRecordingSeen`, `ChowEvidenceReportSent`,
  messaggio "Mission report transmitted: Queen's Tower." Versione A (registrazione vista) / B (non vista).
- **Assalto** (`UCSceneTongLab`): 3 battute di Simons ("You've completed the locating phase..."); poi Tong di persona
  ("There is your answer." ... "You were the authentication."). Variante non scritta: Tong gia' morto ->
  "Tong's death has been confirmed." senza l'ultima battuta. Goal SECURE: "Hold your position: do not interfere...".
- **Fine assalto** (`UCSceneSimonsAfterTong`): flag `VersaLifeEvidenceFragment`, `TongEvidenceReportSent`, messaggio
  "Mission data uploaded to UNATCO.", poi 5 battute di Simons; goal REPORT TO VERSALIFE. Varianti: Tong morto ("Tong is
  dead, and his facility..."); JC ha sparato alla squadra (solo l'avvertimento di Simons, battute gia' doppiate).
- **Cambio zona a meta' InfoLink** (bug: si perdeva e poi si ripeteva): come il gioco originale
  (`DeusExPlayer.PreTravel` -> `DataLinkPlay.AbortAndSaveHistory`) l'InfoLink vale come ascoltato. Flag "fatto" e
  goal partono all'inizio, tutto il testo va subito nella cronologia delle conversazioni (`UCScene.InfoStart`), e
  all'arrivo nella nuova zona la finestra rimasta aperta si chiude (`UCTraveler.CloseStaleWindows`). Il laboratorio di
  Tong riprende dal punto giusto se JC esce a meta' scena (prima ripartiva da capo).
- L'InfoLink di Paul a New York quando JC non manda il segnale (`UCSceneRefuse`) e' tolto: per dire di no
  JC torna da Paul al 'Ton e glielo dice di persona (classe spostata in `src\UnatcoContinues\obsolete`).

### HK-2 — Wan Chai cambiata
- Atteggiamento verso JC (a ogni caricamento, `ChangeAlly('Player', ...)` per classe+alleanza):
  Red Arrow +1, polizia +1, VersaLife/MJ12 +1 (staff `Worker`, guardie `mj12`/`Security`), Luminous Path 0 (sospettosi:
  non attaccano), civili invariati.
- Trigger da spegnere (vedi HK_WORLD 2a): `Onalert`/`TroopsHate`/`AllianceTrigger4/5` sulle truppe MJ12 di Maggie (Street),
  `MaidPissed`, `MaySungWhupass`, `LumpathPissed`/`Breakintocompound` (Compound e TongBase), `VL_OnAlert` e
  `SecurityRevoked` (VersaLife/MJ12 lab, legati a `Have_ROM`/`M07Briefing_Played`). Restano i divieti "di gioco"
  (piano di sopra della stazione di polizia, banco del chiosco): un agente non entra dove non deve.
- Battute da zittire (HK_WORLD 4 / HK_STORY A8): `DL_Jock_05`, `DL_Daedalus_02`, `DL_Jock_04` (gia' fatto),
  `DL_Tong_00B`/`DL_Tong_00` (Street), `Gate_Guard2` e barks con "loyal to UNATCO"/"12 hours", le battute su Paul morto/vivo.
- Compound: resta chiuso finche' Gordon non da' il permesso (cancello e seminterrato col 1997 come in originale), ma JC
  non viene attaccato se ci entra: i Luminous Path lo cacciano a parole.
- Passaggi rotti del gioco originale (verso `06_HongKong_WanChai_Sewers`, che non esiste): disattivati.

### HK-3 — Max Chen
- Il messaggero Red Arrow esiste gia' nel gioco ma non e' piazzato in nessuna mappa (`MeetRed_Arrow_01`): lo mettiamo nel
  mercato. MESSENGER: Denton? / JC: Who's asking? / Someone who knows why you're here. / Who? / Max Chen. Lucky Money. /
  Why does Chen want to see me? / Ask him. -> flag `RedArrowMessengerContacted`, `MaxChenMeetingAvailable`.
  `MaxChenMeetingAvailable` si accende anche entrando nel Lucky Money o parlando con un altro Red Arrow: se il messaggero
  muore o viene ignorato, la quest non si rompe.
- Accenno nel Lucky Money: due uomini "governativi" parlano con un Red Arrow e se ne vanno quando JC si avvicina.
- Quel Red Arrow poi porta JC da Max (5 ottobre 2026): Max l'ha mandato a chiamare, quindi niente biglietto alla
  porta e qualcuno che fa strada fino all'ufficio. Anche il primo dialogo di Max dice perche' l'ha voluto vedere
  ("before the others do"). Dettagli e battute in `docs\DIALOGHI_STILE.md`, "Hong Kong: arrivo e Max Chen".
- Eliporto (5 ottobre 2026): tolta la guardia MJ12 davanti all'ascensore; l'ufficiale corre da JC appena finisce il
  dialogo con Jock.
- Max (Lucky Money, BindName MaxChen) parla per vicinanza (r190) con la sua `MeetMaxChen`, che di base lo insulta e
  imposta `MaxPissed`: la nostra versione va in testa e imposta `MeetMaxChen_Played` (serve a `Show_Chen` piu' avanti).

### HK-4 — Maggie Chow
- `MeetMaggie` (radius 120, con l'introduzione di May Sung): si riscrivono testo e goal mantenendo la struttura; si
  neutralizzano `MeetMaggie2`, le battute su Paul e "UNATCO agents killed him".
- Goal: LOCATE TRACER TONG (gia' presente) + secondario INVESTIGATE THE LUMINOUS PATH + facoltativo INVESTIGATE THE DEATH
  OF RED ARROW LEADER YUEN KONG. Completa ContactMaggieChow.
- Effetti nascosti da controllare: `BeenToCops` (Maggie se ne va, May Sung chiama le guardie), uscita dalla stanza della
  spada (`NoticedMJ12ChowConnection` -> Maggie se ne va). Maggie e' uccidibile: se muore, la storia deve reggere.

### HK-5 — Gordon Quick
- `Gate_Guard2` (frob) riscritta con il dialogo del design; alla fine "Ask Maggie Chow who killed Yuen Kong" (flag per HK-6).
- Il gioco originale completa `CheckCompound`/`DeliverChensResponse` qui: non usiamo quei nomi.

### HK-6 — Indagine (tutte le strade portano a "Maggie mente")
- Prove gia' nel gioco: datacube della polizia (`06_Datacube22`, caveau 87342, porte 911), trascrizione della tortura nella
  stanza della spada (`06_Datacube06`), email sul PC di Max (LUCKYMONEY/REDARROW), email di Simons a Maggie (`Email03`),
  PC di Jock (`Email06`), email del laboratorio MJ12 (`Email16`).
- Testi da sostituire (parlano di "rogue operative J.C. Denton", "terminate them both"...): le email si caricano da
  `<missione>_EmailMenu_<utente>` nel `TextPackage` del computer -> si puo' reindirizzare a un nostro pacchetto di testi
  (da verificare come crearlo con ucc). "Seguire Maggie" non esiste nel gioco originale: per ora no.

### HK-7 — Dragon's Tooth e Simons
- La spada: `WeaponNanoSword0` nella stanza segreta di Maggie (codice 718, o computer `Secret_pc` MChow/INSURGENT).
- `DL_Tong_00B`/`00` (Tong che aiuta JC) vanno sostituiti da un InfoLink di JC a Simons (punti 11–12), che imposta comunque
  `Have_Evidence` e i flag che servono dopo. La tregua si lega a `Have_Evidence`, non al portare la spada (Revision puo'
  rifiutare l'oggetto).
- Ordine: Dragon's Tooth -> ologramma -> chiamata a Simons.
- Ologramma (`M06WaltonHolo`, riscritto: conversazione normale, sospetta solo perche' JC la trova li'):
  SIMONS: Maggie. Denton should be arriving shortly. / MAGGIE: And if he refuses to cooperate? / SIMONS: He won't. /
  MAGGIE: You're very confident. / SIMONS: His brother made that mistake for us. / (pausa) MAGGIE: And Tong? /
  SIMONS: Denton will take care of that. / (fine) JC: Simons...
  Prova solo che Simons e Maggie si coordinavano PRIMA che JC arrivasse.
- Chiamata a Simons (sostituisce i punti 11–12 del design): JC: I found the Dragon's Tooth in Chow's apartment. /
  SIMONS: Then secure it. / JC: I also found a recording. / (silenzio) JC: You and Maggie. / SIMONS: Maggie Chow is an
  intelligence asset. / JC: You knew. / SIMONS: I know a great many things you don't, Denton. / JC: Did she kill Yuen Kong?
  / SIMONS: Your objective is Tracer Tong.

### HK-8 — Max, tregua, Gordon
- `Show_Chen`/`MeetMaxChen` (ramo prova) riscritti col dialogo 13; impostano `MaxChenConvinced` -> tregua vanilla
  (Garage e Lucky Money). L'incursione MJ12 nel Lucky Money che segue in originale va decisa (vedi domande).
- `QuickFinalTalk` riscritta (14) -> `QuickLetPlayerIn` (tastierini 1997 del compound e del seminterrato).

### HK-9 / HK-10 — Laboratorio di Tong e assalto MJ12
- **Design dettagliato (3 ott 2026): `docs\HONGKONG_ASSAULT_DESIGN.md`** — sostituisce le note qui sotto dove diverge.
- Prima: playtest del percorso Messenger -> Max -> Maggie -> Gordon -> tregua (`docs\PLAYTEST_HK.md`).
- Tong (`06_HongKong_TongBase`, BindName TracerTong, invincibile) parla per vicinanza (r90): `MeetTracerTong` va sostituita;
  l'operazione del killswitch (due trigger a terra, `KillswitchFixed`) va spenta.
- Il terminale (Ambrosia / Gray Death): testo nostro (vedi il punto sui pacchetti di testi in HK-6) o finestra della mod.
- Nella base non ci sono MJ12, tecnici o server: la squadra d'assalto, i tecnici Luminous Path e i server da distruggere
  li crea UCMod (alleanze impostate a mano). Fuga di Tong: ordini `Leaving` come il `TracerGone` vanilla, passaggi
  `hatch01`/`hatch02`/`Secretdoor01`.
- Scelta morale (21): conversazione con scelta; flag-contatori `UNATCORoute_Compliant` / `UNATCORoute_QuestionsMJ12`.
- VERSALIFE DATA FRAGMENT: oggetto/nota recuperato dal computer di Tong.

### HK-11 — Fine missione
- InfoLink di Simons all'uscita del compound (23); goal REPORT TO VERSALIFE; il codice dell'ascensore del mercato (06288)
  in originale lo da' solo Tong: qui lo da' Simons (o arriva come nota).

## Missione 2 (VersaLife) — gia' visto
- Ingresso: ascensore del mercato (06288) -> atrio VersaLife -> Hundley / codice 6512 -> laboratorio MJ12. Lo staff del
  laboratorio tratta gia' JC da visitatore autorizzato ("You must be with Simons' office").
- Da tenere spenti: `Have_ROM` e `M07Briefing_Played` (rendono ostili VersaLife e il laboratorio), l'ufficio sicurezza
  dell'atrio (tastierino 9455) e la scena di Hundley/John Smith.

## Domande per Gabby
Risposte del 3 ott 2026 nella sezione "Regole di Gabby" in cima.
