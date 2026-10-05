# Apre una mappa della mod in UnrealEd (SDK Deus Ex, configurato per Revision).
#   .\edit-map.ps1 04_NYC_Hotel
# La prima volta copia la mappa originale di Revision in maps\ : si modifica SEMPRE la
# copia in maps\, mai l'originale. Salvando in UnrealEd (Ctrl+S / File > Save) resta in maps\.
# Poi .\install.ps1 la mette nel gioco (cartella Revision\UnatcoMaps, che il gioco legge per prima).
param([string]$MapName = '04_NYC_Hotel')
. "$PSScriptRoot\config.ps1"

$mapsDir = Join-Path $Root 'maps'
New-Item -ItemType Directory -Force $mapsDir | Out-Null
$mine = Join-Path $mapsDir "$MapName.dx"
if (-not (Test-Path $mine)) {
  $orig = Join-Path $RevSrc "Maps\$MapName.dx"
  if (-not (Test-Path $orig)) { throw "Mappa non trovata: $orig" }
  Copy-Item $orig $mine
  "Copiata la mappa originale in maps\$MapName.dx"
}

# ini dell'editor: tutti i pacchetti di Revision + la cartella maps\ cercata per prima
& "$PSScriptRoot\make-ini.ps1" editor | Out-Null
# viste che rispondono al mouse (rattoppo di WinDrvLite.dll solo nella copia di sviluppo)
& "$PSScriptRoot\tools\patch-windrvlite.ps1"
# movimento con WASD nelle viste (AutoHotkey, se installato; si chiude con l'editor)
$ahk = "C:\Program Files\AutoHotkey\AutoHotkey.exe"
if (Test-Path $ahk) { Start-Process $ahk -ArgumentList "`"$PSScriptRoot\tools\UnrealEd-WASD.ahk`"" }

if (Get-Process UnrealEd -ErrorAction SilentlyContinue) { "UnrealEd e' gia' aperto." }
else { Start-Process "$DevSystem\UnrealEd.exe" -WorkingDirectory $DevSystem }

@"

UnrealEd si sta aprendo (ci mette ~40 secondi).
 1. Prima di aprire la mappa: tasto destro sul titolo della vista 3D -> Wireframe (evita crash).
 2. File > Open... -> $mine
 3. Sposta gli oggetti: clic per selezionare, trascina con il tasto sinistro/destro nelle viste 2D.
    Proprieta' di un oggetto: doppio clic (o tasto destro > Properties).
 4. Se hai spostato solo oggetti (PNG, decorazioni, luci...) NON serve ricostruire la mappa.
    Se hai cambiato la geometria (brush): Build > Rebuild All.
 5. Salva con File > Save (resta in maps\), chiudi UnrealEd e lancia: .\install.ps1
"@
