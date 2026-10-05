# Voci di UNATCO Continues

Eseguire i comandi dalla cartella `UnatcoContinues`.
`voices.ps1` usa Python di Codex: il launcher `py` di Windows, su questo PC,
punta a una vecchia installazione Microsoft Store non utilizzabile.

## Versione corrente: V4, ritmo e mix calibrati

Le battute correnti usano Eleven v4 con direzione sobria e stabilita 0,90;
JC usa stabilita 1,00, somiglianza 0,85 e il tag `deadpan`.
`delivery_natural_v4.json` registra prompt, contesto, canale, durata prevista e
livello per ogni frase. Il confronto usa registrazioni originali per ogni voce, comprese
le chiamate InfoLink di Alex e Paul; la stima dei tempi considera pronuncia
approssimata e pause tra frasi, con tolleranza del 20% o 250 ms. Per JC si
ammette anche lo scarto osservato nel 90esimo percentile degli originali
(circa 575 ms), evitando di accelerare risposte brevi e piatte. I nuovi testi
sono diversi dagli originali, quindi non si tratta di un allineamento esatto.

Soldati e Jock usano stabilita 0,95 e somiglianza 0,80. Le due voci UNATCO
sono cloni separati dei gruppi originali `UNATCOTroop` e `UNATCOTroopB`:
`UC UNATCO Soldier 1` e `UC UNATCO Soldier 2`. La scelta segue `BarkBindName`,
che resta salvato sul PNG anche quando il dialogo usa `UCGreeter` o `UCBark`.
Le varianti di aspetto/skin non creano da sole una nuova voce. A Hong Kong
l'ufficiale e la guardia usano rispettivamente i cloni MJ12 A e B;
anche le loro battute native mantengono quel gruppo vocale.
Jock e Walton Simons hanno cloni separati dai rispettivi originali. Il nuovo
briefing di Simons usa il filtro InfoLink calibrato sulle sue registrazioni
radio; le risposte di JC rimangono locali e asciutte.

L'EQ lieve mantiene le voci in presenza asciutte. Soltanto i mittenti remoti
Alex, Paul e Simons ricevono il filtro InfoLink; JC resta senza filtro radio anche
quando risponde. Il mix comune usa -14 LUFS per gli NPC diretti, -14,5 per
radio e proiezioni e -15,5 per JC, con tolleranza di 0,25 LU. Le nuove battute UNATCO B
usano lo stesso riferimento di mix di A, compensando i barks originali B molto
piu bassi. I dialoghi lunghi dei soldati non vengono accelerati al ritmo delle
brevissime esclamazioni originali: la stima usa anche un limite di 225 parole/min.
Il codice usa volume 1,0 e il raggio nativo di `ConPlay`,
invece del precedente guadagno 2,0. L'ascolto in gioco resta necessario per
valutare timbro, intelligibilita ed equilibrio con musica e ambiente.

Dal 05/10 tutti i WAV ricevono de-essing selettivo a 5,5 kHz, fino a 3 dB;
Simons via radio usa 5 kHz, fino a 6 dB, e minore enfasi a 3,2 kHz.
Il detector lavora dopo il pareggio del livello. Il corpo della voce rimane
fuori dalla banda attenuata. Il limiter e sempre attivo, senza guadagno
automatico, a 4 volte la frequenza di campionamento. Il WAV finale mono PCM
16 bit/22050 Hz viene misurato nuovamente: picchi di campione e true peak
devono rispettare il tetto di -2 dB. Le impostazioni sono in `mix_profile.json`;
una modifica invalida la cache del trattamento, conservando le take TTS grezze.

Per aggiornare i dialoghi dopo modifiche alla campagna:

```powershell
.\tools\voices\voices.ps1 refresh --apply
.\tools\voices\voices.ps1 build --install
```

