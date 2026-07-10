#!/usr/bin/env bash
# Doctor: CRLF/BOM/mixed/duplicated-frontmatter diagnostics and the
# --fix-frontmatter repair.
set -u
# shellcheck source=tests/lib.sh
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
[[ -e "$dk.bak" ]] && fail "no backup should remain for a skipped note"

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

# ── Jekyll/pandoc YAML example in the body: never flagged/repaired ──────
# (nn-only frontmatter + fenced example holding title:/layout: — the block2
# qualifier requires a managed key or key overlap with the leading block)
NB13="$WORK/nb-jekyll"
mkdir -p "$NB13"
jek="$NB13/jekyll.md"
printf -- '---\ntype: task\nstatus: new\n---\n---\ntitle: Example Jekyll frontmatter\nlayout: post\n---\nProse about frontmatter\n' > "$jek"
cp "$jek" "$WORK/jek.orig"
run_doctor "$NB13" || fail "doctor exited non-zero on jekyll note"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "jekyll example falsely flagged"
run_doctor "$NB13" --fix-frontmatter || fail "doctor --fix-frontmatter (jekyll) exited non-zero"
assert_bytes "$jek" "$WORK/jek.orig" "jekyll example left untouched"

# ── zk-path damage (type/status/created block) is detected and repaired ──
NB14="$WORK/nb-zkdamage"
mkdir -p "$NB14"
zkd="$NB14/note.md"
{
  printf -- '---\ntype: fleeting\nstatus: new\ncreated: 2026-01-01 10:00\n---\n'
  printf -- '---\r\ntitle: from template\r\ntype: fleeting\r\n---\r\nbody\r\n'
} > "$zkd"
run_doctor "$NB14" --fix-frontmatter || fail "doctor --fix-frontmatter (zk damage) exited non-zero"
grep -q 'repaired note.md' "$WORK/doctor.out" || fail "zk-path damage not repaired"
printf -- '---\r\ntitle: from template\r\ntype: fleeting\r\nstatus: new\r\ncreated: 2026-01-01 10:00\r\n---\r\nbody\r\n' > "$WORK/zkd.expected"
assert_bytes "$zkd" "$WORK/zkd.expected" "zk-path damage merged correctly"

# ── Long tags list in the damage block: scan and repair caps agree ───────
NB15="$WORK/nb-longtags"
mkdir -p "$NB15"
lt="$NB15/note.md"
{
  printf -- '---\ntags:\n'
  for i in $(seq 1 25); do printf '  - tag%s\n' "$i"; done
  printf -- '---\n'
  printf -- '---\r\ntype: task\r\ntags: [old]\r\n---\r\nbody\r\n'
} > "$lt"
run_doctor "$NB15" --fix-frontmatter || fail "doctor --fix-frontmatter (long tags) exited non-zero"
grep -q 'repaired note.md' "$WORK/doctor.out" || fail "long-tags damage flagged but not repaired (cap asymmetry)"

# ── Over-merge protection: repair stops at the correct state ─────────────
NB16="$WORK/nb-overmerge"
mkdir -p "$NB16"
om="$NB16/note.md"
{
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\nstatus: todo\r\n---\r\n'
  printf -- '---\ncreated: 2020-01-01 example\n---\nprose body\n'
} > "$om"
run_doctor "$NB16" --fix-frontmatter || fail "doctor --fix-frontmatter (over-merge) exited non-zero"
{
  printf -- '---\r\ntype: task\r\nstatus: done\r\n---\r\n'
  printf -- '---\ncreated: 2020-01-01 example\n---\nprose body\n'
} > "$WORK/om.expected"
assert_bytes "$om" "$WORK/om.expected" "repair stops at correct state; body fence block not absorbed"

# ── Repair preserves file permissions ─────────────────────────────────────
NB17="$WORK/nb-perms"
mkdir -p "$NB17"
pm="$NB17/note.md"
{
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$pm"
chmod 664 "$pm"
run_doctor "$NB17" --fix-frontmatter || fail "doctor --fix-frontmatter (perms) exited non-zero"
_mode=$(stat -c '%a' "$pm" 2>/dev/null || stat -f '%Lp' "$pm" 2>/dev/null)
[[ "$_mode" == "664" ]] || fail "repair changed file permissions (664 -> $_mode)"

# ── Body block whose keys are a subset of the frontmatter: not flagged ───
# (clean zk-style note: fm = type/status/created; body opens with a fenced
# YAML example holding only keys already in the frontmatter)
NB18="$WORK/nb-subset"
mkdir -p "$NB18"
sb="$NB18/note.md"
printf -- '---\ntype: fleeting\nstatus: new\ncreated: 2026-01-01\n---\n---\ntype: post\n---\nbody prose\n' > "$sb"
cp "$sb" "$WORK/sb.orig"
run_doctor "$NB18" || fail "doctor exited non-zero on subset-keys note"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "subset-keys body block falsely flagged"
run_doctor "$NB18" --fix-frontmatter || fail "doctor --fix-frontmatter (subset) exited non-zero"
assert_bytes "$sb" "$WORK/sb.orig" "subset-keys note left untouched"

# ── Read-only note is still repairable (mv + mode restore) ───────────────
NB19="$WORK/nb-readonly"
mkdir -p "$NB19"
ro="$NB19/note.md"
{
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$ro"
chmod 444 "$ro"
run_doctor "$NB19" --fix-frontmatter || fail "doctor --fix-frontmatter (read-only) exited non-zero"
grep -q 'repaired note.md' "$WORK/doctor.out" || fail "read-only note not repaired"
_romode=$(stat -c '%a' "$ro" 2>/dev/null || stat -f '%Lp' "$ro" 2>/dev/null)
[[ "$_romode" == "444" ]] || fail "read-only note lost its mode (444 -> $_romode)"
chmod 644 "$ro"

# ── --help works in any argument position; unknown flags error ────────────
(cd "$NB17" && bash "$REPO/bin/nn" doctor --fix-frontmatter --help </dev/null >/dev/null 2>&1) \
  || fail "doctor --fix-frontmatter --help should exit 0"
(cd "$NB17" && bash "$REPO/bin/nn" doctor --bogus </dev/null >/dev/null 2>&1)
[[ $? -eq 2 ]] || fail "doctor --bogus should exit 2"

finish
