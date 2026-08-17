# Codex CLI for Windows. No Node. Local / R2 first, then GitHub mirrors.
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
. (Join-Path $Root 'lib\common.ps1')
MkUsePackagesDir $PackagesDir
$ver = Get-Versions
$tag = $ver['CODEX_TAG']
$plat = Get-PlatformId

if (Test-Have 'codex') {
  Write-Log "codex already installed"
  exit 0
}

if ($plat -eq 'windows-arm64') { $asset = 'codex-aarch64-pc-windows-msvc.exe.zip' }
else { $asset = 'codex-x86_64-pc-windows-msvc.exe.zip' }

$rel = "openai/codex/releases/download/$tag/$asset"
$zip = MkEnsurePackage -App 'codex' -File $asset -Urls (MkGitHubUrls $rel)
if (-not $zip) { throw "Codex CLI download failed. Put $asset in codex\packages" }

$stage = Join-Path $env:TEMP 'mk-codex-extract'
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
MkExpandZip $zip $stage
$src = Get-ChildItem -Path $stage -Recurse -Include 'codex.exe','codex-*.exe' | Select-Object -First 1
if (-not $src) { throw "zip has no exe" }

$bin = Get-UserBin
Copy-Item -Force $src.FullName (Join-Path $bin 'codex.exe')
Add-UserPath $bin

$vc = Join-Path $Root 'vcredist\install.ps1'
if (Test-Path $vc) {
  Write-Log "check VC++"
  try { & $vc -PackagesDir $PackagesDir } catch { Write-Warn $_ }
}

$sbName = 'codex-windows-sandbox-setup-x86_64-pc-windows-msvc.exe.zip'
$sbRel = "openai/codex/releases/download/$tag/$sbName"
$sbZip = MkEnsurePackage -App 'codex' -File $sbName -Urls (MkGitHubUrls $sbRel)
if ($sbZip) {
  Write-Log "install Windows sandbox helper"
  $sbStage = Join-Path $env:TEMP 'mk-codex-sandbox'
  if (Test-Path $sbStage) { Remove-Item -Recurse -Force $sbStage }
  MkExpandZip $sbZip $sbStage
  $sbExe = Get-ChildItem $sbStage -Recurse -Filter '*.exe' | Select-Object -First 1
  if ($sbExe) {
    try { Start-Process -FilePath $sbExe.FullName -Wait } catch { Write-Warn $_ }
  }
}

if (-not (Test-Have 'codex')) {
  Write-Warn "codex.exe is in $bin . Open a new PowerShell, run: codex --version"
} else {
  Write-Log "codex is on PATH"
}
Write-Log "next: double-click configure-codex.bat"
