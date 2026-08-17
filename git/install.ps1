# Git for Windows via MinGit zip. Local / R2 first.
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
. (Join-Path $Root 'lib\common.ps1')
MkUsePackagesDir $PackagesDir
$ver = Get-Versions
$gver = $ver['GIT_MINGIT_VERSION']

if (Test-Have 'git') {
  Write-Log (git --version)
  exit 0
}

$zipName = "MinGit-$gver-64-bit.zip"
if ((Get-PlatformId) -eq 'windows-arm64') { $zipName = "MinGit-$gver-arm64.zip" }
$rel = "git-for-windows/git/releases/download/v$gver.windows.1/$zipName"
$zip = MkEnsurePackage -App 'git' -File $zipName -Urls (MkGitHubUrls $rel)
if (-not $zip) { throw "Git download failed. Put $zipName in git\packages" }

$dest = Join-Path $env:LOCALAPPDATA 'Programs\MinGit'
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
MkExpandZip $zip $dest
$cmd = Join-Path $dest 'cmd'
Add-UserPath $cmd
if (Test-Path (Join-Path $dest 'usr\bin')) {
  Add-UserPath (Join-Path $dest 'usr\bin')
}
Write-Log "Git -> $dest"
