# Crea DevInstall: copia di lavoro di Revision + Deus Ex SDK. L'installazione Steam non viene modificata.
# Uso:  .\setup.ps1 -SdkExe .\tools\DeusExSDK1112f.exe
param([string]$SdkExe = (Join-Path $PSScriptRoot 'tools\DeusExSDK1112f.exe'))
. "$PSScriptRoot\config.ps1"
$ErrorActionPreference = 'Stop'

if (-not (Test-Path "$RevSrc\System\Revision.exe")) { throw "Revision non trovato in $RevSrc" }
if (-not (Test-Path $SdkExe)) { throw "SDK mancante: $SdkExe (vedi README, passo 1)" }

# 1) System: copia reale (UCC/UnrealEd scrivono qui, mai nella cartella Steam)
New-Item -ItemType Directory -Force $DevSystem | Out-Null
robocopy "$RevSrc\System" $DevSystem /E /XF *.log /NFL /NDL /NJH /NJS | Out-Null

# 2) Estrai l'SDK con 7-Zip (senza eseguire l'installer) e copia SOLO gli strumenti.
#    NON copiare Core.dll/Window.dll dell'SDK: sono vecchi e romperebbero Revision.
$tmp = Join-Path $Root 'tools\sdk_extract'
$7z  = Join-Path $env:ProgramFiles '7-Zip' | Join-Path -ChildPath '7z.exe'
if (-not (Test-Path "$tmp\ReleaseSDK1112f")) { & $7z x -y "-o$tmp" $SdkExe | Out-Null }
foreach ($f in 'UCC.exe','UnrealEd.exe','UnrealEd.int','Core.u') { Copy-Item "$tmp\ReleaseSDK1112f\System\$f" $DevSystem -Force; "SDK -> $f" }
# Editor.dll non e' nell'SDK ne' in Revision\System: lo prendiamo dalla cartella TNM2 di Revision
Copy-Item "$RevSrc\TNM2\Editor.dll" $DevSystem -Force; "Revision\TNM2 -> Editor.dll"

# 2b) UnrealEd (Visual Basic 5) vuole MSVBVM50.DLL: la estraiamo dal runtime Microsoft in tools\ (accanto all'exe, nessuna modifica di sistema)
if (Test-Path "$Root\tools\msvbvm50.exe") { & 'C:\Program Files\7-Zip\7z.exe' e -y "-o$DevSystem" "$Root\tools\msvbvm50.exe" MSVBVM50.DLL | Out-Null }

# 3) Ini di sviluppo: Paths assoluti verso la cartella Steam (sola lettura), save locali
$ini = Get-Content "$RevSrc\System\Revision.ini" -Raw
# Asset in sola lettura: junction verso Steam, cosi' i Paths relativi originali di Revision funzionano.
# (Maps NON e' una junction: le mappe nuove/modificate si salvano in DevInstall\Maps; le originali restano leggibili via percorso assoluto.)
foreach ($n in 'Sounds','Textures','NewVision','HDTP','Music') {
  if (-not (Test-Path "$Dev\$n")) { New-Item -ItemType Junction -Path "$Dev\$n" -Target "$RevSrc\$n" | Out-Null }
}
$ini = ($ini -split "`r?`n" | ForEach-Object {
  if ($_ -like 'Paths=..\Maps\*')   { $_; "Paths=$RevSrc\Maps\*.dx" }
  elseif ($_ -like 'Paths=..\..\Music\*') { 'Paths=..\Music\*.umx' }
  elseif ($_ -like 'Paths=..\..\*') { "Paths=$GameRoot\" + $_.Substring(12) }   # gioco base (Deus Ex GOTY) accanto a Revision
  else { $_ }
}) -join "`r`n"
$ini = $ini -replace '(?m)^SavePath=.*', 'SavePath=..\Save'
# mod: package compilabile + caricato dal gioco
if ($ini -notmatch "EditPackages=$ModName") { $ini = $ini -replace '(?m)^(EditPackages=DeusEx)\r?$', "`$1`r`nEditPackages=$ModName" }
Set-Content "$DevSystem\Revision.ini" $ini -Encoding Default
Copy-Item "$DevSystem\Revision.ini" "$DevSystem\DeusEx.ini" -Force   # UnrealEd cerca DeusEx.ini
Copy-Item "$DevSystem\RevisionUser.ini" "$DevSystem\User.ini" -Force
Copy-Item "$DevSystem\RevisionDefault.ini" "$DevSystem\Default.ini" -Force
Copy-Item "$DevSystem\RevisionDefUser.ini" "$DevSystem\DefUser.ini" -Force   # UCC/UnrealEd cercano questi nomi
New-Item -ItemType Directory -Force "$Dev\Save","$Dev\Maps" | Out-Null
# Pacchetti retail che l'editor richiede e che Revision non include: dal gioco base installato (Deus Ex GOTY)
foreach ($n in 'Editor','Fire','UBrowser','UWindow','MPCharacters','IpServer','Core') {
  if (Test-Path "$GameRoot\System\$n.u") { Copy-Item "$GameRoot\System\$n.u" $DevSystem -Force }
}
# ripiego: Community Update (tools\DXCU.exe) se il gioco base non e' installato
if (-not (Test-Path "$GameRoot\System\Editor.u") -and (Test-Path "$Root\tools\DXCU.exe")) {
  $names = 'Editor','Fire','UBrowser','UWindow','MPCharacters','IpServer' | ForEach-Object { "System\1112fm DeusEx\$_.u" }
  & 'C:\Program Files\7-Zip\7z.exe' e -y "-o$DevSystem" "$Root\tools\DXCU.exe" @names | Out-Null
}

# 4) Sorgente mod: collegamento alla cartella src (modifichi in src\, UCC compila da DevInstall)
$link = Join-Path $Dev $ModName
if (-not (Test-Path $link)) { New-Item -ItemType Junction -Path $link -Target $ModSrc | Out-Null }
"Fatto. Prossimo passo: README, passo 3 (Export All dei sorgenti Revision)."
