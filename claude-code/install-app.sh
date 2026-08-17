#!/usr/bin/env bash
# Claude 桌面客户端（Mac dmg）。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/lib/common.sh"
load_versions
mk_parse "$@"

[[ "$(uname -s)" == "Darwin" ]] || die "Linux 桌面见官方文档。Windows 用 install-app.ps1。"

dmg="$(find_package_glob claude-code '*.dmg' || true)"
if [[ -z "${dmg:-}" ]]; then
  ensure_package claude-code "Claude.dmg" \
    "https://claude.ai/api/desktop/darwin/universal/dmg/latest/redirect" \
    || die "桌面 dmg 下载失败。没网就把 Claude.dmg 放到 claude-code/packages 或 MK_PACKAGES=目录"
  dmg="$PKG"
fi

mnt="$(mktemp -d /tmp/claude-dmg-XXXX)"
hdiutil attach -nobrowse -quiet -mountpoint "$mnt" "$dmg"
app="$(find "$mnt" -maxdepth 2 -name '*.app' | head -n 1)"
if [[ -z "$app" ]]; then
  hdiutil detach "$mnt" -quiet || true
  die "dmg 里没有 .app"
fi
rm -rf "/Applications/$(basename "$app")"
cp -R "$app" /Applications/
hdiutil detach "$mnt" -quiet || true
log "已安装 /Applications/$(basename "$app")"
