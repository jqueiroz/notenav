#!/usr/bin/env bash
# Doctor: CRLF/BOM/mixed/duplicated-frontmatter diagnostics and the
# --fix-frontmatter repair.
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

require_gawk
WORK=$(mktemp -d /tmp/nn-t-doctor.XXXXXX) || exit 2
trap 'rm -rf "$WORK"' EXIT

run_doctor() { # <notebook> [args...] -> $WORK/doctor.out, returns rc
  local nb=$1
  shift
  (cd "$nb" && NO_COLOR=1 bash "$REPO/bin/nn" doctor "$@" </dev/null 2>&1) > "$WORK/doctor.out"
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
grep -q 'repaired note.md (backup:' "$WORK/doctor.out" || fail "repair not reported"
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

# ── Duplicate key in leading block: not flagged (scan mirrors repair) ────
# A repeated key is not bug damage; the scan must not flag what the repair
# matcher refuses, or the user gets an un-clearable warning loop
NB6b="$WORK/nb-dupkey"
mkdir -p "$NB6b"
dk="$NB6b/note.md"
{
  printf -- '---\nstatus: done\nstatus: new\n---\n'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$dk"
cp "$dk" "$WORK/dk.orig"
run_doctor "$NB6b" --fix-frontmatter || fail "doctor --fix-frontmatter (dup key) exited non-zero"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "dup-key block flagged despite repair refusing it"
assert_bytes "$dk" "$WORK/dk.orig" "dup-key note left untouched"
[[ -e "$dk.bak" ]] && fail "no backup should exist for an unflagged note"

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
grep -q 'repaired note.md (backup:' "$WORK/doctor.out" || fail "zk-path damage not repaired"
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
grep -q 'repaired note.md (backup:' "$WORK/doctor.out" || fail "long-tags damage flagged but not repaired (cap asymmetry)"

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

# ── Stacked same-key damage: partial merge is reported honestly ──────────
# Two bug layers over an original whose keys are all duplicated in them:
# the conservative matcher merges the bug layers but refuses the final
# subset-key merge, so doctor must NOT claim full success.
NB20="$WORK/nb-residue"
mkdir -p "$NB20"
rsd="$NB20/note.md"
{
  printf -- '---\ntype: task\n---\n'
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: note\r\nstatus: new\r\n---\r\nbody\r\n'
} > "$rsd"
run_doctor "$NB20" --fix-frontmatter || fail "doctor --fix-frontmatter (residue) exited non-zero"
grep -q 'repaired note.md (backup:' "$WORK/doctor.out" && fail "residual merge shown as plain success without verify hint"
grep -q 'verify it is intended content' "$WORK/doctor.out" || fail "residue verify-warning not shown"
[[ -e "$rsd.bak" ]] || fail "backup must be kept when residue remains"
# The intermediate state must be exactly the two bug layers merged (LF, the
# outer layer's values winning) with the original block left as-is below
{
  printf -- '---\nstatus: done\ntype: task\n---\n'
  printf -- '---\r\ntype: note\r\nstatus: new\r\n---\r\nbody\r\n'
} > "$WORK/rsd.expected"
assert_bytes "$rsd" "$WORK/rsd.expected" "residue case: bug layers merged, original block untouched"

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
grep -q 'repaired note.md (backup:' "$WORK/doctor.out" || fail "read-only note not repaired"
_romode=$(stat -c '%a' "$ro" 2>/dev/null || stat -f '%Lp' "$ro" 2>/dev/null)
[[ "$_romode" == "444" ]] || fail "read-only note lost its mode (444 -> $_romode)"
chmod 644 "$ro"

# ── \x1c byte in a tag continuation survives repair byte-exact ───────────
# (the continuation join must never use a separator that can appear in data)
NB23="$WORK/nb-fs-byte"
mkdir -p "$NB23"
fsb="$NB23/note.md"
{
  printf -- '---\ntags:\n  - a\034b\n---\n'
  printf -- '---\ntitle: hi\ntype: task\ntags:\n  - old\n---\nbody\n'
} > "$fsb"
run_doctor "$NB23" --fix-frontmatter || fail "doctor --fix-frontmatter (fs byte) exited non-zero"
printf -- '---\ntitle: hi\ntype: task\ntags:\n  - a\034b\n---\nbody\n' > "$WORK/fsb.expected"
assert_bytes "$fsb" "$WORK/fsb.expected" "\\x1c byte in tag survives repair intact"

# ── \x1f byte in a frontmatter value never derails the scan protocol ─────
NB24="$WORK/nb-us-value"
mkdir -p "$NB24"
usv="$NB24/note.md"
printf -- '---\r\ntype: a\037b\037c\r\nstatus: new\r\n---\r\nbody\r\n' > "$usv"
cp "$usv" "$WORK/usv.orig"
run_doctor "$NB24" || fail "doctor exited non-zero on US-byte value"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "US byte in value caused false dup diagnosis"
grep -q 'no frontmatter' "$WORK/doctor.out" && fail "US byte in value miscounted as no-frontmatter"
run_doctor "$NB24" --fix-frontmatter || fail "doctor --fix-frontmatter (US value) exited non-zero"
assert_bytes "$usv" "$WORK/usv.orig" "US-byte note untouched by repair"

# ── Merge leaving an unqualified-keys block: honest verify-warning ───────
# (two bug layers over an original with only unmanaged keys: pass 2 refuses
# structurally-with-no-qualifying-key — must NOT claim plain success)
NB25="$WORK/nb-rc5"
mkdir -p "$NB25"
r5="$NB25/note.md"
{
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\ntype: task\n---\n'
  printf -- '---\ntitle: real\nauthor: me\n---\nbody\n'
} > "$r5"
run_doctor "$NB25" --fix-frontmatter || fail "doctor --fix-frontmatter (rc5) exited non-zero"
grep -q 'repaired note.md (backup:' "$WORK/doctor.out" && fail "rc5 residue reported as plain success"
grep -q 'verify it is intended content' "$WORK/doctor.out" || fail "rc5 residue verify-warning not shown"

# ── Middle layer without a qualifying key: honest verify-warning ─────────
# (a tags-only layer cannot qualify as the original block, so the chain
# stalls at rc 5 after merging what it can — must not claim plain success)
NB26a="$WORK/nb-stall"
mkdir -p "$NB26a"
st="$NB26a/note.md"
{
  printf -- '---\npriority: 1\n---\n'
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\ntags:\n  - t1\n---\n'
  printf -- '---\r\ntitle: x\r\ntype: note\r\n---\r\nbody\r\n'
} > "$st"
run_doctor "$NB26a" --fix-frontmatter || fail "doctor --fix-frontmatter (stall) exited non-zero"
grep -q 'repaired note.md (backup:' "$WORK/doctor.out" && fail "stalled chain reported as plain success"
grep -q 'verify it is intended content' "$WORK/doctor.out" || fail "stall verify-warning not shown"

# ── True rc-0 exhaustion (5 merges) is necessarily the full repair ───────
# (each merge must add a new key; five bug-writable keys force the fifth
# merge to consume the original — assert plain success, byte-exact)
NB26="$WORK/nb-deepstack"
mkdir -p "$NB26"
ex="$NB26/note.md"
{
  printf -- '---\npriority: 1\n---\n'
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\ntags:\n  - t1\nstatus: mid\n---\n'
  printf -- '---\ncreated: 2026-01-01\npriority: 3\n---\n'
  printf -- '---\ntype: task\n---\n'
  printf -- '---\r\ntitle: x\r\ntype: note\r\nstatus: new\r\n---\r\nbody\r\n'
} > "$ex"
run_doctor "$NB26" --fix-frontmatter || fail "doctor --fix-frontmatter (deep stack) exited non-zero"
grep -q 'repaired note.md (backup:' "$WORK/doctor.out" || fail "deep 5-key stack not reported as plain success"
grep -q 'verify it is intended content' "$WORK/doctor.out" && fail "full deep repair falsely residue-warned"
printf -- '---\r\ntitle: x\r\ntype: task\r\nstatus: done\r\ncreated: 2026-01-01\r\npriority: 1\r\ntags:\r\n  - t1\r\n---\r\nbody\r\n' > "$WORK/deep.expected"
assert_bytes "$ex" "$WORK/deep.expected" "deep stack fully merged with outer values winning"

# ── Long ORIGINAL frontmatter (25 tag lines) is still detected ────────────
NB27="$WORK/nb-longorig"
mkdir -p "$NB27"
{
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\ntags:\r\n'
  for i in $(seq 1 25); do printf '  - tag%s\r\n' "$i"; done
  printf -- '---\r\nbody\r\n'
} > "$NB27/note.md"
run_doctor "$NB27" || fail "doctor exited non-zero on long-original note"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" \
  || fail "long original frontmatter not detected"

# ── Repair I/O failure: reported distinctly, .bak kept ────────────────────
NB28="$WORK/nb-iofail"
mkdir -p "$NB28" "$WORK/gawkshim"
iof="$NB28/note.md"
{
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$iof"
# _nn_resolve_gawk prefers plain awk when it is GNU – shim both names
real_gawk=$(command -v "$NN_TEST_GAWK")
{
  printf '#!/usr/bin/env bash\n'
  printf 'for a in "$@"; do case "$a" in *emit_b1*) exit 7 ;; esac; done\n'
  printf 'exec %s "$@"\n' "$real_gawk"
} > "$WORK/gawkshim/gawk"
chmod +x "$WORK/gawkshim/gawk"
cp "$WORK/gawkshim/gawk" "$WORK/gawkshim/awk"
chmod +x "$WORK/gawkshim/awk"
(cd "$NB28" && PATH="$WORK/gawkshim:$PATH" NO_COLOR=1 bash "$REPO/bin/nn" doctor --fix-frontmatter </dev/null 2>&1) > "$WORK/doctor.out"
grep -q 'read/write failed' "$WORK/doctor.out" || fail "repair I/O failure not reported distinctly"
[[ -e "$iof.bak" ]] || fail "backup must be kept after repair I/O failure"

# ── Corruption beyond the diagnostic 2000-file cap is still repaired ──────
NB29="$WORK/nb-bigcap"
mkdir -p "$NB29"
for i in $(seq 1 2000); do printf -- '---\ntype: task\n---\nb\n' > "$NB29/f$i.md"; done
{
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$NB29/zz-corrupt.md"
run_doctor "$NB29" --fix-frontmatter || fail "doctor --fix-frontmatter (2001 files) exited non-zero"
grep -q 'repaired zz-corrupt.md (backup:' "$WORK/doctor.out" || fail "corruption beyond diagnostic cap not repaired"

# ── Newline-named notes: warned about, never phantom-scanned ─────────────
NB22="$WORK/nb-newline"
mkdir -p "$NB22"
mk_note "$NB22/ok.md" crlf 0 '---' 'type: task' '---' 'body'
mk_note "$NB22/nl"$'\n'"name.md" crlf 0 '---' 'type: task' '---' 'body'
run_doctor "$NB22" || fail "doctor exited non-zero on newline-named notebook"
grep -q 'contain a newline' "$WORK/doctor.out" || fail "newline-filename warning not shown"
grep -q 'no frontmatter' "$WORK/doctor.out" && fail "phantom row counted as no-frontmatter note"

# ── Ambient NN_REPAIR_CHECK must never flip repair into check mode ───────
NB21="$WORK/nb-envcheck"
mkdir -p "$NB21"
ec="$NB21/note.md"
{
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$ec"
(cd "$NB21" && NN_REPAIR_CHECK=1 NO_COLOR=1 bash "$REPO/bin/nn" doctor --fix-frontmatter </dev/null >/dev/null 2>&1)
printf -- '---\r\ntype: task\r\nstatus: done\r\n---\r\nbody\r\n' > "$WORK/ec.expected"
assert_bytes "$ec" "$WORK/ec.expected" "ambient NN_REPAIR_CHECK does not corrupt the repair"

# ── Continuation before any key in leading block: not flagged ────────────
NB30="$WORK/nb-cont-first"
mkdir -p "$NB30"
cf="$NB30/note.md"
{
  printf -- '---\n  - orphan item\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$cf"
cp "$cf" "$WORK/cf.orig"
run_doctor "$NB30" --fix-frontmatter || fail "doctor --fix-frontmatter (cont-first) exited non-zero"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "continuation-first block flagged despite repair refusing it"
assert_bytes "$cf" "$WORK/cf.orig" "continuation-first note left untouched"

# ── Mid-line CR in leading block: not flagged (repair would refuse) ──────
NB31="$WORK/nb-midcr"
mkdir -p "$NB31"
mc="$NB31/note.md"
{
  printf -- '---\n\rtype: task\n---\n'
  printf -- '---\r\ntitle: x\r\ntype: note\r\n---\r\nbody\r\n'
} > "$mc"
cp "$mc" "$WORK/mc.orig"
run_doctor "$NB31" --fix-frontmatter || fail "doctor --fix-frontmatter (mid-CR) exited non-zero"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "mid-line-CR block flagged despite repair refusing it"
assert_bytes "$mc" "$WORK/mc.orig" "mid-CR note left untouched"

# ── Empty leading fence block: not flagged (repair would refuse) ─────────
NB32="$WORK/nb-emptyb1"
mkdir -p "$NB32"
eb="$NB32/note.md"
printf -- '---\n---\n---\ntype: task\nextra: y\n---\nbody\n' > "$eb"
cp "$eb" "$WORK/eb.orig"
run_doctor "$NB32" --fix-frontmatter || fail "doctor --fix-frontmatter (empty b1) exited non-zero"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "empty leading block flagged despite repair refusing it"
assert_bytes "$eb" "$WORK/eb.orig" "empty-leading-block note left untouched"

# ── Skipped-path reporting: pre-existing .bak triggers a deterministic ───
# skip with the note untouched and the precious .bak preserved
NB33="$WORK/nb-bakexists"
mkdir -p "$NB33"
bk="$NB33/note.md"
{
  printf -- '---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\n---\r\nbody\r\n'
} > "$bk"
printf 'precious pre-existing backup\n' > "$bk.bak"
cp "$bk" "$WORK/bk.orig"
run_doctor "$NB33" --fix-frontmatter || fail "doctor --fix-frontmatter (bak exists) exited non-zero"
grep -q 'skipped note.md' "$WORK/doctor.out" || fail "bak-exists skip not reported"
grep -q 'skipped 1' "$WORK/doctor.out" || fail "skip not counted in summary"
assert_bytes "$bk" "$WORK/bk.orig" "note untouched when its .bak already exists"
printf 'precious pre-existing backup\n' > "$WORK/bk.bak.expected"
assert_bytes "$bk.bak" "$WORK/bk.bak.expected" "pre-existing .bak preserved byte-exact"

# ── \r\r-ended damage: still flagged and repaired (repair accepts it) ────
# (a mid-value/extra-trailing CR does NOT refuse in the repair matcher, so
# the scan must keep flagging such notes — one-strip classification parity)
NB34="$WORK/nb-doublecr"
mkdir -p "$NB34"
dc="$NB34/note.md"
printf -- '---\r\r\nstatus: done\r\r\n---\r\r\n---\r\r\ntype: task\r\r\ntitle: x\r\r\n---\r\r\nbody\r\r\n' > "$dc"
run_doctor "$NB34" --fix-frontmatter || fail "doctor --fix-frontmatter (double CR) exited non-zero"
grep -q 'repaired note.md (backup:' "$WORK/doctor.out" || fail "double-CR damage not flagged/repaired"
printf -- '---\r\ntype: task\r\r\ntitle: x\r\r\nstatus: done\r\r\n---\r\nbody\r\r\n' > "$WORK/dc.expected"
assert_bytes "$dc" "$WORK/dc.expected" "double-CR merge: untouched lines verbatim, rewritten in detected style"

# ── CR inside a fence line: not flagged (repair's fence test refuses) ────
NB35="$WORK/nb-fencecr"
mkdir -p "$NB35"
fc="$NB35/note.md"
{
  printf -- '\r---\nstatus: done\n---\n'
  printf -- '---\r\ntype: task\r\ntitle: y\r\n---\r\nbody\r\n'
} > "$fc"
cp "$fc" "$WORK/fc.orig"
run_doctor "$NB35" --fix-frontmatter || fail "doctor --fix-frontmatter (fence CR) exited non-zero"
grep -q 'appear to have a duplicated frontmatter' "$WORK/doctor.out" && fail "CR-in-fence block flagged despite repair refusing it"
assert_bytes "$fc" "$WORK/fc.orig" "CR-in-fence note left untouched"

# ── Byte-0 BOM dup note: flagged and repaired (l_t must strip line-1 BOM) ─
NB36="$WORK/nb-bom0dup"
mkdir -p "$NB36"
b0="$NB36/note.md"
{
  printf '\357\273\277'
  printf -- '---\r\nstatus: done\r\n---\r\n'
  printf -- '---\r\ntype: task\r\ntitle: z\r\n---\r\nbody\r\n'
} > "$b0"
run_doctor "$NB36" --fix-frontmatter || fail "doctor --fix-frontmatter (byte-0 BOM dup) exited non-zero"
grep -q 'repaired note.md (backup:' "$WORK/doctor.out" || fail "byte-0 BOM dup note not flagged/repaired"
{
  printf '\357\273\277'
  printf -- '---\r\ntype: task\r\ntitle: z\r\nstatus: done\r\n---\r\nbody\r\n'
} > "$WORK/b0.expected"
assert_bytes "$b0" "$WORK/b0.expected" "byte-0 BOM dup repaired byte-exact, BOM preserved"

# ── --help works in any argument position; unknown flags error ────────────
(cd "$NB17" && bash "$REPO/bin/nn" doctor --fix-frontmatter --help </dev/null >/dev/null 2>&1) \
  || fail "doctor --fix-frontmatter --help should exit 0"
(cd "$NB17" && bash "$REPO/bin/nn" doctor --bogus </dev/null >/dev/null 2>&1)
[[ $? -eq 2 ]] || fail "doctor --bogus should exit 2"
# a mistyped flag without dashes must NOT silently run a plain check
(cd "$NB17" && bash "$REPO/bin/nn" doctor fix-frontmatter </dev/null >/dev/null 2>&1)
[[ $? -eq 2 ]] || fail "doctor with positional argument should exit 2"

# ── watch mode on an inotify-blind filesystem (WSL /mnt/c = 9p on WSL2,
#    DrvFS on WSL1; SMB/CIFS mounts) warns to switch to poll: the watcher
#    runs but silently never fires there.  The fstype is read from
#    /proc/self/mountinfo; NN_MOUNTINFO overrides it with a fake single
#    root mount so the check is deterministic – independent of the real
#    /tmp filesystem, which could itself be NFS/9p on some CI hosts. ──────
NBFS="$WORK/nb-fstype"; mkdir -p "$NBFS"
mk_note "$NBFS/a.md" lf 0 '---' 'type: task' 'status: new' '---' 'body'
_mkmi() { printf '1 1 0:1 / / rw - %s none rw\n' "$1" > "$2"; }
# both WSL fstypes must warn (9p = WSL2, drvfs = WSL1 – the latter is why a
# `stat -f` magic-number probe was insufficient) as must SMB/CIFS
for _fs in 9p drvfs cifs; do
  _mkmi "$_fs" "$WORK/mi-$_fs"
  (cd "$NBFS" && NO_COLOR=1 NN_MOUNTINFO="$WORK/mi-$_fs" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/fs-$_fs.out"
  grep -qi "'$_fs' filesystem" "$WORK/fs-$_fs.out" || fail "no watch-on-$_fs warning (inotify-blind fs auto-refresh gap)"
  grep -qi 'refresh.mode = "poll"' "$WORK/fs-$_fs.out" || fail "$_fs fstype warning did not recommend poll mode"
done
# a normal fstype must NOT warn (deterministic control via fake ext4 mount)
_mkmi ext4 "$WORK/mi-ext4"
(cd "$NBFS" && NO_COLOR=1 NN_MOUNTINFO="$WORK/mi-ext4" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/fs-ext4.out"
grep -qi 'deliver no change events' "$WORK/fs-ext4.out" && fail "spurious fstype warning on a normal (ext4) filesystem"
# NFS must NOT warn: local inotify DOES fire for the host's own edits there,
# so watch mode still works for a single-user notebook
_mkmi nfs "$WORK/mi-nfs"
(cd "$NBFS" && NO_COLOR=1 NN_MOUNTINFO="$WORK/mi-nfs" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/fs-nfs.out"
grep -qi 'deliver no change events' "$WORK/fs-nfs.out" && fail "fstype warning nagged an NFS notebook (local edits do fire inotify)"
# under refresh.mode = "poll" (USER-scope preference) the warning must NOT
# fire even on 9p
UHFS="$WORK/uhome-fstype"; mkdir -p "$UHFS/notenav"
printf '[refresh]\nmode = "poll"\n' > "$UHFS/notenav/config.toml"
(cd "$NBFS" && NO_COLOR=1 XDG_CONFIG_HOME="$UHFS" NN_MOUNTINFO="$WORK/mi-9p" bash "$REPO/bin/nn" doctor </dev/null 2>&1) > "$WORK/fs-poll.out"
grep -qi 'deliver no change events' "$WORK/fs-poll.out" && fail "fstype warning fired under poll mode (should warn for watch only)"

finish
