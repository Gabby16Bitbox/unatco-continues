# Verifica senza gioco delle mappe di Hong Kong (route UNATCO): per ogni mappa un
# server di prova su una COPIA privata, con UCHKCheck come ServerActor.
# Uso: .\build.ps1 -Isolated  poi  .\tools\check-hongkong.ps1 -BuildSystem <cartella System stampata>
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
$CheckIni = Get-Content -LiteralPath (Join-Path $DevSystem 'DeusEx.ini')
$CheckIni = $CheckIni | Where-Object { $_ -notmatch '^ServerActors=' }
$CheckIni = $CheckIni | ForEach-Object {
    if ($_ -eq '[Core.System]') { $_; "Paths=$CheckMaps\*.dx" }
    elseif ($_ -eq '[DeusEx.DeusExGameEngine]') { $_; 'ServerActors=UnatcoContinues.UCHKCheck' }
    elseif ($_ -match '^DefaultServerGame=') { 'DefaultServerGame=Revision.RevGameInfo' }
    else { $_ }
}
foreach ($CheckIniName in @('DeusEx.ini','Default.ini','Revision.ini','ucc.ini')) {
    Set-Content -LiteralPath (Join-Path $CheckSystem $CheckIniName) -Value $CheckIni -Encoding Default
}
$Failed = 0
foreach ($MapName in @('06_HongKong_WanChai_Market','06_HongKong_WanChai_Underworld','06_HongKong_WanChai_Street','06_HongKong_WanChai_Compound','04_NYC_Street','04_NYC_BatteryPark','06_HongKong_Helibase','06_HongKong_TongBase')) {
    # la copia modificata della mod (maps\) se c'e', altrimenti la mappa di Revision
    $MapSource = Join-Path $Root "maps\$MapName.dx"
    if (-not (Test-Path -LiteralPath $MapSource)) { $MapSource = Join-Path $RevSrc "Maps\$MapName.dx" }
    Copy-Item -LiteralPath $MapSource -Destination (Join-Path $CheckMaps 'DX.dx') -Force
    Push-Location $CheckSystem
    try {
        & .\ucc.exe 'Engine.ServerCommandlet' 'DX.dx?game=Revision.RevGameInfo' '-multihome=127.0.0.1' '-port=8798' '-nosound' *> .\HKCheck.log
        $Log = Get-Content -LiteralPath .\HKCheck.log
        $Log | Where-Object { $_ -match '^UCHKCheck' }
        $Result = $Log | Where-Object { $_ -match '^UCHKCheck: .* \d+ checked, \d+ failed' }
        if (-not $Result -or $Result -notmatch ', 0 failed') { $Failed++ }
    }
    finally { Pop-Location }
}
if ($Failed -gt 0) { throw "Verifica Hong Kong: $Failed mappe con errori (vedi sopra)." }
"Verifica Hong Kong: tutte le mappe OK."
