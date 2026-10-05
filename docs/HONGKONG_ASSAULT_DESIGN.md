# Hong Kong — laboratorio di Tong e assalto MJ12 (design di Gabby, 3 ott 2026)

Pezzi HK-9..HK-11 di `docs\HONGKONG_M1_PIANO.md`. Primo vero reveal operativo di MJ12: prima il giocatore ha visto
Government Agents, uomini che rispondono a Simons, Maggie che mente, il collegamento Simons/Maggie, VersaLife apparentemente
legittima — ma non MJ12 come forza armata separata.

**Regola di tono**: JC non dice "Paul was right"; Simons non confessa nulla; MJ12 non spara a JC. JC puo' ancora dirsi:
"qualcosa non va in questa operazione, ma non vuol dire che l'UNATCO sia il nemico". La Missione 2 rende difficile crederlo.

**Regola aggiunta da Gabby**: se JC impedisce un'esecuzione gli uomini di Simons NON diventano ostili (sarebbe la campagna
vanilla): il comandante si ferma, prende nota dell'insubordinazione e continua l'operazione.

## 1. Ingresso
Dopo la tregua Gordon da' il codice. Il Luminous Path NON diventa amico: JC e' un ospite tollerato/scortato.
Barks: "Tong agreed to see you. That doesn't make you welcome." / "Keep your weapon down and there won't be a problem."

## 2. Primo dialogo con Tong (Tong sa chi e' JC e perche' e' venuto)
TONG: J.C. Denton. / JC: Tracer Tong. / TONG: Paul said you might come. / JC: Paul expected me to ask for your help. /
TONG: And instead? / JC: You're coming with me. / (sorriso) TONG: To UNATCO. / JC: That's right. / TONG: Even after
everything you've seen? / JC: I've seen Maggie Chow lie. / JC: I've seen Triads killing each other. / JC: Neither makes you
innocent. / TONG: Good. / (pausa) TONG: Paul tried to give you a conclusion. / JC: He gave me his conclusion. /
TONG: Then I will give you evidence.

## 3. Tong non diventa subito amico
JC: Why would you help me arrest you? / TONG: Because if you still believe in UNATCO after seeing this, Paul was wrong
about you. / JC: And if I don't? / TONG: Then perhaps he was right.

## 4. Terminale con le prove VersaLife (non tutta la Gray Death)
Mostra: VERSALIFE + AMBROSIA DISTRIBUTION + NANOTECH RESEARCH + riferimenti a clearance UNATCO/governative. Grave, ma non
risolve la cospirazione.
JC: These shipment IDs match the Ambrosia records Paul showed me. / TONG: Yes. / JC: Where did you get them? /
TONG: VersaLife. / JC: VersaLife manufactures pharmaceuticals. / TONG: Among other things. / JC: This doesn't prove UNATCO
is involved. / TONG: Then continue your investigation. (Tong non convince JC: gli da' una direzione.)

## 5. Tracciamento nascosto
All'arrivo nel laboratorio: `JCLedMJ12ToTong = TRUE`. L'assalto parte solo dopo `TongEvidenceConversationComplete`.
Come abbiano tracciato JC resta ambiguo (equipaggiamento, sorveglianza, elicottero, beacon).

## 6. Tong capisce
Un computer/sensore suona. TONG: Interesting. / JC: What? / TONG: Your friends are here. / JC: UNATCO? / TONG: You tell me.

## 7. Assalto
MVP: 6–8 commando, 1 comandante, 2 tecnici, in ondate. Fazioni: MJ12 amico di JC, ostile al Luminous Path e alle guardie
di Tong; Luminous Path ostile a MJ12 ma NON automaticamente a JC (JC puo' stare in mezzo).
Nomi a schermo: non "MJ12 Commando" ma "Special Operations Trooper" / "Special Projects Commando". Un simbolo MJ12 puo'
comparire per la prima volta (cassa, terminale, uniforme) senza commento di JC.

## 8–9. Simons (InfoLink)
SIMONS: Denton. / JC: There's a tactical team entering the compound. / SIMONS: Correct. / JC: They followed me. /
SIMONS: They followed Tong. / JC: Through me. / (pausa) SIMONS: You completed your assignment.
JC: I had Tong contained. / SIMONS: You had Tong talking. / JC: That's how interrogation works. / SIMONS: Not this one.
Goal PRIMARY SECURE TRACER TONG: "A Special Projects recovery team has entered the compound. Assist in securing Tracer Tong."

## 10. Fuga di Tong (via di fuga scriptata semplice)
Con `MJ12AssaultStarted` Tong va all'uscita d'emergenza: TONG: Come with me. / JC: No. / TONG: Then stay. / (pausa)
TONG: And watch what your people do. Sparisce. `TongEscapedCompound`, `TongLocationUnknown`.
Tong non puo' morire durante la fuga scriptata (prima dell'assalto si').

## 11. Se Tong e' gia' morto
L'assalto parte lo stesso. SIMONS: Tong is dead. / JC: That's usually what happens when somebody gets shot. /
SIMONS: Then secure his data. Goal RECOVER TONG'S ARCHIVES. La storia continua attraverso i server: Tong non e' essenziale.

## 12. Cosa fa davvero MJ12 (a stadi)
1) combatte le guardie armate; 2) entra nelle sale tecniche; 3) i tecnici copiano dati, distruggono dischi, piazzano
cariche; 4) alcuni commando eliminano chi non e' piu' una minaccia. JC capisce che non e' un normale arresto.

