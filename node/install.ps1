# Node 22. PS 5.1. Local / R2 / npmmirror.
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
if (-not $PSScriptRoot) { throw 'Run with powershell.exe -File' }
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'lib\common.ps1')
MkUsePackagesDir $PackagesDir
$ver = Get-Versions
$NODE_VERSION = $ver['NODE_VERSION']

if (Test-Have 'node') {
  $major = node -p "process.versions.node.split('.')[0]"
  if ([int]$major -ge 20) {
    Write-Log ('node already ' + (node --version))
    exit 0
  }
  Write-Warn "node too old, install $NODE_VERSION"
}

$plat = Get-PlatformId
if ($plat -eq 'windows-arm64') { $zipName = "node-v$NODE_VERSION-win-arm64.zip" }
else { $zipName = "node-v$NODE_VERSION-win-x64.zip" }

$zip = MkEnsurePackage -App 'node' -File $zipName -Urls @(
  "https://npmmirror.com/mirrors/node/v$NODE_VERSION/$zipName",
  "https://cdn.npmmirror.com/binaries/node/v$NODE_VERSION/$zipName",
  "https://nodejs.org/dist/v$NODE_VERSION/$zipName"
)
if (-not $zip) { throw "Node download failed. Put $zipName in node\packages" }

$dest = Join-Path $env:LOCALAPPDATA "Programs\node-v$NODE_VERSION"
if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
$stage = Join-Path $env:TEMP 'mk-node-extract'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
MkExpandZip $zip $stage
$inner = Get-ChildItem -LiteralPath $stage | Select-Object -First 1
Move-Item -LiteralPath $inner.FullName -Destination $dest
Add-UserPath $dest
if (-not (Test-Have 'node')) {
  Write-Warn "node is in $dest . Open a new PowerShell."
} else {
  Write-Log (node --version)
}
