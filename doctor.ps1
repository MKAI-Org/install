$ErrorActionPreference = 'Stop'
if (-not $PSScriptRoot) { throw 'Run with powershell.exe -File' }
$Root = $PSScriptRoot
. (Join-Path $Root 'lib\common.ps1')
Write-Log ("OS=" + [Environment]::OSVersion.VersionString + " " + (Get-PlatformId))
if (Test-Have 'node') { Write-Log ("node " + (node --version)) } else { Write-Warn "no node -> node\install.bat" }
if (Test-Have 'git') { Write-Log (git --version) } else { Write-Warn "no git -> git\install.bat" }
if (Test-Have 'codex') { Write-Log "codex ok" } else { Write-Warn "no codex -> codex\install.bat" }
if (Test-Have 'claude') { Write-Log "claude ok" } else { Write-Warn "no claude -> claude-code\install.bat" }
