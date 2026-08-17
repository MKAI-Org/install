# Claude desktop for Windows. CLI is install.bat / install.ps1.
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
. (Join-Path $Root 'lib\common.ps1')
MkUsePackagesDir $PackagesDir

$setup = MkFindPackageGlob 'claude-code' 'Claude-Setup*.exe'
if (-not $setup) { $setup = MkFindPackageGlob 'claude-code' 'Claude Setup*.exe' }
if (-not $setup) { $setup = MkFindPackage 'claude-code' 'Claude-Setup.exe' }
if ($setup) {
  Write-Log "run $setup"
  Start-Process -FilePath $setup -Wait
  Write-Log "login with the customer's Claude account"
  exit 0
}

Write-Warn "No Claude desktop installer in packages."
Write-Warn "For CLI (recommended): go up one folder and double-click install.bat"
Write-Warn "Or put Claude-Setup.exe into claude-code\packages and run this again."
exit 1
