param([Parameter(Mandatory=$true)][string]$RequestFile)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
. (Join-Path $PSScriptRoot '..\..\config.ps1')
$request = Get-Content -LiteralPath $RequestFile -Raw -Encoding UTF8 | ConvertFrom-Json
$after = ([DateTimeOffset]::Parse($request.launched_at)).UtcDateTime
$expectedExe = [IO.Path]::GetFullPath((Join-Path $RevSrc 'System\Revision.exe'))
$launchMap = if ($request.setup) { $request.start_map } else { $request.map }
$closed = @()
foreach ($candidate in @(Get-CimInstance Win32_Process -Filter "Name = 'Revision.exe'")) {
    # Only a new process launched with this photographer's map and mutator is owned by the trial.
    if ($candidate.ExecutablePath -ne $expectedExe -or
        $candidate.CreationDate.ToUniversalTime() -lt $after -or
        $candidate.CommandLine -notlike '*UnatcoContinues.UCMutator*' -or
        $candidate.CommandLine -notlike "*$launchMap*") { continue }
    $process = Get-Process -Id $candidate.ProcessId -ErrorAction SilentlyContinue
    if (-not $process) { continue }
    [void]$process.CloseMainWindow()
    if (-not $process.WaitForExit(15000)) { $process.Kill(); [void]$process.WaitForExit(5000) }
    $closed += $candidate.ProcessId
}
@{ closed_trial_pids = $closed } | ConvertTo-Json -Compress
