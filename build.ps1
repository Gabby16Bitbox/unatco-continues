# Compila la mod: "ucc editor.make" ricompila solo i .u mancanti, quindi si cancellano
# prima UnatcoVoices.u (voci) e UnatcoContinues.u (codice). Risultato in dist\
param([switch]$Isolated)
. "$PSScriptRoot\config.ps1"
$ErrorActionPreference = 'Stop'
# Il pacchetto delle voci (src\UnatcoVoices) e' facoltativo: l'audio non e' nel repository
# pubblico. Senza, si compila solo la mod e le battute restano come testo.
# UC_NO_VOICES=1 lo esclude anche quando c'e' (per provare la compilazione "da repository").
$HasVoices = (Test-Path "$Root\src\UnatcoVoices\Classes\UnatcoVoices.uc") -and -not $env:UC_NO_VOICES
$BuildPackages = @($ModName)
if ($HasVoices) { $BuildPackages = @('UnatcoVoices') + $BuildPackages }
& "$PSScriptRoot\make-ini.ps1" make | Out-Null
if ($Isolated) {
  # Fresh output packages avoid files held open by UnrealEd. Dependencies are
  # read-only hard links; configuration files are independent copies.
  $BuildRoot = Join-Path $Dev ('Build-' + [guid]::NewGuid().ToString('N'))
  $BuildSystem = Join-Path $BuildRoot 'System'
  New-Item -ItemType Directory -Path $BuildSystem | Out-Null
  foreach ($BuildDependency in Get-ChildItem -LiteralPath $DevSystem -File) {
    if ($BuildDependency.Name -in @('UnatcoVoices.u', "$ModName.u")) { continue }
    $BuildTarget = Join-Path $BuildSystem $BuildDependency.Name
    if ($BuildDependency.Extension -in @('.exe','.dll','.u')) {
      New-Item -ItemType HardLink -Path $BuildTarget -Target $BuildDependency.FullName | Out-Null
    }
    elseif ($BuildDependency.Extension -in @('.ini','.int')) {
      Copy-Item -LiteralPath $BuildDependency.FullName -Destination $BuildTarget
    }
  }
  foreach ($BuildAssets in @('Maps','Sounds','Textures','Music','HDTP','NewVision')) {
    $BuildAssetSource = Join-Path $Dev $BuildAssets
    if (Test-Path -LiteralPath $BuildAssetSource) {
      New-Item -ItemType Junction -Path (Join-Path $BuildRoot $BuildAssets) -Target $BuildAssetSource | Out-Null
    }
  }
  foreach ($BuildSourcePackage in $BuildPackages) {
    New-Item -ItemType Junction -Path (Join-Path $BuildRoot $BuildSourcePackage) -Target (Join-Path $Root "src\$BuildSourcePackage") | Out-Null
  }
  $DevSystem = $BuildSystem
  "Compilazione isolata: $BuildSystem"
  # Keep only the 3 newest Build-* folders (this one included). Junctions are
  # removed as links and never entered: they lead to src\ and the game assets.
  function Remove-IsolatedBuild([string]$Path) {
    foreach ($Entry in [IO.DirectoryInfo]::new($Path).GetFileSystemInfos()) {
      if ($Entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        if ($Entry -is [IO.DirectoryInfo]) { [IO.Directory]::Delete($Entry.FullName, $false) }
        else { [IO.File]::Delete($Entry.FullName) }
      }
      elseif ($Entry -is [IO.DirectoryInfo]) { Remove-IsolatedBuild $Entry.FullName }
      else { [IO.File]::Delete($Entry.FullName) }
    }
    [IO.Directory]::Delete($Path, $false)
  }
  $BuildStale = [IO.DirectoryInfo]::new($Dev).GetDirectories('Build-*') |
    Where-Object { $_.Name -match '^Build-[0-9a-f]{32}$' -and $_.FullName -ne $BuildRoot -and
                   -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
    Sort-Object CreationTime -Descending | Select-Object -Skip 2
  foreach ($BuildOld in $BuildStale) {
    # a check may still be running there (ucc.exe started from that folder)
    if (Get-Process -Name ucc, UnrealEd, Revision -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -like "$($BuildOld.FullName)\*" }) { continue }
    try { Remove-IsolatedBuild $BuildOld.FullName; "Eliminata compilazione vecchia: $($BuildOld.Name)" }
    catch { Write-Warning "Compilazione vecchia non eliminata ($($BuildOld.Name)): $($_.Exception.Message)" }
  }
}
# Il compilatore dell'SDK (anno 2000) va in crash, senza un messaggio utile, quando il
# percorso della cartella System e' lungo: provato il 5 ott 2026 con un clone del
# repository, funziona a 103 caratteri e si pianta a 125. Meglio dirlo subito.
if ($DevSystem.Length -gt 105) {
  throw ("Percorso troppo lungo per il compilatore dell'SDK ($($DevSystem.Length) caratteri: $DevSystem). " +
         "Sposta il progetto in una cartella dal percorso corto, per esempio C:\Dev\unatco-continues. / " +
         "The project folder path is too long for the SDK compiler: move the project to a short path.")
}
Push-Location $DevSystem
try {
  foreach ($BuildPackage in @('UnatcoVoices.u', "$ModName.u")) {
    if (Test-Path -LiteralPath $BuildPackage) { Remove-Item -LiteralPath $BuildPackage -Force }
  }
  & .\ucc.exe 'editor.make'
  if ($LASTEXITCODE -ne 0) { throw "Compilazione UCC fallita: $LASTEXITCODE" }
  # DrawScale delle texture HD (l'import di ucc non ha l'opzione; in UnrealScript e' const)
  & python "$PSScriptRoot\tools\set_texture_prop.py" "$ModName.u" UCSignElevators DrawScale 0.125
  if ($LASTEXITCODE -ne 0) { throw "DrawScale della scritta ELEVATORS non impostato" }
}
finally { Pop-Location }
New-Item -ItemType Directory -Force "$Root\dist" | Out-Null
foreach ($p in $BuildPackages) {
  if (Test-Path "$DevSystem\$p.u") { Copy-Item "$DevSystem\$p.u" "$Root\dist\" -Force; "OK: dist\$p.u" }
  else { throw "ERRORE: $p.u non compilato (vedi sopra)" }
}
