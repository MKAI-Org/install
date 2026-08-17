# PowerShell 5.1 baseline. Dot-source: . (Join-Path $Root 'lib\common.ps1')
$ErrorActionPreference = 'Stop'

if (-not $PSVersionTable -or $PSVersionTable.PSVersion.Major -lt 5) {
  throw "Need Windows PowerShell 5.1 or newer"
}

function MkEnableTls {
  try {
    $cur = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol = $cur -bor [Net.SecurityProtocolType]::Tls12
  } catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  }
}
MkEnableTls

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
    Write-Log "PATH added: $Bin (open a new PowerShell)"
  }
  if ($env:Path -notlike "*$Bin*") {
    $env:Path = "$Bin;$env:Path"
  }
}

function Get-Versions {
  $file = Join-Path $Root 'lib\versions.env'
  $map = @{}
  Get-Content -LiteralPath $file | ForEach-Object {
    if ($_ -match '^([A-Z0-9_]+)=(.*)$') { $map[$matches[1]] = $matches[2] }
  }
  return $map
}

function MkR2Url([string]$App, [string]$File) {
  $ver = Get-Versions
  $base = $ver['R2_BASE']
  if (-not $base) { $base = 'https://dl.mkstore.life' }
  return ($base.TrimEnd('/') + '/' + $App + '/' + $File)
}

function MkSearchDirs([string]$App) {
  $dirs = New-Object System.Collections.Generic.List[string]
  $extra = $env:MK_PACKAGES
  if ($extra) {
    $dirs.Add($extra)
    $dirs.Add((Join-Path $extra $App))
    $dirs.Add((Join-Path $extra (Join-Path $App 'packages')))
    $dirs.Add((Join-Path $extra (Join-Path 'packages' $App)))
    $dirs.Add((Join-Path $extra 'packages'))
  }
  $dirs.Add((Join-Path $Root (Join-Path $App 'packages')))
  $dirs.Add((Join-Path $Root (Join-Path 'packages' $App)))
  $here = (Get-Location).Path
  $dirs.Add((Join-Path $here (Join-Path $App 'packages')))
  $dirs.Add((Join-Path $here 'packages'))
  $dirs.Add((Join-Path $env:USERPROFILE (Join-Path 'Desktop' (Join-Path 'install' (Join-Path $App 'packages')))))
  $dirs.Add((Join-Path $env:USERPROFILE (Join-Path 'Downloads' (Join-Path 'install' (Join-Path $App 'packages')))))
  Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | ForEach-Object {
    $drive = $_.Root
    if (-not $drive) { return }
    $dirs.Add((Join-Path $drive (Join-Path $App 'packages')))
    $dirs.Add((Join-Path $drive (Join-Path 'install' (Join-Path $App 'packages'))))
    $dirs.Add((Join-Path $drive (Join-Path 'packages' $App)))
    $dirs.Add((Join-Path $drive 'packages'))
    $dirs.Add((Join-Path $drive 'install'))
  }
  return $dirs
}

function MkFindLocal([string]$Dir, [string]$Pattern) {
  if (-not (Test-Path -LiteralPath $Dir)) { return $null }
  $hit = Get-ChildItem -LiteralPath $Dir -Filter $Pattern -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($hit) { return $hit.FullName }
  return $null
}

function MkFindPackage([string]$App, [string]$File) {
  foreach ($d in MkSearchDirs $App) {
    $p = Join-Path $d $File
    if (Test-Path -LiteralPath $p) { return $p }
  }
  return $null
}

function MkFindPackageGlob([string]$App, [string]$Pattern) {
  foreach ($d in MkSearchDirs $App) {
    $hit = MkFindLocal $d $Pattern
    if ($hit) { return $hit }
  }
  return $null
}

function MkJoinUrls {
  $all = New-Object System.Collections.Generic.List[string]
  foreach ($item in $args) {
    foreach ($u in @($item)) {
      if ($u) { $all.Add([string]$u) }
    }
  }
  return $all.ToArray()
}

