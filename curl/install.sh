#!/bin/sh
# notenav installer
# Usage: curl -fsSL https://raw.githubusercontent.com/jqueiroz/notenav/stable/curl/install.sh | sh
set -e

NOTENAV_DIR="${NOTENAV_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/notenav}"
NOTENAV_BIN="${NOTENAV_BIN:-$HOME/.local/bin}"

info() { printf '  %s\n' "$@"; }
warn() { printf '  [warn] %s\n' "$@" >&2; }
err()  { printf '  [error] %s\n' "$@" >&2; exit 1; }

check_dep() {
  if command -v "$1" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# --- dependency check ---
missing=""
for dep in bash fzf gawk sort sed git yq jq; do
  if ! check_dep "$dep"; then
    # Accept awk as fallback for gawk, but warn if it's not GNU awk
    if [ "$dep" = "gawk" ] && check_dep awk; then
      awk_impl=$(awk --version 2>/dev/null | head -1)
      case "$awk_impl" in
        *GNU*|*gawk*) ;;
        *) warn "awk found but notenav requires gawk (GNU awk)"
           missing="$missing gawk" ;;
      esac
    else
      missing="$missing $dep"
    fi
  fi
done

# fzf version check (need 0.44+)
if check_dep fzf; then
  fzf_version=$(fzf --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
  if [ -n "$fzf_version" ]; then
    fzf_major="${fzf_version%%.*}"
    fzf_rest="${fzf_version#*.}"
    fzf_minor="${fzf_rest%%.*}"
    if [ "$fzf_major" -eq 0 ] 2>/dev/null && [ "$fzf_minor" -lt 44 ] 2>/dev/null; then
      warn "fzf $fzf_version found but notenav requires fzf 0.44+."
      warn "Upgrade: https://github.com/junegunn/fzf#installation"
    fi
  fi
fi

# yq must be yq-go (mikefarah), not yq-python (kislyuk)
if check_dep yq; then
  if ! yq -p=toml -o=json '.' /dev/null >/dev/null 2>&1; then
    warn "yq found but does not appear to be yq-go (github.com/mikefarah/yq)."
    warn "notenav requires yq-go, not the Python yq. Install: https://github.com/mikefarah/yq#install"
    missing="$missing yq-go"
  fi
fi

# bat or batcat (optional – default previewer; alternatives: glow, mdcat)
if ! check_dep bat && ! check_dep batcat; then
  warn "bat not found (optional – default previewer; alternatives: glow, mdcat)"
fi

# zk (optional – faster indexing and link graph)
if ! check_dep zk; then
  warn "zk not found (optional – install for faster indexing and link graph)"
fi

# bash version check (need 4+)
if check_dep bash; then
  bash_version=$(bash -c 'echo "${BASH_VERSINFO[0]}"' 2>/dev/null)
  if [ -n "$bash_version" ] && [ "$bash_version" -lt 4 ] 2>/dev/null; then
    warn "bash $bash_version found but notenav requires bash 4+."
    warn "On macOS: brew install bash (or use the Nix install)."
  fi
fi

if [ -n "$missing" ]; then
  case "$missing" in
    *git*) err "git is required to install notenav. Install git and try again." ;;
  esac
  warn "Missing dependencies:$missing"
  warn "notenav will be installed but may not work until these are available."
  echo >&2
fi

# --- install or update ---
if [ -d "$NOTENAV_DIR/.git" ]; then
  echo "Updating notenav..."
  git -C "$NOTENAV_DIR" pull --ff-only origin stable
elif [ -d "$NOTENAV_DIR" ]; then
  err "$NOTENAV_DIR already exists but is not a git repository. Remove it and try again."
else
  echo "Installing notenav..."
  mkdir -p "$(dirname "$NOTENAV_DIR")"
  git clone --branch stable https://github.com/jqueiroz/notenav.git "$NOTENAV_DIR"
fi

# --- symlink ---
mkdir -p "$NOTENAV_BIN"
ln -sf "$NOTENAV_DIR/bin/nn" "$NOTENAV_BIN/nn"

echo
info "Installed nn -> $NOTENAV_BIN/nn"

# --- PATH check ---
case ":$PATH:" in
  *":$NOTENAV_BIN:"*) ;;
  *)
    warn "$NOTENAV_BIN is not on your PATH."
    info "Add this to your shell profile:"
    info "  export PATH=\"$NOTENAV_BIN:\$PATH\""
    ;;
esac

echo
info "Done. Run 'nn --version' to verify."
info "Then: cd to your notes directory and run 'nn init' to get started."
