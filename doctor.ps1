$Root = $PSScriptRoot
. "$Root\lib\common.ps1"
Write-Log ("OS=" + [Environment]::OSVersion.VersionString + " " + (Get-PlatformId))
if (Test-Have 'node') { Write-Log ("node " + (node --version)) } else { Write-Warn "node 无  → node\install.ps1" }
if (Test-Have 'git') { Write-Log (git --version) } else { Write-Warn "git 无   → git\install.ps1" }
if (Test-Have 'codex') { Write-Log "codex ok" } else { Write-Warn "codex 无 → codex\install.ps1" }
if (Test-Have 'claude') { Write-Log "claude ok" } else { Write-Warn "claude 无 → claude-code\install.ps1" }
$pkg = Join-Path $Root 'codex\packages'
if (-not (Test-Path $pkg) -or -not (Get-ChildItem $pkg -ErrorAction SilentlyContinue)) {
  Write-Warn "codex\packages 空。国内请先在能翻墙的电脑跑 fetch-packages.ps1 再拷过来。"
}
