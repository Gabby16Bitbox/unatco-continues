# Expand-MapPatch: one of the mod's maps made from its patch (maps\patches\<name>.ucpatch, made by tools\mappatch.py)
# and the player's own copy of Revision's original maps. The repository carries only our differences, never
# Revision's maps. Returns $true when the map was written; $false (with the reason) when an original is
# missing or is another version than the one the patch was made from.
#   . .\tools\Expand-MapPatch.ps1; Expand-MapPatch maps\patches\X.ucpatch "<Revision>\Maps" "<Revision>\UnatcoMaps\X.dx"
function Expand-MapPatch([string]$PatchFile, [string]$MapsDir, [string]$OutFile) {
  $raw = [System.IO.File]::ReadAllBytes($PatchFile)
  if ([System.Text.Encoding]::ASCII.GetString($raw, 0, 8) -ne 'UCPATCH1') { Write-Warning "$PatchFile is not a map patch"; return $false }
  $in = New-Object System.IO.MemoryStream(, $raw)
  $in.Position = 8
  $def = New-Object System.IO.Compression.DeflateStream($in, [System.IO.Compression.CompressionMode]::Decompress)
  $ms = New-Object System.IO.MemoryStream
  $def.CopyTo($ms)
  $def.Close()
  $r = New-Object System.IO.BinaryReader(New-Object System.IO.MemoryStream(, $ms.ToArray()))
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $latin = [System.Text.Encoding]::GetEncoding(28591)
  $same = { param($a, $b) [System.BitConverter]::ToString($a) -eq [System.BitConverter]::ToString($b) }
  $sources = New-Object System.Collections.ArrayList
  $n = $r.ReadUInt32()
  for ($k = 0; $k -lt $n; $k++) {
    $name = $latin.GetString($r.ReadBytes($r.ReadUInt16()))
    $size = $r.ReadUInt64()
    $hash = $r.ReadBytes(32)
    $path = Join-Path $MapsDir $name
    if (-not (Test-Path -LiteralPath $path)) { Write-Warning "$(Split-Path $PatchFile -Leaf): Revision's map $name is missing in $MapsDir"; return $false }
    $b = [System.IO.File]::ReadAllBytes($path)
    if ($b.Length -ne $size -or -not (& $same $sha.ComputeHash($b) $hash)) {
      Write-Warning "$(Split-Path $PatchFile -Leaf): your $name is another version than the one the mod was made for (Revision updated?): this map of the mod is skipped"
      return $false
    }
    [void]$sources.Add($b)
  }
  $size = $r.ReadUInt64()
  $want = $r.ReadBytes(32)
  $out = New-Object System.IO.MemoryStream
  $end = $r.BaseStream.Length
  while ($r.BaseStream.Position -lt $end) {
    $kind = $r.ReadByte()
    if ($kind -eq 1) {
      $si = $r.ReadByte(); $off = $r.ReadUInt64(); $len = $r.ReadUInt32()
      $out.Write($sources[$si], [int]$off, [int]$len)
    } elseif ($kind -eq 2) {
      $len = $r.ReadUInt32()
      $bytes = $r.ReadBytes([int]$len)
      $out.Write($bytes, 0, $bytes.Length)
    } else { Write-Warning "$PatchFile is damaged"; return $false }
  }
  $res = $out.ToArray()
  if ($res.Length -ne $size -or -not (& $same $sha.ComputeHash($res) $want)) { Write-Warning "$(Split-Path $PatchFile -Leaf): the result is not the mod's map"; return $false }
  [System.IO.File]::WriteAllBytes($OutFile, $res)
  return $true
}
