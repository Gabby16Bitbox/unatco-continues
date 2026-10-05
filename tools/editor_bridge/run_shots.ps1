# The request contains data only: never interpolate camera or console actions into shell code.
param([Parameter(Mandatory=$true)][string]$RequestFile,
      [Parameter(Mandatory=$true)][string]$ReportFile)
$ErrorActionPreference = 'Stop'
$request = Get-Content -LiteralPath $RequestFile -Raw -Encoding UTF8 | ConvertFrom-Json
$script = Join-Path $PSScriptRoot '..\shots.ps1'
$result = @{ success = $false; output = @(); error = $null }
try {
    $shotArgs = @{ Map = [string]$request.map; StartMap = [string]$request.start_map;
        Setup = [string]$request.setup; Delay = [float]$request.delay;
        Shots = [string[]]$request.shots; Name = [string]$request.name;
        Timeout = [int]$request.timeout; Width = [int]$request.width }
    $result.output = @(& $script @shotArgs | ForEach-Object { [string]$_ })
    $result.success = $true
}
catch { $result.error = $_.Exception.Message }
finally { $result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ReportFile -Encoding UTF8 }
if (-not $result.success) { exit 1 }
