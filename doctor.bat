@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title MK doctor
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0doctor.ps1"
echo.
pause
