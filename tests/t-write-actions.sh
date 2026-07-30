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
               | grep -oE '"\$_nn_dir/[A-Za-z0-9_.]+"' | grep -oE '_nn_dir/[A-Za-z0-9_.]+' \
               | sed 's|_nn_dir/||' | sort -u)
# Belt to the capture's braces: a config-guarded emission would not fire in
# this hermetic capture, but any emission spelled with $_nn_dir is visible
# in the source regardless of guards – every one of those must be listed
# too (subset check: helper-mediated emissions are the capture's job)
_sf_src=$( { grep -oE 'cat >>? "\$_nn_dir/[A-Za-z0-9_.]+"' "$REPO/lib/notenav.sh"
             grep -oE '(printf|declare -f) [^>|]*> "\$_nn_dir/[A-Za-z0-9_.]+"' "$REPO/lib/notenav.sh"
           } | grep -oE '_nn_dir/[A-Za-z0-9_.]+' | sed 's|_nn_dir/||' \
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
    fail "source-visible emissions missing from the startup list: $_sf_unlisted"
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
