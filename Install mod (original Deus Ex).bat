@echo off
rem Installs the mod into the original Deus Ex (Game of the Year Edition; the game must be closed).
rem Uses the ready-made package in release\vanilla\ unless you have built your own (dist\vanilla\).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-vanilla.ps1"
pause
