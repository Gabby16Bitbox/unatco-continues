param([string]$BridgeRoot = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
. (Join-Path $BridgeRoot '..\..\config.ps1')
$games = @(Get-CimInstance Win32_Process | Where-Object {
    $_.Name -in @('Revision.exe', 'DeusEx.exe')
} | ForEach-Object {
    @{ pid = $_.ProcessId; name = $_.Name; path = $_.ExecutablePath }
})
@{ revision = $RevSrc; project = $Root; games = $games } | ConvertTo-Json -Depth 4 -Compress
