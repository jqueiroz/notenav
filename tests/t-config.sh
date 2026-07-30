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
if run_nn "$B" type=task >/dev/null 2>&1; then
  fail "nn ran with an unparseable .nn/workflow.toml (should hard-fail)"
fi
grep -q 'failed to parse .nn/workflow.toml' "$WORK/err" || fail "no parse-error message on malformed workflow.toml"

# ── refresh numerics fail fast on bad values (like every enum key) ───────
#    user config overlays the notebook workflow; point XDG at a scratch home
UHOME="$WORK/uhome"; mkdir -p "$UHOME/notenav"
uconf() { printf '%s\n' "$@" > "$UHOME/notenav/config.toml"; }
run_nn_u() { (cd "$1" && shift && TERM=xterm NO_COLOR=1 XDG_CONFIG_HOME="$UHOME" bash "$REPO/bin/nn" "$@" </dev/null 2>"$WORK/err") ; }
G="$WORK/good"; nb "$G" 'extends = "zenith"'
# baseline: a clean notebook + empty user config lists fine
uconf ''
run_nn_u "$G" type=task >/dev/null 2>&1 || { fail "baseline query failed with empty user config"; sed 's/^/    /' "$WORK/err" | head -3; }
for bad in 'poll_interval = "30s"' 'poll_interval = 0' 'auto_refresh_note_limit = "500x"' 'auto_refresh_note_limit = -5'; do
  uconf '[refresh]' "$bad"
  if run_nn_u "$G" type=task >/dev/null 2>&1; then
    fail "nn accepted invalid refresh config: $bad"
  fi
done
# a valid poll config is accepted
uconf '[refresh]' 'mode = "poll"' 'poll_interval = 15' 'auto_refresh_note_limit = 0'
run_nn_u "$G" type=task >/dev/null 2>&1 || { fail "nn rejected a valid refresh config"; sed 's/^/    /' "$WORK/err" | head -3; }

# ── prompt sanitizer: %/backslash (printf-format hazards) and [ " must be
#    stripped at runtime AND flagged by doctor via the same helper ────────
# a prompt with % previously broke the R/reset transform's printf; now it is
# stripped, so launch must stay clean
uconf '[ui]' 'command_prompt = "100% "' 'search_prompt = "[go] "'
run_nn_u "$G" type=task >/dev/null 2>&1 || { fail "a %-containing prompt broke launch (not stripped)"; sed 's/^/    /' "$WORK/err" | head -3; }
# doctor must warn about the stripped characters for both prompts
(cd "$G" && TERM=xterm NO_COLOR=1 XDG_CONFIG_HOME="$UHOME" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/doc.out"
grep -q "command_prompt contains characters stripped at runtime" "$WORK/doc.out" || fail "doctor did not warn about the %-stripped command_prompt"
grep -q "search_prompt contains characters stripped at runtime" "$WORK/doc.out" || fail "doctor did not warn about the [-stripped search_prompt"
# a backslash prompt is also caught (printf escape injection)
uconf '[ui]' 'command_prompt = "a\\b "'
(cd "$G" && TERM=xterm NO_COLOR=1 XDG_CONFIG_HOME="$UHOME" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/doc2.out"
grep -q "command_prompt contains characters stripped at runtime" "$WORK/doc2.out" || fail "doctor did not warn about a backslash in command_prompt"

# ── `--` passthrough on the NATIVE backend must be ignored, not fed to
#    find(1) (where '--limit'/etc. break the whole listing) ───────────────
# D is a plain notebook with no .zk index → native backend even if zk exists
D="$WORK/native"; nb "$D" 'extends = "zenith"'
dout=$(run_nn "$D" type=task -- --limit 10); drc=$?
[[ "$drc" -eq 0 ]] || { fail "-- passthrough broke the native listing (exit $drc)"; sed 's/^/    /' "$WORK/err" | head -3; }
printf '%s\n' "$dout" | grep -q 'only-note' || fail "native listing lost its note when -- passthrough args were present"
grep -qiE 'find: (unknown predicate|.*No such file)' "$WORK/err" && fail "-- passthrough args reached find(1) on the native backend"
grep -q "passthrough args are ignored on the native backend" "$WORK/err" || fail "no native-backend passthrough notice emitted"

finish
