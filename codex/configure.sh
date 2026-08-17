#!/usr/bin/env bash
# 只写 key，不安装。可重复跑。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/lib/common.sh"

KEY=""
BASE=""
MODEL=""
WIRE="chat"
PROVIDER="custom"

usage() {
  cat <<'EOF'
Usage:
  ./configure.sh --key sk-xxx --base-url https://api.example.com/v1 --model deepseek-chat
  ./configure.sh --key sk-xxx --base-url https://api.openai.com/v1 --model gpt-5.4 --wire-api responses

写入 ~/.codex/config.toml ，并把 OPENAI_API_KEY 写进 ~/.zshrc（不打印 key）。
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key) KEY="${2:-}"; shift 2 ;;
    --base-url) BASE="${2:-}"; shift 2 ;;
    --model) MODEL="${2:-}"; shift 2 ;;
    --wire-api) WIRE="${2:-}"; shift 2 ;;
    --provider) PROVIDER="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown arg $1" ;;
  esac
done

[[ -n "$KEY" && -n "$BASE" && -n "$MODEL" ]] || { usage; exit 1; }

mkdir -p "$HOME/.codex"
cfg="$HOME/.codex/config.toml"
cat > "$cfg" <<EOF
model = "$MODEL"
model_provider = "$PROVIDER"

[model_providers.$PROVIDER]
name = "$PROVIDER"
base_url = "$BASE"
env_key = "OPENAI_API_KEY"
wire_api = "$WIRE"
EOF
log "已写 $cfg"

line="export OPENAI_API_KEY=\"$KEY\""
for rc in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bashrc" "$HOME/.profile"; do
  [[ -f "$rc" ]] || continue
  if grep -q 'export OPENAI_API_KEY=' "$rc"; then
    # portable replace
    tmp="$rc.mk.tmp"
    grep -v 'export OPENAI_API_KEY=' "$rc" > "$tmp" || true
    mv "$tmp" "$rc"
  fi
done
rc="$HOME/.zshrc"
[[ -f "$HOME/.zshrc" ]] || rc="$HOME/.profile"
touch "$rc"
printf '\n# mk-codex-key\n%s\n' "$line" >> "$rc"
export OPENAI_API_KEY="$KEY"
log "已写入 OPENAI_API_KEY 到 $rc （不在日志里打印）。新开终端后 codex"
