# Percorsi condivisi dagli script. Modifica qui se sposti qualcosa.
$Root       = $PSScriptRoot
# the game's folder: Steam's, unless an installer passes another one (UC_GAME_ROOT)
$GameRoot   = if ($env:UC_GAME_ROOT) { $env:UC_GAME_ROOT } else { 'C:\Program Files (x86)\Steam\steamapps\common\Deus Ex' }     # installazione Steam (SOLO LETTURA)
$RevSrc     = Join-Path $GameRoot 'Revision'
$Dev        = Join-Path $Root 'DevInstall'                    # copia di lavoro
$DevSystem  = Join-Path $Dev 'System'
$ModName    = 'UnatcoContinues'
$ModSrc     = Join-Path $Root "src\$ModName"
