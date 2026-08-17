@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title MK 桌面客户端
echo 安装 Codex / Claude 桌面客户端
echo.

echo [1/2] Codex 桌面
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0codex\install-app.ps1"
echo [2/2] Claude 桌面
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0claude-code\install-app.ps1"

echo.
pause
