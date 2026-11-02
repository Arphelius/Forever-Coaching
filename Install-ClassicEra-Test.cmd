@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Install-ClassicEraTest.ps1" %*
pause
