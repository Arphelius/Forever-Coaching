@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Check-ForeverTuning.ps1"
set "checkResult=%errorlevel%"
if "%checkResult%"=="2" echo New tuning found. Review .tmp\forever-tuning-check\tuning-report.md before applying changes.
pause
exit /b %checkResult%
