# Shared helpers for notenav tests. Sourced by t-*.sh; requires bash 4.2+.
# shellcheck shell=bash

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FAILS=0

# Hermetic: a contributor's ~/.config/notenav/config.toml must not leak into
# test runs. Point XDG_CONFIG_HOME at a per-run unique path that is never
# created (a fixed /tmp name could be pre-created by another user/stale run).
export XDG_CONFIG_HOME="${TMPDIR:-/tmp}/nn-test-no-user-config.$$.$RANDOM"

fail() { printf '  FAIL: %s\n' "$*"; FAILS=$((FAILS + 1)); }
finish() { exit $((FAILS > 0 ? 1 : 0)); }

# GNU awk resolution DERIVED from the lib's own _nn_resolve_gawk (sourcing
# the lib is cheap – top level only defines functions and constants), so
# the suite always tests the same interpreter the product resolves.  The
# lib returns a best-effort 'awk' even with no GNU awk installed (runtime
# surfaces a doctor message); the suite additionally verifies GNU-ness so
# require_gawk can detect true absence and SKIP with a clear message.
# shellcheck source=lib/notenav.sh
NOTENAV_ROOT="$REPO" . "$REPO/lib/notenav.sh" 2>/dev/null
if declare -F _nn_resolve_gawk >/dev/null 2>&1; then
  NN_TEST_GAWK=$(_nn_resolve_gawk)
else
  # Sourcing the lib failed (e.g. a syntax error under test) – fall back to
  # independent detection so a broken LIB is not misreported as a missing
  # gawk DEPENDENCY (on mawk-as-awk systems the plain 'awk' fallback would
  # empty out below and require_gawk would blame the wrong thing)
  echo "  note: could not source lib/notenav.sh for gawk resolution" >&2
  if awk --version </dev/null 2>/dev/null | head -n 1 | grep -qiE 'GNU|gawk'; then
    NN_TEST_GAWK="awk"
  elif command -v gawk >/dev/null 2>&1; then
    NN_TEST_GAWK="gawk"
  else
    NN_TEST_GAWK="awk"
  fi
fi
"$NN_TEST_GAWK" --version </dev/null 2>/dev/null | head -n 1 | grep -qiE 'GNU|gawk' \
  || NN_TEST_GAWK=""

# require_gawk – fail the current test file with a clear dependency message
# instead of letting gawk-only constructs (\x regexes, 3-arg match) surface
# as phantom lib regressions. Call after any gawk-independent diagnostics.
require_gawk() {
  if [[ -z "$NN_TEST_GAWK" ]]; then
    fail "GNU awk not installed – required by this test file"
    finish
  fi
}

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
  # Syntax-gate every generated script BEFORE any are neutralized: heredoc
  # bodies are invisible to shellcheck, so a paren/;; slip in an emitted
  # script would otherwise surface only when that keybinding fires.
  local _cs
  for _cs in "$dest"/*.sh; do
    if ! bash -n "$_cs" 2>"$tmp/synerr"; then
      fail "generated ${_cs##*/} has a syntax error:"
      sed 's/^/    /' "$tmp/synerr" | head -5
    fi
  done
  # Neutralize post-action reload/filter so byte assertions stay
  # deterministic; keep the originals for tests that exercise them directly
  cp "$dest/reload_raw.sh" "$dest/reload_raw.sh.orig"
  cp "$dest/filter.sh" "$dest/filter.sh.orig"
  printf '#!/bin/sh\nexit 0\n' > "$dest/reload_raw.sh"
  printf '#!/bin/sh\nexit 0\n' > "$dest/filter.sh"
  chmod +x "$dest/reload_raw.sh" "$dest/filter.sh"
  rm -rf "$tmp"
  return 0
}
