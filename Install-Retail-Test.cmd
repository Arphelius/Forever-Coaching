@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Install-AddonTest.ps1" -Client Retail %*
pause
