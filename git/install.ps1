# Git for Windows via MinGit zip. Local / R2 first.
param([string]$PackagesDir)
$Root = Split-Path $PSScriptRoot -Parent
. "$Root\lib\common.ps1"
Use-PackagesDir $PackagesDir
$ver = Get-Versions
$gver = $ver['GIT_MINGIT_VERSION']

if (Test-Have 'git') {
  Write-Log (git --version)
  exit 0
}

$zipName = "MinGit-$gver-64-bit.zip"
if ((Get-PlatformId) -eq 'windows-arm64') { $zipName = "MinGit-$gver-arm64.zip" }
$rel = "git-for-windows/git/releases/download/v$gver.windows.1/$zipName"
$zip = Ensure-Package -App 'git' -File $zipName -Urls (Get-GitHubUrls $rel)
if (-not $zip) { throw "Git 下载失败。没网就把 $zipName 放到 git\packages 或 -PackagesDir" }

$dest = Join-Path $env:LOCALAPPDATA 'Programs\MinGit'
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
Expand-ZipTo $zip $dest
$cmd = Join-Path $dest 'cmd'
Add-UserPath $cmd
if (Test-Path (Join-Path $dest 'usr\bin')) {
  Add-UserPath (Join-Path $dest 'usr\bin')
}
Write-Log "Git 装到 $dest 。新开 PowerShell 后 git --version"
