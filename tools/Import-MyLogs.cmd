@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Import-MyCombatLogs.ps1"
echo.
pause
