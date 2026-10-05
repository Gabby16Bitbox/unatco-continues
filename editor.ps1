# Apre UnrealEd (SDK) con la configurazione di Revision
param([string]$Map = '')
. "$PSScriptRoot\config.ps1"
& "$PSScriptRoot\tools\patch-windrvlite.ps1"   # viste che rispondono al mouse
# movimento con WASD nelle viste (AutoHotkey, se installato; si chiude con l'editor)
$ahk = "C:\Program Files\AutoHotkey\AutoHotkey.exe"
if (Test-Path $ahk) { Start-Process $ahk -ArgumentList "`"$PSScriptRoot\tools\UnrealEd-WASD.ahk`"" }
Start-Process "$DevSystem\UnrealEd.exe" -ArgumentList "$Map -ini=Revision.ini" -WorkingDirectory $DevSystem
