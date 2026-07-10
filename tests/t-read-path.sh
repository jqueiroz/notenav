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

finish
