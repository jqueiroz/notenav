Validate fzf keybindings in `lib/notenav.sh` for correctness and consistency with documentation.

Read `lib/notenav.sh` and `README.md`. Extract all `--bind` lines from the main fzf invocation (faceted browser mode). Report every issue found.

## Checks

### 1. Mode leak detection

For every `--bind` line whose `transform[...]` block reads `.nn-mode`:

- **Bare `else` with command-mode action:** If the `else` branch performs a command-mode action (executing a script, running filter.sh, opening a picker), flag it. Command-mode actions must be guarded behind `test -z "$m"` (use `elif test -z "$m"` instead of bare `else`). See GUIDELINES.md for the rule.
- **Bare `else` with mode transition is OK:** An `else` branch that writes to `.nn-mode` and changes the prompt/header (entering a prefix mode) is a mode transition, not a command-mode action. These are fine -- do NOT flag them.
- **Pattern to flag:** `else echo 'execute(...)` or `else .../filter.sh ...` without a preceding `test -z "$m"` check.
- **Pattern that is OK:** `elif test -z "$m"; then echo 'execute(...)` or `elif test -z "$m"; then .../filter.sh ...`.

### 2. Keybinding table sync

Cross-reference the `--bind` lines in `lib/notenav.sh` with the keybinding table in `README.md`:

- Every user-facing `--bind` key should have a row in the README table.
- Every row in the README table should correspond to an actual `--bind` line.
- Skip internal bindings that aren't user-facing (`start`, `change`).
- Check that the described behavior in the README matches what the binding actually does.

### 3. Guideline compliance

Check each `--bind` line against the keybinding rules in `GUIDELINES.md`:

- No modifier keys other than `ctrl-j`/`ctrl-k` (no ctrl-*, alt-*, meta-*).
- No `[ ]` (shell test syntax) inside `transform[...]` -- must use `test` instead.

## Output format

For each finding:
1. The binding key (e.g., `g`, `n`, `ctrl-x`)
2. The issue
3. The current code (abbreviated if very long)
4. The fix

Group by check category. End with a pass/fail summary.

Do NOT make any changes -- this is a check only.
