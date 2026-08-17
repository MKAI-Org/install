# Claude desktop. PS 5.1. MSIX needs Administrator (UAC).
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
if (-not $PSScriptRoot) { throw 'Run with powershell.exe -File' }
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'lib\common.ps1')
MkUsePackagesDir $PackagesDir
MkEnsureAdmin

$setup = MkFindPackageGlob 'claude-code' 'Claude-Setup*.exe'
if (-not $setup) { $setup = MkFindPackageGlob 'claude-code' 'Claude Setup*.exe' }
if (-not $setup) { $setup = MkFindPackage 'claude-code' 'Claude-Setup.exe' }
if ($setup) {
  Write-Log "run $setup"
  Start-Process -FilePath $setup -Wait
  Write-Log 'login with the customer Claude account'
  exit 0
}

$msix = MkFindPackageGlob 'claude-code' '*.msix'
if (-not $msix) { $msix = MkFindPackage 'claude-code' 'Claude.msix' }
if (-not $msix) {
  $msix = MkEnsurePackage -App 'claude-code' -File 'Claude.msix' -Urls @(
    'https://claude.ai/api/desktop/win32/x64/msix/latest/redirect'
  )
}
if (-not $msix) { throw 'Claude desktop download failed' }

MkInstallMsix $msix
Write-Log 'desktop app installed. login with the customer Claude account'
