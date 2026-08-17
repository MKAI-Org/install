# Codex / ChatGPT desktop on Windows. Store often fails in China.
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
. (Join-Path $Root 'lib\common.ps1')
MkUsePackagesDir $PackagesDir

$msix = MkFindPackageGlob 'codex' 'ChatGPT*.msix'
if (-not $msix) { $msix = MkFindPackageGlob 'codex' 'Codex*.msix' }
if ($msix) {
  Write-Log "install $msix"
  Add-AppxPackage -Path $msix
  Write-Log "desktop app installed"
  exit 0
}

if (Test-Have 'winget') {
  Write-Log "try winget Microsoft Store"
  try {
    winget install --id 9PLM9XGG6VKS -s msstore --accept-package-agreements --accept-source-agreements
    Write-Log "Store app installed"
    exit 0
  } catch {
    Write-Warn $_
  }
}

Write-Warn "Windows desktop app is hard to get in China."
Write-Warn "Use install.bat for CLI (recommended)."
exit 1
