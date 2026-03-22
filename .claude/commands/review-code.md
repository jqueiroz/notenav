Audit the notenav codebase for best practices across all relevant dimensions.

Read all source files (`bin/nn`, `lib/notenav.sh`, `curl/install.sh`, `flake.nix`, config files) and evaluate against the categories below. For each category, report what's already done well and what needs improvement.

## Categories to audit

### Shell scripting
- **Shebangs**: `#!/usr/bin/env bash` (not hardcoded `/bin/bash`) for portability (macOS ships bash 3.2 at `/bin/bash`)
- **Strict mode**: `set -euo pipefail` where appropriate (standalone scripts yes, sourced libraries need care)
- **Quoting**: all variable expansions properly quoted; `local var; var=$(cmd)` pattern so `local` doesn't mask exit codes
- **Argument handling**: `--` before positional args passed to subcommands to prevent flag injection
- **Globbing safety**: `shopt -s nullglob` where needed, no unquoted globs

### Security
- **Temp files**: no predictable names in `/tmp`; use `mktemp` and scope sentinel files to the temp dir
- **Cleanup**: `trap ... EXIT` for temp dirs so they don't leak on signals
- **Injection**: user-supplied or config-derived values interpolated into AWK/sed must be sanitized (quotes, backslashes, special chars)
- **File operations**: `mv "$file.tmp" "$file"` pattern for atomic writes (already used — verify consistent)
- **Permissions**: temp scripts shouldn't be world-writable; sensitive data not written to predictable paths

### Standards compliance
- **XDG Base Directory Spec**: config via `${XDG_CONFIG_HOME:-$HOME/.config}`, data via `${XDG_DATA_HOME:-$HOME/.local/share}`, runtime via `${XDG_RUNTIME_DIR:-/tmp}`
- **NO_COLOR** ([no-color.org](https://no-color.org)): respect `$NO_COLOR` environment variable
- **TERM=dumb**: degrade gracefully when terminal capabilities are limited
- **POSIX editor**: fallback chain should end with `vi` (POSIX-guaranteed), not `nvim`

### Naming convention (`nn` vs `notenav`)
- **Project-local paths** must use `nn` (e.g. `.nn/`, temp file prefixes `.nn-*`)
- **User-global paths** must use `notenav` (e.g. `~/.config/notenav/`, `~/.local/share/notenav/`)
- **Documentation and branding** must use "notenav" as the product name
- **CLI command** is always `nn`
- No mixed usage: never `.notenav/` in a project root, never `~/.config/nn/`
- See `GUIDELINES.md` for rationale

### Portability (Linux + macOS)
- **`sed -i`**: must never appear — GNU and BSD/macOS `sed -i` have incompatible syntax. Use `sed 's/…' "$file" > "$tmp" && mv "$tmp" "$file"` instead
- **`while read` trailing newlines**: `while IFS= read -r line` skips the last line if the file has no trailing newline. Use `|| [[ -n "$line" ]]` when reading user-editable files
- **`date` vs `stat`**: `date -r <file>` works on macOS but not GNU/Linux (where `-r` expects a timestamp). `stat -c` is GNU-only. Use a fallback chain
- **`readlink -f`**: not available on macOS stock `readlink`. The codebase already has a `_realpath` fallback — verify all usages go through it
- **GNU-only flags**: watch for `grep -P`, `sort -V`, `mktemp --suffix`, and similar GNU extensions

### CLI conventions
- **`--help` / `-h`**: standard help flag
- **Exit codes**: meaningful codes (0 success, 1 general error, 2 usage error)
- **Stderr for errors**: all error/warning messages to stderr (not stdout)
- **`--` separator**: support `--` to end option parsing

### Installation & packaging
- **Install script**: XDG-compliant paths, idempotent, handles updates cleanly
- **Nix flake**: `flake.lock` committed for reproducibility; runtime deps complete
- **Dependency checking**: version requirements verified at startup (fzf 0.44+, bash 4+, yq-go not yq-python)

### Accessibility
- **Color**: respect `NO_COLOR`, don't rely solely on color to convey information (icons help here)
- **Screen readers**: not typically applicable for TUI, but error messages should be plain text

### Code quality
- **DRY**: duplicated logic (e.g., preview script appears twice — faceted and ad-hoc modes)
- **Hardcoded values**: magic numbers or strings that should come from config
- **Error messages**: consistent format, actionable, point to fix

## Output format

For each finding:
1. State the issue concisely
2. Show the current code (file:line)
3. Show the recommended fix
4. Rate: P1 (high impact, fix now), P2 (should fix), P3 (nice to have), P4 (nitpick)

Group findings by category. At the end, provide a summary table sorted by priority.

Do NOT make any changes — this is an audit only. Report findings so the user can decide what to fix.
