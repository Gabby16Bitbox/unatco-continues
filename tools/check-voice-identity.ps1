param([Parameter(Mandatory=$true)][string]$BuildSystem)
. "$PSScriptRoot\..\config.ps1"
$ErrorActionPreference = 'Stop'
$CheckSystem = (Resolve-Path -LiteralPath $BuildSystem).Path
$CheckAllowed = [IO.Path]::GetFullPath((Join-Path $Dev 'Build-'))
if (-not $CheckSystem.StartsWith($CheckAllowed, [StringComparison]::OrdinalIgnoreCase) -or
    (Split-Path -Leaf $CheckSystem) -ne 'System') { throw 'Serve System di una compilazione -Isolated.' }
$CheckMaps = Join-Path (Split-Path -Parent $CheckSystem) 'VoiceTestMaps'
New-Item -ItemType Directory -Path $CheckMaps -Force | Out-Null
if ((Get-Item -LiteralPath $CheckMaps).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Cartella di test non privata.' }
Copy-Item -LiteralPath (Join-Path $RevSrc 'Maps\04_NYC_Street.dx') -Destination (Join-Path $CheckMaps 'DX.dx') -Force
$CheckIni = Get-Content -LiteralPath (Join-Path $DevSystem 'DeusEx.ini') |
    Where-Object { $_ -notmatch '^ServerActors=' }
$CheckIni = $CheckIni | ForEach-Object {
    if ($_ -eq '[Core.System]') { $_; "Paths=$CheckMaps\*.dx" }
    elseif ($_ -eq '[DeusEx.DeusExGameEngine]') { $_; 'ServerActors=UnatcoContinues.UCVoiceIdentityCheck' }
    elseif ($_ -match '^DefaultServerGame=') { 'DefaultServerGame=Revision.RevGameInfo' }
    else { $_ }
}
foreach ($CheckIniName in @('DeusEx.ini','Default.ini','Revision.ini','ucc.ini')) {
    Set-Content -LiteralPath (Join-Path $CheckSystem $CheckIniName) -Value $CheckIni -Encoding Default
}
Push-Location $CheckSystem
try {
    & .\ucc.exe 'Engine.ServerCommandlet' 'DX.dx?game=Revision.RevGameInfo' '-multihome=127.0.0.1' '-port=8796' '-nosound' *> .\VoiceIdentity.log
    if ($LASTEXITCODE -ne 0) { throw "Server fallito: $LASTEXITCODE" }
    $CheckLog = Get-Content -LiteralPath .\VoiceIdentity.log
    $CheckResult = $CheckLog | Where-Object { $_ -match '^UCVoiceIdentityCheck: \d+ checked, \d+ failed' }
    $CheckLog | Where-Object { $_ -match '^UCVoiceIdentityCheck' } |
        Tee-Object -FilePath (Join-Path $Root 'tools\voices\natural_v4\route-engine-identity.log')
    if (-not $CheckResult -or $CheckResult -notmatch ', 0 failed') { throw 'Verifica identita vocale fallita.' }
}
finally { Pop-Location }
