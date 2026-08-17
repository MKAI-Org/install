#!/usr/bin/env bash
# 把 R2 / 官方源的安装包填进各软件的 packages/，给没网的机器拷走。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT/lib/common.sh"
load_versions

ALL=0
[[ "${1:-}" == "--all" ]] && ALL=1

mkdir -p \
  "$ROOT/codex/packages" \
  "$ROOT/claude-code/packages" \
  "$ROOT/node/packages" \
  "$ROOT/git/packages" \
  "$ROOT/vcredist/packages"

pull() {
  local dest="$1"
  shift
  if [[ -f "$dest" ]]; then
    log "已有 $(basename "$dest")"
    return 0
  fi
  download "$dest" "$@" || warn "跳过 $(basename "$dest")"
}

log "Codex CLI + Mac dmg  tag=$CODEX_TAG"
for asset in \
  codex-x86_64-pc-windows-msvc.exe.zip \
  codex-aarch64-pc-windows-msvc.exe.zip \
  codex-aarch64-apple-darwin.tar.gz \
  codex-x86_64-apple-darwin.tar.gz \
  codex-x86_64-unknown-linux-musl.tar.gz \
  codex-aarch64-unknown-linux-musl.tar.gz \
  codex-aarch64-apple-darwin.dmg \
  codex-x86_64-apple-darwin.dmg \
  codex-windows-sandbox-setup-x86_64-pc-windows-msvc.exe.zip
do
  gh="openai/codex/releases/download/${CODEX_TAG}/$asset"
  pull "$ROOT/codex/packages/$asset" \
    "$(r2_url codex "$asset")" \
    "https://ghfast.top/https://github.com/$gh" \
    "https://gh-proxy.com/https://github.com/$gh" \
    "https://github.com/$gh"
done

log "Claude Code $CLAUDE_VERSION"
pull "$ROOT/claude-code/packages/claude.exe" \
  "$(r2_url claude-code claude.exe)" \
  "${CLAUDE_GCS}/${CLAUDE_VERSION}/win32-x64/claude.exe"
pull "$ROOT/claude-code/packages/claude-win32-arm64.exe" \
  "$(r2_url claude-code claude-win32-arm64.exe)" \
  "${CLAUDE_GCS}/${CLAUDE_VERSION}/win32-arm64/claude.exe"
pull "$ROOT/claude-code/packages/claude-darwin-arm64" \
  "$(r2_url claude-code claude-darwin-arm64)" \
  "${CLAUDE_GCS}/${CLAUDE_VERSION}/darwin-arm64/claude"
pull "$ROOT/claude-code/packages/claude-darwin-x64" \
  "$(r2_url claude-code claude-darwin-x64)" \
  "${CLAUDE_GCS}/${CLAUDE_VERSION}/darwin-x64/claude"
if [[ "$ALL" -eq 1 ]]; then
  pull "$ROOT/claude-code/packages/claude-linux-x64" \
    "$(r2_url claude-code claude-linux-x64)" \
    "${CLAUDE_GCS}/${CLAUDE_VERSION}/linux-x64/claude"
  pull "$ROOT/claude-code/packages/claude-linux-arm64" \
    "$(r2_url claude-code claude-linux-arm64)" \
    "${CLAUDE_GCS}/${CLAUDE_VERSION}/linux-arm64/claude"
fi
pull "$ROOT/claude-code/packages/Claude.dmg" \
  "$(r2_url claude-code Claude.dmg)" \
  "https://claude.ai/api/desktop/darwin/universal/dmg/latest/redirect"
pull "$ROOT/claude-code/packages/Claude.msix" \
  "$(r2_url claude-code Claude.msix)" \
  "https://claude.ai/api/desktop/win32/x64/msix/latest/redirect"

log "Node $NODE_VERSION"
for f in \
  "node-v${NODE_VERSION}-win-x64.zip" \
  "node-v${NODE_VERSION}-win-arm64.zip" \
  "node-v${NODE_VERSION}-darwin-arm64.tar.gz" \
  "node-v${NODE_VERSION}-darwin-x64.tar.gz"
do
  pull "$ROOT/node/packages/$f" \
    "$(r2_url node "$f")" \
    "https://npmmirror.com/mirrors/node/v${NODE_VERSION}/$f" \
    "https://nodejs.org/dist/v${NODE_VERSION}/$f"
done
if [[ "$ALL" -eq 1 ]]; then
  for f in "node-v${NODE_VERSION}-linux-x64.tar.gz" "node-v${NODE_VERSION}-linux-arm64.tar.gz"; do
    pull "$ROOT/node/packages/$f" \
      "$(r2_url node "$f")" \
      "https://npmmirror.com/mirrors/node/v${NODE_VERSION}/$f"
  done
fi

log "MinGit $GIT_MINGIT_VERSION"
gh="git-for-windows/git/releases/download/v${GIT_MINGIT_VERSION}.windows.1/MinGit-${GIT_MINGIT_VERSION}-64-bit.zip"
pull "$ROOT/git/packages/MinGit-${GIT_MINGIT_VERSION}-64-bit.zip" \
  "$(r2_url git "MinGit-${GIT_MINGIT_VERSION}-64-bit.zip")" \
  "https://ghfast.top/https://github.com/$gh" \
  "https://github.com/$gh"

log "VC++ redist"
pull "$ROOT/vcredist/packages/vc_redist.x64.exe" \
  "$(r2_url vcredist vc_redist.x64.exe)" \
  "https://aka.ms/vs/17/release/vc_redist.x64.exe"

log "完成。没网的机器把整个 install 拷走，或只拷 packages。"
