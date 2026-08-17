# Codex CLI. PS 5.1. No Node.
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
if (-not $PSScriptRoot) { throw 'Run with powershell.exe -File' }
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'lib\common.ps1')
MkUsePackagesDir $PackagesDir
$ver = Get-Versions
$tag = $ver['CODEX_TAG']
$plat = Get-PlatformId

if (Test-Have 'codex') {
  Write-Log 'codex already installed'
  exit 0
}

if ($plat -eq 'windows-arm64') { $asset = 'codex-aarch64-pc-windows-msvc.exe.zip' }
else { $asset = 'codex-x86_64-pc-windows-msvc.exe.zip' }

$rel = "openai/codex/releases/download/$tag/$asset"
$zip = MkEnsurePackage -App 'codex' -File $asset -Urls (MkGitHubUrls $rel)
if (-not $zip) { throw "Codex CLI download failed. Put $asset in codex\packages" }

$stage = Join-Path $env:TEMP 'mk-codex-extract'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
MkExpandZip $zip $stage
$src = Get-ChildItem -LiteralPath $stage -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -eq 'codex.exe' -or $_.Name -like 'codex-*.exe' } |
  Select-Object -First 1
if (-not $src) { throw 'zip has no exe' }

$bin = Get-UserBin
Copy-Item -Force -LiteralPath $src.FullName -Destination (Join-Path $bin 'codex.exe')
Add-UserPath $bin

$vc = Join-Path $Root 'vcredist\install.ps1'
if (Test-Path -LiteralPath $vc) {
  Write-Log 'check VC++'
  try { & $vc -PackagesDir $PackagesDir } catch { Write-Warn "$_" }
}

$sbName = 'codex-windows-sandbox-setup-x86_64-pc-windows-msvc.exe.zip'
$sbRel = "openai/codex/releases/download/$tag/$sbName"
$sbZip = MkEnsurePackage -App 'codex' -File $sbName -Urls (MkGitHubUrls $sbRel)
if ($sbZip) {
  Write-Log 'install Windows sandbox helper'
  $sbStage = Join-Path $env:TEMP 'mk-codex-sandbox'
  if (Test-Path -LiteralPath $sbStage) { Remove-Item -LiteralPath $sbStage -Recurse -Force }
  MkExpandZip $sbZip $sbStage
  $sbExe = Get-ChildItem -LiteralPath $sbStage -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like '*.exe' } |
    Select-Object -First 1
  if ($sbExe) {
    try { Start-Process -FilePath $sbExe.FullName -Wait } catch { Write-Warn "$_" }
  }
}

if (-not (Test-Have 'codex')) {
  Write-Warn "codex.exe is in $bin . Open a new PowerShell: codex --version"
} else {
  Write-Log 'codex is on PATH'
}
Write-Log 'next: double-click configure-codex.bat'
