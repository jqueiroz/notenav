#!/usr/bin/env bash
# Byte-level matrix for the generated write scripts (action.sh, bulkedit_update.sh)
# across line-ending/BOM variants. Fixtures and expected outputs are built with
# printf at runtime so git line-ending settings can never affect them.
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

require_gawk
WORK=$(mktemp -d /tmp/nn-t-write.XXXXXX) || exit 2
trap 'rm -rf "$WORK"' EXIT
NOTEBOOK="$WORK/notebook"
CAP="$WORK/cap"
mkdir -p "$NOTEBOOK"
mk_note "$NOTEBOOK/seed.md" lf 0 '---' 'type: task' 'status: new' '---' '# Seed'

capture_nn_dir "$NOTEBOOK" "$CAP" || finish

# ── startup integrity list must cover every emitted session program ──────
# Under nullglob a never-created file matches no glob, so the startup check
# lists each emitted program literally; a name missing from that list means
# a failed write passes the check and its keybinding silently no-ops (the
# delete.sh class).  Diff the list against REALITY: the captured session
# dir holds exactly what a live startup emitted, whatever idiom or
# variable each emission used – source-regex derivations missed files
# written through helper-local paths.
_sf_real=$(cd "$CAP" && for _sf in ./*.sh ./.awk_* ./.fn_*; do
             [[ -e "$_sf" ]] && printf '%s\n' "${_sf#./}"; done | sort -u)
_sf_listed=$(sed -n '\|for _nn_sf in "\$_nn_dir"/\*\.sh|,\|; do$|p' "$REPO/lib/notenav.sh" \
               | grep -oE '"\$_nn_dir/[A-Za-z0-9_.-]+"' | grep -oE '_nn_dir/[A-Za-z0-9_.-]+' \
               | sed 's|_nn_dir/||' | sort -u)
# Belt to the capture's braces: a config-guarded emission would not fire in
# this hermetic capture, but any redirection to a QUOTED literal $_nn_dir
# path is visible in the source regardless of guards, writer idiom (cat,
# printf, echo, compound blocks, appends), spacing, quote placement
# ("$_nn_dir/x", "$_nn_dir"/x, "${_nn_dir}/x"), or hyphens in the name –
# every one of those must be listed too (subset check: helper-mediated
# emissions are the capture's job; fully unquoted spellings are outside
# house style)
_sf_src=$(grep -oE '>>?[[:space:]]*"\$\{?_nn_dir\}?"?/[A-Za-z0-9_.-]+' "$REPO/lib/notenav.sh" \
            | grep -oE '_nn_dir[}"]*/[A-Za-z0-9_.-]+' | sed 's|_nn_dir[}"]*/||' \
            | grep -E '\.sh$|^\.awk_|^\.fn_' | sort -u)
# The startup check's glob classes and this pin's enumeration are the same
# three patterns by construction – hold them in sync explicitly
_sf_globs=$(sed -n '\|for _nn_sf in "\$_nn_dir"/\*\.sh|p' "$REPO/lib/notenav.sh" \
              | grep -oE '"\$_nn_dir"/[^ ]+' | tr '\n' ' ')
if [[ -z "$_sf_real" || -z "$_sf_listed" || -z "$_sf_src" ]]; then
  fail "session-file list extraction anchors drifted – update this test"
else
  if [[ "$_sf_real" != "$_sf_listed" ]]; then
    fail "startup integrity list out of sync with the emitted session files:"
    diff <(printf '%s\n' "$_sf_real") <(printf '%s\n' "$_sf_listed") | sed 's/^/    /'
  fi
  _sf_unlisted=$(comm -23 <(printf '%s\n' "$_sf_src") <(printf '%s\n' "$_sf_listed"))
  if [[ -n "$_sf_unlisted" ]]; then
    fail "source-visible emissions missing from the startup list:"
    printf '%s\n' "$_sf_unlisted" | sed 's/^/    /'
  fi
  if [[ "$_sf_globs" != '"$_nn_dir"/*.sh "$_nn_dir"/.awk_* "$_nn_dir"/.fn_* ' ]]; then
    fail "startup check glob classes changed – update this pin's enumeration to match"
  fi
fi

run_action() { bash "$CAP/action.sh" "$CAP" "$@" >/dev/null 2>&1; }
run_bulk() { bash "$CAP/bulkedit_update.sh" "$@" >/dev/null 2>&1; }

# Standard fixture bodies
BASE=('---' 'type: task' 'status: new' '---' '# Marker note' 'body text')

f="$WORK/note.md"
x="$WORK/expected.md"

# ── action.sh: set existing key ────────────────────────────────────────
for enc in "lf 0" "crlf 0" "crlf 1" "lf 1"; do
  # shellcheck disable=SC2086  # intentional split into "<eol> <bom>"
  set -- $enc
  mk_note "$f" "$1" "$2" "${BASE[@]}"
  mk_note "$x" "$1" "$2" '---' 'type: task' 'status: active' '---' '# Marker note' 'body text'
  run_action status active "$f"
  assert_bytes "$f" "$x" "set-existing status ($1 bom=$2)"
done

# ── action.sh: set absent key (insert before closing fence) ───────────
for enc in "lf 0" "crlf 0" "crlf 1"; do
  # shellcheck disable=SC2086  # intentional split into "<eol> <bom>"
  set -- $enc
  mk_note "$f" "$1" "$2" "${BASE[@]}"
  mk_note "$x" "$1" "$2" '---' 'type: task' 'status: new' 'priority: 2' '---' '# Marker note' 'body text'
  run_action priority 2 "$f"
  assert_bytes "$f" "$x" "set-absent priority ($1 bom=$2)"
done

# ── action.sh: clear existing key ──────────────────────────────────────
for enc in "lf 0" "crlf 0"; do
  # shellcheck disable=SC2086  # intentional split into "<eol> <bom>"
  set -- $enc
  mk_note "$f" "$1" "$2" "${BASE[@]}"
  mk_note "$x" "$1" "$2" '---' 'type: task' '---' '# Marker note' 'body text'
  run_action status '' "$f"
  assert_bytes "$f" "$x" "clear status ($1 bom=$2)"
done

# ── action.sh: same-value set must be a byte-identical no-op ───────────
for enc in "lf 0" "crlf 0" "crlf 1"; do
  # shellcheck disable=SC2086  # intentional split into "<eol> <bom>"
  set -- $enc
  mk_note "$f" "$1" "$2" "${BASE[@]}"
  mk_note "$x" "$1" "$2" "${BASE[@]}"
  run_action status new "$f"
  assert_bytes "$f" "$x" "same-value no-op ($1 bom=$2)"
done

# ── action.sh: fence with trailing space is valid frontmatter ──────────
for enc in lf crlf; do
  mk_note "$f" "$enc" 0 '--- ' 'type: task' 'status: new' '---' 'body text'
  mk_note "$x" "$enc" 0 '--- ' 'type: task' 'status: active' '---' 'body text'
  run_action status active "$f"
  assert_bytes "$f" "$x" "trailing-space fence ($enc)"
done

# ── action.sh: mixed EOL (CRLF frontmatter, LF body) – line-1 anchor ───
{
  printf -- '---\r\ntype: task\r\nstatus: new\r\n---\r\n'
  printf '# Marker note\nbody text\n'
} > "$f"
{
  printf -- '---\r\ntype: task\r\nstatus: new\r\npriority: 2\r\n---\r\n'
  printf '# Marker note\nbody text\n'
} > "$x"
run_action priority 2 "$f"
assert_bytes "$f" "$x" "mixed-EOL insert follows line-1 style"

# ── action.sh: no frontmatter, CRLF body – prepend matches body EOL ────
mk_note "$f" crlf 0 '# Marker note' 'body text'
mk_note "$x" crlf 0 '---' 'status: active' '---' '# Marker note' 'body text'
run_action status active "$f"
assert_bytes "$f" "$x" "no-frontmatter prepend (crlf)"

mk_note "$f" crlf 0 '# Marker note' 'body text'
mk_note "$x" crlf 0 '# Marker note' 'body text'
run_action status '' "$f"
assert_bytes "$f" "$x" "no-frontmatter clear is a no-op (crlf)"

# ── action.sh: empty file ───────────────────────────────────────────────
: > "$f"
mk_note "$x" lf 0 '---' 'status: active' '---'
run_action status active "$f"
assert_bytes "$f" "$x" "empty file gains LF frontmatter"

: > "$f"
: > "$x"
run_action status '' "$f"
assert_bytes "$f" "$x" "empty file clear is a no-op"

# ── action.sh: fence-only file (unclosed frontmatter) → no-op ──────────
for enc in lf crlf; do
  mk_note "$f" "$enc" 0 '---'
  mk_note "$x" "$enc" 0 '---'
  run_action status active "$f"
  assert_bytes "$f" "$x" "fence-only no-op ($enc)"
done

# ── action.sh: missing final newline gains one (documented I4a) ────────
printf -- '---\ntype: task\nstatus: new\n---\nbody text' > "$f"
mk_note "$x" lf 0 '---' 'type: task' 'status: new' '---' 'body text'
run_action status new "$f"
assert_bytes "$f" "$x" "no-final-newline (lf, same-value) gains terminator"

printf -- '---\r\ntype: task\r\nstatus: new\r\n---\r\nbody text' > "$f"
printf -- '---\r\ntype: task\r\nstatus: active\r\n---\r\nbody text\n' > "$x"
run_action status active "$f"
assert_bytes "$f" "$x" "no-final-newline (crlf) keeps CRLF lines, bare LF terminator added"

# ── action.sh: CR-only file – never corrupted, converges ───────────────
printf -- '---\rtype: task\rstatus: new\r---\rbody\r' > "$f"
run_action status active "$f"
{
  printf -- '---\r\nstatus: active\r\n---\r\n'
  printf -- '---\rtype: task\rstatus: new\r---\rbody\r'
} > "$x"
assert_bytes "$f" "$x" "cr-only treated as no-frontmatter, original bytes intact"
# Second run re-edits the prepended block in place; the final CR-only record
# gains a terminator (documented I4a normalization). Third run is byte-stable.
cat "$f" > "$WORK/cr-only.run2-expected"
printf '\n' >> "$WORK/cr-only.run2-expected"
run_action status active "$f"
assert_bytes "$f" "$WORK/cr-only.run2-expected" "cr-only second run: no repeated prepend, gains final terminator"
cp "$f" "$WORK/cr-only.run2"
run_action status active "$f"
assert_bytes "$f" "$WORK/cr-only.run2" "cr-only third run is byte-stable"

# ── unclosed frontmatter: refused, byte-identical (fuzzer repros) ───────
# Continuation-shaped body lines after an unclosed fence must never be eaten
printf -- '---\nstatus: new\n  precious indented text\n- precious dash line\n' > "$f"
cp "$f" "$WORK/unclosed.orig"
run_action status '' "$f"
assert_bytes "$f" "$WORK/unclosed.orig" "unclosed fm: clear is a byte-identical no-op"
run_action status active "$f"
assert_bytes "$f" "$WORK/unclosed.orig" "unclosed fm: set is a byte-identical no-op"

# A CR-terminated close fence merges into the next record (mixed CR/LF file):
# frontmatter that renders as closed is unclosed to awk – body must survive
printf -- '---\ntitle: x\n---\rMy notes\nstatus: needs review with Bob\n' > "$f"
cp "$f" "$WORK/crclose.orig"
run_action status active "$f"
assert_bytes "$f" "$WORK/crclose.orig" "CR-merged close fence: body line not rewritten"

# Long frontmatter (201 content lines): the pre-scan finds the close fence
# wherever it is, so the edit succeeds cleanly — and is idempotent
{
  printf -- '---\n'
  for i in $(seq 1 199); do printf 'k%s: v\n' "$i"; done
  printf -- 'tags:\n  - alpha\n---\nbody\n'
} > "$f"
{
  printf -- '---\n'
  for i in $(seq 1 199); do printf 'k%s: v\n' "$i"; done
  printf -- 'tags:\n  - beta\n---\nbody\n'
} > "$x"
run_bulk "$f" "tags=beta"
assert_bytes "$f" "$x" "201-line frontmatter: bulk tags replace succeeds"
run_bulk "$f" "tags=beta"
assert_bytes "$f" "$x" "201-line frontmatter: second run idempotent (no duplication)"

# 250-line frontmatter with the target key at line 2: previously editable,
# regressed by a capped pre-scan, must stay editable (max-review repro)
{
  printf -- '---\nstatus: new\n'
  for i in $(seq 1 249); do printf 'k%s: v\n' "$i"; done
  printf -- '---\nbody\n'
} > "$f"
{
  printf -- '---\nstatus: done\n'
  for i in $(seq 1 249); do printf 'k%s: v\n' "$i"; done
  printf -- '---\nbody\n'
} > "$x"
run_action status 'done' "$f"
assert_bytes "$f" "$x" "250-line frontmatter: status edit succeeds"

# Exactly at the 100000-line rewriter cap: pre-scan must see the close fence
# (the off-by-one class has bitten twice; pin the real constant)
{
  printf -- '---\nstatus: new\n'
  seq 1 99999 | awk '{print "k" $0 ": v"}'
  printf -- '---\nbody\n'
} > "$f"
{
  printf -- '---\nstatus: active\n'
  seq 1 99999 | awk '{print "k" $0 ": v"}'
  printf -- '---\nbody\n'
} > "$x"
run_action status active "$f"
assert_bytes "$f" "$x" "100000-line frontmatter cap boundary: edit succeeds"

# Same boundary through bulkedit's independent copy of the cap
{
  printf -- '---\nstatus: new\n'
  seq 1 99999 | awk '{print "k" $0 ": v"}'
  printf -- '---\nbody\n'
} > "$f"
{
  printf -- '---\nstatus: done\n'
  seq 1 99999 | awk '{print "k" $0 ": v"}'
  printf -- '---\nbody\n'
} > "$x"
run_bulk "$f" status=done
assert_bytes "$f" "$x" "100000-line frontmatter cap boundary: bulk edit succeeds"

# Exactly 200 frontmatter lines (the documented cap): write must succeed
{
  printf -- '---\n'
  for i in $(seq 1 199); do printf 'k%s: v\n' "$i"; done
  printf -- 'status: new\n---\nbody\n'
} > "$f"
{
  printf -- '---\n'
  for i in $(seq 1 199); do printf 'k%s: v\n' "$i"; done
  printf -- 'status: active\n---\nbody\n'
} > "$x"
run_action status active "$f"
assert_bytes "$f" "$x" "200-line frontmatter boundary: write succeeds"

# Same boundary through bulkedit (separate copy of the pre-scan)
{
  printf -- '---\n'
  for i in $(seq 1 199); do printf 'k%s: v\n' "$i"; done
  printf -- 'status: new\n---\nbody\n'
} > "$f"
{
  printf -- '---\n'
  for i in $(seq 1 199); do printf 'k%s: v\n' "$i"; done
  printf -- 'status: done\n---\nbody\n'
} > "$x"
run_bulk "$f" status=done
assert_bytes "$f" "$x" "200-line frontmatter boundary: bulk edit succeeds"

# ── bulkedit_update.sh: multi-field incl. multi-line tags ──────────────
for enc in "lf 0" "crlf 0" "crlf 1"; do
  # shellcheck disable=SC2086  # intentional split into "<eol> <bom>"
  set -- $enc
  mk_note "$f" "$1" "$2" "${BASE[@]}"
  mk_note "$x" "$1" "$2" '---' 'type: idea' 'status: done' 'priority: 1' 'tags:' \
    '  - alpha' '  - beta' '  - gamma' '---' '# Marker note' 'body text'
  run_bulk "$f" type=idea status=done priority=1 "tags=alpha beta gamma"
  assert_bytes "$f" "$x" "bulk multi-field ($1 bom=$2)"
done

# ── bulkedit_update.sh: no-frontmatter prepend with tags ───────────────
mk_note "$f" crlf 0 '# Marker note' 'body text'
mk_note "$x" crlf 0 '---' 'type: idea' 'status: done' 'priority: 1' 'tags:' \
  '  - alpha' '  - beta' '  - gamma' '---' '# Marker note' 'body text'
run_bulk "$f" type=idea status=done priority=1 "tags=alpha beta gamma"
assert_bytes "$f" "$x" "bulk no-frontmatter prepend with tags (crlf)"

# ── bulkedit_update.sh: replace an existing inline tags value ──────────
mk_note "$f" crlf 0 '---' 'type: task' 'tags: [old, stale]' '---' 'body text'
mk_note "$x" crlf 0 '---' 'type: task' 'tags:' '  - alpha' '  - beta' '---' 'body text'
run_bulk "$f" "tags=alpha beta"
assert_bytes "$f" "$x" "bulk tags replace (crlf)"

# ── prepend on a BOM'd no-frontmatter note: single BOM at byte 0 ────────
# (mutation testing found only bom=0 prepend fixtures existed)
mk_note "$f" crlf 1 '# Marker note' 'body text'
mk_note "$x" crlf 1 '---' 'status: active' '---' '# Marker note' 'body text'
run_action status active "$f"
assert_bytes "$f" "$x" "no-frontmatter prepend keeps single BOM (action, crlf bom=1)"

mk_note "$f" crlf 1 '# Marker note' 'body text'
mk_note "$x" crlf 1 '---' 'type: idea' '---' '# Marker note' 'body text'
run_bulk "$f" type=idea
assert_bytes "$f" "$x" "no-frontmatter prepend keeps single BOM (bulk, crlf bom=1)"

# ── bumppri.sh reads through BOM+CRLF (zenith ladder: 2 -up-> 1) ────────
mk_note "$f" crlf 1 '---' 'type: task' 'priority: 2' '---' 'body'
mk_note "$x" crlf 1 '---' 'type: task' 'priority: 1' '---' 'body'
bash "$CAP/bumppri.sh" "$CAP" "$f" up >/dev/null 2>&1
assert_bytes "$f" "$x" "bumppri reads through BOM+CRLF and steps priority"

# ── cyclestatus.sh end-to-end: reader + action.sh on BOM/CRLF notes ─────
# (zenith lifecycle: new -> active)
mk_note "$f" crlf 1 "${BASE[@]}"
mk_note "$x" crlf 1 '---' 'type: task' 'status: active' '---' '# Marker note' 'body text'
bash "$CAP/cyclestatus.sh" "$CAP" "$f" fwd >/dev/null 2>&1
assert_bytes "$f" "$x" "cyclestatus reads through BOM+CRLF and writes in style"

# A CRLF note without a status gets the workflow's initial status
mk_note "$f" crlf 0 '---' 'type: task' '---' 'body text'
mk_note "$x" crlf 0 '---' 'type: task' 'status: new' '---' 'body text'
bash "$CAP/cyclestatus.sh" "$CAP" "$f" fwd >/dev/null 2>&1
assert_bytes "$f" "$x" "cyclestatus assigns initial status on CRLF note"

# ── new-note EOL sampler (extracted from the shipped newnote.sh) ─────────
# CRLF majority must win, and .raw rows with EMPTY status/priority/tags
# fields must not shift the path column (the IFS=tab read regression)
_sampler=$(awk '/prevailing line-ending style/{s=1} s{print} s && /&& _nn_ceol=/{exit}' "$CAP/newnote.sh")
# Fail closed if either anchor drifts: the snippet must stay small and must
# never reach the note-creation code below it
if [[ -z "$_sampler" || $(wc -l <<< "$_sampler") -gt 25 || "$_sampler" == *mktemp* ]]; then
  fail "sampler snippet extraction anchors drifted – update this test"
else
  SDIR=$(mktemp -d /tmp/nn-sampler.XXXXXX)
  for i in 1 2 3; do mk_note "$SDIR/c$i.md" crlf 0 '---' 'type: task' '---' 'b'; done
  mk_note "$SDIR/l1.md" lf 0 '---' 'type: task' '---' 'b'
  {
    for i in 1 2 3; do printf 'task\t\t\t\tt\t%s\t2026-01-01 00:00\t\n' "$SDIR/c$i.md"; done
    printf 'task\t\t\t\tt\t%s\t2026-01-01 00:00\t\n' "$SDIR/l1.md"
  } > "$WORK/raw.sampletest"
  cp "$CAP/.raw" "$WORK/raw.keep" 2>/dev/null || : > "$WORK/raw.keep"
  cp "$WORK/raw.sampletest" "$CAP/.raw"
  # shellcheck disable=SC2034  # dir is read inside the eval'd snippet
  dir="$CAP"
  eval "$_sampler"
  # shellcheck disable=SC2154  # _nn_ceol is assigned inside the eval'd snippet
  [[ "${_nn_ceol:-}" == $'\r' ]] || fail "sampler did not choose CRLF majority"
  cp "$WORK/raw.keep" "$CAP/.raw"
  rm -rf "$SDIR"
fi

# ── missing .fn_note helpers: writers fail CLOSED, never corrupt ─────────
# (running on without the helpers would misclassify frontmatter notes and
# re-create the duplicate-block damage this whole feature exists to fix)
mk_note "$f" crlf 0 "${BASE[@]}"
cp "$f" "$WORK/fnnote.orig"
mv "$CAP/.fn_note" "$CAP/.fn_note.hidden"
if run_action status active "$f"; then
  fail "action.sh should exit non-zero without .fn_note"
fi
assert_bytes "$f" "$WORK/fnnote.orig" "action.sh refuses byte-identically without .fn_note"
if bash "$CAP/bulkedit_update.sh" "$f" status=done >/dev/null 2>&1; then
  fail "bulkedit should exit non-zero without .fn_note"
fi
assert_bytes "$f" "$WORK/fnnote.orig" "bulkedit refuses byte-identically without .fn_note"
mv "$CAP/.fn_note.hidden" "$CAP/.fn_note"

# ── EMPTY session files: writers fail CLOSED, never truncate ─────────────
# (sourcing an empty .fn_note succeeds, and gawk treats an empty -f program
# file as a valid no-rule program printing nothing – without the guards a
# field edit would replace the note with a zero-byte file)
mk_note "$f" crlf 0 "${BASE[@]}"
cp "$f" "$WORK/emptysf.orig"
for _sf in .fn_note .awk_prescan .awk_action_rewrite; do
  mv "$CAP/$_sf" "$CAP/$_sf.hidden"
  : > "$CAP/$_sf"
  if run_action status active "$f"; then
    fail "action.sh should exit non-zero with empty $_sf"
  fi
  assert_bytes "$f" "$WORK/emptysf.orig" "action.sh refuses byte-identically with empty $_sf"
  mv "$CAP/$_sf.hidden" "$CAP/$_sf"
done
for _sf in .fn_note .awk_prescan .awk_bulk_rewrite; do
  mv "$CAP/$_sf" "$CAP/$_sf.hidden"
  : > "$CAP/$_sf"
  if run_bulk "$f" status=done; then
    fail "bulkedit should exit non-zero with empty $_sf"
  fi
  assert_bytes "$f" "$WORK/emptysf.orig" "bulkedit refuses byte-identically with empty $_sf"
  mv "$CAP/$_sf.hidden" "$CAP/$_sf"
done
# cyclestatus/bumppri with an empty shared getter: an unreadable current
# value must NOT be treated as "no status set" (which would WRITE)
mv "$CAP/.awk_fm_get" "$CAP/.awk_fm_get.hidden"
: > "$CAP/.awk_fm_get"
if bash "$CAP/cyclestatus.sh" "$CAP" "$f" fwd >/dev/null 2>&1; then
  fail "cyclestatus should exit non-zero with empty .awk_fm_get"
fi
assert_bytes "$f" "$WORK/emptysf.orig" "cyclestatus refuses byte-identically with empty .awk_fm_get"
if bash "$CAP/bumppri.sh" "$CAP" "$f" up >/dev/null 2>&1; then
  fail "bumppri should exit non-zero with empty .awk_fm_get"
fi
assert_bytes "$f" "$WORK/emptysf.orig" "bumppri refuses byte-identically with empty .awk_fm_get"
mv "$CAP/.awk_fm_get.hidden" "$CAP/.awk_fm_get"
# newnote guards at the top of the script, before any tty interaction or
# note creation – so the refusal is observable headlessly via its stderr
# marker (an empty backfill program would truncate the just-created note)
mv "$CAP/.awk_fm_backfill" "$CAP/.awk_fm_backfill.hidden"
: > "$CAP/.awk_fm_backfill"
if bash "$CAP/newnote.sh" "$CAP" </dev/null >/dev/null 2>"$WORK/nn.err"; then
  fail "newnote.sh should exit non-zero with empty .awk_fm_backfill"
fi
grep -q 'session files missing' "$WORK/nn.err" \
  || fail "newnote.sh guard did not report missing session files"
mv "$CAP/.awk_fm_backfill.hidden" "$CAP/.awk_fm_backfill"

# ── state lock: helpers emitted, semantics correct, writers wired ────────
grep -q '_nn_state_lock' "$CAP/.fn_note" || fail ".fn_note does not carry the state-lock helpers"
# shellcheck source=/dev/null
. "$CAP/.fn_note" || fail "sourcing captured .fn_note failed"
_nn_state_lock "$CAP"
[[ -d "$CAP/.state.lock" ]] || fail "_nn_state_lock did not create the lock dir"
_nn_state_unlock "$CAP"
[[ -d "$CAP/.state.lock" ]] && fail "_nn_state_unlock left the lock dir behind"
# stale-holder steal: a pre-existing OLD lock (dead holder) must be taken
# over in bounded time, with ownership, leaving no steal residue
mkdir "$CAP/.state.lock"
touch -t 202001010000 "$CAP/.state.lock"   # backdate: provably stale
_lock_t0=$SECONDS
_nn_state_lock "$CAP"
_lock_dt=$((SECONDS - _lock_t0))
[[ -d "$CAP/.state.lock" ]] || fail "stale-lock steal did not re-acquire the lock"
[[ "$_lock_dt" -le 10 ]] || fail "stale-lock steal took ${_lock_dt}s (want ~1s)"
[[ "${NN_STATE_LOCK_OWNED:-0}" == 1 ]] || fail "steal did not record ownership"
[[ "$(cat "$CAP/.state.lock/owner" 2>/dev/null)" == "$$" ]] \
  || fail "acquired lock does not carry our PID as owner"
_lk_res=$(find "$CAP" -maxdepth 1 -name '.state.lock.stale.*' | wc -l)
[[ "$_lk_res" -eq 0 ]] || fail "steal left $_lk_res .state.lock.stale.* corpse dirs"
_nn_state_unlock "$CAP"
[[ -d "$CAP/.state.lock" ]] && fail "owned unlock did not remove the lock"
# a foreign-owned lock must survive an unlock even when OWNED misreports 1
# (the stall-then-stolen scenario: our lock was stolen and re-acquired)
mkdir "$CAP/.state.lock"; printf '99' > "$CAP/.state.lock/owner"
NN_STATE_LOCK_OWNED=1
_nn_state_unlock "$CAP"
[[ -d "$CAP/.state.lock" ]] \
  || fail "unlock removed a lock owned by another process (identity check failed)"
rm -rf "$CAP/.state.lock"
# a YOUNG lock must NOT be stolen (it may belong to a live slow holder) –
# the caller proceeds unlocked/unowned and its unlock must NOT release the
# holder's lock to a third writer.  Future-dated mtime keeps the lock young
# regardless of how slowly a loaded machine runs the spin loop; computed
# relative to now (an absolute timestamp would be a date bomb).
mkdir "$CAP/.state.lock"
# GNU, BSD, then busybox spellings; validate the result is a 12-digit
# timestamp strictly in the future (a BSD date -d that "succeeds" prints
# the CURRENT time – that must not silently reintroduce load sensitivity)
_lk_fut=$(date -d '+1 day' +%Y%m%d%H%M 2>/dev/null \
  || date -v+1d +%Y%m%d%H%M 2>/dev/null \
  || date -D '%s' -d "$(( $(date +%s) + 86400 ))" +%Y%m%d%H%M 2>/dev/null)
case "$_lk_fut" in
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;;
  *) _lk_fut="" ;;
