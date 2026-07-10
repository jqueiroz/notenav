#!/usr/bin/env bash
# Doctor: CRLF/BOM/mixed/duplicated-frontmatter diagnostics and the
# --fix-frontmatter repair.
set -u
. "$(dirname "$0")/lib.sh"

WORK=$(mktemp -d /tmp/nn-t-doctor.XXXXXX) || exit 2
trap 'rm -rf "$WORK"' EXIT

run_doctor() { # <notebook> [args...] -> $WORK/doctor.out, returns rc
  local nb=$1
  shift
  (cd "$nb" && bash "$REPO/bin/nn" doctor "$@" </dev/null 2>&1) > "$WORK/doctor.out"
}

# ── Healthy CRLF/BOM notebook: informational only, exit 0 ───────────────
NB1="$WORK/nb-healthy"
mkdir -p "$NB1"
mk_note "$NB1/a.md" crlf 0 '---' 'type: task' 'status: new' '---' 'body'
mk_note "$NB1/b.md" crlf 1 '---' 'type: idea' '---' 'body'
mk_note "$NB1/c.md" lf 0 '---' 'type: task' '---' 'body'
run_doctor "$NB1" || fail "doctor exited non-zero on healthy CRLF/BOM notebook"
grep -q 'use CRLF' "$WORK/doctor.out" || fail "missing CRLF info line"
grep -q 'byte-order mark' "$WORK/doctor.out" || fail "missing BOM info line"
grep -q 'mixed line endings' "$WORK/doctor.out" && fail "spurious mixed-EOL warning"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "spurious dup-frontmatter warning"

# ── Thematic break right after frontmatter is NOT flagged ───────────────
NB2="$WORK/nb-hr"
mkdir -p "$NB2"
mk_note "$NB2/hr.md" lf 0 '---' 'type: task' '---' '---' 'Just text below a rule'
run_doctor "$NB2" || fail "doctor exited non-zero on thematic-break note"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "thematic break false positive"

# ── Mixed EOL inside the frontmatter is warned ──────────────────────────
NB3="$WORK/nb-mixed"
mkdir -p "$NB3"
printf -- '---\r\ntype: task\n---\r\nbody\n' > "$NB3/m.md"
run_doctor "$NB3" || fail "doctor exited non-zero on mixed notebook"
grep -q 'mixed line endings' "$WORK/doctor.out" || fail "missing mixed-EOL warning"

# ── Corrupted note: detected, repaired, idempotent ──────────────────────
NB4="$WORK/nb-corrupt"
mkdir -p "$NB4"
corrupt="$NB4/note.md"
{
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\nstatus: new\r\ntitle: x\r\n---\r\nbody\r\n'
} > "$corrupt"
cp "$corrupt" "$WORK/corrupt.orig"

run_doctor "$NB4" || fail "doctor exited non-zero on corrupted notebook"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" || fail "corruption not detected"
grep -q 'note.md' "$WORK/doctor.out" || fail "affected path not listed"
grep -q 'fix-frontmatter' "$WORK/doctor.out" || fail "repair hint not shown"

run_doctor "$NB4" --fix-frontmatter || fail "doctor --fix-frontmatter exited non-zero"
grep -q 'repaired note.md' "$WORK/doctor.out" || fail "repair not reported"
printf -- '---\r\ntype: task\r\nstatus: done\r\ntitle: x\r\n---\r\nbody\r\n' > "$WORK/repaired.expected"
assert_bytes "$corrupt" "$WORK/repaired.expected" "repaired note merges blocks in original EOL style"
assert_bytes "$corrupt.bak" "$WORK/corrupt.orig" "backup preserves original bytes"

run_doctor "$NB4" --fix-frontmatter || fail "second --fix-frontmatter exited non-zero"
grep -q 'nothing to repair' "$WORK/doctor.out" || fail "repair not idempotent"
assert_bytes "$corrupt" "$WORK/repaired.expected" "note unchanged by second repair run"

