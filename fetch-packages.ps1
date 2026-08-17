# Fill packages\ from R2 (China) then official mirrors. For USB copy to offline PCs.
$Root = $PSScriptRoot
. "$Root\lib\common.ps1"
$v = Get-Versions

New-Item -ItemType Directory -Force -Path `
  (Join-Path $Root 'codex\packages'), `
  (Join-Path $Root 'claude-code\packages'), `
  (Join-Path $Root 'node\packages'), `
  (Join-Path $Root 'git\packages'), `
  (Join-Path $Root 'vcredist\packages') | Out-Null

function Pull([string]$Dest, [string[]]$Urls) {
  if (Test-Path $Dest) { Write-Log "已有 $(Split-Path $Dest -Leaf)"; return }
  [void](Save-Download -Dest $Dest -Urls $Urls)
}

$tag = $v['CODEX_TAG']
foreach ($asset in @(
    'codex-x86_64-pc-windows-msvc.exe.zip',
    'codex-aarch64-pc-windows-msvc.exe.zip',
    'codex-aarch64-apple-darwin.tar.gz',
    'codex-x86_64-apple-darwin.tar.gz',
    'codex-aarch64-apple-darwin.dmg',
    'codex-windows-sandbox-setup-x86_64-pc-windows-msvc.exe.zip'
  )) {
  $rel = "openai/codex/releases/download/$tag/$asset"
  Pull (Join-Path $Root "codex\packages\$asset") (@((Get-R2Url 'codex' $asset) + (Get-GitHubUrls $rel)))
}

$gcs = $v['CLAUDE_GCS']
$cv = $v['CLAUDE_VERSION']
Pull (Join-Path $Root 'claude-code\packages\claude.exe') @(
  (Get-R2Url 'claude-code' 'claude.exe'),
  "$gcs/$cv/win32-x64/claude.exe"
)
Pull (Join-Path $Root 'claude-code\packages\claude-darwin-arm64') @(
  (Get-R2Url 'claude-code' 'claude-darwin-arm64'),
  "$gcs/$cv/darwin-arm64/claude"
)

$nv = $v['NODE_VERSION']
$nodeZip = "node-v$nv-win-x64.zip"
Pull (Join-Path $Root "node\packages\$nodeZip") @(
  (Get-R2Url 'node' $nodeZip),
  "https://npmmirror.com/mirrors/node/v$nv/$nodeZip"
)

$gv = $v['GIT_MINGIT_VERSION']
$zipName = "MinGit-$gv-64-bit.zip"
$grel = "git-for-windows/git/releases/download/v$gv.windows.1/$zipName"
Pull (Join-Path $Root "git\packages\$zipName") (@((Get-R2Url 'git' $zipName) + (Get-GitHubUrls $grel)))

Pull (Join-Path $Root 'vcredist\packages\vc_redist.x64.exe') @(
  (Get-R2Url 'vcredist' 'vc_redist.x64.exe'),
  'https://aka.ms/vs/17/release/vc_redist.x64.exe'
)
Write-Log "完成。拷整个 install 目录到没网的电脑。"
