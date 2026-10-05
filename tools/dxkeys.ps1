# Invia tasti a Deus Ex (DirectInput legge gli SCANCODE, non i codici virtuali).
# Uso:  .\dxkeys.ps1 -Keys "esc"            (tasti speciali separati da spazio)
#       .\dxkeys.ps1 -Text "uchotel" -Enter  (scrive testo nella console e preme Invio)
#       .\dxkeys.ps1 -Console -Text "uchotel" -Enter   (apre la console con T prima)
param([string]$Keys = '', [string]$Text = '', [switch]$Enter, [switch]$Console, [int]$DelayMs = 60)

Add-Type @"
using System; using System.Runtime.InteropServices;
public class DXK {
  [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT { public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public IntPtr extra; }
  [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx; public int dy; public uint data; public uint flags; public uint time; public IntPtr extra; }
  [StructLayout(LayoutKind.Explicit)] public struct INPUT { [FieldOffset(0)] public uint type; [FieldOffset(8)] public KEYBDINPUT ki; [FieldOffset(8)] public MOUSEINPUT mi; }
  [DllImport("user32.dll")] public static extern uint SendInput(uint n, INPUT[] inputs, int size);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  public static void Scan(ushort sc, bool ext, bool up) {
    INPUT[] i = new INPUT[1]; i[0].type = 1; i[0].ki.wScan = sc;
    i[0].ki.dwFlags = 0x0008 | (ext ? 0x0001u : 0u) | (up ? 0x0002u : 0u);
    SendInput(1, i, Marshal.SizeOf(typeof(INPUT)));
  }
}
"@

$scan = @{
  'esc'=0x01; '1'=0x02; '2'=0x03; '3'=0x04; '4'=0x05; '5'=0x06; '6'=0x07; '7'=0x08; '8'=0x09; '9'=0x0A; '0'=0x0B;
  'q'=0x10; 'w'=0x11; 'e'=0x12; 'r'=0x13; 't'=0x14; 'y'=0x15; 'u'=0x16; 'i'=0x17; 'o'=0x18; 'p'=0x19;
  'enter'=0x1C; 'a'=0x1E; 's'=0x1F; 'd'=0x20; 'f'=0x21; 'g'=0x22; 'h'=0x23; 'j'=0x24; 'k'=0x25; 'l'=0x26;
  'z'=0x2C; 'x'=0x2D; 'c'=0x2E; 'v'=0x2F; 'b'=0x30; 'n'=0x31; 'm'=0x32; '.'=0x34; 'space'=0x39; ' '=0x39;
  'f1'=0x3B; 'f2'=0x3C; 'f3'=0x3D; 'f9'=0x43; 'f10'=0x44; 'tab'=0x0F; 'backspace'=0x0E; 'lshift'=0x2A;
}
$ext = @{ 'home'=0x47; 'up'=0x48; 'down'=0x50; 'left'=0x4B; 'right'=0x4D; 'pgup'=0x49; 'pgdn'=0x51; 'end'=0x4F; 'insert'=0x52; 'delete'=0x53 }

$g = Get-Process Revision -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $g) { "Revision non e' in esecuzione"; exit 1 }
[DXK]::SetForegroundWindow($g.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 150

function Press([string]$k) {
  $k = $k.ToLower()
  if ($ext.ContainsKey($k)) { [DXK]::Scan($ext[$k], $true, $false); Start-Sleep -Milliseconds $DelayMs; [DXK]::Scan($ext[$k], $true, $true) }
  elseif ($scan.ContainsKey($k)) { [DXK]::Scan($scan[$k], $false, $false); Start-Sleep -Milliseconds $DelayMs; [DXK]::Scan($scan[$k], $false, $true) }
  else { "tasto sconosciuto: $k" }
  Start-Sleep -Milliseconds $DelayMs
}

if ($Console) { Press 't'; Start-Sleep -Milliseconds 300 }
foreach ($k in ($Keys -split ' ')) { if ($k) { Press $k } }
foreach ($ch in $Text.ToCharArray()) { Press ([string]$ch) }
if ($Enter) { Press 'enter' }
"ok"
