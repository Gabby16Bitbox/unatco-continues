@echo off
rem Installs the mod into Deus Ex: Revision (the game must be closed).
rem Uses the package you built (dist\).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
