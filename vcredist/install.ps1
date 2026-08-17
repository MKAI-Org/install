# Microsoft VC++ Redistributable x64/arm64. Needs admin. Silent if possible.
param([string]$PackagesDir)
$Root = Split-Path $PSScriptRoot -Parent
. "$Root\lib\common.ps1"
Use-PackagesDir $PackagesDir

$plat = Get-PlatformId
if ($plat -eq 'windows-arm64') {
  $name = 'vc_redist.arm64.exe'
  $url = 'https://aka.ms/vs/17/release/vc_redist.arm64.exe'
} else {
  $name = 'vc_redist.x64.exe'
  $url = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
}

$exe = Ensure-Package -App 'vcredist' -File $name -Urls @($url)
if (-not $exe) { throw "VC++ 下载失败。没网就把 $name 放到 vcredist\packages 或 -PackagesDir" }

Write-Log "安装 VC++ 运行库（可能弹出 UAC）"
$p = Start-Process -FilePath $exe -ArgumentList '/install','/quiet','/norestart' -Wait -PassThru
if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 1638 -and $p.ExitCode -ne 3010) {
  Write-Warn "静默安装失败 exit=$($p.ExitCode)。双击 $exe 手动装。"
  exit $p.ExitCode
}
Write-Log "VC++ 运行库 OK"