function MkDownloadOne([string]$Url, [string]$Dest) {
  $req = [Net.WebRequest]::Create($Url)
  $req.Timeout = 600000
  if ($req -is [Net.HttpWebRequest]) {
    $req.Method = 'GET'
    $req.UserAgent = 'mk-install/1'
    $req.AllowAutoRedirect = $true
    $req.ReadWriteTimeout = 600000
    $req.AutomaticDecompression = [Net.DecompressionMethods]::None
  }
  $resp = $req.GetResponse()
  try {
    $src = $resp.GetResponseStream()
    $fs = [IO.File]::Create($Dest)
    try {
      $buf = New-Object byte[] 81920
      while (($n = $src.Read($buf, 0, $buf.Length)) -gt 0) {
        $fs.Write($buf, 0, $n)
      }
    } finally {
      $fs.Close()
    }
  } finally {
    $resp.Close()
  }
}

function MkDownload {
  param(
    [Parameter(Mandatory = $true)][string]$Dest,
    [Parameter(Mandatory = $true)]$Urls
  )
  $dir = Split-Path $Dest -Parent
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  MkEnableTls
  foreach ($url in @($Urls)) {
    if (-not $url) { continue }
    $s = [string]$url
    if ($s -notmatch '^https?://') { continue }
    Write-Log "download $s"
    $tmp = $Dest + '.part'
    try {
      if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
      MkDownloadOne $s $tmp
      if (-not (Test-Path -LiteralPath $tmp)) { throw 'no file' }
      if ((Get-Item -LiteralPath $tmp).Length -lt 16) { throw 'too small' }
      Move-Item -Force -LiteralPath $tmp -Destination $Dest
      return $true
    } catch {
      Write-Warn ("fail: " + $s)
      if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    }
  }
  return $false
}

function MkEnsurePackage {
  param(
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$File,
    $Urls = @()
  )
  $hit = MkFindPackage $App $File
  if ($hit) {
    Write-Log "local $hit"
    return $hit
  }
  $dest = Join-Path $Root (Join-Path $App (Join-Path 'packages' $File))
  $ok = MkDownload -Dest $dest -Urls (MkJoinUrls (MkR2Url $App $File) $Urls)
  if (-not $ok) { return $null }
  return $dest
}

function MkGitHubUrls([string]$Path) {
  return @(
    ("https://ghfast.top/https://github.com/" + $Path),
    ("https://gh-proxy.com/https://github.com/" + $Path),
    ("https://mirror.ghproxy.com/https://github.com/" + $Path),
    ("https://github.com/" + $Path)
  )
}

function MkExpandZip([string]$Zip, [string]$Dest) {
  New-Item -ItemType Directory -Force -Path $Dest | Out-Null
  try {
    Expand-Archive -LiteralPath $Zip -DestinationPath $Dest -Force
  } catch {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($Zip, $Dest)
  }
}

function MkUsePackagesDir([string]$PackagesDir) {
  if ($PackagesDir) { $env:MK_PACKAGES = $PackagesDir }
}

function MkWriteUtf8([string]$Path, [string]$Text) {
  $enc = New-Object System.Text.UTF8Encoding $false
  [IO.File]::WriteAllText($Path, $Text, $enc)
}

function MkIsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $prin = New-Object Security.Principal.WindowsPrincipal($id)
  return $prin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function MkEnsureAdmin {
  if (MkIsAdmin) { return }
  $ps1 = $PSCommandPath
  if (-not $ps1) { $ps1 = $MyInvocation.MyCommand.Path }
  if (-not $ps1) { throw 'Need Administrator. Right-click bat -> Run as administrator' }
  Write-Log 'UAC: Administrator required'
  $exe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $arg = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "' + $ps1 + '"'
  $p = Start-Process -FilePath $exe -Verb RunAs -ArgumentList $arg -Wait -PassThru
  if ($p) { exit $p.ExitCode }
  exit 0
}

function MkInstallMsix([string]$Msix) {
  if (-not (Get-Command Add-AppxPackage -ErrorAction SilentlyContinue)) {
    throw 'Need Windows 10+ (Add-AppxPackage missing)'
  }
  Write-Log ("install " + $Msix)
  $err = $null
  try {
    Add-AppxPackage -LiteralPath $Msix
    return
  } catch {
    $err = $_
    Write-Warn $err.Exception.Message
  }
  Write-Log 'retry as provisioned package (all users)'
  Add-AppxProvisionedPackage -Online -PackagePath $Msix -SkipLicense | Out-Null
}

$script:MkCommonLoaded = $true
