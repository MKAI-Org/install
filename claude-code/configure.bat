@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 按提示输入 ApiKey，BaseUrl 可留空
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0configure.ps1" %*
echo.
pause
