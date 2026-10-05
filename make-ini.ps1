# Genera DeusEx.ini / Default.ini in DevInstall\System con la lista EditPackages giusta.
#   -Mode editor : tutti i pacchetti Revision esistenti (per UnrealEd)
#   -Mode make   : come editor, piu' la mod anche se non ancora compilata (per "ucc editor.make")
param([ValidateSet('editor','make')][string]$Mode = 'editor')
. "$PSScriptRoot\config.ps1"
$orig = Get-Content "$DevSystem\Revision.ini"
$all  = $orig | Where-Object { $_ -match '^EditPackages=' } | ForEach-Object { $_.Substring(13).Trim() }
if ($true) { $pk = $all | Where-Object { $_ -ne $ModName -and (Test-Path "$DevSystem\$_.u") } }
# pacchetto audio delle voci (ElevenLabs), compilato prima della mod
# (facoltativo: senza i sorgenti delle voci, o con UC_NO_VOICES=1, il pacchetto non si compila)
$pk = @($pk | Where-Object { $_ -ne 'UnatcoVoices' })
if ((Test-Path "$Root\src\UnatcoVoices\Classes\UnatcoVoices.uc") -and -not $env:UC_NO_VOICES) { $pk += 'UnatcoVoices' }
if ($Mode -eq 'make' -or (Test-Path "$DevSystem\$ModName.u")) { $pk += $ModName }
$out = New-Object System.Collections.Generic.List[string]
foreach ($l in $orig) {
  if ($l -match '^EditPackages=') { continue }
  $out.Add($l)
  if ($l -match '^\[Editor\.EditorEngine\]') { foreach ($x in $pk) { $out.Add("EditPackages=$x") } }
}
# percorso per asset di terze parti (Ambient/MoverSFX dal demo del Community Update)
$out2 = New-Object System.Collections.Generic.List[string]
$mapsFirst = $false
foreach ($l in $out) {
  # le mappe modificate della mod (cartella maps\ del progetto) vengono cercate per prime
  if (-not $mapsFirst -and $l -like 'Paths=*') {
    $out2.Add("Paths=$Root\maps\*.dx")
    # Revision's Music junction contains OGG files; original tracker themes
    # live in the base game's Music directory, including UNATCO_Music.umx.
    $out2.Add("Paths=$GameRoot\Music\*.umx")
    $mapsFirst = $true
  }
  $out2.Add($l)
}   # (ExtraAssets del demo non serve piu': ora c'e' il gioco base installato)
$out = $out2
# NB: WinDrv.WindowsClient al posto di WinDrvLite fa chiudere l'editor all'avvio (prova del
# 4 ott 2026): il gestore delle finestre resta quello di Revision.
foreach ($f in 'DeusEx.ini','Default.ini') { $out = $out | Where-Object { $_ -notmatch '^Suppress=(DevLoad|DevPath|DevCompile)' }
  Set-Content "$DevSystem\$f" $out -Encoding Default }
"ini ($Mode): " + ($pk -join ',')
