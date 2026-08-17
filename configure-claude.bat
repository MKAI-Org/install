@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title 配置 Claude Code
echo 按提示输入 ApiKey，BaseUrl 可留空
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0claude-code\configure.ps1"
echo.
pause
