# Comandi e tasti della mod in RevisionUser.ini:
#   uc = menu di debug (anche tasto Home, se libero); e per la presentazione del video (UCTour):
#   uctour = parte dal primo capitolo, ucnext = capitolo successivo (anche tasto PagSu),
#   uchide = togli la scritta (anche tasto PagGiu'), ucagain = ripeti il passo, ucstop = ferma.
# Il gioco deve essere chiuso (quando esce riscrive il file). Copia di sicurezza:
# RevisionUser.ini.bak_tour (solo la prima volta).
. "$PSScriptRoot\..\config.ps1"
$ErrorActionPreference = 'Stop'
if (Get-Process Revision -ErrorAction SilentlyContinue) { throw "Revision e' aperto: chiudilo prima." }

$ini = Join-Path $RevSrc 'System\RevisionUser.ini'
if (-not (Test-Path "$ini.bak_tour")) { Copy-Item -LiteralPath $ini "$ini.bak_tour" }
$text = Get-Content -LiteralPath $ini -Raw

$aliases = [ordered]@{
  uc      = 'UCDbgMenu'
  uctour  = 'UCDbgTour'
  ucnext  = 'UCDbgTourNext'
  ucagain = 'UCDbgTourAgain'
  ucstop  = 'UCDbgTourStop'
  uchide  = 'UCDbgTourHide'
}
foreach ($name in $aliases.Keys) {
  $line = '(Command="summon UnatcoContinues.' + $aliases[$name] + '",Alias=' + $name + ')'
  if ($text.Contains($line)) { continue }
  # il primo posto libero fra gli alias
  $m = [regex]::Match($text, '(?m)^(Aliases\[\d+\]=)\(Command="",Alias=None\)')
  if (-not $m.Success) { throw "Nessun alias libero in $ini" }
  $text = $text.Substring(0, $m.Index) + $m.Groups[1].Value + $line + $text.Substring($m.Index + $m.Length)
  Write-Host "alias $name aggiunto"
}
# Home apre il menu di debug: solo se non e' gia' usato per altro
$m = [regex]::Match($text, '(?m)^Home=([^\r\n]*)')
if ($m.Success -and $m.Groups[1].Value -eq '') {
  $text = $text.Substring(0, $m.Index) + 'Home=uc' + $text.Substring($m.Index + $m.Length)
  Write-Host 'tasto Home = uc'
}
# PagSu: solo se non e' gia' usato per altro
$m = [regex]::Match($text, '(?m)^PageUp=([^\r\n]*)')
if ($m.Success -and $m.Groups[1].Value -eq '') {
  $text = $text.Substring(0, $m.Index) + 'PageUp=ucnext' + $text.Substring($m.Index + $m.Length)
  Write-Host 'tasto PagSu = ucnext'
} elseif ($m.Success -and $m.Groups[1].Value -ne 'ucnext') {
  Write-Host "PagSu e' gia' usato ($($m.Groups[1].Value)): non lo cambio, usa ucnext in console."
}
# PagGiu' toglie la scritta (chiesto da Gabby): prende il posto di quello che c'era (di solito LookDown)
$m = [regex]::Match($text, '(?m)^PageDown=([^\r\n]*)')
if ($m.Success -and $m.Groups[1].Value -ne 'uchide') {
  Write-Host "tasto PagGiu' = uchide (prima era: '$($m.Groups[1].Value)')"
  $text = $text.Substring(0, $m.Index) + 'PageDown=uchide' + $text.Substring($m.Index + $m.Length)
}
Set-Content -LiteralPath $ini -Value $text -NoNewline -Encoding Default
Write-Host 'Fatto.'
