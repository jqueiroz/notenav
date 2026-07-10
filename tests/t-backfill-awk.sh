#!/usr/bin/env bash
# Unit tests for the emitted .awk_fm_backfill (newnote zk-backfill helper)
# across line-ending/BOM variants.
set -u
. "$(dirname "$0")/lib.sh"

WORK=$(mktemp -d /tmp/nn-t-backfill.XXXXXX) || exit 2
trap 'rm -rf "$WORK"' EXIT
NOTEBOOK="$WORK/notebook"
CAP="$WORK/cap"
mkdir -p "$NOTEBOOK"
mk_note "$NOTEBOOK/seed.md" lf 0 '---' 'type: task' '---' '# Seed'

capture_nn_dir "$NOTEBOOK" "$CAP" || finish
[ -f "$CAP/.awk_fm_backfill" ] || { fail ".awk_fm_backfill not emitted"; finish; }

nn_gawk=$(cat "$CAP/.gawk" 2>/dev/null || echo gawk)

run_backfill() { # <in> <out>
  nn_type=task nn_status=new nn_created='2026-07-09 12:00' \
    "$nn_gawk" -f "$CAP/.awk_fm_backfill" "$1" > "$2"
}

f="$WORK/in.md"
o="$WORK/out.md"
x="$WORK/expected.md"

# Missing fields are inserted before the closing fence, in the file's EOL style
for enc in "lf 0" "crlf 0" "crlf 1"; do
  set -- $enc
  mk_note "$f" "$1" "$2" '---' 'title: x' '---' 'body'
  mk_note "$x" "$1" "$2" '---' 'title: x' 'type: task' 'status: new' \
    'created: 2026-07-09 12:00' '---' 'body'
  run_backfill "$f" "$o"
  assert_bytes "$o" "$x" "backfill inserts missing fields ($1 bom=$2)"
done

# Present fields are not duplicated
mk_note "$f" crlf 0 '---' 'type: idea' '---' 'body'
mk_note "$x" crlf 0 '---' 'type: idea' 'status: new' 'created: 2026-07-09 12:00' '---' 'body'
run_backfill "$f" "$o"
assert_bytes "$o" "$x" "backfill keeps existing type (crlf)"

# A bare "type:" key (empty value) still counts as present – no duplicate key
mk_note "$f" crlf 0 '---' 'type:' '---' 'body'
mk_note "$x" crlf 0 '---' 'type:' 'status: new' 'created: 2026-07-09 12:00' '---' 'body'
run_backfill "$f" "$o"
assert_bytes "$o" "$x" "bare type: key not duplicated (crlf)"

finish
