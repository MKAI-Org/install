#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/lib/common.sh"
load_versions
mk_parse "$@"

if have claude; then
  log "claude 已存在 $(claude --version 2>/dev/null | head -n 1 || echo ok)"
  exit 0
fi

if ! have git; then
  warn "没有 git，先装 ../git/install.sh （Claude Code 的 Bash 工具需要）"
  "$ROOT/git/install.sh" || warn "git 安装失败，Claude 仍可装，部分功能会弱"
fi

plat="$(platform_id)"
case "$plat" in
  darwin-arm64) gcs_plat="darwin-arm64"; binname="claude" ;;
  darwin-x64) gcs_plat="darwin-x64"; binname="claude" ;;
  linux-arm64) gcs_plat="linux-arm64"; binname="claude" ;;
  linux-x64) gcs_plat="linux-x64"; binname="claude" ;;
  *) die "Windows 用 install.ps1" ;;
esac

file="$binname-$gcs_plat"
hit="$(find_package_file claude-code "$file" || true)"
[[ -n "${hit:-}" ]] || hit="$(find_package_glob claude-code "$binname-$gcs_plat" || true)"
[[ -n "${hit:-}" ]] || hit="$(find_package_file claude-code "$binname" || true)"

if [[ -z "${hit:-}" ]]; then
  url="${CLAUDE_GCS}/${CLAUDE_VERSION}/${gcs_plat}/${binname}"
  ensure_package claude-code "$file" "$url" \
    || die "Claude Code 下载失败。没网就把包放到 claude-code/packages 或 MK_PACKAGES=目录"
  hit="$PKG"
fi

dest="$(user_bin)/claude"
cp "$hit" "$dest"
chmod_x "$dest"
ensure_path_unix "$(user_bin)"
hash -r || true
have claude || die "已放到 $dest ，请新开终端"
log "claude $(claude --version 2>/dev/null | head -n 1)"
log "配 key: $ROOT/claude-code/configure.sh --key ..."