esac
[[ -n "$_lk_fut" && "$_lk_fut" -gt "$(date +%Y%m%d%H%M)" ]] || _lk_fut=""
if [[ -n "$_lk_fut" ]]; then touch -t "$_lk_fut" "$CAP/.state.lock"; else touch "$CAP/.state.lock"; fi
_lk_ino_before=$(stat -c %i "$CAP/.state.lock" 2>/dev/null || stat -f %i "$CAP/.state.lock")
_nn_state_lock "$CAP"
_lk_ino_after=$(stat -c %i "$CAP/.state.lock" 2>/dev/null || stat -f %i "$CAP/.state.lock" 2>/dev/null)
[[ "$_lk_ino_before" == "$_lk_ino_after" ]] \
  || fail "young lock was stolen (inode changed) – a live slow holder would lose its lock"
[[ "${NN_STATE_LOCK_OWNED:-0}" == 0 ]] || fail "unowned proceed recorded ownership"
_nn_state_unlock "$CAP"
[[ -d "$CAP/.state.lock" ]] \
  || fail "unowned unlock removed the live holder's lock (third-writer hazard)"
rmdir "$CAP/.state.lock"
# under the lock, interleaved append/prune rounds must never lose an entry
: > "$CAP/.pinned"
# Unique temp per contender: $$ inside ( ) & stays the parent's PID (all
# contenders would share one name, making the test load-sensitive), and a
# bare $BASHPID inside a pipeline REDIRECT expands in the pipeline child,
# not this subshell – so capture the subshell's PID into a variable first.
# Contenders retry until OWNED: this asserts the lock's mutual-exclusion
# guarantee deterministically at any machine load.  (Production callers
# deliberately proceed unlocked after ~1s – an availability policy, not a
# correctness guarantee, and not what this test measures.)
for _lk_i in $(seq 1 25); do
  (
    _lk_me=$BASHPID
    _nn_state_lock "$CAP"
    while [[ "${NN_STATE_LOCK_OWNED:-0}" != 1 ]]; do sleep 0.05; _nn_state_lock "$CAP"; done
    { cat "$CAP/.pinned" 2>/dev/null; printf '/nb/pin-%s.md\n' "$_lk_i"; } | awk '!seen[$0]++' > "$CAP/.pinned.tmp.$_lk_me"
    mv "$CAP/.pinned.tmp.$_lk_me" "$CAP/.pinned"
    _nn_state_unlock "$CAP"
  ) &
  (
    _lk_me=$BASHPID
    _nn_state_lock "$CAP"
    while [[ "${NN_STATE_LOCK_OWNED:-0}" != 1 ]]; do sleep 0.05; _nn_state_lock "$CAP"; done
    # prune that keeps everything (models reload_raw when no notes vanished)
    cat "$CAP/.pinned" 2>/dev/null > "$CAP/.pinned.tmp.p$_lk_me" && mv "$CAP/.pinned.tmp.p$_lk_me" "$CAP/.pinned"
    _nn_state_unlock "$CAP"
  ) &
