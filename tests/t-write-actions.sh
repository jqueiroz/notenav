#!/usr/bin/env bash
# Byte-level matrix for the generated write scripts (action.sh, bulkedit_update.sh)
# across line-ending/BOM variants. Fixtures and expected outputs are built with
# printf at runtime so git line-ending settings can never affect them.
set -u
. "$(dirname "$0")/lib.sh"

WORK=$(mktemp -d /tmp/nn-t-write.XXXXXX) || exit 2
trap 'rm -rf "$WORK"' EXIT
NOTEBOOK="$WORK/notebook"
CAP="$WORK/cap"
mkdir -p "$NOTEBOOK"
mk_note "$NOTEBOOK/seed.md" lf 0 '---' 'type: task' 'status: new' '---' '# Seed'

capture_nn_dir "$NOTEBOOK" "$CAP" || finish

run_action() { bash "$CAP/action.sh" "$CAP" "$@" >/dev/null 2>&1; }
run_bulk() { bash "$CAP/bulkedit_update.sh" "$@" >/dev/null 2>&1; }

# Standard fixture bodies
BASE=('---' 'type: task' 'status: new' '---' '# Marker note' 'body text')

f="$WORK/note.md"
x="$WORK/expected.md"

# ── action.sh: set existing key ────────────────────────────────────────
for enc in "lf 0" "crlf 0" "crlf 1" "lf 1"; do
  set -- $enc
  mk_note "$f" "$1" "$2" "${BASE[@]}"
  mk_note "$x" "$1" "$2" '---' 'type: task' 'status: active' '---' '# Marker note' 'body text'
  run_action status active "$f"
  assert_bytes "$f" "$x" "set-existing status ($1 bom=$2)"
done

# ── action.sh: set absent key (insert before closing fence) ───────────
for enc in "lf 0" "crlf 0" "crlf 1"; do
  set -- $enc
  mk_note "$f" "$1" "$2" "${BASE[@]}"
  mk_note "$x" "$1" "$2" '---' 'type: task' 'status: new' 'priority: 2' '---' '# Marker note' 'body text'
  run_action priority 2 "$f"
  assert_bytes "$f" "$x" "set-absent priority ($1 bom=$2)"
done

# ── action.sh: clear existing key ──────────────────────────────────────
for enc in "lf 0" "crlf 0"; do
  set -- $enc
  mk_note "$f" "$1" "$2" "${BASE[@]}"
  mk_note "$x" "$1" "$2" '---' 'type: task' '---' '# Marker note' 'body text'
  run_action status '' "$f"
  assert_bytes "$f" "$x" "clear status ($1 bom=$2)"
done

# ── action.sh: same-value set must be a byte-identical no-op ───────────
for enc in "lf 0" "crlf 0" "crlf 1"; do
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

# ── bulkedit_update.sh: multi-field incl. multi-line tags ──────────────
for enc in "lf 0" "crlf 0" "crlf 1"; do
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

finish
