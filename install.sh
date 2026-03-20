#!/bin/sh
# notenav installer
# Usage: curl -fsSL https://raw.githubusercontent.com/jqueiroz/notenav/main/install.sh | sh
set -e

NOTENAV_DIR="${NOTENAV_DIR:-$HOME/.local/share/notenav}"
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
for dep in bash fzf awk sort sed git; do
  if ! check_dep "$dep"; then
    missing="$missing $dep"
  fi
done

# bat or batcat
if ! check_dep bat && ! check_dep batcat; then
  missing="$missing bat"
fi

# zk
if ! check_dep zk; then
  missing="$missing zk"
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
  warn "Missing dependencies:$missing"
  warn "notenav will be installed but may not work until these are available."
  echo
fi

# --- install or update ---
if [ -d "$NOTENAV_DIR/.git" ]; then
  echo "Updating notenav..."
  git -C "$NOTENAV_DIR" pull --ff-only
else
  echo "Installing notenav..."
  mkdir -p "$(dirname "$NOTENAV_DIR")"
  git clone https://github.com/jqueiroz/notenav.git "$NOTENAV_DIR"
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
