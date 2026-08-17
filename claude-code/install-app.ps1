# Claude desktop for Windows. Do not match claude.exe CLI.
param([string]$PackagesDir)
$Root = Split-Path $PSScriptRoot -Parent
. "$Root\lib\common.ps1"
Use-PackagesDir $PackagesDir

$setup = Find-PackageGlob 'claude-code' 'Claude-Setup*.exe'
if (-not $setup) { $setup = Find-PackageGlob 'claude-code' 'Claude Setup*.exe' }
if (-not $setup) { $setup = Find-PackageFile 'claude-code' 'Claude-Setup.exe' }
if (-not $setup) {
  $setup = Ensure-Package -App 'claude-code' -File 'Claude-Setup.exe' -Urls @(
    'https://claude.ai/api/desktop/win32/x64/exe/latest/redirect'
  )
}
if (-not $setup) { throw "桌面客户端下载失败。没网就把 Claude-Setup.exe 放到 claude-code\packages 或 -PackagesDir" }

Write-Log "运行 $setup"
Start-Process -FilePath $setup -Wait
Write-Log "装完后用客户自己的 Claude 账号登录。CLI key 仍用 .\configure.ps1"
