#!/usr/bin/env bash
# zk backend: a zk-initialized notebook with CRLF/BOM notes must list cleanly
# through `zk list` (CR-free output, correct fields). Skips when zk is not
# installed (CI legs without zk still get the native-backend coverage from
# the other test files).
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

require_gawk
if ! command -v zk >/dev/null 2>&1; then
  echo "  SKIP: zk not installed"
  finish
fi

WORK=$(mktemp -d /tmp/nn-t-zk.XXXXXX) || exit 2
trap 'rm -rf "$WORK"' EXIT
NOTEBOOK="$WORK/notebook"
mkdir -p "$NOTEBOOK"

if ! (cd "$NOTEBOOK" && zk init --no-input . >/dev/null 2>&1); then
  echo "  SKIP: zk init failed (unsupported zk version?)"
  finish
fi

mk_note "$NOTEBOOK/a.md" crlf 0 '---' 'title: zk-crlf-marker' 'type: task' 'status: new' '---' 'body'
mk_note "$NOTEBOOK/b.md" crlf 1 '---' 'title: zk-bomcrlf-marker' 'type: task' 'status: new' '---' 'body'
mk_note "$NOTEBOOK/c.md" lf 0 '---' 'title: zk-lf-marker' 'type: task' 'status: new' '---' 'body'

out="$WORK/out.txt"
(cd "$NOTEBOOK" && TERM=xterm bash "$REPO/bin/nn" type=task </dev/null 2>"$WORK/stderr") > "$out"
rc=$?
[[ "$rc" -eq 0 ]] || { fail "zk-backend query exited $rc"; sed 's/^/    /' "$WORK/stderr" | head -5; }

for m in zk-crlf-marker zk-bomcrlf-marker zk-lf-marker; do
  grep -q "$m" "$out" || fail "missing note in zk-backend output: $m"
done
grep -q $'\r' "$out" && fail "zk-backend output contains CR bytes"

finish
