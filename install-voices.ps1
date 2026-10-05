# Installs the two compiled packages, preserving previous copies in dist\backup.
. "$PSScriptRoot\config.ps1"
$ErrorActionPreference = 'Stop'
if (Get-Process -Name Revision,DeusEx -ErrorAction SilentlyContinue) {
    throw 'Chiudere Deus Ex / Revision prima di installare i pacchetti.'
}
$VoiceSystem = Join-Path $RevSrc 'System'
if (-not (Test-Path -LiteralPath $VoiceSystem -PathType Container)) {
    throw "System di Revision non trovato: $VoiceSystem"
}
$VoiceBackup = Join-Path $Root ('dist\backup\voices-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$VoicePackages = @('UnatcoVoices.u','UnatcoContinues.u')
foreach ($VoicePackage in $VoicePackages) {
    $VoiceSource = Join-Path $Root ("dist\$VoicePackage")
    if (-not (Test-Path -LiteralPath $VoiceSource -PathType Leaf)) { throw "Pacchetto mancante: $VoiceSource" }
}
New-Item -ItemType Directory -Path $VoiceBackup -Force | Out-Null
foreach ($VoicePackage in $VoicePackages) {
    $VoiceTarget = Join-Path $VoiceSystem $VoicePackage
    if (Test-Path -LiteralPath $VoiceTarget) {
        Copy-Item -LiteralPath $VoiceTarget -Destination (Join-Path $VoiceBackup $VoicePackage)
    }
    $VoiceSource = Join-Path $Root ("dist\$VoicePackage")
    Copy-Item -LiteralPath $VoiceSource -Destination $VoiceTarget -Force
    if ((Get-FileHash -LiteralPath $VoiceSource -Algorithm SHA256).Hash -ne
        (Get-FileHash -LiteralPath $VoiceTarget -Algorithm SHA256).Hash) {
        throw "Verifica installazione fallita: $VoicePackage"
    }
    "Installato e verificato: $VoiceTarget"
}
"Backup precedente: $VoiceBackup"
