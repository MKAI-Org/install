# Codex CLI for Windows. No Node. Local / R2 first, then GitHub mirrors.
param([string]$PackagesDir)
$Root = Split-Path $PSScriptRoot -Parent
. "$Root\lib\common.ps1"
Use-PackagesDir $PackagesDir
$ver = Get-Versions
$tag = $ver['CODEX_TAG']
$plat = Get-PlatformId

if (Test-Have 'codex') {
  Write-Log "codex 已存在"
  exit 0
}

if ($plat -eq 'windows-arm64') { $asset = 'codex-aarch64-pc-windows-msvc.exe.zip' }
else { $asset = 'codex-x86_64-pc-windows-msvc.exe.zip' }

$rel = "openai/codex/releases/download/$tag/$asset"
$zip = Ensure-Package -App 'codex' -File $asset -Urls (Get-GitHubUrls $rel)
if (-not $zip) { throw "Codex CLI 下载失败。没网就把 $asset 放到 codex\packages 或 -PackagesDir" }

$stage = Join-Path $env:TEMP 'mk-codex-extract'
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
Expand-ZipTo $zip $stage
$src = Get-ChildItem -Path $stage -Recurse -Include 'codex.exe','codex-*.exe' | Select-Object -First 1
if (-not $src) { throw "zip 里没有 exe" }

$bin = Get-UserBin
Copy-Item -Force $src.FullName (Join-Path $bin 'codex.exe')
Add-UserPath $bin

$vc = Join-Path $Root 'vcredist\install.ps1'
if (Test-Path $vc) {
  Write-Log "检查 VC++ 运行库"
  try { & $vc -PackagesDir $PackagesDir } catch { Write-Warn $_ }
}

$sbName = 'codex-windows-sandbox-setup-x86_64-pc-windows-msvc.exe.zip'
$sbRel = "openai/codex/releases/download/$tag/$sbName"
$sbZip = Ensure-Package -App 'codex' -File $sbName -Urls (Get-GitHubUrls $sbRel)
if ($sbZip) {
  Write-Log "安装 Windows sandbox helper"
  $sbStage = Join-Path $env:TEMP 'mk-codex-sandbox'
  if (Test-Path $sbStage) { Remove-Item -Recurse -Force $sbStage }
  Expand-ZipTo $sbZip $sbStage
  $sbExe = Get-ChildItem $sbStage -Recurse -Filter '*.exe' | Select-Object -First 1
  if ($sbExe) {
    try { Start-Process -FilePath $sbExe.FullName -Wait } catch { Write-Warn $_ }
  }
}

if (-not (Test-Have 'codex')) {
  Write-Warn "codex.exe 已放到 $bin 。关掉这个窗口，新开 PowerShell，再运行 codex --version"
} else {
  Write-Log "codex 已在 PATH"
}
Write-Log "配 key: .\configure.ps1 -ApiKey ... -BaseUrl ... -Model ..."