done
wait
_lk_n=$(grep -c . "$CAP/.pinned")
[[ "$_lk_n" -eq 25 ]] || fail "locked append/prune interleave lost pins: $_lk_n/25 survived"
rm -f "$CAP/.pinned"
# the real writers must actually take the lock (wiring, not just helpers)
for _lk_s in action.sh delete.sh; do
  grep -q '_nn_state_lock' "$CAP/$_lk_s" || fail "$_lk_s does not take the state lock"
done
# filter.sh/reload_raw.sh keep .orig copies; every best-effort script must
# carry the .fn_note source line, the declare -F fallback, AND at least one
# real lock CALL – the fallback line alone contains the token
# '_nn_state_lock', so a plain grep would stay green while the script
# degraded to unlocked writes
for _lk_s in filter.sh.orig reload_raw.sh.orig bulkedit_apply.sh delete.sh; do
  grep -q '\. "\$dir/\.fn_note"' "$CAP/$_lk_s" \
    || fail "$_lk_s does not source .fn_note"
  grep -q 'declare -F _nn_state_lock' "$CAP/$_lk_s" \
    || fail "$_lk_s lacks the tolerant-source fallback prologue"
  grep -q '_nn_state_lock "\$dir"' "$CAP/$_lk_s" \
    || fail "$_lk_s has no actual _nn_state_lock call"
