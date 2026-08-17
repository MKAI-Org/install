# Claude Code CLI for Windows. No Node. Git recommended.
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
. (Join-Path $Root 'lib\common.ps1')
MkUsePackagesDir $PackagesDir
$ver = Get-Versions
$CLAUDE_VERSION = $ver['CLAUDE_VERSION']
$CLAUDE_GCS = $ver['CLAUDE_GCS']
$plat = Get-PlatformId

if (Test-Have 'claude') {
  Write-Log "claude already installed"
  exit 0
}

if (-not (Test-Have 'git')) {
  Write-Warn "no git, running git\install.ps1"
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

$src = MkFindPackage 'claude-code' $file
if (-not $src) { $src = MkFindPackage 'claude-code' 'claude.exe' }
if (-not $src) { $src = MkFindPackageGlob 'claude-code' "claude-$gcsPlat.exe" }
if (-not $src) {
  $url = "$CLAUDE_GCS/$CLAUDE_VERSION/$gcsPlat/claude.exe"
  $src = MkEnsurePackage -App 'claude-code' -File $file -Urls @($url)
}
if (-not $src) { throw "Claude Code download failed. Put the file in claude-code\packages" }

$bin = Get-UserBin
Copy-Item -Force $src (Join-Path $bin 'claude.exe')
Add-UserPath $bin

$official = Join-Path $env:USERPROFILE '.local\bin'
New-Item -ItemType Directory -Force -Path $official | Out-Null
Copy-Item -Force (Join-Path $bin 'claude.exe') (Join-Path $official 'claude.exe')
Add-UserPath $official

if (-not (Test-Have 'claude')) {
  Write-Warn "claude.exe is in $bin . Open a new PowerShell: claude --version"
} else {
  Write-Log "claude is on PATH"
}
Write-Log "next: double-click configure-claude.bat"
