# Git for Windows MinGit. PS 5.1.
param([string]$PackagesDir)
$ErrorActionPreference = 'Stop'
if (-not $PSScriptRoot) { throw 'Run with powershell.exe -File' }
$Root = Split-Path -Parent $PSScriptRoot
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
if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
MkExpandZip $zip $dest
Add-UserPath (Join-Path $dest 'cmd')
$usr = Join-Path $dest 'usr\bin'
if (Test-Path -LiteralPath $usr) { Add-UserPath $usr }
Write-Log "Git -> $dest"
