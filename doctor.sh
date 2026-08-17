#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/common.sh"
load_versions
log "OS=$(uname -s) arch=$(uname -m)"
have node && log "node $(node --version)" || warn "node 无  → node/install.sh"
have git && log "git $(git --version)" || warn "git 无   → git/install.sh"
have codex && log "codex ok" || warn "codex 无 → codex/install.sh"
have claude && log "claude ok" || warn "claude 无 → claude-code/install.sh"
if curl -fsI -A 'mk-install/1' --connect-timeout 8 "${R2_BASE%/}/vcredist/vc_redist.x64.exe" >/dev/null 2>&1; then
  log "R2 $R2_BASE 可达"
else
  warn "R2 不可达。有本地包就继续；否则需要网或 U 盘"
fi
ls "$ROOT/codex/packages" 2>/dev/null | head || warn "codex/packages 空。有网走 R2；没网把包放到 packages 或 MK_PACKAGES="
