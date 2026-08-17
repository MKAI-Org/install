# Codex / ChatGPT desktop on Windows. Store often fails in China.
param([string]$PackagesDir)
$Root = Split-Path $PSScriptRoot -Parent
. "$Root\lib\common.ps1"
Use-PackagesDir $PackagesDir

$msix = Find-PackageGlob 'codex' 'ChatGPT*.msix'
if (-not $msix) { $msix = Find-PackageGlob 'codex' 'Codex*.msix' }
if ($msix) {
  Write-Log "安装本地 $msix"
  Add-AppxPackage -Path $msix
  Write-Log "客户端已装。登录用客户自己的 ChatGPT 账号，或配 CLI key: .\configure.ps1"
  exit 0
}

if (Test-Have 'winget') {
  Write-Log "尝试 winget Microsoft Store（国内经常失败）"
  try {
    winget install --id 9PLM9XGG6VKS -s msstore --accept-package-agreements --accept-source-agreements
    Write-Log "Store 客户端已装"
    exit 0
  } catch {
    Write-Warn $_
  }
}

Write-Warn "Windows 桌面客户端在国内很难从 Store 拉下来。"
Write-Warn "1) 先 .\install.ps1 装 CLI（不依赖 Store）"
Write-Warn "2) 有 MSIX 就放到 codex\packages 再跑本脚本"
Write-Warn "3) 装完 CLI 后可试: codex app"
exit 1
