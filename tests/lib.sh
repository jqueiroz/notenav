# Shared helpers for notenav tests. Sourced by t-*.sh; requires bash 4.2+.
# shellcheck shell=bash

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FAILS=0

# Hermetic: a contributor's ~/.config/notenav/config.toml must not leak into
# test runs. Point XDG_CONFIG_HOME at a path that cannot contain one.
export XDG_CONFIG_HOME="${TMPDIR:-/tmp}/nn-test-no-user-config"

fail() { printf '  FAIL: %s\n' "$*"; FAILS=$((FAILS + 1)); }
finish() { exit $((FAILS > 0 ? 1 : 0)); }

# mk_note <dest> <lf|crlf> <bom:0|1> line...
# Builds a note file with the given EOL style on every line.
mk_note() {
  local dest=$1 eol=$2 bom=$3
  shift 3
  local e=$'\n'
  [[ "$eol" == crlf ]] && e=$'\r\n'
  {
    [[ "$bom" == 1 ]] && printf '\357\273\277'
    local l
    for l in "$@"; do printf '%s%s' "$l" "$e"; done
  } > "$dest"
}

# assert_bytes <actual> <expected> <label>
assert_bytes() {
  if cmp -s "$1" "$2"; then return 0; fi
  fail "$3"
  diff <(od -An -c "$2") <(od -An -c "$1") | sed 's/^/    /' | head -30
  printf '    (expected vs actual)\n'
  return 1
}

# capture_nn_dir <notebook> <dest>
# Launches the real TUI startup with a PATH-shimmed fzf that copies the
# generated runtime dir ($_nn_dir) to <dest> and exits 130 (normal cancel).
capture_nn_dir() {
  local notebook=$1 dest=$2
  local tmp shim rc
  tmp=$(mktemp -d /tmp/nn-harness.XXXXXX) || { fail "mktemp harness dir"; return 1; }
  shim="$tmp/bin"
  mkdir -p "$shim" "$dest"
  cat > "$shim/fzf" <<'ENDSHIM'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then echo "0.99.0 (nn-test-shim)"; exit 0; fi
for d in "$NN_TEST_TMPDIR"/nn.*; do
  [ -d "$d" ] && cp -pR "$d/." "$NN_TEST_CAPTURE/" && break
done
exit 130
ENDSHIM
  chmod +x "$shim/fzf"
  (
    cd "$notebook" &&
      PATH="$shim:$PATH" TMPDIR="$tmp" NN_TEST_TMPDIR="$tmp" \
      NN_TEST_CAPTURE="$dest" TERM=xterm \
      bash "$REPO/bin/nn" </dev/null >/dev/null 2>"$tmp/stderr"
  )
  rc=$?
  if [[ "$rc" -ne 130 ]]; then
    fail "nn exited $rc (expected 130 via shim); stderr:"
    sed 's/^/    /' "$tmp/stderr" | head -10
    rm -rf "$tmp"
    return 1
  fi
  if [[ ! -x "$dest/action.sh" ]]; then
    fail "capture incomplete: $dest/action.sh missing"
    rm -rf "$tmp"
    return 1
  fi
  # Neutralize post-action reload/filter so byte assertions stay deterministic
  printf '#!/bin/sh\nexit 0\n' > "$dest/reload_raw.sh"
  printf '#!/bin/sh\nexit 0\n' > "$dest/filter.sh"
  chmod +x "$dest/reload_raw.sh" "$dest/filter.sh"
  rm -rf "$tmp"
  return 0
}
