# VC++ redistributable. PS 5.1. May show UAC.
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
if (-not $PSScriptRoot) { throw 'Run with powershell.exe -File' }
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'lib\common.ps1')
MkUsePackagesDir $PackagesDir

$plat = Get-PlatformId
if ($plat -eq 'windows-arm64') {
  $name = 'vc_redist.arm64.exe'
  $url = 'https://aka.ms/vs/17/release/vc_redist.arm64.exe'
} else {
  $name = 'vc_redist.x64.exe'
  $url = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
}

$exe = MkEnsurePackage -App 'vcredist' -File $name -Urls @($url)
if (-not $exe) { throw "VC++ download failed. Put $name in vcredist\packages" }

Write-Log "install VC++ (UAC may pop)"
$p = Start-Process -FilePath $exe -ArgumentList '/install','/quiet','/norestart' -Wait -PassThru
if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 1638 -and $p.ExitCode -ne 3010) {
  Write-Warn "silent install failed exit=$($p.ExitCode). Double-click $exe"
  exit $p.ExitCode
}
Write-Log "VC++ OK"
