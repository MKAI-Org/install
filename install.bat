@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title MK 安装
echo 将安装 Node / Git / VC++ / Codex / Claude Code
echo 包从 https://dl.mkstore.life 下载
echo.

echo [1/5] Node
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0node\install.ps1"
echo [2/5] Git
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0git\install.ps1"
echo [3/5] VC++
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0vcredist\install.ps1"
echo [4/5] Codex
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0codex\install.ps1"
echo [5/5] Claude Code
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0claude-code\install.ps1"

echo.
echo 完成。新开一个 PowerShell 再用。
echo 配 key：双击 configure-codex.bat 或 configure-claude.bat
echo 桌面客户端：双击 install-app.bat
echo.
pause