# ── Corrupted note with BOM: BOM restored to byte 0 ─────────────────────
NB5="$WORK/nb-corrupt-bom"
mkdir -p "$NB5"
corrupt2="$NB5/note.md"
{
  printf -- '---\nstatus: done\n---\n'
  printf '\357\273\277'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$corrupt2"
run_doctor "$NB5" --fix-frontmatter || fail "doctor --fix-frontmatter (BOM) exited non-zero"
{
  printf '\357\273\277'
  printf -- '---\r\ntype: task\r\nstatus: done\r\n---\r\nbody\r\n'
} > "$WORK/repaired-bom.expected"
assert_bytes "$corrupt2" "$WORK/repaired-bom.expected" "BOM restored to byte 0 after repair"

# ── Clean note whose body starts with a fence block: untouched ──────────
# The damage signature only accepts type/status/priority/tags in the leading
# block, so a real frontmatter (title:) followed by a YAML example is not
# even flagged, and repair must leave it byte-identical.
NB7="$WORK/nb-yaml-example"
mkdir -p "$NB7"
yex="$NB7/note.md"
printf -- '---\ntitle: doc\n---\n---\nfoo: example yaml\n---\nprose\n' > "$yex"
cp "$yex" "$WORK/yex.orig"
run_doctor "$NB7" --fix-frontmatter || fail "doctor --fix-frontmatter (yaml example) exited non-zero"
assert_bytes "$yex" "$WORK/yex.orig" "clean note with fence-block body left untouched"

# ── Stacked corruption converges in one invocation ──────────────────────
NB8="$WORK/nb-stacked"
mkdir -p "$NB8"
stk="$NB8/note.md"
{
  printf -- '---\npriority: 1\n---\n'
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\nstatus: new\r\n---\r\nbody\r\n'
} > "$stk"
run_doctor "$NB8" --fix-frontmatter || fail "doctor --fix-frontmatter (stacked) exited non-zero"
printf -- '---\r\ntype: task\r\nstatus: done\r\npriority: 1\r\n---\r\nbody\r\n' > "$WORK/stacked.expected"
assert_bytes "$stk" "$WORK/stacked.expected" "stacked corruption converges to one block"

# ── Overridden tags: old list items never leak (0-indent, blank lines) ──
NB9="$WORK/nb-tagleak"
mkdir -p "$NB9"
tl="$NB9/note.md"
{
  printf -- '---\ntags:\n  - new1\n  - new2\n---\n'
  printf -- '---\ntitle: x\ntags:\n- old1\n\n  - old2\n---\nbody\n'
} > "$tl"
run_doctor "$NB9" --fix-frontmatter || fail "doctor --fix-frontmatter (tag leak) exited non-zero"
printf -- '---\ntitle: x\ntags:\n  - new1\n  - new2\n---\nbody\n' > "$WORK/tagleak.expected"
assert_bytes "$tl" "$WORK/tagleak.expected" "old tag list items do not leak through override"

# ── Prose in the leading block: not even flagged (scan alignment) ───────
NB6="$WORK/nb-prose-block1"
mkdir -p "$NB6"
amb="$NB6/note.md"
{
  printf -- '---\nstatus: done\nsome prose line\n---\n'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$amb"
cp "$amb" "$WORK/amb.orig"
run_doctor "$NB6" --fix-frontmatter || fail "doctor --fix-frontmatter (prose block1) exited non-zero"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "prose block1 should not be flagged"
assert_bytes "$amb" "$WORK/amb.orig" "prose-block1 note left untouched"

# ── Scan-flagged but repair-refused: duplicate key in leading block ──────
NB6b="$WORK/nb-dupkey"
mkdir -p "$NB6b"
dk="$NB6b/note.md"
{
  printf -- '---\nstatus: done\nstatus: new\n---\n'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$dk"
cp "$dk" "$WORK/dk.orig"
run_doctor "$NB6b" --fix-frontmatter || fail "doctor --fix-frontmatter (dup key) exited non-zero"
grep -q 'skipped note.md' "$WORK/doctor.out" || fail "dup-key note not reported as skipped"
assert_bytes "$dk" "$WORK/dk.orig" "dup-key note left untouched"
[ -e "$dk.bak" ] && fail "no backup should remain for a skipped note"

# ── Body prose disguised as keys: never flagged, never repaired ──────────
# (adversarial review repros: interview-style body and non-frontmatter keys)
NB10="$WORK/nb-speaker"
mkdir -p "$NB10"
spk="$NB10/interview.md"
printf -- '---\ntype: idea\n---\n---\nSpeaker: John\nsome text\n---\nmore body\n' > "$spk"
cp "$spk" "$WORK/spk.orig"
run_doctor "$NB10" || fail "doctor exited non-zero on interview note"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "interview note falsely flagged"
run_doctor "$NB10" --fix-frontmatter || fail "doctor --fix-frontmatter (interview) exited non-zero"
assert_bytes "$spk" "$WORK/spk.orig" "interview note left untouched"

NB11="$WORK/nb-milk"
mkdir -p "$NB11"
mlk="$NB11/milk.md"
printf -- '---\ntype: task\nstatus: new\n---\n---\nnote: remember the milk\ndate: tomorrow\n---\nActual body\n' > "$mlk"
cp "$mlk" "$WORK/mlk.orig"
run_doctor "$NB11" --fix-frontmatter || fail "doctor --fix-frontmatter (milk) exited non-zero"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "key-shaped body falsely flagged"
assert_bytes "$mlk" "$WORK/mlk.orig" "key-shaped body left untouched"

# ── CRLF note without trailing newline: not mixed ────────────────────────
NB12="$WORK/nb-crlf-nonl"
mkdir -p "$NB12"
printf -- '---\r\ntype: task\r\n---' > "$NB12/n.md"
run_doctor "$NB12" || fail "doctor exited non-zero on CRLF no-final-newline note"
grep -q 'mixed line endings' "$WORK/doctor.out" && fail "CRLF note without final newline falsely flagged as mixed"

finish
