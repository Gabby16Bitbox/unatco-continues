# Installa la mod nel gioco: codice (UnatcoContinues.u), voci (UnatcoVoices.u) e le
# mappe modificate (maps\*.dx -> Revision\UnatcoMaps\). Il gioco deve essere chiuso.
# La prima volta aggiunge a Revision.ini la riga che fa leggere UnatcoMaps per prima
# (backup: Revision.ini.bak_maps).
. "$PSScriptRoot\config.ps1"
if (Get-Process Revision -ErrorAction SilentlyContinue) { throw "Chiudi Revision prima di installare." }
if (Get-Process UnrealEd -ErrorAction SilentlyContinue) { "Attenzione: UnrealEd e' aperto, ricordati di aver salvato la mappa." }

$sys = Join-Path $RevSrc 'System'
foreach ($p in 'UnatcoContinues', 'UnatcoVoices') {
  $f = Join-Path $Root "dist\$p.u"
  if (Test-Path $f) { Copy-Item $f $sys -Force; "installato $p.u" }
}

$dest = Join-Path $RevSrc 'UnatcoMaps'
New-Item -ItemType Directory -Force $dest | Out-Null
Get-ChildItem (Join-Path $Root 'maps') -Filter *.dx -ErrorAction SilentlyContinue | ForEach-Object {
  Copy-Item $_.FullName $dest -Force; "installata mappa $($_.Name)"
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
  "Revision.ini [$section]: aggiunta la cartella UnatcoMaps (prima delle mappe di Revision)"
}
if ($changed) {
  Copy-Item $ini "$ini.bak_maps2" -Force
  Set-Content $ini $text -NoNewline -Encoding Default
}
"Fatto."
