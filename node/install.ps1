# Node 22. Local packages / MK_PACKAGES first, then R2, then npmmirror.
param([string]$PackagesDir)
$Root = Split-Path $PSScriptRoot -Parent
. "$Root\lib\common.ps1"
Use-PackagesDir $PackagesDir
$ver = Get-Versions
$NODE_VERSION = $ver['NODE_VERSION']

if (Test-Have 'node') {
  $major = node -p "process.versions.node.split('.')[0]"
  if ([int]$major -ge 20) {
    Write-Log ("node 已存在 " + (node --version))
    exit 0
  }
  Write-Warn "node 太旧，继续装 $NODE_VERSION"
}

$plat = Get-PlatformId
if ($plat -eq 'windows-arm64') { $zipName = "node-v$NODE_VERSION-win-arm64.zip" }
else { $zipName = "node-v$NODE_VERSION-win-x64.zip" }

$zip = Ensure-Package -App 'node' -File $zipName -Urls @(
  "https://npmmirror.com/mirrors/node/v$NODE_VERSION/$zipName",
  "https://cdn.npmmirror.com/binaries/node/v$NODE_VERSION/$zipName",
  "https://nodejs.org/dist/v$NODE_VERSION/$zipName"
)
if (-not $zip) { throw "Node 下载失败。没网就把 $zipName 放到 node\packages 或 -PackagesDir" }

$dest = Join-Path $env:LOCALAPPDATA "Programs\node-v$NODE_VERSION"
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
$stage = Join-Path $env:TEMP "mk-node-extract"
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
Expand-ZipTo $zip $stage
$inner = Get-ChildItem $stage | Select-Object -First 1
Move-Item $inner.FullName $dest
Add-UserPath $dest
if (-not (Test-Have 'node')) {
  Write-Warn "当前窗口可能还没有 node。关掉 PowerShell 再开一次，或先: `$env:Path = '$dest;' + `$env:Path"
} else {
  Write-Log (node --version)
}