done
# and action.sh/newnote.sh (fail-closed sourcing) must call it too
for _lk_s in action.sh newnote.sh; do
  grep -q '_nn_state_lock "\$dir"' "$CAP/$_lk_s" \
    || fail "$_lk_s has no actual _nn_state_lock call"
done

# ── killwatcher.sh: identity-checked watcher kill (PID-reuse guard) ──────
# recycled PID: an alive process whose args lack the session dir (PID 1)
# must NOT be signaled; the stale pidfile is still cleaned up
printf '1' > "$CAP/.watcher_pid"
bash "$CAP/killwatcher.sh" "$CAP" || fail "killwatcher exited non-zero on a recycled PID"
[[ -f "$CAP/.watcher_pid" ]] && fail "killwatcher left the stale pidfile behind"
# genuine session process (args contain the session dir) must be killed;
# the wrapper reaps its child on TERM so no sleep is orphaned past the test
bash -c "trap 'kill \$c 2>/dev/null; exit' TERM; sleep 30 & c=\$!; wait \$c" nn-kw-pin "$CAP" & _kw_p=$!
sleep 0.2
printf '%s' "$_kw_p" > "$CAP/.watcher_pid"
bash "$CAP/killwatcher.sh" "$CAP"
sleep 0.3
if kill -0 "$_kw_p" 2>/dev/null; then
  fail "killwatcher did not kill a genuine session process"
  kill "$_kw_p" 2>/dev/null
