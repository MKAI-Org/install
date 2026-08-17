@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title 配置 Codex
echo 按提示输入 ApiKey / BaseUrl / Model
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0codex\configure.ps1"
echo.
pause
