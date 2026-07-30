#!/usr/bin/env bash
# Read path: ad-hoc queries must return identical, CR-free results for the
# same note regardless of its encoding (LF, CRLF, BOM variants).
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

WORK=$(mktemp -d /tmp/nn-t-read.XXXXXX) || exit 2
trap 'rm -rf "$WORK"' EXIT
NOTEBOOK="$WORK/notebook"
mkdir -p "$NOTEBOOK"

mk_note "$NOTEBOOK/a.md" lf 0 '---' 'title: alpha-lf-marker' 'type: task' 'status: new' '---' 'body'
mk_note "$NOTEBOOK/b.md" crlf 0 '---' 'title: bravo-crlf-marker' 'type: task' 'status: new' '---' 'body'
mk_note "$NOTEBOOK/c.md" crlf 1 '---' 'title: charlie-bomcrlf-marker' 'type: task' 'status: new' '---' 'body'
mk_note "$NOTEBOOK/d.md" lf 1 '---' 'title: delta-bomlf-marker' 'type: task' 'status: new' '---' 'body'
# Unsupported: a newline in the filename must be excluded entirely (phantom
# rows in line-oriented pipelines could misdirect writes to innocent files)
mk_note "$NOTEBOOK/nl"$'\n'"name.md" crlf 0 '---' 'title: echo-newline-marker' 'type: task' 'status: new' '---' 'body'

# ── zk row-normalization stage (extracted from lib): anchor checks ───────
# The stage's BOM-divert regex uses gawk \x escapes, but the extraction and
# anchor checks here are plain POSIX; they run BEFORE require_gawk so anchor
# drift still gets its own diagnosis on machines without GNU awk
_zkanchor='BEGIN { bomlist = ENVIRON'
_zkanchors=$(grep -cF "$_zkanchor" "$REPO/lib/notenav.sh")
# extract from the BEGIN line to the program's closing brace+quote line
_zkstage=$(awk '/BEGIN \{ bomlist = ENVIRON/{s=1} s{print} s && /^[[:space:]]*\}.$/{exit}' "$REPO/lib/notenav.sh")
_zkstage_ok=1
if [[ "$_zkanchors" -ne 1 || -z "$_zkstage" || $(wc -l <<< "$_zkstage") -gt 15 ]]; then
  fail "zk stage extraction anchors drifted (found $_zkanchors) – update this test"
  _zkstage_ok=0
fi

# ── _nn_mtime_rows: symlinked notes must be listed (find -L, stat -L) ────
# The zk-backend BOM re-list feeds explicit paths through this helper; a
# plain find -type f drops symlink arguments, whereas the [[ -f ]] loop it
# replaced followed them.  Pure find/stat – gawk-independent.
NOTENAV_ROOT="$REPO" . "$REPO/lib/notenav.sh" 2>/dev/null || fail "sourcing lib/notenav.sh failed"
mkdir -p "$WORK/mt"
printf 'x\n' > "$WORK/mt/real.md"
ln -s "$WORK/mt/real.md" "$WORK/mt/link.md"
_mtout=$(_nn_mtime_rows -L "$WORK/mt/real.md" "$WORK/mt/link.md" -maxdepth 0 -type f 2>/dev/null)
printf '%s\n' "$_mtout" | cut -f1 | grep -qxF "$WORK/mt/real.md" \
  || fail "_nn_mtime_rows missing the regular file"
printf '%s\n' "$_mtout" | cut -f1 | grep -qxF "$WORK/mt/link.md" \
  || fail "_nn_mtime_rows dropped the symlinked note"
_mtcnt=$(printf '%s\n' "$_mtout" | grep -c .)
[[ "$_mtcnt" -eq 2 ]] || fail "_nn_mtime_rows emitted $_mtcnt rows (want 2)"

# after ALL gawk-independent checks (per the require_gawk contract): from
# here on bin/nn and the extracted stage run, both of which need GNU awk
require_gawk

out="$WORK/out.txt"
(cd "$NOTEBOOK" && TERM=xterm bash "$REPO/bin/nn" type=task </dev/null 2>"$WORK/stderr") > "$out"
rc=$?
[[ "$rc" -eq 0 ]] || { fail "ad-hoc query exited $rc"; sed 's/^/    /' "$WORK/stderr" | head -5; }

# A field value containing an AWK metacharacter ('$') must be matched
# literally, with no interpreter warning: '$' is not special inside an AWK
# string literal, so the value escaper must NOT emit the undefined '\$'
mk_note "$NOTEBOOK/dollar.md" lf 0 '---' 'title: dollar-tag-marker' 'type: task' 'status: new' 'tags: q4$budget' '---' 'body'
dout="$WORK/dollar.txt"
(cd "$NOTEBOOK" && TERM=xterm bash "$REPO/bin/nn" 'tag=q4$budget' </dev/null 2>"$WORK/dstderr") > "$dout"
grep -q 'dollar-tag-marker' "$dout" || fail "\$-containing tag value not matched"
grep -qi 'escape sequence' "$WORK/dstderr" && fail "awk warned on \$ in a tag value (undefined \\\$ escape emitted)"
[[ -s "$WORK/dstderr" ]] && { fail "unexpected stderr on \$-tag query:"; sed 's/^/    /' "$WORK/dstderr" | head -3; }
rm -f "$NOTEBOOK/dollar.md"

