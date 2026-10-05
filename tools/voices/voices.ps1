# Uses Codex's bundled Python when the Windows Store Python launcher is unavailable.
param(
    [Parameter(Position=0)]
    [ValidateSet('list','generate','voices','class','design','samples','clone','direct','natural','refresh','build')]
    [string]$Command = 'list',
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$ExtraArgs
)
$ErrorActionPreference = 'Stop'
$BundledPython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
if (Test-Path -LiteralPath $BundledPython) { $VoicePython = $BundledPython }
else {
    $CandidatePython = Get-Command python.exe -ErrorAction SilentlyContinue
    if (-not $CandidatePython) { throw 'Python non trovato. Eseguire lo script con un interprete Python 3.' }
    $VoicePython = $CandidatePython.Source
}
$VoiceScript = 'make_voices.py'
$VoiceArgs = @($Command) + $ExtraArgs
if ($Command -eq 'samples') { $VoiceScript = 'prepare_samples.py'; $VoiceArgs = $ExtraArgs }
if ($Command -eq 'clone') { $VoiceScript = 'clone_voices.py'; $VoiceArgs = $ExtraArgs }
if ($Command -eq 'direct') { $VoiceScript = 'direct_voices.py'; $VoiceArgs = $ExtraArgs }
if ($Command -eq 'natural') { $VoiceScript = 'natural_voices.py'; $VoiceArgs = $ExtraArgs }
if ($Command -eq 'refresh') { $VoiceScript = 'refresh_dialogue.py'; $VoiceArgs = $ExtraArgs }
if ($Command -eq 'build') { $VoiceScript = 'build_voice_snapshot.py'; $VoiceArgs = $ExtraArgs }
& $VoicePython (Join-Path $PSScriptRoot $VoiceScript) @VoiceArgs
if ($LASTEXITCODE -ne 0) { throw "Il comando voci e' fallito (codice $LASTEXITCODE)." }
