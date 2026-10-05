# Percorsi condivisi dagli script. Modifica qui se sposti qualcosa.
$Root       = $PSScriptRoot
$GameRoot   = 'C:\Program Files (x86)\Steam\steamapps\common\Deus Ex'     # installazione Steam (SOLO LETTURA)
$RevSrc     = Join-Path $GameRoot 'Revision'
$Dev        = Join-Path $Root 'DevInstall'                    # copia di lavoro
$DevSystem  = Join-Path $Dev 'System'
$ModName    = 'UnatcoContinues'
$ModSrc     = Join-Path $Root "src\$ModName"
