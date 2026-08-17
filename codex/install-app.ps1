# Codex / ChatGPT desktop. PS 5.1. MSIX needs Administrator.
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
if (-not $PSScriptRoot) { throw 'Run with powershell.exe -File' }
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'lib\common.ps1')
MkUsePackagesDir $PackagesDir

$msix = MkFindPackageGlob 'codex' 'ChatGPT*.msix'
if (-not $msix) { $msix = MkFindPackageGlob 'codex' 'Codex*.msix' }
if (-not $msix) { $msix = MkFindPackage 'codex' 'ChatGPT.msix' }
if ($msix) {
  MkEnsureAdmin
  MkInstallMsix $msix
  Write-Log 'desktop app installed'
  exit 0
}

if (Test-Have 'winget') {
  Write-Log 'try winget Microsoft Store'
  try {
    winget install --id 9PLM9XGG6VKS -s msstore --accept-package-agreements --accept-source-agreements
    Write-Log 'Store app installed'
    exit 0
  } catch {
    Write-Warn "$_"
  }
}

Write-Warn 'Codex desktop (Store) often fails in China.'
Write-Warn 'Use install.bat for CLI'
exit 1