fi
# dead PID: a real, guaranteed-dead one (a magic number like 999999 can be
# a live process under pid_max=4194304, silently testing the wrong branch)
true & _kw_dead=$!
wait "$_kw_dead" 2>/dev/null
printf '%s' "$_kw_dead" > "$CAP/.watcher_pid"
bash "$CAP/killwatcher.sh" "$CAP" && [[ ! -f "$CAP/.watcher_pid" ]] \
  || fail "killwatcher mishandled a dead PID"

# ── concurrent filter.sh runs: consistent .current, no stray temps ───────
# Per-invocation $$-suffixed intermediates mean every installed .current is
# one run's complete output – interleaved/garbled rows are impossible, so
# six concurrent runs over identical state must land byte-identical to a
# sequential reference run.  (filter.sh.orig is the pre-neutralization copy
# the harness keeps.)
bash "$CAP/filter.sh.orig" "$CAP" refresh >/dev/null 2>&1
cp "$CAP/.current" "$WORK/current.ref"
for _fc_i in 1 2 3 4 5 6; do
  bash "$CAP/filter.sh.orig" "$CAP" refresh >/dev/null 2>&1 &
done
wait
assert_bytes "$CAP/.current" "$WORK/current.ref" "concurrent filter runs corrupted .current"
# again WITH a title filter active: the .raw_title intermediate was missed
# by the first suffixing pass, so this path must be exercised explicitly
printf 'seed' > "$CAP/.f_title"
bash "$CAP/filter.sh.orig" "$CAP" refresh >/dev/null 2>&1
cp "$CAP/.current" "$WORK/current.title.ref"
for _fc_i in 1 2 3 4 5 6; do
  bash "$CAP/filter.sh.orig" "$CAP" refresh >/dev/null 2>&1 &
