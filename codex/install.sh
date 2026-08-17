#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/lib/common.sh"
load_versions
mk_parse "$@"

if have codex; then
  log "codex 已存在 $($(command -v codex) --version 2>/dev/null | head -n 1 || echo ok)"
  exit 0
fi

plat="$(platform_id)"
bin_dir="$(user_bin)"
case "$plat" in
  darwin-arm64) asset="codex-aarch64-apple-darwin.tar.gz" ;;
  darwin-x64) asset="codex-x86_64-apple-darwin.tar.gz" ;;
  linux-arm64) asset="codex-aarch64-unknown-linux-musl.tar.gz" ;;
  linux-x64) asset="codex-x86_64-unknown-linux-musl.tar.gz" ;;
  *) die "Windows 用 codex/install.ps1" ;;
esac

gh="openai/codex/releases/download/${CODEX_TAG}/$asset"
ensure_package codex "$asset" \
  "https://ghfast.top/https://github.com/$gh" \
  "https://gh-proxy.com/https://github.com/$gh" \
  "https://mirror.ghproxy.com/https://github.com/$gh" \
  "https://github.com/$gh" \
  || die "Codex CLI 下载失败。没网就把包放到 codex/packages 或 MK_PACKAGES=目录"

tarball="$PKG"
stage="$(mktemp -d)"
tar -xzf "$tarball" -C "$stage"
src="$(find "$stage" -type f \( -name 'codex' -o -name 'codex-*' \) | head -n 1)"
[[ -n "$src" ]] || die "压缩包里没有 codex 二进制"
chmod_x "$src"
cp "$src" "$bin_dir/codex"
ensure_path_unix "$bin_dir"
hash -r || true
have codex || die "codex 已拷到 $bin_dir/codex，请新开终端"
log "codex $(codex --version 2>/dev/null | head -n 1)"
log "配 key: $ROOT/codex/configure.sh --key ... --base-url ... --model ..."
