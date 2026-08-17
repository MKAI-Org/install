# Shared helpers. Source from each app script: . "$ROOT/lib/common.sh"
# shellcheck disable=SC2034

INSTALL_OS="$(uname -s)"
INSTALL_ARCH="$(uname -m)"
PKG=""

log() { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }
die() { warn "$*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

load_versions() {
  # shellcheck disable=SC1090
  . "$ROOT/lib/versions.env"
}

# MK_PACKAGES=/path  or  ./install.sh --packages /path
mk_parse() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --packages|-p)
        [[ $# -ge 2 ]] || die "--packages 需要目录"
        MK_PACKAGES="$2"
        export MK_PACKAGES
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
}

platform_id() {
  case "$INSTALL_OS" in
    Darwin)
      case "$INSTALL_ARCH" in
        arm64) echo darwin-arm64 ;;
        *) echo darwin-x64 ;;
      esac
      ;;
    Linux)
      case "$INSTALL_ARCH" in
        aarch64|arm64) echo linux-arm64 ;;
        *) echo linux-x64 ;;
      esac
      ;;
    MINGW*|MSYS*|CYGWIN*)
      case "$INSTALL_ARCH" in
        aarch64|arm64) echo windows-arm64 ;;
        *) echo windows-x64 ;;
      esac
      ;;
    *) die "unsupported OS: $INSTALL_OS" ;;
  esac
}

user_bin() {
  mkdir -p "$HOME/.local/bin"
  echo "$HOME/.local/bin"
}

ensure_path_unix() {
  local bin="$1"
  case ":$PATH:" in
    *":$bin:"*) ;;
    *) export PATH="$bin:$PATH" ;;
  esac
  local line="export PATH=\"$bin:\$PATH\""
  for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.zprofile" "$HOME/.profile"; do
    if [[ -f "$rc" ]] && grep -Fqs "$bin" "$rc"; then
      return 0
    fi
  done
  local rc="$HOME/.zshrc"
  [[ -f "$HOME/.bashrc" && ! -f "$HOME/.zshrc" ]] && rc="$HOME/.bashrc"
  mkdir -p "$(dirname "$rc")"
  touch "$rc"
  printf '\n# mk-install\n%s\n' "$line" >> "$rc"
  log "已写入 PATH 到 $rc ，新开终端生效"
}

r2_url() {
  local app="$1" file="$2"
  echo "${R2_BASE%/}/$app/$file"
}

package_search_dirs() {
  local app="$1"
  local extra="${MK_PACKAGES:-}"
  local d vol
  if [[ -n "$extra" ]]; then
    printf '%s\n' "$extra" "$extra/$app" "$extra/$app/packages" "$extra/packages/$app" "$extra/packages"
  fi
  printf '%s\n' \
    "$ROOT/$app/packages" \
    "$ROOT/packages/$app" \
    "$PWD/$app/packages" \
    "$PWD/packages" \
    "$HOME/Desktop/install/$app/packages" \
    "$HOME/Downloads/install/$app/packages"
  if [[ -d /Volumes ]]; then
    for vol in /Volumes/*; do
      [[ -d "$vol" ]] || continue
      printf '%s\n' \
        "$vol/$app/packages" \
        "$vol/install/$app/packages" \
        "$vol/packages/$app" \
        "$vol/packages" \
        "$vol/install"
    done
  fi
  for d in /media/*/* /mnt/* /run/media/*/*; do
    [[ -d "$d" ]] || continue
    printf '%s\n' "$d/$app/packages" "$d/install/$app/packages" "$d/packages"
  done
}

find_package_file() {
  local app="$1" file="$2"
  local d
  while IFS= read -r d; do
    [[ -n "$d" && -f "$d/$file" ]] || continue
    echo "$d/$file"
    return 0
  done < <(package_search_dirs "$app")
  return 1
}

find_package_glob() {
  local app="$1" pattern="$2"
  local d f old
  old="$(shopt -p nullglob || true)"
  shopt -s nullglob
  while IFS= read -r d; do
    [[ -d "$d" ]] || continue
    for f in "$d"/$pattern; do
      [[ -f "$f" ]] || continue
      eval "$old" >/dev/null 2>&1 || true
      echo "$f"
      return 0
    done
  done < <(package_search_dirs "$app")
  eval "$old" >/dev/null 2>&1 || true
  return 1
}

# Try local file first, then URLs in order (R2, then mirrors).
download() {
  local dest="$1"
  shift
  mkdir -p "$(dirname "$dest")"
  local url
  for url in "$@"; do
    [[ -n "$url" ]] || continue
    log "下载 $url"
    if curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 --max-time 600 -o "$dest.part" "$url"; then
      mv "$dest.part" "$dest"
      return 0
    fi
    rm -f "$dest.part"
    warn "失败: $url"
  done
  return 1
}

# Sets PKG to local or downloaded path. Extra args are fallback URLs after R2.
ensure_package() {
  local app="$1" file="$2"
  shift 2
  local hit dest
  hit="$(find_package_file "$app" "$file" || true)"
  if [[ -n "${hit:-}" ]]; then
    log "本地包 $hit"
    PKG="$hit"
    return 0
  fi
  dest="$ROOT/$app/packages/$file"
  if download "$dest" "$(r2_url "$app" "$file")" "$@"; then
    PKG="$dest"
    return 0
  fi
  PKG=""
  return 1
}

github_urls() {
  local path="$1" # openai/codex/releases/download/TAG/FILE
  echo "https://ghfast.top/https://github.com/$path"
  echo "https://gh-proxy.com/https://github.com/$path"
  echo "https://mirror.ghproxy.com/https://github.com/$path"
  echo "https://github.com/$path"
}

find_local() {
  local dir="$1"
  local pattern="$2"
  local f old
  old="$(shopt -p nullglob || true)"
  shopt -s nullglob
  for f in "$dir"/$pattern; do
    eval "$old" >/dev/null 2>&1 || true
    echo "$f"
    return 0
  done
  eval "$old" >/dev/null 2>&1 || true
  return 1
}

extract_tar_gz() {
  tar -xzf "$1" -C "$2"
}

chmod_x() { chmod +x "$1"; }