done
wait
assert_bytes "$CAP/.current" "$WORK/current.title.ref" "concurrent title-filtered runs corrupted .current"
: > "$CAP/.f_title"
bash "$CAP/filter.sh.orig" "$CAP" refresh >/dev/null 2>&1
_fc_stray=$(find "$CAP" -name '.raw.snap.*' -o -name '.raw_title.*' -o -name '.current.tmp.*' -o -name '.pin_ghost_count.*' | wc -l)
[[ "$_fc_stray" -eq 0 ]] || fail "filter runs left $_fc_stray stray per-invocation temp files"
# a find that dies MID-WALK (partial listing, non-zero exit) must still
# install the best-effort view but NEVER let the satellite prune delete
# pins for notes missing from the truncated listing
_fw="$WORK/badfind"; mkdir -p "$_fw"
cat > "$_fw/find" <<EOF
#!/bin/sh
case "\$*" in *"/dev/null"*) exit 1 ;; esac
printf '%s\t2026-01-01 01:01:01\n' "$NOTEBOOK/seed.md"
exit 1
EOF
chmod +x "$_fw/find"
printf '%s\n' "$NOTEBOOK/ghost-of-missing-note.md" > "$CAP/.pinned"
: > "$CAP/.last_action"
PATH="$_fw:$PATH" bash "$CAP/reload_raw.sh.orig" "$CAP" >/dev/null 2>&1
grep -qxF "$NOTEBOOK/ghost-of-missing-note.md" "$CAP/.pinned" \
  || fail "partial-walk prune deleted a pin for a note missing from the truncated listing"
