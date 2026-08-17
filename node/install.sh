#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../lib/common.sh
. "$ROOT/lib/common.sh"
load_versions
mk_parse "$@"

if have node; then
  major="$(node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo 0)"
  if [[ "$major" -ge 20 ]]; then
    log "node 已存在 $(node --version)"
    exit 0
  fi
  warn "node 太旧 $(node --version)，继续装 22"
fi

plat="$(platform_id)"
case "$plat" in
  darwin-arm64) file="node-v${NODE_VERSION}-darwin-arm64.tar.gz" ;;
  darwin-x64) file="node-v${NODE_VERSION}-darwin-x64.tar.gz" ;;
  linux-arm64) file="node-v${NODE_VERSION}-linux-arm64.tar.gz" ;;
  linux-x64) file="node-v${NODE_VERSION}-linux-x64.tar.gz" ;;
  *) die "请用 node/install.ps1" ;;
esac

if ensure_package node "$file" \
    "https://npmmirror.com/mirrors/node/v${NODE_VERSION}/$file" \
    "https://cdn.npmmirror.com/binaries/node/v${NODE_VERSION}/$file" \
    "https://nodejs.org/dist/v${NODE_VERSION}/$file"; then
  tarball="$PKG"
  dest_dir="$HOME/.local/node-v${NODE_VERSION}"
  rm -rf "$dest_dir"
  mkdir -p "$HOME/.local"
  tar -xzf "$tarball" -C "$HOME/.local"
  extracted="$(tar -tzf "$tarball" | head -n 1 | cut -d/ -f1)"
  mv "$HOME/.local/$extracted" "$dest_dir"
  ensure_path_unix "$dest_dir/bin"
  export PATH="$dest_dir/bin:$PATH"
  have node || die "node 仍不在 PATH"
  log "node $(node --version)"
  exit 0
fi

if have brew; then
  log "Homebrew 安装 node@22"
  brew install node@22 || brew install node
  log "node $(node --version 2>/dev/null || echo 装完请新开终端)"
  exit 0
fi

die "Node 下载失败。没网就把安装包放到 node/packages 或 MK_PACKAGES=目录"
