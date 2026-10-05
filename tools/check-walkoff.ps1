# Headless regression run in a fresh isolated build; never changes installed maps.
param([Parameter(Mandatory=$true)][string]$BuildSystem)
. "$PSScriptRoot\..\config.ps1"
$ErrorActionPreference = 'Stop'
$CheckSystem = (Resolve-Path -LiteralPath $BuildSystem).Path
$CheckAllowed = [IO.Path]::GetFullPath((Join-Path $Dev 'Build-'))
if (-not $CheckSystem.StartsWith($CheckAllowed, [StringComparison]::OrdinalIgnoreCase) -or
    (Split-Path -Leaf $CheckSystem) -ne 'System') { throw 'Serve la cartella System di una compilazione -Isolated.' }
$CheckRoot = Split-Path -Parent $CheckSystem
$CheckMaps = Join-Path $CheckRoot 'TestMaps'
New-Item -ItemType Directory -Path $CheckMaps -Force | Out-Null
if ((Get-Item -LiteralPath $CheckMaps).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw 'TestMaps deve essere una cartella privata, senza collegamenti alle mappe del gioco.'
}
Copy-Item -LiteralPath (Join-Path $RevSrc 'Maps\04_NYC_BatteryPark.dx') -Destination (Join-Path $CheckMaps 'DX.dx') -Force
$CheckIni = Get-Content -LiteralPath (Join-Path $DevSystem 'DeusEx.ini')
$CheckIni = $CheckIni | Where-Object { $_ -notmatch '^ServerActors=' }
$CheckIni = $CheckIni | ForEach-Object {
    if ($_ -eq '[Core.System]') { $_; "Paths=$CheckMaps\*.dx" }
    elseif ($_ -eq '[DeusEx.DeusExGameEngine]') { $_; 'ServerActors=UnatcoContinues.UCWalkOffCheck' }
    elseif ($_ -match '^DefaultServerGame=') { 'DefaultServerGame=Revision.RevGameInfo' }
    else { $_ }
}
foreach ($CheckIniName in @('DeusEx.ini','Default.ini','Revision.ini','ucc.ini')) {
    Set-Content -LiteralPath (Join-Path $CheckSystem $CheckIniName) -Value $CheckIni -Encoding Default
}
Push-Location $CheckSystem
try {
    & .\ucc.exe 'Engine.ServerCommandlet' 'DX.dx?game=Revision.RevGameInfo' '-multihome=127.0.0.1' '-port=8797' '-nosound' *> .\RefinementGeometry.log
    if ($LASTEXITCODE -ne 0) { throw "Server di verifica fallito: $LASTEXITCODE" }
    $CheckLog = Get-Content -LiteralPath .\RefinementGeometry.log
    $CheckResult = $CheckLog | Where-Object { $_ -match '^UCWalkOffCheck: \d+ checked, \d+ failed' }
    $CheckLog | Where-Object { $_ -match '^(UCWalkOffCheck|UCVoice|UCDialogue|UnatcoContinues)' } |
        Tee-Object -FilePath (Join-Path $Root 'tools\voices\natural_v4\refinement-engine-walkoff.log')
    if (-not $CheckResult -or $CheckResult -notmatch ', 0 failed') { throw 'Verifica camminata fallita; vedere RefinementGeometry.log.' }
}
finally { Pop-Location }
