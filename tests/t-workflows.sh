#!/usr/bin/env bash
# Characterization pins for the built-in workflows: the config-derived
# colour/icon/label state each workflow resolves to is captured as a golden
# .awk_color_body / .awk_color_stats program.  A behaviour-preserving change
# to config loading (e.g. batching the per-value jq extraction) must
# reproduce these byte-for-byte; an intentional rendering change regenerates
# the fixtures in one deliberate step.
# shellcheck shell=bash
set -u
cd "$(dirname "$0")" || exit 2
. ./lib.sh

WORK=$(mktemp -d "${TMPDIR:-/tmp}/nn-t-workflows.XXXXXX") || { echo "mktemp failed" >&2; exit 2; }
trap 'rm -rf "$WORK"' EXIT

require_gawk

FIX="$REPO/tests/fixtures/color-awk"

for wf in zenith cuboid ado gtd zettelkasten; do
  NB="$WORK/nb-$wf"; CAP="$WORK/cap-$wf"; mkdir -p "$NB/.nn"
  printf 'extends = "%s"\n' "$wf" > "$NB/.nn/workflow.toml"
  printf -- '---\ntype: task\nstatus: new\ntitle: t\n---\nb\n' > "$NB/n.md"
  if ! capture_nn_dir "$NB" "$CAP"; then
    fail "capture failed for workflow '$wf'"
    continue
  fi
  # The colour-body program encodes every type icon+colour, status colour,
  # and priority colour+label the workflow resolves – the exact output of
  # the per-value config extraction under test.
  assert_bytes "$CAP/.awk_color_body" "$FIX/$wf.awk" \
    "workflow '$wf' colour-body drifted from golden (config extraction changed?)"
  # The stats program renders the group labels/counts template, a second
  # independent view of the same resolved maps.
  assert_bytes "$CAP/.awk_color_stats" "$FIX/$wf.stats.awk" \
    "workflow '$wf' stats program drifted from golden"
  # Direct snapshot of every resolved config map: type/status/priority
  # values, icons, colours, descriptions, lifecycle, labels, ordering –
  # the raw output of the per-value extraction (stronger than the rendered
  # awk above).  All .schema_* files, concatenated in a stable order.
  # LC_ALL=C sort: the concatenation ORDER must be collation-stable so the
  # golden matches regardless of the locale the suite runs under (C vs UTF-8
  # order '_' differently); the file CONTENTS are locale-independent.
  ( cd "$CAP" && for _scf in $(ls .schema_* 2>/dev/null | LC_ALL=C sort); do
      printf '== %s ==\n' "$_scf"; cat "$_scf"; printf '\n'
    done ) > "$WORK/$wf.schema"
  assert_bytes "$WORK/$wf.schema" "$REPO/tests/fixtures/schema/$wf.txt" \
    "workflow '$wf' resolved config maps drifted from golden (extraction changed?)"
done

finish
