@echo off
rem Double-cliquez sur ce fichier pour tout installer (Windows).
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
echo.
pause
