# Installs the mod into the ORIGINAL Deus Ex (Game of the Year Edition), next to Revision's version (install.ps1).
# The game must be closed.
#  - the mod's packages (built for the original game: dist\vanilla\UnatcoContinues.u, else release\vanilla\; the
#    voices, animations and models: dist\, else release\) and its maps go to a folder of their own, <Deus Ex>\UnatcoMaps
#  - the maps: the repository carries only our differences (maps\vanilla\patches\*.ucpatch, tools\mappatch.py), applied
#    to the player's own copy of the original maps (<Deus Ex>\Maps, never changed); who develops has the whole maps in
#    maps\vanilla\ (outside git): those are installed as they are
#  - DeusEx.ini: UnatcoMaps read first ([Core.System] Paths; backup DeusEx.ini.bak_unatco, the first time)
#  - System\unatcostart.txt (starts the mod in the game being played), System\unatco.txt (the menu that jumps to each
#    part of the new story), System\unatcopaul.txt (to Paul at the 'Ton, evidence found and signal not sent: the choice):
#    typed in the console as  exec unatcostart.txt . In the original game 'summon' works only with the cheats on: they
#    turn them on just for that and off again. User.ini [Extension.InputExt] (the original game's keys and aliases) and
#    [Engine.Input]: the same as aliases and the Home key for 'unatco' if free (backup User.ini.bak_unatco)
#   -Game       the Deus Ex folder (default: $GameRoot of config.ps1)
#   -Originals  where the original maps are read from (default: <Game>\Maps)
#   -FromPatches the maps from the patches even when the whole maps are here (what a player gets)
#   -NoGameCheck a test install into another folder while the game is open
param([string]$Game = '', [string]$Originals = '', [switch]$FromPatches, [switch]$NoGameCheck)
. "$PSScriptRoot\config.ps1"
$ErrorActionPreference = 'Stop'
if ($Game -ne '') { $GameRoot = $Game }
$OriginalMaps = if ($Originals -ne '') { $Originals } else { Join-Path $GameRoot 'Maps' }
if (-not $NoGameCheck -and (Get-Process DeusEx -ErrorAction SilentlyContinue)) { throw "Close Deus Ex before installing." }
$sys = Join-Path $GameRoot 'System'
if (-not (Test-Path (Join-Path $sys 'DeusEx.ini'))) { throw "Deus Ex not found in $GameRoot (change the path in config.ps1)" }

$dest = Join-Path $GameRoot 'UnatcoMaps'
New-Item -ItemType Directory -Force $dest | Out-Null

# --- packages
$found = @{}
foreach ($p in 'UnatcoContinues', 'UnatcoVoices', 'UCAnims', 'UCModels', 'UCSounds') {
  $from = if ($p -eq 'UnatcoContinues') { @("dist\vanilla\$p.u", "release\vanilla\$p.u") } else { @("dist\$p.u", "release\$p.u") }
  foreach ($rel in $from) {
    $f = Join-Path $PSScriptRoot $rel
    if (Test-Path $f) { Copy-Item $f $dest -Force; "installed $p.u (from $(Split-Path $rel -Parent)\)"; $found[$p] = $true; break }
  }
}
if (-not $found['UnatcoContinues']) { throw "UnatcoContinues.u for the original game found neither in dist\vanilla\ nor in release\vanilla\ (tools\build_vanilla.ps1 makes it)" }

# --- maps
$ours = Join-Path $PSScriptRoot 'maps\vanilla'
if (-not $FromPatches) { Get-ChildItem $ours -Filter *.dx -ErrorAction SilentlyContinue | ForEach-Object {
  Copy-Item $_.FullName $dest -Force; "installed map $($_.Name)"
} }
. "$PSScriptRoot\tools\Expand-MapPatch.ps1"
Get-ChildItem (Join-Path $ours 'patches') -Filter *.ucpatch -ErrorAction SilentlyContinue | ForEach-Object {
  if (-not $FromPatches -and (Test-Path (Join-Path $ours "$($_.BaseName).dx"))) { return }   # the whole map: installed above
  if (Expand-MapPatch $_.FullName $OriginalMaps (Join-Path $dest "$($_.BaseName).dx")) {
    "installed map $($_.BaseName).dx (made from your Deus Ex\Maps)"
  }
}