grep -q 'partial scan' "$CAP/.last_action" || fail "no partial-scan hint after a mid-walk find death"
grep -q 'seed.md' "$CAP/.raw" || fail "best-effort partial listing was not installed"
rm -f "$CAP/.pinned"; bash "$CAP/reload_raw.sh.orig" "$CAP" >/dev/null 2>&1  # restore real .raw

# a sort dying MID-PIPELINE (inside do_chain_sort/do_sort's nested
# pipelines, where a last-segment-only status check cannot see it) must
# never publish a truncated view – .current stays byte-identical
_bs="$WORK/badsort"; mkdir -p "$_bs"
printf '#!/bin/sh\nhead -c 20 >/dev/null\nexit 1\n' > "$_bs/sort"; chmod +x "$_bs/sort"
bash "$CAP/filter.sh.orig" "$CAP" refresh >/dev/null 2>&1   # known-good baseline
cp "$CAP/.current" "$WORK/cur.keep"
PATH="$_bs:$PATH" bash "$CAP/filter.sh.orig" "$CAP" refresh >/dev/null 2>&1
assert_bytes "$CAP/.current" "$WORK/cur.keep" "a mid-pipeline sort death published a truncated view"

# ── sort parity: the TUI (filter.sh) and the ad-hoc path must order the
#    same notebook identically – the chain-sort implementations are twins
#    held together by comments, so pin their BEHAVIOR together ──────────
# zenith priorities are "1"-"4"; every chain branch must be OBSERVABLE:
# a/b tie through priority+status+created (title breaks), c ties through
# priority+status (created breaks), d ties on priority (status breaks),
# e exercises the primary sort, f the unset-priority placeholder
NB2="$WORK/nb2"; CAP2="$WORK/cap2"; mkdir -p "$NB2"
mk_note "$NB2/a.md" lf 0 '---' 'title: Cc' 'type: task' 'status: new' 'priority: 1' 'created: 2026-01-03' '---' 'x'
mk_note "$NB2/b.md" crlf 0 '---' 'title: Aa' 'type: task' 'status: new' 'priority: 1' 'created: 2026-01-03' '---' 'x'
mk_note "$NB2/c.md" lf 1 '---' 'title: Bb' 'type: task' 'status: new' 'priority: 1' 'created: 2026-01-01' '---' 'x'
mk_note "$NB2/d.md" crlf 1 '---' 'title: Dd' 'type: task' 'status: active' 'priority: 1' 'created: 2026-01-02' '---' 'x'
mk_note "$NB2/e.md" lf 0 '---' 'title: Ee' 'type: task' 'status: new' 'priority: 2' 'created: 2026-01-02' '---' 'x'
mk_note "$NB2/f.md" crlf 0 '---' 'title: Ff' 'type: task' 'status: new' 'created: 2026-01-02' '---' 'x'
# g is ARCHIVED (done is in zenith's status.archive): both paths must hide
# it identically – archive-visibility parity, which the old fixture had
mk_note "$NB2/g.md" lf 0 '---' 'title: Gg' 'type: task' 'status: done' 'priority: 1' 'created: 2026-01-04' '---' 'x'
if capture_nn_dir "$NB2" "$CAP2"; then
  bash "$CAP2/filter.sh.orig" "$CAP2" refresh >/dev/null 2>&1
  _sp_tui=$(awk -F'\t' 'NF>1 && $1 != "" {print $1}' "$CAP2/.current" | xargs -n1 basename 2>/dev/null)
  _sp_adhoc=$(cd "$NB2" && TERM=xterm bash "$REPO/bin/nn" type=task -l </dev/null 2>/dev/null | awk -F'\t' '{print $5}' | xargs -n1 basename 2>/dev/null)
  if [[ -z "$_sp_tui" || -z "$_sp_adhoc" ]]; then
    fail "sort-parity fixture produced empty output (tui=[$_sp_tui] adhoc=[$_sp_adhoc])"
  elif [[ "$_sp_tui" != "$_sp_adhoc" ]]; then
    fail "TUI and ad-hoc order the same notebook differently:"
    printf '    tui:   %s\n    adhoc: %s\n' "${_sp_tui//$'\n'/ }" "${_sp_adhoc//$'\n'/ }"
  fi