`refresh` controlla i testi correnti, recupera le take compatibili, genera
soltanto quelle necessarie e verifica tutte le battute. `--process-only`
consente esclusivamente la rielaborazione locale. `--apply` aggiorna i WAV
sorgenti con backup; senza questa opzione il risultato rimane nella staging.
`build` compila su una copia privata dei sorgenti, esegue i controlli nativi
e verifica che altri lavori non abbiano cambiato sorgenti o pacchetti.
`--publish` aggiorna solo `dist`; `--install` aggiorna anche Revision a gioco
chiuso, con backup e controllo SHA256. L'SDK dell'editor aperto rimane separato.
Il test offline del de-esser e del limiter e `check_dynamics.py`.

La banda del de-esser usa l'[equalizzatore dinamico FFmpeg](https://ffmpeg.org/ffmpeg-filters.html#adynamicequalizer),
con un detector nella stessa banda; non e un passa-basso permanente.

```powershell
.\tools\voices\voices.ps1 natural plan
.\tools\voices\voices.ps1 natural generate
.\tools\voices\voices.ps1 natural generate --process-only
.\tools\voices\voices.ps1 natural apply
.\build.ps1
.\install-voices.ps1
```

`--only AnnaNavarre` o `--keys V7245097` limitano la generazione.
`--process-only` rielabora i file grezzi gia presenti senza chiamare ElevenLabs.
`natural calibrate` aggiorna i riferimenti e il piano dopo cambiamenti ai testi.
Poi `sync_route_dialogue.py` aggiunge le intenzioni delle scene e recupera solo
take compatibili per voce, testo, canale, prompt e impostazioni:

```powershell
.\tools\voices\voices.ps1 natural calibrate
python tools\voices\sync_route_dialogue.py
.\tools\voices\voices.ps1 natural generate
```

`apply` richiede il piano completo verificato e salva WAV/configurazione
precedenti in `backups`. Cache e ricevute sono in `natural_v4`; il rapporto
`natural_v4/report.md` riporta i tempi e i livelli di tutte le take.
Anche `make_voices.py generate` usa questa pipeline per i WAV mancanti quando
`voices.json` indica il piano V4 calibrato.

La procedura `direct` descritta piu sotto riguarda la precedente versione v3.
Le sue take e le anteprime V4 restano conservate per confronto e ripristino.

## Preparare i campioni originali

```powershell
.\tools\voices\voices.ps1 samples
```

Estrae i suoni direttamente da `DevInstall\System`, collegandoli al personaggio
tramite i dati delle conversazioni. Produce `samples\UC_<personaggio>.wav`, mono,
PCM 16 bit a 22050 Hz, e `samples\manifest.json` con battute, pacchetti sorgente e
tempi. Non mescola `UNATCOTroopB` con `UNATCOTroop`. I campioni contengono frasi
complete, senza silenzi iniziali/finali, e sono tutti sotto 10 MB.

## Creare e collegare i cloni

La chiave resta in `elevenlabs_key.txt` (ignorato da Git) oppure nella variabile
`ELEVENLABS_API_KEY`. Servono Text to Speech e Voices Write per clonare; Voices
Read serve anche per elencare le voci. Non inserire la chiave nei file condivisi.

```powershell
.\tools\voices\voices.ps1 clone --dry-run
.\tools\voices\voices.ps1 clone --only AnnaNavarre --rights-confirmed
```

Il caricamento richiede la conferma dell'operatore di avere diritti e consenso
alla clonazione. Gli ID gia' configurati sono preservati. Il raffinamento di JC
usa un nuovo IVC separato, creato con 89,6 secondi / 34 battute originali sobrie;
il precedente ID e' conservato in `jc_refined_clone.json`. I nuovi ID sono salvati in `voices.json` subito dopo
ogni successo. Le ricevute sono in `clone_receipts.json`; una voce che richiede
verifica resta disabilitata nella mod finche' la verifica non e' completata.
Non sono effettuati tentativi automatici dopo errori o timeout, per evitare
cloni duplicati. In caso di timeout verificare My Voices prima di riprovare.

## Generare le battute della mod

```powershell
.\tools\voices\voices.ps1 list
.\tools\voices\voices.ps1 generate --only AnnaNavarre --limit 1 --dry-run
.\tools\voices\voices.ps1 generate --only AnnaNavarre --limit 1
.\tools\voices\voices.ps1 generate
.\build.ps1
.\install-voices.ps1
```

