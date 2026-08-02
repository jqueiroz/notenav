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
# leading-zero digits are DECIMAL, not octal: "08" used to raise a bash
# 'value too great for base' error and "010" silently meant 8
uconf '[refresh]' 'mode = "poll"' 'poll_interval = "08"' 'auto_refresh_note_limit = "010"'
run_nn_u "$G" type=task >/dev/null 2>&1 || { fail "leading-zero refresh numerics rejected"; sed 's/^/    /' "$WORK/err" | head -3; }
grep -qi 'value too great' "$WORK/err" && fail "octal parse error leaked on leading-zero numerics"

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
# fzf placeholder braces are stripped too ({q}/{} would be expanded by fzf
# INSIDE transform bodies, splicing the current row into the command)
uconf '[ui]' 'command_prompt = "{q} "'
run_nn_u "$G" type=task >/dev/null 2>&1 || { fail "a brace-containing prompt broke launch (not stripped)"; sed 's/^/    /' "$WORK/err" | head -3; }
(cd "$G" && TERM=xterm NO_COLOR=1 XDG_CONFIG_HOME="$UHOME" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/doc3.out"
grep -q "command_prompt contains characters stripped at runtime" "$WORK/doc3.out" || fail "doctor did not warn about braces in command_prompt"

# ── `--` passthrough on the NATIVE backend must be ignored, not fed to
#    find(1) (where '--limit'/etc. break the whole listing) ───────────────
# D is a plain notebook with no .zk index → native backend even if zk exists
D="$WORK/native"; nb "$D" 'extends = "zenith"'
dout=$(run_nn "$D" type=task -- --limit 10); drc=$?
[[ "$drc" -eq 0 ]] || { fail "-- passthrough broke the native listing (exit $drc)"; sed 's/^/    /' "$WORK/err" | head -3; }
printf '%s\n' "$dout" | grep -q 'only-note' || fail "native listing lost its note when -- passthrough args were present"
grep -qiE 'find: (unknown predicate|.*No such file)' "$WORK/err" && fail "-- passthrough args reached find(1) on the native backend"
grep -q "passthrough args are ignored on the native backend" "$WORK/err" || fail "no native-backend passthrough notice emitted"
# `--` AFTER a positional scope arg must also switch to passthrough (it
# used to fall into the scope list and reach find as a literal path)
mkdir -p "$D/sub"; printf -- '---\ntype: task\nstatus: todo\ntitle: subnote\n---\nb\n' > "$D/sub/s.md"
dout=$(run_nn "$D" sub -- --limit 5); drc=$?
[[ "$drc" -eq 0 ]] || { fail "late -- broke the native scoped listing (exit $drc)"; sed 's/^/    /' "$WORK/err" | head -3; }
printf '%s\n' "$dout" | grep -q 'subnote' || fail "scoped listing lost its note with a late --"
grep -qiE 'find: (unknown predicate|.*No such file)' "$WORK/err" && fail "late -- passthrough args reached find(1)"
grep -q "passthrough args are ignored on the native backend" "$WORK/err" || fail "no notice for late -- passthrough"

# ── doctor flags an unrecognized [defaults.sort_chain] key (typo) like it
#    does for every sibling table ────────────────────────────────────────
uconf '[defaults.sort_chain]' 'modifed = ["title"]' 'priority = ["status"]'
(cd "$G" && TERM=xterm NO_COLOR=1 XDG_CONFIG_HOME="$UHOME" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/sc.out"
grep -q "sort_chain: unrecognized key 'modifed'" "$WORK/sc.out" || fail "doctor did not flag a typo'd sort_chain key"
# a valid chain key must not be reported
grep -q "sort_chain: unrecognized key 'priority'" "$WORK/sc.out" && fail "doctor wrongly flagged a valid sort_chain key"

# ── defaults.sort_by = "" (the documented no-sort setting) must not
#    subscript NN_SORT_CHAINS with an empty key – bash prints a raw
#    "bad array subscript" error on every ad-hoc query ──────────────────
# self-validation first: a BOGUS sort_by must fail through run_nn_u,
# proving the user config reaches the validator at all – without this a
# plumbing regression would leave the "" pin below vacuously green
uconf '[defaults]' 'sort_by = "bogus"'
run_nn_u "$G" type=task -l >/dev/null 2>&1 \
  && fail "invalid sort_by passed (user-config plumbing broken – the \"\" pin is vacuous)"
grep -q "sort_by 'bogus' invalid" "$WORK/err" || fail "invalid sort_by lost its validator message"
uconf '[defaults]' 'sort_by = ""'
sbout=$(run_nn_u "$G" type=task -l); sbrc=$?
[[ "$sbrc" -eq 0 ]] || { fail "sort_by=\"\" broke the ad-hoc listing (exit $sbrc)"; sed 's/^/    /' "$WORK/err" | head -3; }
[[ -n "$sbout" ]] || fail "sort_by=\"\" produced an empty listing"
grep -q 'bad array subscript' "$WORK/err" \
  && fail "sort_by=\"\" hit the NN_SORT_CHAINS empty-subscript error"

# ── control characters in workflow values: startup refuses, doctor warns ──
T="$WORK/tabval"; mkdir -p "$T/.nn"
printf '[meta]\nname = "t"\n[type]\nvalues = ["task", "in\\tprogress"]\n[type.task]\nicon = "t"\n[status]\nvalues = ["new"]\nfilter_cycle = ["new"]\n' > "$T/.nn/workflow.toml"
printf -- '---\ntype: task\n---\nb\n' > "$T/n.md"
if run_nn "$T" type=task >/dev/null 2>&1; then
  fail "nn loaded a workflow whose value contains a tab"
fi
grep -q 'contains a tab, newline, or carriage return' "$WORK/err" || fail "no control-char message on tab-containing value"
(cd "$T" && TERM=xterm NO_COLOR=1 bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/ctl.out"
grep -q 'contains a tab/newline/CR' "$WORK/ctl.out" || fail "doctor did not warn about the tab-containing value"
# a value consisting ONLY of a newline must also be rejected: command
# substitution strips trailing newlines, which used to bypass the guard
printf '[meta]\nname = "t"\n[type]\nvalues = ["task", "\\n"]\n[type.task]\nicon = "t"\n[status]\nvalues = ["new"]\nfilter_cycle = ["new"]\n' > "$T/.nn/workflow.toml"
if run_nn "$T" type=task >/dev/null 2>&1; then
  fail "nn loaded a workflow whose value is a bare newline (trailing-strip bypass)"
fi
grep -q 'contains a tab, newline, or carriage return' "$WORK/err" || fail "no control-char message on newline-only value"
# an EMPTY STRING in a values list is equally unusable: it becomes an empty
# TSV join key and an empty associative-array subscript – bash aborts the
# icon/color map builds with a raw "bad array subscript" error instead of
# any diagnostic naming the offending key
printf '[meta]\nname = "t"\n[type]\nvalues = ["task", ""]\n[type.task]\nicon = "t"\n[status]\nvalues = ["new"]\nfilter_cycle = ["new"]\n' > "$T/.nn/workflow.toml"
if run_nn "$T" type=task >/dev/null 2>&1; then
  fail "nn loaded a workflow whose type.values contains an empty string"
fi
grep -q 'bad array subscript' "$WORK/err" && fail "empty type value crashed with a raw bash error"
grep -q 'type.values contains an empty string' "$WORK/err" || fail "no clean diagnostic for an empty type value"
# XDG_CONFIG_HOME explicit: the developer's real ~/.config must never leak
# into a doctor diagnosis (lib.sh exports a hermetic default, pinned here)
(cd "$T" && TERM=xterm NO_COLOR=1 XDG_CONFIG_HOME="$UHOME" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/emptyv.out"
grep -q 'type.values contains an empty string' "$WORK/emptyv.out" || fail "doctor did not warn about the empty type value"
grep -q 'bad array subscript' "$WORK/emptyv.out" && fail "doctor crashed on the empty type value"
# same guard for the status section (the shared helper's other branch).
# Doctor must warn EXACTLY ONCE: a leftover per-section inline check
# alongside the shared helper would double-report with inconsistent wording
printf '[meta]\nname = "t"\n[type]\nvalues = ["task"]\n[type.task]\nicon = "t"\n[status]\nvalues = ["new", ""]\nfilter_cycle = ["new"]\n' > "$T/.nn/workflow.toml"
if run_nn "$T" type=task >/dev/null 2>&1; then
  fail "nn loaded a workflow whose status.values contains an empty string"
fi
grep -q 'status.values contains an empty string' "$WORK/err" || fail "no clean diagnostic for an empty status value"
(cd "$T" && TERM=xterm NO_COLOR=1 XDG_CONFIG_HOME="$UHOME" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/emptysv.out"
grep -q 'bad array subscript' "$WORK/emptysv.out" && fail "doctor crashed on the empty status value"
_esv_n=$(grep -c 'status.values contains an empty string' "$WORK/emptysv.out")
[[ "$_esv_n" -eq 1 ]] || fail "doctor reported the empty status value $_esv_n times (expected exactly 1)"
# priority.values: the mixed-type branch (numeric values), where jq's
# index("") on a number array must still find a bare empty string
printf '[meta]\nname = "t"\n[type]\nvalues = ["task"]\n[type.task]\nicon = "t"\n[status]\nvalues = ["new"]\nfilter_cycle = ["new"]\n[priority]\nvalues = [1, 2, ""]\n' > "$T/.nn/workflow.toml"
if run_nn "$T" type=task >/dev/null 2>&1; then
  fail "nn loaded a workflow whose priority.values contains an empty string"
fi
grep -q 'priority.values contains an empty string' "$WORK/err" || fail "no clean diagnostic for an empty priority value"
(cd "$T" && TERM=xterm NO_COLOR=1 XDG_CONFIG_HOME="$UHOME" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/emptypv.out"
grep -q 'bad array subscript' "$WORK/emptypv.out" && fail "doctor crashed on the empty priority value"
_epv_n=$(grep -c 'priority.values contains an empty string' "$WORK/emptypv.out")
[[ "$_epv_n" -eq 1 ]] || fail "doctor reported the empty priority value $_epv_n times (expected exactly 1)"

# ── a NESTED sort stage dying mid-stream must fail the ad-hoc listing ────
# (the failure lives inside _nn_adhoc_sort's awk|sort|awk – only pipefail
# at the call site can see it; a partial listing with exit 0 would let
# `nn -l | xargs` consumers act on a truncated notebook)
SHIM="$WORK/shim"; mkdir -p "$SHIM"
printf '#!/bin/sh\nhead -n 1\nexit 1\n' > "$SHIM/sort"; chmod +x "$SHIM/sort"
if (cd "$G" && TERM=xterm NO_COLOR=1 PATH="$SHIM:$PATH" bash "$REPO/bin/nn" type=task -l </dev/null >"$WORK/trunc.out" 2>"$WORK/err"); then
  fail "a mid-stream sort death exited 0 (truncated listing read as complete)"
fi
[[ -s "$WORK/trunc.out" ]] && fail "partial rows were printed despite the failed listing"
grep -q 'listing failed part-way' "$WORK/err" || fail "no listing-failure message on nested sort death"

# ── walker severity bands: an unreadable subdir DEGRADES (readable rows
#    still listed, exit 0); a KILLED walker is FATAL (no partial rows) ────
W="$WORK/bands"; mkdir -p "$W/.nn" "$W/locked"
printf 'extends = "zenith"\n' > "$W/.nn/workflow.toml"
printf -- '---\ntype: task\nstatus: new\ntitle: band-open\n---\nb\n' > "$W/open.md"
printf -- '---\ntype: task\nstatus: new\ntitle: band-hidden\n---\nb\n' > "$W/locked/h.md"
if chmod 000 "$W/locked" 2>/dev/null && [[ "$(id -u)" != 0 ]]; then
  bout=$(run_nn "$W" type=task -l); brc=$?
  [[ "$brc" -eq 0 ]] || fail "unreadable subdir hard-failed the listing (exit $brc) – availability regression"
  printf '%s\n' "$bout" | grep -q 'band-open' || fail "readable note missing when a sibling dir is unreadable"
  printf '%s\n' "$bout" | grep -q 'band-hidden' && fail "unreadable-dir note leaked into the listing"
  grep -q 'listing may be incomplete' "$WORK/err" \
    || fail "degraded walk emitted no incomplete-listing note (the warning half of the contract)"
  chmod 755 "$W/locked"
fi
KSH="$WORK/killfind"
mk_find_shim "$KSH" 137 "$W/open.md"
if (cd "$W" && TERM=xterm NO_COLOR=1 PATH="$KSH:$PATH" bash "$REPO/bin/nn" type=task -l </dev/null >"$WORK/kf.out" 2>"$WORK/err"); then
  fail "a KILLED walker (exit 137) still exited 0 (truncated listing read as complete)"
fi
[[ -s "$WORK/kf.out" ]] && fail "partial rows printed despite the killed walker"
# an EMPTY scope argument (reachable via `nn -l type=task ""`; a first-arg
# empty string takes the preset-lookup path instead) must not silently
# widen the listing to the whole current directory – "${@:-.}" substitutes
# "." for a single null positional, not just for zero args.  It must reach
# find as-is, fail, and land in the degraded band like any unwalkable path
eout=$(run_nn "$W" -l type=task ""); erc=$?
[[ "$erc" -eq 0 ]] && fail "empty scope arg exited 0 (no-match failure expected)"
printf '%s\n' "$eout" | grep -q 'band-open' \
  && fail "empty scope arg silently widened to the current directory"
grep -q 'listing may be incomplete' "$WORK/err" \
  || fail "empty scope walk emitted no incomplete-listing note"
# a FIRST-position empty arg is preset lookup: it must fail with the clean
# not-a-preset message, not a "bad array subscript" bash error (empty
# subscript on the saved_queries associative array)
run_nn "$W" "" >/dev/null 2>&1 && fail "lone empty arg exited 0"
grep -q 'bad array subscript' "$WORK/err" \
  && fail "empty first arg crashed the preset lookup (bad array subscript)"
grep -q 'is not a query preset' "$WORK/err" \
  || fail "empty first arg lost the not-a-preset diagnostic"

# ── doctor reports user-config keys the load-time whitelist drops ────────
# schema sub-keys (icon, values) are silently dead in user config; only
# colors cross scopes – doctor must name the dead keys and stay silent on
# a config using only legitimate user-scope keys (incl. array values)
uconf '[ui]' 'command_prompt = "ok "' '[defaults.sort_chain]' 'priority = ["status"]' \
      '[type.task]' 'icon = "X"' 'color = "red"' '[status.colors]' 'todo = "yellow"'
(cd "$G" && TERM=xterm NO_COLOR=1 XDG_CONFIG_HOME="$UHOME" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/drop.out"
grep -q "'type.task.icon' has no effect" "$WORK/drop.out" || fail "doctor did not flag the dropped type.task.icon"
grep -q "'type.task.color' has no effect" "$WORK/drop.out" && fail "doctor wrongly flagged the color carve-out"
uconf '[ui]' 'command_prompt = "ok "' '[defaults.sort_chain]' 'priority = ["status"]' \
      '[type.task]' 'color = "red"' '[status.colors]' 'todo = "yellow"'
(cd "$G" && TERM=xterm NO_COLOR=1 XDG_CONFIG_HOME="$UHOME" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/drop2.out"
grep -c "has no effect" "$WORK/drop2.out" | grep -qx 0 || fail "doctor flagged a clean user-scope config"

finish
