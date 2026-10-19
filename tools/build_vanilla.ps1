# The mod compiled for the original Deus Ex (GOTY 1112fm), next to the Revision build (build.ps1).
# The compile environment is DevVanilla\: its System holds read-only hard links to the original game's
# packages and programs (nothing of the game is changed), its own copy of DeusEx.ini with the mod in
# EditPackages, and junctions to the game's Textures/Sounds/Music/Maps. The mod's sources: the classes of
# src\UnatcoContinues\Classes (hard links); a class with //#if revision / //#if vanilla blocks is written by
# tools\uc_variant.py with the original game's lines (one source for both games); a whole class of its own
# for the original game may go in src\UnatcoContinues\Vanilla\Classes (it wins). The other folders of the
# sources (Textures...) are junctions.
# The compiler is the one in the game's Editor.dll, started by the map editor's engine (UCMapKitHost --make).
# Result: dist\vanilla\UnatcoContinues.u (the compiler's output also in DevVanilla\make.log)
param([switch]$Fresh)
. "$PSScriptRoot\..\config.ps1"
$ErrorActionPreference = 'Stop'
$HostExe = Join-Path $Root 'tools\mapkit\bin\UCMapKitHost.exe'
$Vanilla = Join-Path $Root 'DevVanilla'
$VSystem = Join-Path $Vanilla 'System'
$VSrc = Join-Path $Vanilla $ModName
$GameSystem = Join-Path $GameRoot 'System'

# a folder emptied: its junctions removed as links, never entered (they lead to the game and to src\).
# The folder itself may be a junction too (the first version of this script linked DevVanilla\UnatcoContinues
# to src\UnatcoContinues, and emptying it through the link deleted the mod's sources on 18 Oct 2026):
# then only the link goes.
function Remove-Tree([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $Item = Get-Item -LiteralPath $Path -Force
  if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    if ($Item -is [IO.DirectoryInfo]) { [IO.Directory]::Delete($Item.FullName, $false) } else { [IO.File]::Delete($Item.FullName) }
    return
  }
  # never anything outside DevVanilla
  if (-not $Item.FullName.StartsWith($Vanilla, [StringComparison]::OrdinalIgnoreCase)) { throw "Remove-Tree outside DevVanilla: $Path" }
  foreach ($Entry in [IO.DirectoryInfo]::new($Path).GetFileSystemInfos()) {
    if ($Entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
      if ($Entry -is [IO.DirectoryInfo]) { [IO.Directory]::Delete($Entry.FullName, $false) } else { [IO.File]::Delete($Entry.FullName) }
    }
    elseif ($Entry -is [IO.DirectoryInfo]) { Remove-Tree $Entry.FullName }
    else { [IO.File]::Delete($Entry.FullName) }
  }
  [IO.Directory]::Delete($Path, $false)
}

if ($Fresh) { Remove-Tree $Vanilla }
if (-not (Test-Path -LiteralPath $VSystem)) {
  New-Item -ItemType Directory -Path $VSystem | Out-Null
  foreach ($File in Get-ChildItem -LiteralPath $GameSystem -File) {
    $Target = Join-Path $VSystem $File.Name
    if ($File.Extension -in @('.exe', '.dll', '.u')) { New-Item -ItemType HardLink -Path $Target -Target $File.FullName | Out-Null }
    elseif ($File.Extension -in @('.ini', '.int')) { Copy-Item -LiteralPath $File.FullName -Destination $Target }
  }
  foreach ($Assets in @('Textures', 'Sounds', 'Music', 'Maps')) {
    New-Item -ItemType Junction -Path (Join-Path $Vanilla $Assets) -Target (Join-Path $GameRoot $Assets) | Out-Null
  }
  # the mod after the game's own packages
  $Ini = Join-Path $VSystem 'DeusEx.ini'
  $Lines = [Collections.Generic.List[string]](Get-Content -LiteralPath $Ini)
  $Last = $Lines.FindLastIndex([Predicate[string]]{ param($l) $l -like 'EditPackages=*' })
  $Lines.Insert($Last + 1, "EditPackages=$ModName")
  Set-Content -LiteralPath $Ini -Value $Lines -Encoding ASCII
}

# the sources, made again each time: the shared classes, the original game's versions over them
Remove-Tree $VSrc
New-Item -ItemType Directory -Path (Join-Path $VSrc 'Classes') | Out-Null
foreach ($Dir in Get-ChildItem -LiteralPath $ModSrc -Directory) {
  if ($Dir.Name -in @('Classes', 'Vanilla')) { continue }
  New-Item -ItemType Junction -Path (Join-Path $VSrc $Dir.Name) -Target $Dir.FullName | Out-Null
}
$Own = Join-Path $ModSrc 'Vanilla\Classes'
$Python = Join-Path $Root 'tools\mapkit\.venv\Scripts\python.exe'
$Variant = Join-Path $Root 'tools\uc_variant.py'
foreach ($File in Get-ChildItem -LiteralPath (Join-Path $ModSrc 'Classes') -Filter *.uc) {
  $Mine = Join-Path $Own $File.Name
  $Dest = Join-Path $VSrc ('Classes\' + $File.Name)
  if (Test-Path -LiteralPath $Mine) { New-Item -ItemType HardLink -Path $Dest -Target $Mine | Out-Null }
  elseif (Select-String -LiteralPath $File.FullName -Pattern '^\s*//#if ' -Quiet) {
    # one source for both games: Revision's lines left out, the original game's in (tools\uc_variant.py)
    & $Python $Variant vanilla $File.FullName $Dest
    if ($LASTEXITCODE -ne 0) { throw "uc_variant failed on $($File.Name)" }
  }
  else { New-Item -ItemType HardLink -Path $Dest -Target $File.FullName | Out-Null }
}
if (Test-Path -LiteralPath $Own) {
  foreach ($File in Get-ChildItem -LiteralPath $Own -Filter *.uc) {
    $Dest = Join-Path $VSrc ('Classes\' + $File.Name)
    if (-not (Test-Path -LiteralPath $Dest)) { New-Item -ItemType HardLink -Path $Dest -Target $File.FullName | Out-Null }
  }
}

Push-Location $VSystem
try {
  if (Test-Path -LiteralPath "$ModName.u") { Remove-Item -LiteralPath "$ModName.u" -Force }
  Copy-Item -LiteralPath $HostExe -Destination '.\UCMapKitHost.exe' -Force
  try {
    $Out = cmd /c '.\UCMapKitHost.exe --make DeusEx.ini 2>&1'
    $MakeCode = $LASTEXITCODE
    $Out | Set-Content -LiteralPath (Join-Path $Vanilla 'make.log') -Encoding UTF8
    $Out | Where-Object { $_ -match ': Error|Warning|Failed' -and $_ -notmatch "Can't find file '$ModName.u'" }
  }
  finally { Remove-Item -LiteralPath '.\UCMapKitHost.exe' -Force -ErrorAction SilentlyContinue }
  if ($MakeCode -ne 0) { throw "Script compiler failed: $MakeCode" }
}
finally { Pop-Location }
New-Item -ItemType Directory -Force "$Root\dist\vanilla" | Out-Null
Copy-Item "$VSystem\$ModName.u" "$Root\dist\vanilla\" -Force
"OK: dist\vanilla\$ModName.u"