# --- DeusEx.ini: UnatcoMaps first, its maps and its packages
$ini = Join-Path $sys 'DeusEx.ini'
$text = [System.IO.File]::ReadAllText($ini, [System.Text.Encoding]::Default)
$m = [regex]::Match($text, '\[Core\.System\][^\[]*')
if (-not $m.Success) { throw "DeusEx.ini has no [Core.System] section" }
if ($m.Value -notmatch 'Paths=\.\.\\UnatcoMaps\\\*\.dx') {
  $nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
  $fixed = ([regex]'(\r?\n)(Paths=)').Replace($m.Value, "`$1Paths=..\UnatcoMaps\*.dx`$1Paths=..\UnatcoMaps\*.u`$1`$2", 1)
  if ($fixed -eq $m.Value) { throw "DeusEx.ini [Core.System] has no Paths" }
  if (-not (Test-Path "$ini.bak_unatco")) { Copy-Item $ini "$ini.bak_unatco" }
  $text = $text.Substring(0, $m.Index) + $fixed + $text.Substring($m.Index + $m.Length)
  [System.IO.File]::WriteAllText($ini, $text, [System.Text.Encoding]::Default)
  "DeusEx.ini [Core.System]: the UnatcoMaps folder is read first (backup: DeusEx.ini.bak_unatco)"
}

# --- the commands: little files of console commands in System, typed as  exec unatcostart.txt  (works in any case),
# and the same as aliases (typed  unatcostart ) and the Home key for the menu. The original game's 'summon' needs the
# cheats: on for it, off again (an alias chained with | stopped after its first command, 19 Oct 2026).
# The original game reads its keys and aliases from [Extension.InputExt] (its input class), not from [Engine.Input]
# (where the first install put them: they did nothing).
$commands = @(@('unatcostart', 'UCCampaign'), @('unatco', 'UCDbgMenu'), @('unatcopaul', 'UCDbgHotel'))
foreach ($a in $commands) {
  $lines = @('set DeusExPlayer bCheatsEnabled True', "summon UnatcoContinues.$($a[1])", 'set DeusExPlayer bCheatsEnabled False')
  [System.IO.File]::WriteAllText((Join-Path $sys "$($a[0]).txt"), ($lines -join "`r`n") + "`r`n", [System.Text.Encoding]::ASCII)
  Remove-Item (Join-Path $dest "$($a[0]).txt") -ErrorAction SilentlyContinue      # where an older install put it
}
"installed the commands: exec unatcostart.txt, exec unatco.txt, exec unatcopaul.txt"

function Edit-Section([string]$text, [string]$section, [scriptblock]$edit) {
  $m = [regex]::Match($text, '(?ms)^\[' + [regex]::Escape($section) + '\]\r?\n.*?(?=^\[|\z)')
  if (-not $m.Success) { return $text }
  return $text.Substring(0, $m.Index) + (& $edit $m.Value) + $text.Substring($m.Index + $m.Length)
}

$user = Join-Path $sys 'User.ini'
if (Test-Path $user) {
  $text = [System.IO.File]::ReadAllText($user, [System.Text.Encoding]::Default)
  $before = $text
  foreach ($section in 'Extension.InputExt', 'Engine.Input') {
    $text = Edit-Section $text $section {
      param($s)
      foreach ($a in $commands) {
        $line = '(Command="exec ' + $a[0] + '.txt",Alias=' + $a[0] + ')'
        $have = [regex]::Match($s, '(?m)^(Aliases\[\d+\]=)\([^\r\n]*Alias=' + $a[0] + '\)')
        if ($have.Success) {
          $s = $s.Substring(0, $have.Index) + $have.Groups[1].Value + $line + $s.Substring($have.Index + $have.Length)
          continue
        }
        $free = [regex]::Match($s, '(?m)^(Aliases\[\d+\]=)\(Command="",Alias=None\)')
        if (-not $free.Success) { Write-Warning "No free alias in [$section] for '$($a[0])'"; continue }
        $s = $s.Substring(0, $free.Index) + $free.Groups[1].Value + $line + $s.Substring($free.Index + $free.Length)
      }
      $homeKey = [regex]::Match($s, '(?mi)^Home=([^\r\n]*)')
      if ($homeKey.Success -and $homeKey.Groups[1].Value -eq '') {
        $s = $s.Substring(0, $homeKey.Index) + 'Home=unatco' + $s.Substring($homeKey.Index + $homeKey.Length)
      }
      return $s
    }
  }
  if ($text -ne $before) {
    if (-not (Test-Path "$user.bak_unatco")) { Copy-Item $user "$user.bak_unatco" }
    [System.IO.File]::WriteAllText($user, $text, [System.Text.Encoding]::Default)
    "User.ini: the commands as aliases, the Home key for the menu (if it was free)"
  }
}
"Done. Start Deus Ex, load or begin a game, press T, delete 'Say' and type:  exec unatcostart.txt"
