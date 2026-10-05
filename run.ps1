# Avvia Revision dalla copia di sviluppo (-hax0r gia' usato da Revision per console/debug)
param([string]$Map = '')
. "$PSScriptRoot\config.ps1"
Start-Process "$DevSystem\Revision.exe" -ArgumentList "$Map -log" -WorkingDirectory $DevSystem
