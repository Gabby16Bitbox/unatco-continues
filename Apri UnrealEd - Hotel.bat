@echo off
rem Apre la mappa dell hotel in UnrealEd (configurato per Revision e per la mod)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0edit-map.ps1" 04_NYC_Hotel
pause
