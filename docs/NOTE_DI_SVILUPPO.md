# Note di sviluppo (in italiano)

*Il vecchio README di lavoro: stato, comandi e tutto quello che e' servito per mettere in piedi l'ambiente. Il README del repository e' `README.md` nella cartella principale.*

Mod che aggiunge una biforcazione UNATCO alla Mission 04 e continua la storia (design: `docs\ROUTE_DESIGN.md`).
Gioco: `C:\Program Files (x86)\Steam\steamapps\common\Deus Ex\Revision`; sviluppo su `DevInstall`, con installazione dei soli pacchetti della mod.

## Struttura
| Percorso | Cosa |
|---|---|
| `src\UnatcoContinues\Classes\*.uc` | codice UnrealScript della mod (package `UnatcoContinues.u`) |
| `DevInstall\<Pacchetto>\Classes\*.uc` | sorgenti di Revision esportati (DeusEx, Revision, RevisionMission, ...) — sola consultazione |
| `maps\` | mappe `.dx` nuove/modificate (salvale anche in `DevInstall\Maps`) |
| `docs\ROUTE_DESIGN.md`, `docs\STORY.md` | design della route e trama |
| `setup.ps1` | crea `DevInstall` (copia System, junction asset, SDK, pacchetti retail, ini) |
| `make-ini.ps1` | genera le ini (`editor` per UnrealEd, `make` per ucc) |
| `build.ps1` | `ucc editor.make` -> `dist\UnatcoContinues.u` |
| `editor.ps1` / `run.ps1` | UnrealEd / Revision dalla copia di sviluppo |
| `config.ps1` | percorsi |
| `tools\` | SDK 1112f, runtime VB5, UnrealEd 2.2, DXCU (sorgente dei pacchetti retail mancanti) |

## Uso quotidiano
1. Modifica `src\UnatcoContinues\Classes\*.uc`.
2. `.\build.ps1` (deve finire con `0 error(s)`; il risultato e' in `dist\`). Con UnrealEd aperto usare `.\build.ps1 -Isolated`.
3. Mappe: `.\make-ini.ps1 editor` poi `.\editor.ps1` (UnrealEd ci mette ~40 s ad aprirsi).
4. Per leggere la logica vanilla: `DevInstall\RevisionMission\Classes\RevisionMission04.uc` (flag `NSFSignalSent`, `TalkedToPaulAfterMessage_Played`, ...).

## Stato (2 ott 2026)
**Funziona**
- `DevInstall` completa; UnrealEd (SDK) si apre con tutti i pacchetti Revision.
- Sorgenti Revision esportati con *Export All* (DeusEx 1226 file, Revision 344, RevisionMission 18, ...).
- `build.ps1` compila `UnatcoContinues.u` con 0 errori. `ucc editor.make` ricompila solo i `.u` mancanti, quindi i pacchetti Revision restano intatti.

**Non ancora risolto**
- `Revision.exe` copiato in `DevInstall\System` esce subito (codice 53, nessun log), anche con `steam_appid.txt`. Per provare la mod in gioco:
  copiare `dist\UnatcoContinues.u` in `...\Revision\System` (aggiunge un file) e avviare da Steam.
- Le mappe `.dx` non sono ancora state aperte in UnrealEd. Ambient/MoverSFX/InfoPortraits vengono dal demo (non retail): ok per l'editor, non per il gioco.

## Cosa e' stato necessario (per rifare il setup)
- SDK `DeusExSDK1112f.exe` (dxgalaxy.org) + `Editor.dll` da `Revision\TNM2` (NON copiare Core.dll/Window.dll dell'SDK).
- Runtime VB5 `msvbvm50.exe` (Microsoft) e OCX VB dall'SDK (`ConvEdit.cab`) registrati una volta come amministratore (`regsvr32`, UAC).
- `Editor.u`, `Fire.u`, `UWindow.u`, `UBrowser.u`, `MPCharacters.u`, `IpServer.u` retail da `tools\DXCU.exe` (cartella `System\1112fm DeusEx`).
- UCC/UnrealEd cercano `Default.ini`, `User.ini`, `DefUser.ini`, `DeusEx.ini` (copie delle Revision*.ini).
- `ucc batchexport` non funziona: per esportare i sorgenti usare UnrealEd, tendina *Browse* -> *Classes* -> *Export All*.

Fonti: [setup Revision+UnrealEd](https://steamcommunity.com/app/397550/discussions/0/1777136225041010849/),
[compilare DeusEx.u di Revision](https://steamcommunity.com/app/397550/discussions/0/492378806380571951/),
[SDK](https://dev.dxgalaxy.org/guides/installing/).

## Mod: architettura e comandi (3 ott 2026)
- `UCMod` = direttore (parte da solo a ogni mappa: riga `ServerActors=UnatcoContinues.UCMod` in `Revision.ini`, backup `Revision.ini.bak_unatco`).
  Controlla i flag, attiva la route, blocca il raid vanilla, tiene amici i soldati UNATCO, lancia le scene.
- Flusso attuale (3 ott 2026, sera): dopo M04PlayerLikesUNATCO Paul resta seduto al 'Ton (battute UC_PaulAfter1-4), goal
  `MeetJockBatteryPark`; Hell's Kitchen con 4 pattuglie amiche (una riconosce JC), porte INF, uscite verso altre mappe chiuse,
  metro aperta, niente posti di blocco; Battery Park: niente Anna ne' Gunther (dal 4 ott sera Anna e' alla grata della metro di Hell's Kitchen: `docs\DIALOGHI_STILE.md`),
  Jock nell'elicottero (`UC_JockBP` con scelta pronto/un minuto) -> `UCSceneTakeoff` (percorso vanilla HelicopterFlysOff)
  -> `06_HongKong_Helibase` resa amica (niente allarme/assalto, porte blindate aperte) -> `UC_JockHK` -> `UCSceneHongKong`
  (Jock riparte, titolo, goal `FindTracerTong` + secondario `PaulLuminousPath`). All'eliporto tutte le porte INF tranne
  l'ascensore; MJ12 aggiunti dalla mod: ufficiale `UCHKOfficer` (va incontro a JC, lo manda all'ascensore) e guardia `UCHKGuard`
  nell'atrio dell'ascensore (dialogo facoltativo su Tong). Ricerca sull'arrivo vanilla: `docs\HK_ARRIVAL_RESEARCH.md`.
  Le vecchie scene (Prologue, PaulEscape, HotelRaid, DbgIsland) sono in `src\UnatcoContinues\obsolete\` (non compilate).
- Gunther al 'Ton (3 ott 2026, sera): uscendo dalla porta JC trova Gunther + 2 MIB presentati come "Special Agent"
  (`UCSceneGuntherTon`, dialogo in due parti); Paul sparisce appena JC esce dall'hotel (irreversibile, `PaulEscapedTon`).
  Facoltativo: se JC rientra, Gunther attraversa l'hotel (Gilbert, camera vuota con sangue/medkit, domande, momento
  privato, radio: `UCSceneGuntherSearch`). Dalla finestra si evita la scena (`GuntherTonSkipped`). Attaccare Gunther o gli
  agenti = `JCBrokeWithUNATCO` (route lealista interrotta). Goal "Meet Jock" dopo Gunther (o se lo si evita).
- Segnale NSF: niente menu; "Broadcast Message" lo invia, chi non lo invia torna da Paul (come nel gioco originale).
- Grata della metro: gia' aperta per il personale UNATCO; la sorveglia Anna Navarre (un soldato se Anna e' morta).
- Mappe gia' visitate: `UCMutator` (salvato nella mappa) ricrea UCMod quando la mappa viene ricaricata dal salvataggio.
- Verifica senza gioco delle mappe di Hong Kong: `.uild.ps1 -Isolated` poi `.	ools\check-hongkong.ps1 -BuildSystem <cartella System stampata>` (UCHKCheck su copie private delle mappe). Checklist di prova in gioco: `docs\PLAYTEST_HK.md`.
- Controllo nel motore: `ucc.exe UnatcoContinues.UCRouteCheckCommandlet` (conversazione di Jock: scelta, etichette, flag del decollo; porte di Battery Park).
- Nota: `Actor.ConListItems` e' transient: le conversazioni aggiunte vanno riattaccate a ogni caricamento (UCMod lo fa, con controllo per nome).
- `UCCon` = conversazioni native costruite da codice; `UCCam` = telecamera da cutscene. Lettore offline dei dati di gioco: `tools\ue1pkg.py`.
- Regola: nessun puntatore a Player/flags/finestre in variabili membro (crash al cambio mappa).
- Debug (console, `summon UnatcoContinues.<nome>`): `UCDbgNSF`, `UCDbgHotel`, `UCDbgStreet`, `UCDbgPark`, `UCDbgHongKong`, `UCDbgStatus`, `UCDbgReset`,
  `UCDbgTags` (scrive nel log cosa fanno i tag vanilla).
- Menu di debug in gioco: tasto **Home** (o `uc` in console). Comandi brevi: `ucnsf`, `uchotel`, `ucpark`, `uchk`, `ucstatus`, `ucreset`
  (`uchk` sostituisce `ucisland`; backup `RevisionUser.ini.bak_hk`).
  Sono alias in `RevisionUser.ini` ([Engine.Input], Aliases[18..24] + `Home=uc`; backup `RevisionUser.ini.bak_unatco`).

## Modifiche a Revision (non alla storia) - 3 ott 2026
- `Revision.ini` (backup `Revision.ini.bak_display`): `StartupFullscreen=False` (WinDrv e WinDrvLite) e `OneXBlending=False` (D3D9 e OpenGL) per un'illuminazione piu' chiara.
- La mod salva da sola finestra/schermo intero (`UCMod.RememberWindowMode`): il pulsante del menu non lo salvava.
- In finestra la luminosita' del menu (gamma hardware) non ha effetto: e' un limite di Windows/renderer, funziona solo a schermo intero.

## Modificare le mappe con UnrealEd (3 ott 2026)
- Doppio clic su `Apri UnrealEd - Hotel.bat` (o `Apri UnrealEd - Strade.bat`), oppure `.\edit-map.ps1 <NomeMappa>`:
  copia la mappa originale in `maps\` (la prima volta), prepara le ini e apre UnrealEd.
- In UnrealEd: Ctrl+O = apri (`maps\<mappa>.dx`), Ctrl+L = salva. Le viste sono finestre separate: se coprono i menu,
  clicca sulla barra del titolo di UnrealEd.
- Poi `Installa nel gioco.bat` (o `.\install.ps1`, gioco chiuso): copia mod, voci e `maps\*.dx` in `Revision\UnatcoMaps\`,
  che il gioco legge prima delle mappe di Revision (riga `Paths=..\UnatcoMaps\*.dx` in Revision.ini, backup `.bak_maps`).
- Attenzione: una mappa gia' visitata nella partita in corso viene ricaricata dal salvataggio, non dal file nuovo.

## Muri e macerie solo nella variante UNATCO (4 ott 2026)
- Mover con Tag `UCWall...`: invisibili nel gioco normale, muri solidi sulla route UNATCO. Oggetti con Tag
  `UCVanilla...`: spariscono sulla route UNATCO. Guida passo passo: `docs\MURI_SOLO_UNATCO.md`.
- Eliporto: scintille e fumo sopra la porta blindata tolti da script (solo route UNATCO).
- `Apri UnrealEd - Eliporto.bat` apre la copia dell'eliporto (`maps_HongKong_Helibase.dx`).
- UnrealEd 2.2 (versione del 18 maggio 2025, in `UED22Dev\`) non apre le mappe di Revision (motore UT 469);
  per Revision si usa l'UnrealEd dell'SDK.

## Editor: viste ferme risolte (4 ott 2026)
- Con il gestore mouse di Revision (`WinDrvLite.dll`, raw input) le viste di UnrealEd dell'SDK non rispondevano
  (clic e trascinamenti ignorati); `WinDrv` standard fa chiudere l'editor. `tools\patch-windrvlite.ps1` rattoppa 8
  byte SOLO nella copia `DevInstall\System\WinDrvLite.dll` (originale in `.orig`, `-Undo` per tornare indietro): le
  viste passano al gestore standard di WinDrv. Lo applicano da soli `edit-map.ps1` / `editor.ps1` / i `.bat`.
- Comandi nella vista 3D: sinistro trascinando = avanti/indietro e gira; destro = guarda intorno; entrambi = su/giu'
  e di lato. Viste 2D: sinistro trascinando = sposta.
- WASD: l'editor del 2000 non lo prevede; `tools\UnrealEd-WASD.ahk` (AutoHotkey 1.1, parte da solo con i `.bat`)
  simula i trascinamenti: vista 3D W/S avanti/indietro, A/D di lato, E/Q su/giu', W+A/W+D avanti girando; viste 2D
  W/A/S/D spostano. Shift = piu' veloce, F8 = on/off. Agisce solo con il puntatore sopra una vista e non mentre si
  scrive in una casella; si chiude con l'editor.
- Eliporto: porta blindata "riparata" solo nella variante UNATCO (coperture `UCWall`, macerie `UCVanilla`, scritta
  ELEVATORS). Dettagli e comandi dell'editor in `docs\MURI_SOLO_UNATCO.md`.
- `tools\patch-windrvlite.ps1` ha 2 rattoppi: viste che rispondono al mouse e LIGHT APPLY senza crash
  ("Assertion failed: !IsTemporary").
