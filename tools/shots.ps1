# Foto automatiche dal gioco (vedi src\UnatcoContinues\Classes\UCShotRunner.uc).
# Scrive la sezione del fotografo in System\RevisionUser.ini, avvia Revision da Steam con la mod, il gioco
# prepara la scena (comando UCDbg* -Setup), scatta le foto e si chiude da solo; poi le
# foto vengono convertite in PNG in shots\<data>-<nome>\ con l'etichetta di ognuna.
# Il gioco deve essere chiuso. Esempio:
#   .\tools\shots.ps1 -Name porta -Setup UCDbgHeliDoor -Shots @(
#     'porta;view', 'atrio;cam;-1100;-60;560;-1600;-120;470')
param(
  [string]$Map = '06_HongKong_Helibase',
  # mappa di partenza: con -Setup si parte da un'altra missione, cosi' il salto carica la
  # mappa da zero (tornare nella stessa mappa la ricarica dallo stato salvato)
  [string]$StartMap = '01_NYC_UNATCOIsland',
  [string]$Setup = '',
  # flag da cambiare dopo il comando di preparazione, es. 'AnnaNavarre_Dead=1,M03PlayerKilledAnna=1'
  [string]$Flags = '',
  [float]$Delay = 6,
  [Parameter(Mandatory = $true)][string[]]$Shots,
  [string]$Name = 'foto',
  [int]$Timeout = 300,
  [int]$Width = 1600
)
. "$PSScriptRoot\..\config.ps1"
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
if (Get-Process Revision -ErrorAction SilentlyContinue) { throw "Revision e' aperto: chiudilo prima delle foto." }

$sys = Join-Path $RevSrc 'System'
# la sezione del fotografo va in RevisionUser.ini (l'unico file utente che Revision legge)
$ini = Join-Path $sys 'RevisionUser.ini'
if (-not (Test-Path "$ini.bak_shots")) { Copy-Item -LiteralPath $ini "$ini.bak_shots" }
function Set-ShotSection([string[]]$body) {
  $text = Get-Content -LiteralPath $ini -Raw
  $text = [regex]::Replace($text, '(?ms)^\[UnatcoContinues\.UCShotRunner\][^\r\n]*\r?\n.*?(?=^\[|\z)', '')
  if ($body) { $text = $text.TrimEnd() + "`r`n`r`n" + ($body -join "`r`n") + "`r`n" }
  Set-Content -LiteralPath $ini -Value $text -NoNewline -Encoding Default
}
$lines = @('[UnatcoContinues.UCShotRunner]', 'bActive=True', "Setup=$Setup", "SetupFlags=$Flags", "StartDelay=$Delay")
for ($i = 0; $i -lt $Shots.Count; $i++) { $lines += "Shots[$i]=$($Shots[$i])" }
Set-ShotSection $lines
foreach ($old in 'UCShots.ini', 'RevisionUCShots.ini') { Remove-Item -LiteralPath (Join-Path $sys $old) -ErrorAction SilentlyContinue }

# lo stato salvato della mappa da fotografare (lasciato da prove precedenti) si toglie:
# la mappa deve caricarsi da zero
$launchMap = if ($Setup) { $StartMap } else { $Map }
Remove-Item -LiteralPath (Join-Path $RevSrc "Save\Current\$Map.dxs") -ErrorAction SilentlyContinue

$start = Get-Date
try {
  # Revision avviato da fuori chiede a Steam di rilanciarlo (con conferma dei parametri):
  # si passa direttamente da Steam, che aggiunge anche le opzioni di avvio di Gabby.
  $steam = [IO.Path]::GetFullPath((Get-ItemProperty 'HKCU:\Software\Valve\Steam').SteamExe)
  # l'URL fra virgolette: senza, Steam taglia tutto prima del primo "="
  Start-Process $steam -ArgumentList ('-applaunch 397550 "' + $launchMap + '?Mutator=UnatcoContinues.UCMutator" -windowed')
  $game = $null
  for ($w = 0; $w -lt 90 -and -not $game; $w++) {
    Start-Sleep -Seconds 1
    $game = Get-Process Revision -ErrorAction SilentlyContinue | Select-Object -First 1
  }
  if (-not $game) {
    "Il gioco non e' partito entro 90 s (Steam ha chiesto conferma dei parametri?)"
  }
  elseif (-not $game.WaitForExit($Timeout * 1000)) {
    # chiusura gentile prima (cosi' il gioco scrive il log), poi a forza
    [void]$game.CloseMainWindow()
    if (-not $game.WaitForExit(20000)) { $game.Kill() }
    "ATTENZIONE: il gioco non si e' chiuso da solo entro $Timeout s (chiuso da qui)"
  }
}
finally {
  # spento: la mod torna a non fare foto (la sezione si toglie, il resto del file resta)
  Set-ShotSection @()
}

# le etichette, nell'ordine in cui sono state scattate (dal log del gioco)
$labels = @()
$log = Join-Path $sys 'Revision.log'
if (Test-Path $log) {
  foreach ($l in Get-Content $log) { if ($l -match 'UCShot preso \d+ (.+)$') { $labels += $Matches[1].Trim() } }
}

# le foto nuove (il motore le mette in System o nella cartella del gioco)
$imgs = @()
foreach ($d in @($sys, $RevSrc, (Split-Path $RevSrc -Parent))) {
  $imgs += Get-ChildItem -LiteralPath $d -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'Shot*' -and $_.Extension -in '.bmp', '.png', '.jpg' -and $_.LastWriteTime -gt $start }
}
$imgs = $imgs | Sort-Object LastWriteTime
$out = Join-Path $Root ("shots\" + (Get-Date -Format 'yyyyMMdd-HHmmss') + "-$Name")
New-Item -ItemType Directory -Force -Path $out | Out-Null
$n = 0
foreach ($f in $imgs) {
  $label = if ($n -lt $labels.Count) { $labels[$n] } else { "foto$n" }
  $src = [System.Drawing.Image]::FromFile($f.FullName)
  $h = [int]($src.Height * $Width / $src.Width)
  $bmp = New-Object System.Drawing.Bitmap($Width, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($src, 0, 0, $Width, $h)
  $g.Dispose(); $src.Dispose()
  $dst = Join-Path $out ('{0:D2}_{1}.png' -f $n, ($label -replace '[^\w-]', '_'))
  $bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Remove-Item -LiteralPath $f.FullName   # l'originale (enorme) non serve piu'
  $dst
  $n++
}
"Foto: $n (attese: $($labels.Count)) in $out"
