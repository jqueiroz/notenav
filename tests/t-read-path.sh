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

# ── zk row-normalization stage (extracted from lib): fragment latch ──────
# A split row's fragments must be dropped WITHOUT eating the next real note
# (the latch must consume before the short-row rule re-arms it)
_zkstage=$(awk '/skip \{ skip = 0; next \}/{s=1} s{print} s && /print \}/{exit}' "$REPO/lib/notenav.sh")
if [[ -z "$_zkstage" || $(wc -l <<< "$_zkstage") -gt 6 ]]; then
  fail "zk stage extraction anchors drifted – update this test"
else
  _zkout=$(printf 'task\topen\tp1\tt\tti\t/bad\nname.md\t2026\t2026\ntask\topen\tp2\tt\tGood\t/good.md\t2026\t2026\n' \
    | gawk -F'\t' "${_zkstage%\'}")
  [[ "$_zkout" == *Good* ]] || fail "legit row after split fragments was eaten (latch order)"
  [[ "$_zkout" == *name.md* ]] && fail "split fragment leaked through the zk stage"
  _zkcnt=$(printf '%s\n' "$_zkout" | grep -c .)
  [[ "$_zkcnt" -eq 1 ]] || fail "zk stage emitted $_zkcnt rows, expected 1"
fi

finish
