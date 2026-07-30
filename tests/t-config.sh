#!/usr/bin/env bash
# Config + CLI surface: query-preset resolution, project-workflow parse
# failure handling, refresh numeric validation, prompt sanitization.
# Fixtures are built with printf/heredocs at runtime.
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

require_gawk
command -v yq >/dev/null 2>&1 || { echo "  SKIP: yq not installed"; finish; }

WORK=$(mktemp -d /tmp/nn-t-config.XXXXXX) || exit 2
trap 'rm -rf "$WORK"' EXIT

# nb <dir> <workflow.toml body...> ; then drops a single type=task note
nb() {
  local d="$1"; shift
  mkdir -p "$d/.nn"
  printf '%s\n' "$@" > "$d/.nn/workflow.toml"
  printf -- '---\ntype: task\nstatus: todo\ntitle: only-note\n---\nbody\n' > "$d/only.md"
}
run_nn() { (cd "$1" && shift && TERM=xterm NO_COLOR=1 bash "$REPO/bin/nn" "$@" </dev/null 2>"$WORK/err") ; }

# ── query preset: a string-valued [queries] sibling must not nuke a valid
#    table preset.  Before the object guard, jq aborted the whole stream on
#    `.value.args` against the string, discarding every preset. ───────────
P="$WORK/preset"
nb "$P" 'extends = "zenith"' '[queries]' 'aaa = "type=task"' '[queries.myq]' 'order = 1' 'args = "type=task"'
out=$(run_nn "$P" myq); rc=$?
[[ "$rc" -eq 0 ]] || { fail "nn myq exited $rc with a string-valued [queries] sibling"; sed 's/^/    /' "$WORK/err" | head -3; }
printf '%s\n' "$out" | grep -q 'only-note' || fail "valid preset myq did not resolve past the string sibling"
# and the invalid sibling itself is not usable as a preset
run_nn "$P" aaa >/dev/null 2>&1 && fail "string-valued 'aaa' should not resolve as a preset"

# ── malformed project workflow must hard-fail, not silently run the
#    default workflow (which would write foreign statuses into notes) ─────
B="$WORK/badwf"
mkdir -p "$B/.nn"
# unterminated basic string – yq rejects it
printf 'extends = "zenith\n[queries.x]\nargs = "type=task"\n' > "$B/.nn/workflow.toml"
printf -- '---\ntype: task\nstatus: todo\ntitle: n\n---\nb\n' > "$B/only.md"
run_nn "$B" type=task >/dev/null 2>&1
[[ $? -ne 0 ]] || fail "nn ran with an unparseable .nn/workflow.toml (should hard-fail)"
grep -q 'failed to parse .nn/workflow.toml' "$WORK/err" || fail "no parse-error message on malformed workflow.toml"

finish
