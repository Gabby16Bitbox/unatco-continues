# Removes the mod from Deus Ex: Revision (what install.ps1 added), keeping every other setting of the player as it is
# now: its packages in Revision\System, the Revision\UnatcoMaps folder, its Paths lines in Revision.ini, its console
# commands and the Home key in RevisionUser.ini. The .bak copies are left where they are.
#   -Game  the Deus Ex folder (default: config.ps1)
param([string]$Game = '')
if ($Game) { $env:UC_GAME_ROOT = $Game }
. "$PSScriptRoot\config.ps1"
$ErrorActionPreference = 'Stop'
if (Get-Process Revision -ErrorAction SilentlyContinue) { throw "Close Revision before uninstalling." }
$sys = Join-Path $RevSrc 'System'
foreach ($p in 'UnatcoContinues', 'UnatcoVoices', 'UCAnims', 'UCModels', 'UCSounds', 'UCScripts') {
  $f = Join-Path $sys "$p.u"
  if (Test-Path $f) { Remove-Item $f -Force; "removed $p.u" }
}
$ini = Join-Path $sys 'Revision.ini'
if (Test-Path $ini) {
  $text = [System.IO.File]::ReadAllText($ini, [System.Text.Encoding]::Default)
  $new = [regex]::Replace($text, '(?mi)^Paths=\.\.\\UnatcoMaps\\\*\.dx\r?\n', '')
  if ($new -ne $text) { [System.IO.File]::WriteAllText($ini, $new, [System.Text.Encoding]::Default); "Revision.ini: UnatcoMaps removed" }
}
$user = Join-Path $sys 'RevisionUser.ini'
if (Test-Path $user) {
  $text = [System.IO.File]::ReadAllText($user, [System.Text.Encoding]::Default)
  $new = [regex]::Replace($text, '(?m)^(Aliases\[\d+\]=)\(Command="summon UnatcoContinues\.[^"]*",Alias=\w+\)', '$1(Command="",Alias=None)')
  $new = [regex]::Replace($new, '(?mi)^Home=unatco(\r?)$', 'Home=$1')
  if ($new -ne $text) { [System.IO.File]::WriteAllText($user, $new, [System.Text.Encoding]::Default); "RevisionUser.ini: the mod's commands removed" }
}
$dest = Join-Path $RevSrc 'UnatcoMaps'
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force; "removed $dest" }
"Done."
