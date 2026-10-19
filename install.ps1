# Installa la mod nel gioco: codice (UnatcoContinues.u), voci (UnatcoVoices.u) e le
# mappe modificate (-> Revision\UnatcoMaps\). Il gioco deve essere chiuso.
# Le mappe: il repository non contiene le mappe di Revision (sono loro), solo le nostre differenze
# (maps\patches\*.ucpatch, tools\mappatch.py): qui vengono applicate alla copia di Revision\Maps di chi
# installa (tools\Expand-MapPatch.ps1). Chi sviluppa ha anche le mappe intere in maps\ (fuori da git):
# quelle vanno installate cosi' come sono.
# Il pacchetto viene da dist\ (l'ultima compilazione); se non hai compilato niente, da
# release\ (la versione pronta pubblicata nel repository: per chi vuole solo giocare).
# La prima volta aggiunge a Revision.ini la riga che fa leggere UnatcoMaps per prima
# (backup: Revision.ini.bak_maps).
#   -Game  the Deus Ex folder (an installer passes it; default: config.ps1)
param([string]$Game = '')
if ($Game) { $env:UC_GAME_ROOT = $Game }
. "$PSScriptRoot\config.ps1"
if (Get-Process Revision -ErrorAction SilentlyContinue) { throw "Close Revision before installing." }
if (Get-Process UnrealEd -ErrorAction SilentlyContinue) { "Warning: UnrealEd is open, make sure you saved the map." }

$sys = Join-Path $RevSrc 'System'
if (-not (Test-Path $sys)) { throw "Revision not found in $RevSrc (change the paths in config.ps1)" }
# UCAnims.u: the characters' models with the animations made in the map editor's Animation Studio
# UCModels.u: the 3D models imported in the map editor (Models > Import)
# UCSounds.u: the sounds imported in the map editor (browser > Import)
foreach ($p in 'UnatcoContinues', 'UnatcoVoices', 'UCAnims', 'UCModels', 'UCSounds', 'UCScripts') {   # UCScripts: the editor's Tools > Scripts
  $f = Join-Path $Root "dist\$p.u"
  if (-not (Test-Path $f)) { $f = Join-Path $Root "release\$p.u" }
  if (Test-Path $f) { Copy-Item $f $sys -Force; "installed $p.u (from $(Split-Path (Split-Path $f) -Leaf)\)" }
  # the map editor (DeusEdix) installs the packages in UnatcoMaps, which Revision.ini reads before System:
  # a copy there would hide the one just installed (18 Oct 2026: the game kept playing the old code)
  $shadow = Join-Path $RevSrc "UnatcoMaps\$p.u"
  if ((Test-Path $f) -and (Test-Path $shadow)) { Copy-Item $f $shadow -Force; "installed $p.u in UnatcoMaps too (read first)" }
}
if (-not (Test-Path (Join-Path $sys 'UnatcoContinues.u'))) { throw "UnatcoContinues.u found neither in dist\ nor in release\" }

$dest = Join-Path $RevSrc 'UnatcoMaps'
New-Item -ItemType Directory -Force $dest | Out-Null
Get-ChildItem (Join-Path $Root 'maps') -Filter *.dx -ErrorAction SilentlyContinue | ForEach-Object {
  Copy-Item $_.FullName $dest -Force; "installed map $($_.Name)"
}
. "$PSScriptRoot\tools\Expand-MapPatch.ps1"
Get-ChildItem (Join-Path $Root 'maps\patches') -Filter *.ucpatch -ErrorAction SilentlyContinue | ForEach-Object {
  if (Test-Path (Join-Path $Root "maps\$($_.BaseName).dx")) { return }      # the whole map is here: installed above
  if (Expand-MapPatch $_.FullName (Join-Path $RevSrc 'Maps') (Join-Path $dest "$($_.BaseName).dx")) {
    "installed map $($_.BaseName).dx (made from your Revision\Maps)"
  }
}

# Revision.ini: le mappe della mod vanno cercate PRIMA di quelle di Revision. Le liste
# sono due: [Core.System] (editor, ucc) e [RevisionInternal.LaunchSystem], quella che
# usa davvero il gioco avviato da Revision.exe (senza, il gioco carica le mappe originali).
$ini = Join-Path $sys 'Revision.ini'
$text = Get-Content $ini -Raw
$changed = $false
foreach ($section in 'Core.System', 'RevisionInternal.LaunchSystem') {
  $m = [regex]::Match($text, '\[' + [regex]::Escape($section) + '\][^\[]*')
  if (-not $m.Success -or $m.Value -match 'Paths=\.\.\\UnatcoMaps\\\*\.dx') { continue }
  $fixed = ([regex]'(\r?\n)(Paths=)').Replace($m.Value, "`$1Paths=..\UnatcoMaps\*.dx`$1`$2", 1)   # solo la prima riga Paths=
  if ($fixed -eq $m.Value) { continue }
  $text = $text.Substring(0, $m.Index) + $fixed + $text.Substring($m.Index + $m.Length)
  $changed = $true
  "Revision.ini [$section]: added the UnatcoMaps folder (before the Revision maps)"
}
if ($changed) {
  Copy-Item $ini "$ini.bak_maps2" -Force
  Set-Content $ini $text -NoNewline -Encoding Default
}
# comando 'unatco' / 'unatcostart' e tasto Home (solo se liberi): servono per avviare la mod in gioco
& "$PSScriptRoot\tools\tour-keys.ps1" -MenuOnly
"Done."