`--dry-run` mostra richieste e caratteri senza chiamare ElevenLabs.
`--limit 1` genera una sola battuta. I WAV esistenti sono conservati: rilanciare
il comando genera solo quelli mancanti. I file completati restano utilizzabili
anche se una richiesta successiva fallisce. Gli InfoLink ricevono il filtro
radio quando il mittente e remoto; gli altri dialoghi sono calibrati. L'eco/pitch aggiuntivi per Gunther
e MIB sono rimossi quando viene collegato il loro clone originale.

La compilazione produce `dist\UnatcoVoices.u` e `dist\UnatcoContinues.u`.
Installare entrambi in `Revision\System` con il gioco chiuso. Il pacchetto voci
viene cercato dalla mod tramite il nome `V` seguito dall'hash di
`personaggio|canale|testo`: risposte identiche dette da persone diverse hanno
suoni distinti. Il pacchetto importa solo le battute ancora presenti nei
sorgenti; le vecchie take rimangono nelle cartelle locali per ripristino.
`install-voices.ps1` verifica che il gioco sia chiuso, salva i vecchi pacchetti
in `dist\backup` e verifica con SHA256 le copie installate.
Il driver aspetta la preparazione della telecamera, avvia l'animazione di parlato,
registra il suono nel lettore nativo per interromperlo quando si salta una battuta
e adegua alla durata dell'audio il timer dei dialoghi passivi (soldati/MIB).