fi

# completeness sweep: every filter.sh intermediate must be $$-suffixed –
# any .raw<anything>/snap/tmp/count name inside the heredoc without the
# suffix is a fresh instance of the .raw_title gap.  The name class admits
# digits/uppercase (".raw2col" must not slip through), and an empty heredoc
# extraction is itself a failure (a renamed delimiter would otherwise make
# the sweep pass vacuously forever).
_fc_src=$(sed -n '\|cat > "\$_nn_dir/filter.sh"|,/^ENDFILTER$/p' "$REPO/lib/notenav.sh")
[[ -n "$_fc_src" ]] || fail "filter.sh heredoc extraction anchors drifted – update this test"
_fc_unsuf=$(printf '%s\n' "$_fc_src" \
              | grep -oE '"\$dir/\.(raw[A-Za-z0-9_.]+|current\.(tmp|build)|pin_ghost_count|pinned\.snap|marked\.snap)[^"]*"' \
              | grep -v '\.\$\$"' | sort -u)
[[ -z "$_fc_unsuf" ]] || fail "unsuffixed filter.sh intermediates: $_fc_unsuf"

# ── writes preserve file permissions (mktemp is 0600; mode must survive) ─
file_mode() { stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null; }
mk_note "$f" crlf 0 "${BASE[@]}"
chmod 664 "$f"
run_action status active "$f"
[[ "$(file_mode "$f")" == "664" ]] || fail "action.sh awk edit changed mode (664 -> $(file_mode "$f"))"
mk_note "$f" crlf 0 '# Marker note' 'body text'
chmod 664 "$f"
run_action status active "$f"
[[ "$(file_mode "$f")" == "664" ]] || fail "action.sh prepend changed mode (664 -> $(file_mode "$f"))"
mk_note "$f" crlf 0 "${BASE[@]}"
chmod 664 "$f"
run_bulk "$f" status=done
[[ "$(file_mode "$f")" == "664" ]] || fail "bulkedit awk edit changed mode (664 -> $(file_mode "$f"))"
mk_note "$f" crlf 0 '# Marker note' 'body text'
chmod 664 "$f"
run_bulk "$f" status=done
[[ "$(file_mode "$f")" == "664" ]] || fail "bulkedit prepend changed mode (664 -> $(file_mode "$f"))"

finish
