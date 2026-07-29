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

out="$WORK/out.txt"
(cd "$NOTEBOOK" && TERM=xterm bash "$REPO/bin/nn" type=task </dev/null 2>"$WORK/stderr") > "$out"
rc=$?
[[ "$rc" -eq 0 ]] || { fail "ad-hoc query exited $rc"; sed 's/^/    /' "$WORK/stderr" | head -5; }

for m in alpha-lf-marker bravo-crlf-marker charlie-bomcrlf-marker delta-bomlf-marker; do
  grep -q "$m" "$out" || fail "missing note in query output: $m"
done
if grep -q $'\r' "$out"; then
  fail "query output contains CR bytes"
fi
grep -q 'echo-newline-marker' "$out" && fail "newline-named note must be excluded, not listed"
grep -q '^name.md' "$out" && fail "phantom row leaked from newline-named note"

# ── zk row-normalization stage (extracted from lib): fragment consumer ───
# Split-row fragments must be consumed exactly, never eating the next real
# note, for any pure-newline path shape.  The stage's BOM-divert regex uses
# gawk \x escapes, so it requires gawk (a hard production dependency;
# installed on every CI leg) – fail fast with a clear message rather than
# letting a silently non-matching regex read as a lib regression
if ! command -v gawk >/dev/null 2>&1; then
  fail "gawk not installed – required by the zk-stage tests"
  finish
fi
_zkawk=gawk
_zkanchor='rem { rem -='
_zkanchors=$(grep -cF "$_zkanchor" "$REPO/lib/notenav.sh")
# extract from the first latch rule to the program's closing brace+quote line
_zkstage=$(awk '/rem \{ rem -=/{s=1} s{print} s && /^[[:space:]]*\}.$/{exit}' "$REPO/lib/notenav.sh")
if [[ "$_zkanchors" -ne 1 || -z "$_zkstage" || $(wc -l <<< "$_zkstage") -gt 14 ]]; then
  fail "zk stage extraction anchors drifted (found $_zkanchors) – update this test"
else
  _zkprog="${_zkstage%\'}"
  # shellcheck disable=SC2059  # the case strings ARE printf formats (\t/\n escapes)
  run_zkstage() { printf "$1" | "$_zkawk" -F'\t' -v bomlist= "$_zkprog" 2>/dev/null; }
  # sanity: the extracted program must execute at all (distinct diagnosis)
  if ! printf 'a\tb\tc\td\te\t/f\tg\th\n' | "$_zkawk" -F'\t' -v bomlist= "$_zkprog" >/dev/null 2>&1; then
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
    _zkout=$(printf '\t\t\t\t\xef\xbb\xbf---title: x\t/p/b.md\t2026\t2026\n' \
      | "$_zkawk" -F'\t' -v bomlist="$_zkbl" "$_zkprog" 2>/dev/null)
    [[ -z "$_zkout" ]] || fail "BOM-titled zk row printed despite an available side list"
    grep -qxF '/p/b.md' "$_zkbl" || fail "BOM-titled zk row's path not diverted to the side list"
    _zkout=$(run_zkstage '\t\t\t\t\xef\xbb\xbf---title: x\t/p/b.md\t2026\t2026\n')
    [[ -n "$_zkout" ]] || fail "degraded mode (no side list) dropped the BOM-titled row"
  fi
fi

finish