for m in alpha-lf-marker bravo-crlf-marker charlie-bomcrlf-marker delta-bomlf-marker; do
  grep -q "$m" "$out" || fail "missing note in query output: $m"
done
if grep -q $'\r' "$out"; then
  fail "query output contains CR bytes"
fi
grep -q 'echo-newline-marker' "$out" && fail "newline-named note must be excluded, not listed"
grep -q '^name.md' "$out" && fail "phantom row leaked from newline-named note"

# ── zk stage execution: fragment consumer ────────────────────────────────
# Split-row fragments must be consumed exactly, never eating the next real
# note, for any pure-newline path shape
if [[ "$_zkstage_ok" -eq 1 ]]; then
  _zkprog="${_zkstage%\'}"
  # the side-list path rides ENVIRON (never -v: awk -v escape-processes the
  # value); the optional second arg supplies it, default empty = degraded
  # shellcheck disable=SC2059  # the case strings ARE printf formats (\t/\n escapes)
  run_zkstage() { printf "$1" | NN_ZK_BOMLIST="${2-}" "$NN_TEST_GAWK" -F'\t' "$_zkprog" 2>/dev/null; }
  # sanity: the extracted program must execute at all (distinct diagnosis)
  if ! printf 'a\tb\tc\td\te\t/f\tg\th\n' | NN_ZK_BOMLIST='' "$NN_TEST_GAWK" -F'\t' "$_zkprog" >/dev/null 2>&1; then
    fail "extracted zk stage does not execute – extraction problem, not a latch regression"
  else
    for case_in in \
      'task\topen\tp1\tt\tti\t/bad\nname.md\t2026\t2026\ntask\topen\tp2\tt\tGood\t/good.md\t2026\t2026\n' \
      'task\topen\tp1\tt\tti\t/a\n\nb.md\t2026\t2026\ntask\topen\tp2\tt\tGood\t/good.md\t2026\t2026\n' \
      'task\tnew\t\ta\tT\t/nb/a\nb\tc\td\te\tf\t/g.md\t2026\t2026\ntask\tnew\t\ta\tGood\t/good.md\t2026\t2026\n' \
      'task\topen\tp1\tt\tti\t/a\n\n\nb.md\t2026\t2026\ntask\topen\tp2\tt\tGood\t/good.md\t2026\t2026\n' \
      'task\topen\tp1\tt\tti\t\nname.md\t2026\t2026\ntask\topen\tp2\tt\tGood\t/good.md\t2026\t2026\n' \
      'task\topen\tp1\tt\tti\t/a\n\t2026\t2026\ntask\topen\tp2\tt\tGood\t/good.md\t2026\t2026\n'; do
      _zkout=$(run_zkstage "$case_in")
      [[ "$_zkout" == *Good* ]] || fail "legit row eaten after fragments: $case_in"
      _zkcnt=$(printf '%s\n' "$_zkout" | grep -c .)
      [[ "$_zkcnt" -eq 1 ]] || fail "zk stage emitted $_zkcnt rows (want 1) for: $case_in"
    done
    # a zk-unparsed BOM row (U+FEFF-prefixed title): with a side list the
    # path is diverted for native re-listing; without one (mktemp failed)
    # the garbled row is still printed – never dropped
    _zkbl="$WORK/bomlist"
    : > "$_zkbl"
    _zkout=$(run_zkstage '\t\t\t\t\xef\xbb\xbf---title: x\t/p/b.md\t2026\t2026\n' "$_zkbl")
    [[ -z "$_zkout" ]] || fail "BOM-titled zk row printed despite an available side list"
    grep -qxF '/p/b.md' "$_zkbl" || fail "BOM-titled zk row's path not diverted to the side list"
    _zkout=$(run_zkstage '\t\t\t\t\xef\xbb\xbf---title: x\t/p/b.md\t2026\t2026\n')
    [[ -n "$_zkout" ]] || fail "degraded mode (no side list) dropped the BOM-titled row"
    # a side-list path containing a backslash must be used byte-for-byte
    # (with -v transport, escape processing would mangle the redirect
    # target: the row vanishes and gawk aborts the whole stage)
    mkdir -p "$WORK/"'bs\dir'
    _zkbl2="$WORK/"'bs\dir/bomlist'
    : > "$_zkbl2"
    _zkout=$(run_zkstage '\t\t\t\t\xef\xbb\xbf---title: x\t/p/c.md\t2026\t2026\n' "$_zkbl2")
    [[ -z "$_zkout" ]] || fail "BOM row printed despite a backslash-path side list"
    grep -qxF '/p/c.md' "$_zkbl2" || fail "backslash side-list path mangled – BOM row not diverted"
  fi
fi

finish