Documentazione ElevenLabs:
[Instant Voice Cloning](https://elevenlabs.io/docs/eleven-creative/voices/voice-cloning/instant-voice-cloning),
[Create IVC voice](https://elevenlabs.io/docs/api-reference/voices/ivc/create).

## Risultato del 3 ottobre 2026

Creati sei Instant Voice Clones (Anna, Gunther, UNATCO, MIB, Alex, Paul) dai
campioni originali; il clone JC preesistente e' stato riutilizzato.
Generate tutte le 55 battute correnti: JC 14, Anna 7, Gunther 6, UNATCO 14,
MIB 5, Alex 6, Paul 3. Verificati tutti i WAV e i 55 Sound esportati dal pacchetto
compilato. Compilazione con 0 errori/0 avvisi. Entrambi i pacchetti installati e
verificati in Revision. La somiglianza e il comportamento in gioco vanno ancora
valutati ascoltando la scena; `voice_preview.wav` contiene Anna, Gunther, soldato
UNATCO e JC in questo ordine.

Corretto il silenzio nei dialoghi: in UE1 l'operatore `%` usa float, perdendo
precisione nel calcolo dei nomi audio. Il test eseguito nel motore rilevava
54 lookup falliti su 55. `UCVoice.Key` ora usa solo aritmetica intera e lo stesso
test carica tutti i 55 Sound con zero errori, senza rigenerare audio.
`UCVoiceCheckCommandlet.uc` viene preparato da `prepare_voice_check.py` con i
testi correnti e i nomi calcolati in Python. Dopo la compilazione si verifica con:

```powershell
Push-Location .\DevInstall\System
.\ucc.exe UnatcoContinues.UCVoiceCheckCommandlet
Pop-Location
```

Esito atteso: `UCVoiceCheck: 55 checked, 0 failed.`

## Raffinamento JC, pronuncia e continuita dei dialoghi

Rigenerate soltanto 18 battute: le 14 di JC e le quattro che pronunciano UNATCO.
Le altre 37 conservano esattamente il PCM della versione precedente. Il clone
JC riceve campioni coerenti, senza EQ, denoising o modifica dell'altezza.
L'uscita evita l'aumento di brillantezza e attenua lievemente gli alti sopra
3,5 kHz. L'accento in `I didn't AGREE` resta un'eccezione alla recitazione piatta.
Non si aggiunge una raucedine artificiale. Le misure acustiche comparative
sono in `natural_v4/jc_acoustic_refinement.json`; testi diversi e possibili
errori di ottava limitano la precisione del confronto.

Nel solo prompt audio, UNATCO usa `/juːˈnætkoʊ/` e il possessivo usa
`/juːˈnætkoʊz/`, secondo il supporto IPA di Eleven v4. I testi del gioco restano
invariati. [Documentazione prompting](https://elevenlabs.io/docs/overview/capabilities/text-to-speech/best-practices).

FEMA usa `/ˈfiːmə/` ("FIMA") nel solo prompt audio. La correzione riguarda
soltanto `V162037`, la battuta di Gunther con FEMA e UNATCO; le altre 54 take
restano identiche. Stato di compilazione/installazione e backup sono registrati
in `natural_v4/fema_correction.json`.

Il driver elimina copie duplicate dei gestori, azzera lo stato tra lettori e
riprova un avvio audio fallito. I nomi temporanei `UCBark` vengono ripristinati
dopo il collegamento degli attori, usando le conversazioni originali del PNG;
anche i nomi rimasti nei vecchi salvataggi vengono recuperati.

La scena finale aggiornata tiene JC fermo in una posa `Still` senza AI, animazioni
casuali o rotazioni. Gunther e' l'unico a camminare, entro un campo largo fisso
che copre tutto il percorso. Parte il tema UNATCO originale, sezione ambient 0,
durante i sette secondi della partenza. `UCCam` compensa lo spostamento nativo di
150 unita e aggiorna `ViewRotation`, evitando di usare la direzione precedente di JC.

Con UnrealEd aperto, `.\build.ps1 -Isolated` compila in una cartella nuova e
copia in `dist` soltanto dopo il successo. Il controllo nativo della camminata
usa una copia privata di Battery Park, senza modificare mappe installate:

```powershell
.\tools\check-walkoff.ps1 -BuildSystem .\DevInstall\Build-<id>\System
```

La geometria BSP e il PCM del pacchetto vengono controllati da
`check_refinement.py --previous-package <backup precedente di UnatcoVoices.u>`.
I log sono in `natural_v4/refinement-engine-*.log`. Queste prove non sostituiscono
l'ascolto e la valutazione visiva nel gioco.
Il log di Revision ora registra gli avvii delle voci e segnala i Sound mancanti.
Per ripetere una scena gia' consumata in un salvataggio, aprire il menu Home e
selezionare `4. Battery Park - Anna e Gunther` (oppure `ucpark` in console).
Riavviare Revision dopo l'installazione, per caricare il nuovo codice.

## Prima versione della direzione di recitazione (storico v3)

`delivery_plan.json` contiene i prompt effettivi, separati dal testo nel gioco.
`delivery_plan.md` rende leggibili la regia di tutte le 55 frasi e le battute
originali di riferimento (con posizione nei campioni). La direzione e' una
interpretazione dei testi originali e delle scene complete; l'ascolto resta il
riferimento per giudicare timbro e risultato della generazione.

Il piano usa Eleven v3 con tag vocali: JC e MIB hanno stabilita' robusta, come i
rapporti dei soldati; Anna, Gunther, Alex e Paul usano stabilita' naturale e
indicazioni contenute per rimproveri, minacce, ordini, preoccupazione e rassegnazione.
Nessun tag aggiunge risate, sospiri, musica o effetti. I dialoghi e i nomi Sound
sono identici agli originali della mod, cosi' resta valido il collegamento UE1.

```powershell
.\tools\voices\voices.ps1 direct plan
.\tools\voices\voices.ps1 direct generate --dry-run
.\tools\voices\voices.ps1 direct generate
.\tools\voices\voices.ps1 direct preview --keys V8633042 V1299363 V11261584
.\tools\voices\voices.ps1 direct apply
.\build.ps1
.\install-voices.ps1
```

Le nuove take sono preparate in `directed_v1` senza sostituire subito i WAV
funzionanti. I metadati registrano prompt, parametri, ID richiesta e SHA256;
le generazioni gia' completate sono riutilizzate soltanto se richiesta e file
corrispondono. `apply` richiede l'intero piano aggiornato e tutti i WAV validi,
poi conserva vecchi WAV e configurazione in `backups` prima della sostituzione.
Le generazioni future con `make_voices.py generate` usano lo stesso piano,
indicato da `_delivery_plan` in `voices.json`. Se cambiano le parole di una
battuta, aggiornare la sua regia prima di generare.

[Guida ufficiale ai tag vocali](https://elevenlabs.io/docs/overview/capabilities/text-to-speech/best-practices).

Prima revisione applicata e installata il 3 ottobre 2026: 55 take, 167.92 secondi
totali; controllo PCM, SHA256 e preservazione delle parole superato. Compilazione
con 0 errori/0 avvisi e test nativo `55 checked, 0 failed`. Le copie installate
sono verificate dallo script di installazione. Anteprima delle sei prime take
(Gunther, Anna, JC): `directed_v1/preview.wav`. La recitazione resta da valutare
all'ascolto in gioco; i backup permettono di ripristinare i WAV precedenti.

## Revisione precedente: Gunther e bozze Hong Kong (3 ottobre 2026)

Il piano corrente e `delivery_natural_v4.json`: 218 audio installati, di cui
124 nuovi rispetto alla precedente versione da 94. Include 62 battute di
Gunther e il clone originale di Gilbert Renton. Il controllo nativo carica
tutti i 218 Sound; i test delle identita passano anche per la guardia della
metro e gli Special Agents. Il resoconto e in `docs/VOICE_ROUTE_REVIEW.md`.

Le 116 battute esplicite di Hong Kong M1 sono preparate separatamente in
`delivery_hk_draft_v4.json`, con fonti e sequenza delle scene. La revisione
piu recente HK-7 nel piano M1 prevale sui punti 11–12 del vecchio design.
Sono disponibili Maggie, Max, Gordon, Tong e il messaggero Red_Arrow_01.
I WAV sono in `natural_v4`; non sono importati nel pacchetto finche la stessa
voce/canale/battuta non compare nel codice. Il rapporto e in
`docs/HK_VOICES_DRAFT.md`; anteprime `*_hk_preview.wav`.

Quando il codice aggiunge nuove battute, `natural_voices.py calibrate`,
`sync_route_dialogue.py` e `natural_voices.py generate` riusano le take solo
se clone, testo pronunciato, parametri e hash corrispondono. La regia mantiene
JC deadpan; Gunther usa tag brevi e controllati. Le pause dei codici e la
variabilita osservata negli originali evitano di accelerare le risposte corte.
`apply` aggiorna i WAV sorgente dopo la verifica; poi preparare il commandlet,
compilare e verificare prima dell'installazione.

Per aggiornare le sole bozze dai documenti, usare
`prepare_hk_drafts.py prepare` e `prepare_hk_drafts.py generate`.
Il testo della prosa narrativa non viene convertito in battute inventate.

## Stato corrente: Hong Kong collegata (3 ottobre 2026)

Il codice comprende ora 305 audio: aggiunte 87 battute in UCHKStory e
UCSceneSimonsSword, con Maggie, Max, Gordon, messaggero, agenti e Simons.
59 delle aggiunte riusano take compatibili delle bozze; 28 sono nuove.
Il PCM dei 218 audio precedenti resta identico. Il report corrente e
`docs/VOICE_ROUTE_REVIEW.md`; il piano runtime e `delivery_natural_v4.json`.

Il codice 1997 viene letto come cifre separate nel solo prompt, con pause
calibrate. M06WaltonHolo mantiene le chiavi direct delle conversazioni native,
ma entrambe le voci della registrazione hanno un filtro elettronico e livelli
derivati dalle registrazioni remote originali di Simons. La chiamata sulla
spada usa le chiavi radio di InfoLink. JC resta sempre locale e deadpan.

La cache conserva separatamente MP3 grezzi e WAV elaborati. Un MP3 puo essere
riusato fra canali solo se voce, testo del prompt, parametri, seed e hash del
file provano la stessa richiesta API; il nuovo canale richiede elaborazione
locale. Le ricevute correnti hanno precedenza sui vecchi nomi/hash, per evitare
di invalidare registrazioni gia verificate durante la sincronizzazione.
