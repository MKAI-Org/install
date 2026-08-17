# Shared helpers. Dot-source from each app: . "$Root\lib\common.ps1"
$ErrorActionPreference = 'Stop'

function Write-Log([string]$Message) { Write-Host "==> $Message" }
function Write-Warn([string]$Message) { Write-Host "!!  $Message" -ForegroundColor Yellow }
function Test-Have([string]$Name) { return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Get-PlatformId {
  $arch = $env:PROCESSOR_ARCHITECTURE
  if ($arch -eq 'ARM64') { return 'windows-arm64' }
  return 'windows-x64'
}

function Get-UserBin {
  $p = Join-Path $env:LOCALAPPDATA 'Programs\mk-bin'
  New-Item -ItemType Directory -Force -Path $p | Out-Null
  return $p
}

function Add-UserPath([string]$Bin) {
  $user = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not $user) { $user = '' }
  $parts = $user.Split(';') | Where-Object { $_ -and $_ -ne $Bin }
  if ($user -notlike "*$Bin*") {
    $new = (@($Bin) + $parts) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $new, 'User')
    Write-Log "已加入用户 PATH: $Bin （新开 PowerShell 生效）"
  }
  if ($env:Path -notlike "*$Bin*") {
    $env:Path = "$Bin;$env:Path"
  }
}

function Get-Versions {
  $file = Join-Path $Root 'lib\versions.env'
  $map = @{}
  Get-Content $file | ForEach-Object {
    if ($_ -match '^([A-Z0-9_]+)=(.*)$') { $map[$matches[1]] = $matches[2] }
  }
  return $map
}

function Get-R2Url([string]$App, [string]$File) {
  $ver = Get-Versions
  $base = $ver['R2_BASE']
  if (-not $base) { $base = 'https://dl.mkstore.life' }
  return "$($base.TrimEnd('/'))/$App/$File"
}

function Get-PackageSearchDirs([string]$App) {
  $dirs = New-Object System.Collections.Generic.List[string]
  $extra = $env:MK_PACKAGES
  if ($extra) {
    foreach ($p in @(
        $extra,
        (Join-Path $extra $App),
        (Join-Path $extra "$App\packages"),
        (Join-Path $extra "packages\$App"),
        (Join-Path $extra 'packages')
      )) { $dirs.Add($p) }
  }
  foreach ($p in @(
      (Join-Path $Root "$App\packages"),
      (Join-Path $Root "packages\$App"),
      (Join-Path (Get-Location) "$App\packages"),
      (Join-Path (Get-Location) 'packages'),
      (Join-Path $env:USERPROFILE "Desktop\install\$App\packages"),
      (Join-Path $env:USERPROFILE "Downloads\install\$App\packages")
    )) { $dirs.Add($p) }
  Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | ForEach-Object {
    $drive = $_.Root
    if (-not $drive) { return }
    foreach ($p in @(
        (Join-Path $drive "$App\packages"),
        (Join-Path $drive "install\$App\packages"),
        (Join-Path $drive "packages\$App"),
        (Join-Path $drive 'packages'),
        (Join-Path $drive 'install')
      )) { $dirs.Add($p) }
  }
  return $dirs
}

function Find-LocalPackage([string]$Dir, [string]$Pattern) {
  if (-not (Test-Path $Dir)) { return $null }
  $hit = Get-ChildItem -Path $Dir -Filter $Pattern -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($hit) { return $hit.FullName }
  return $null
}

function Find-PackageFile([string]$App, [string]$File) {
  foreach ($d in Get-PackageSearchDirs $App) {
    $p = Join-Path $d $File
    if (Test-Path -LiteralPath $p) { return $p }
  }
  return $null
}

function Find-PackageGlob([string]$App, [string]$Pattern) {
  foreach ($d in Get-PackageSearchDirs $App) {
    $hit = Find-LocalPackage $d $Pattern
    if ($hit) { return $hit }
  }
  return $null
}

function Save-Download {
  param(
    [Parameter(Mandatory = $true)][string]$Dest,
    [Parameter(Mandatory = $true)][string[]]$Urls
  )
  $dir = Split-Path $Dest -Parent
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  foreach ($url in $Urls) {
    if (-not $url) { continue }
    Write-Log "下载 $url"
    try {
      $tmp = "$Dest.part"
      Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -TimeoutSec 600
      Move-Item -Force $tmp $Dest
      return $true
    } catch {
      Write-Warn "失败: $url"
      Remove-Item -Force "$Dest.part" -ErrorAction SilentlyContinue
    }
  }
  return $false
}

function Ensure-Package {
  param(
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$File,
    [string[]]$Urls = @()
  )
  $hit = Find-PackageFile $App $File
  if ($hit) {
    Write-Log "本地包 $hit"
    return $hit
  }
  $dest = Join-Path $Root "$App\packages\$File"
  $all = @((Get-R2Url $App $File) + @($Urls))
  $ok = Save-Download -Dest $dest -Urls $all
  if (-not $ok) { return $null }
  return $dest
}

function Get-GitHubUrls([string]$Path) {
  return @(
    "https://ghfast.top/https://github.com/$Path",
    "https://gh-proxy.com/https://github.com/$Path",
    "https://mirror.ghproxy.com/https://github.com/$Path",
    "https://github.com/$Path"
  )
}

function Expand-ZipTo([string]$Zip, [string]$Dest) {
  New-Item -ItemType Directory -Force -Path $Dest | Out-Null
  Expand-Archive -LiteralPath $Zip -DestinationPath $Dest -Force
}

function Use-PackagesDir([string]$PackagesDir) {
  if ($PackagesDir) { $env:MK_PACKAGES = $PackagesDir }
}
