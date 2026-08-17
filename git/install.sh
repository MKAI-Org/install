#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/lib/common.sh"
load_versions
mk_parse "$@"

if have git; then
  log "git 已存在 $(git --version)"
  exit 0
fi
if have brew; then
  brew install git
  exit 0
fi
if have apt-get; then
  sudo apt-get update && sudo apt-get install -y git
  exit 0
fi
die "没有 git。Mac 装 Xcode CLT 或 brew；Linux 用发行版包管理器。"
