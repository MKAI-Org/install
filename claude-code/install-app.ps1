# Claude desktop for Windows. Downloads Claude.msix from R2.
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

$msix = MkFindPackageGlob 'claude-code' '*.msix'
if (-not $msix) { $msix = MkFindPackage 'claude-code' 'Claude.msix' }
if (-not $msix) {
  $msix = MkEnsurePackage -App 'claude-code' -File 'Claude.msix' -Urls @(
    'https://claude.ai/api/desktop/win32/x64/msix/latest/redirect'
  )
}
if (-not $msix) { throw "Claude desktop download failed" }

Write-Log "install $msix"
Add-AppxPackage -Path $msix
Write-Log "desktop app installed. login with the customer's Claude account"
