#!/usr/bin/env bash
# notenav test runner: executes every tests/t-*.sh and reports pass/fail.
set -u
cd "$(dirname "$0")" || exit 2
overall=0
for t in t-*.sh; do
  printf '== %s\n' "$t"
  if bash "$t"; then
    printf '   PASS\n'
  else
    printf '   FAIL\n'
    overall=1
  fi
done
exit "$overall"
