#!/usr/bin/env bash
# Codex 桌面客户端（Mac = GitHub dmg；Linux 无独立客户端，用 CLI）。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/lib/common.sh"
load_versions
mk_parse "$@"

[[ "$(uname -s)" == "Darwin" ]] || die "Linux 没有 Codex 桌面包，用 ./install.sh 装 CLI。Windows 用 install-app.ps1。"

plat="$(platform_id)"
if [[ "$plat" == "darwin-arm64" ]]; then
  asset="codex-aarch64-apple-darwin.dmg"
else
  asset="codex-x86_64-apple-darwin.dmg"
fi

gh="openai/codex/releases/download/${CODEX_TAG}/$asset"
ensure_package codex "$asset" \
  "https://ghfast.top/https://github.com/$gh" \
  "https://gh-proxy.com/https://github.com/$gh" \
  "https://mirror.ghproxy.com/https://github.com/$gh" \
  "https://github.com/$gh" \
  || die "dmg 下载失败。没网就把 $asset 放到 codex/packages 或 MK_PACKAGES=目录"

dmg="$PKG"
mnt="$(mktemp -d /tmp/codex-dmg-XXXX)"
log "挂载 $dmg"
hdiutil attach -nobrowse -quiet -mountpoint "$mnt" "$dmg"
app="$(find "$mnt" -maxdepth 2 -name '*.app' | head -n 1)"
if [[ -z "$app" ]]; then
  hdiutil detach "$mnt" -quiet || true
  die "dmg 里没有 .app"
fi
log "拷到 /Applications"
rm -rf "/Applications/$(basename "$app")"
cp -R "$app" /Applications/
hdiutil detach "$mnt" -quiet || true
log "已安装 /Applications/$(basename "$app")"
log "配 key 仍用 ./configure.sh （CLI 和 App 共用 ~/.codex）"