## 13. Il prigioniero (facoltativo)
TECHNICIAN: I'm unarmed! (il comandante punta l'arma) JC (se vicino): Hold your fire. / COMMANDER: Continue your
assignment, Agent Denton. / JC: He's unarmed. / COMMANDER: He's part of Tong's operation. / JC: Then arrest him. / (pausa)
COMMANDER: Our orders don't require prisoners.
Niente scelta a menu: se JC se ne va `JCIgnoredMJ12Execution`. Se resta/insiste (MVP): JC: Mine do. / COMMANDER: This isn't
your operation. / JC: Then stop giving me objectives. / COMMANDER: Take him. (un soldato porta via il prigioniero;
`JCObjectedToMJ12Execution`; il comandante prende nota, nessun combattimento).

## 14. I server
JC: What are you doing? / TECH: Sanitizing compromised systems. / JC: Those systems are evidence. / TECH: Not anymore.

## 15. Frammento VersaLife
Prima della distruzione JC recupera (da solo o automaticamente) `VersaLifeEvidenceFragment`: VersaLife Level 2, ricerca
nanotecnologica, riferimenti a laboratori riservati, rapporto Gray Death / Ambrosia accennato. Non prova definitiva.

## 16–18. Simons dopo la fuga
JC: Tong got away. / SIMONS: Unfortunate. / JC: Your team gave him the warning. / SIMONS: Our team prevented the
destruction of sensitive intelligence. / JC: They're destroying it. / (pausa) SIMONS: They're containing it. /
JC: Interesting distinction.
JC: Tong showed me records from VersaLife. / (pausa) SIMONS: What records? (reazione immediata) / JC: Ambrosia shipments.
Nanotechnology research. / SIMONS: Tong manufactures evidence as easily as weapons. / JC: Then it should be easy to
disprove. / (pausa) JC: I'll check VersaLife. / SIMONS: That won't be necessary. / JC: Why? / (silenzio) SIMONS: Because
you'll be granted access. / SIMONS: Report to VersaLife. / JC: Officially? / SIMONS: You're still an UNATCO agent,
Denton. / JC: I noticed.
Goal PRIMARY REPORT TO VERSALIFE: "Walton Simons has authorized an investigation of the information recovered from Tracer
Tong. Report to VersaLife." JC non disobbedisce: l'indagine e' autorizzata ("il sistema puo' indagare su se stesso").

## 21. Il comandante dopo l'assalto
COMMANDER: The facility is secure. / JC: Tong escaped. / COMMANDER: The facility is secure. / JC: You already said that. /
COMMANDER: Then we're done.

## 22–23. Paracadute
- JC se ne va durante l'assalto: `MJ12AssaultResolvesOffscreen`, `TongEscapedCompound`, `VersaLifeEvidenceFragment`;
  Simons lo contatta all'uscita ("Tong escaped during the operation." ...). La storia non si blocca.
- JC spara agli uomini di Simons: `JCAttackedSpecialProjects` (la campagna NON si ferma: forse reagiva a un'esecuzione).
  Dopo: SIMONS: I understand you fired on Coalition personnel. / JC: They were executing prisoners. / SIMONS: We'll
  discuss your judgment later. Solo un massacro sistematico: `UNATCORouteDisciplineViolation` (da gestire dopo).

## Flag
TongMeetingStarted, TongMeetingComplete, TongEvidenceShown, VersaLifeEvidenceFragment, JCLedMJ12ToTong,
MJ12AssaultStarted, MJ12AssaultResolved, TongEscapedCompound, TongLocationUnknown, JCIgnoredMJ12Execution,
JCObjectedToMJ12Execution, JCAttackedSpecialProjects, SimonsVersaLifeConcern, VersaLifeInvestigationAuthorized.

## Note tecniche (dalla ricerca, `docs\HK_WORLD_RESEARCH.md` sez. 6)
- Base di Tong: ingresso dal seminterrato del compound (teletrasporto a (1240,-886,296), scala verso la sala grigliata);
  laboratorio centrale con Tong (127,-83,46) e il PC "Illuminati Information Base" (274,-28,49); porta segreta
  `Secretdoor01`; ala ovest con i portelli `hatch01`/`hatch02` (evento `hatch`) verso il magazzino: via di fuga di Tong.
- Nessun MJ12, tecnico o server nella mappa: si creano da script. Allarmi `AlarmUnit` (senza Event) usabili per l'effetto.
- Gli MJ12Troop creati non hanno alleanza: impostare `Alliance='mj12'` e le `ChangeAlly` (Player +1, Triad/Allies -1).
- Tong, Paul, Alex, Jaime sono invincibili di classe; Tong e' bImportant (`TracerTong_Dead`).
- L'IA del gioco basta (ordini, alleanze, fuga, combattimento): niente IA nuova. UnrealEd solo per cambiare la mappa
  (nuovi passaggi, server fisici) se servira'.
