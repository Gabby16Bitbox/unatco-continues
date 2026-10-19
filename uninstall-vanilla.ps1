# Removes the mod from the ORIGINAL Deus Ex (what install-vanilla.ps1 added), keeping every other setting of the
# player as it is now: the UnatcoMaps folder, its two Paths lines in DeusEx.ini, its console files in System, its
# aliases and the Home key in User.ini. The .bak_unatco copies are left where they are.
#   -Game  the Deus Ex folder (default: config.ps1)
param([string]$Game = '')
if ($Game) { $env:UC_GAME_ROOT = $Game }
. "$PSScriptRoot\config.ps1"
$ErrorActionPreference = 'Stop'
if (Get-Process DeusEx -ErrorAction SilentlyContinue) { throw "Close Deus Ex before uninstalling." }
$sys = Join-Path $GameRoot 'System'

$ini = Join-Path $sys 'DeusEx.ini'
if (Test-Path $ini) {
  $text = [System.IO.File]::ReadAllText($ini, [System.Text.Encoding]::Default)
  $new = [regex]::Replace($text, '(?mi)^Paths=\.\.\\UnatcoMaps\\\*\.(dx|u)\r?\n', '')
  if ($new -ne $text) { [System.IO.File]::WriteAllText($ini, $new, [System.Text.Encoding]::Default); "DeusEx.ini: UnatcoMaps removed" }
}
$user = Join-Path $sys 'User.ini'
if (Test-Path $user) {
  $text = [System.IO.File]::ReadAllText($user, [System.Text.Encoding]::Default)
  $new = [regex]::Replace($text, '(?m)^(Aliases\[\d+\]=)\([^\r\n]*Alias=unatco(start|paul)?\)', '$1(Command="",Alias=None)')
  $new = [regex]::Replace($new, '(?mi)^Home=unatco(\r?)$', 'Home=$1')
  if ($new -ne $text) { [System.IO.File]::WriteAllText($user, $new, [System.Text.Encoding]::Default); "User.ini: the mod's commands removed" }
}
foreach ($f in 'unatcostart.txt', 'unatco.txt', 'unatcopaul.txt') { Remove-Item (Join-Path $sys $f) -ErrorAction SilentlyContinue }
$dest = Join-Path $GameRoot 'UnatcoMaps'
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force; "removed $dest" }
"Done."
