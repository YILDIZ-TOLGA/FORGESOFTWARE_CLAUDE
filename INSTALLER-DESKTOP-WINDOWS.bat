@echo off
rem Double-cliquez sur ce fichier pour tout installer pour Claude Desktop (Windows).
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-desktop.ps1" %*
echo.
pause
