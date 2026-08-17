#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/lib/common.sh"

KEY=""
BASE=""

usage() {
  cat <<'EOF'
Usage:
  ./configure.sh --key sk-ant-xxx
  ./configure.sh --key sk-xxx --base-url https://api.example.com

写入 ~/.claude/settings.json 的 env，以及 ~/.zshrc 里的 ANTHROPIC_API_KEY。
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key) KEY="${2:-}"; shift 2 ;;
    --base-url) BASE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown $1" ;;
  esac
done
[[ -n "$KEY" ]] || { usage; exit 1; }

mkdir -p "$HOME/.claude"
if [[ -n "$BASE" ]]; then
  cat > "$HOME/.claude/settings.json" <<EOF
{
  "env": {
    "ANTHROPIC_API_KEY": "$KEY",
    "ANTHROPIC_BASE_URL": "$BASE"
  }
}
EOF
else
  cat > "$HOME/.claude/settings.json" <<EOF
{
  "env": {
    "ANTHROPIC_API_KEY": "$KEY"
  }
}
EOF
fi
log "已写 $HOME/.claude/settings.json"

rc="$HOME/.zshrc"
touch "$rc"
grep -v 'export ANTHROPIC_API_KEY=' "$rc" > "$rc.mk.tmp" || true
grep -v 'export ANTHROPIC_BASE_URL=' "$rc.mk.tmp" > "$rc" || true
rm -f "$rc.mk.tmp"
printf '\n# mk-claude-key\nexport ANTHROPIC_API_KEY="%s"\n' "$KEY" >> "$rc"
[[ -n "$BASE" ]] && printf 'export ANTHROPIC_BASE_URL="%s"\n' "$BASE" >> "$rc"
export ANTHROPIC_API_KEY="$KEY"
[[ -n "$BASE" ]] && export ANTHROPIC_BASE_URL="$BASE"
log "已写环境变量到 $rc。新开终端后 claude"
