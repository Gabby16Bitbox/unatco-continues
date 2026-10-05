@echo off
rem Apre la mappa dell eliporto di Hong Kong in UnrealEd (configurato per Revision e per la mod)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0edit-map.ps1" 06_HongKong_Helibase
pause
