# Rattoppo di WinDrvLite.dll (gestore finestre/mouse di Revision) SOLO nella copia di
# sviluppo usata da UnrealEd dell'SDK (DevInstall\System). Il gioco usa la sua copia in
# Revision\System, che non viene mai toccata.
#
# 1) Viste ferme (4 ott 2026): WinDrvLite legge il mouse con il raw input e nell'editor
#    del 2000 clic e trascinamenti non arrivano alle viste (WinDrv standard nell'editor
#    va in crash). All'inizio di UWindowsViewportLite::ViewportWndProc (VA 10017C10) si
#    salta subito al ramo che passa il messaggio al gestore standard di WinDrv.dll:
#      10017C3A: 8B 7D 08        mov edi,[ebp+8]   (il messaggio, come si aspetta quel ramo)
#      10017C3D: E9 48 07 00 00  jmp 1001838A      (salto relativo: indipendente dalla base)
# 2) Luci (LIGHT APPLY): l'editor apre una vista "temporanea" e WinDrvLite si ferma con
#    "Assertion failed: !IsTemporary" (UWindowsViewportLite::OpenWindow). Il controllo
#    viene saltato: la vista temporanea si apre come una normale.
#      10016481: 74 18 -> EB 18   (je -> jmp)
param([switch]$Undo)
. "$PSScriptRoot\..\config.ps1"
$dll  = Join-Path $DevSystem 'WinDrvLite.dll'
$orig = Join-Path $DevSystem 'WinDrvLite.dll.orig'
$patches = @(
  @{ Off = 0x17C3A; Before = [byte[]](0x8B,0x8E,0x84,0x01,0x00,0x00,0x8B,0x46); After = [byte[]](0x8B,0x7D,0x08,0xE9,0x48,0x07,0x00,0x00) },
  @{ Off = 0x16481; Before = [byte[]](0x74,0x18); After = [byte[]](0xEB,0x18) }
)

if ($Undo) {
  if (Get-Process UnrealEd -ErrorAction SilentlyContinue) { "UnrealEd e' aperto: chiudilo prima."; return }
  if (Test-Path $orig) { Copy-Item $orig $dll -Force; "WinDrvLite.dll originale ripristinata." }
  return
}
$b = [System.IO.File]::ReadAllBytes($dll)
function Matches([int]$off, [byte[]]$pat) { for ($i = 0; $i -lt $pat.Length; $i++) { if ($b[$off + $i] -ne $pat[$i]) { return $false } }; return $true }
$todo = @()
foreach ($p in $patches) {
  if (Matches $p.Off $p.After) { continue }
  if (-not (Matches $p.Off $p.Before)) { "WinDrvLite.dll di una versione diversa: rattoppo NON applicato."; return }
  $todo += $p
}
if ($todo.Count -eq 0) { "WinDrvLite.dll gia' rattoppata."; return }
if (Get-Process UnrealEd -ErrorAction SilentlyContinue) { "UnrealEd e' aperto: chiudilo e riapri per applicare il rattoppo."; return }
if (-not (Test-Path $orig)) { Copy-Item $dll $orig }
foreach ($p in $todo) { for ($i = 0; $i -lt $p.After.Length; $i++) { $b[$p.Off + $i] = $p.After[$i] } }
[System.IO.File]::WriteAllBytes($dll, $b)
"WinDrvLite.dll rattoppata per l'editor ($($todo.Count) modifiche; originale: WinDrvLite.dll.orig)."
