# Claude Code CLI for Windows. No Node. Git recommended.
param([string]$PackagesDir)
$Root = Split-Path $PSScriptRoot -Parent
. "$Root\lib\common.ps1"
Use-PackagesDir $PackagesDir
$ver = Get-Versions
$CLAUDE_VERSION = $ver['CLAUDE_VERSION']
$CLAUDE_GCS = $ver['CLAUDE_GCS']
$plat = Get-PlatformId

if (Test-Have 'claude') {
  Write-Log "claude 已存在"
  exit 0
}

if (-not (Test-Have 'git')) {
  Write-Warn "没有 Git。先跑 ..\git\install.ps1"
  $git = Join-Path $Root 'git\install.ps1'
  if (Test-Path $git) {
    try { & $git -PackagesDir $PackagesDir } catch { Write-Warn $_ }
  }
}

if ($plat -eq 'windows-arm64') {
  $gcsPlat = 'win32-arm64'
  $file = 'claude-win32-arm64.exe'
} else {
  $gcsPlat = 'win32-x64'
  $file = 'claude.exe'
}

$src = Find-PackageFile 'claude-code' $file
if (-not $src) { $src = Find-PackageFile 'claude-code' 'claude.exe' }
if (-not $src) { $src = Find-PackageGlob 'claude-code' "claude-$gcsPlat.exe" }
if (-not $src) {
  $url = "$CLAUDE_GCS/$CLAUDE_VERSION/$gcsPlat/claude.exe"
  $src = Ensure-Package -App 'claude-code' -File $file -Urls @($url)
}
if (-not $src) { throw "Claude Code 下载失败。没网就把包放到 claude-code\packages 或 -PackagesDir" }

$bin = Get-UserBin
Copy-Item -Force $src (Join-Path $bin 'claude.exe')
Add-UserPath $bin

$official = Join-Path $env:USERPROFILE '.local\bin'
New-Item -ItemType Directory -Force -Path $official | Out-Null
Copy-Item -Force (Join-Path $bin 'claude.exe') (Join-Path $official 'claude.exe')
Add-UserPath $official

if (-not (Test-Have 'claude')) {
  Write-Warn "claude.exe 已放到 $bin 。新开 PowerShell 再 claude --version"
} else {
  Write-Log "claude 已在 PATH"
}
Write-Log "配 key: .\configure.ps1 -ApiKey ... [-BaseUrl ...]"
