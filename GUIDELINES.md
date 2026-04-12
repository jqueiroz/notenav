# notenav Development Guidelines

Rules and conventions for contributing to notenav.

## Architecture

- Entry point (`bin/nn`) stays minimal – all logic in `lib/notenav.sh`.
- Helper scripts are generated into a per-session `mktemp -d` directory, cleaned up via `EXIT` trap.
- Config values are precomputed once at startup (`nn_precompute_workflow`) and written to temp files (`nn_write_workflow_files`) – helper scripts read flat files, never re-parse TOML/JSON at runtime.

## Shell scripting

- Target **bash 4.2+** (`declare -gA` needs 4.2). Use `#!/usr/bin/env bash` (not hardcoded `/bin/bash`).
- Quote all variable expansions. Use `local var; var=$(cmd)` so `local` doesn't mask exit codes.
- Use `mktemp` for temp files – never predictable names in `/tmp`.
- Sanitize user-supplied or config-derived values before interpolating into AWK/sed expressions (escape `\` and `"`).
- Use `mv "$file.tmp" "$file"` for atomic writes.
- Use `nn_assert "message"` for impossible states. Every `case` that branches on a config enum must have a `*) nn_assert "context: unknown value '$var'" ;;` catch-all. Generated helper scripts define their own local copy of `nn_assert`.
- Enum config values (e.g. `sort_by`, `group_by`, `exit_message`, `priority_plus`, `after_create`, `refresh.mode`) are validated in `nn_precompute_workflow` at startup – runtime catch-alls are defense-in-depth, not the primary check.

### Portability (Linux + macOS + FreeBSD)

- **Never use `sed -i`:** GNU sed requires `sed -i 's/…'`, BSD/macOS/FreeBSD sed requires `sed -i '' 's/…'`. Instead, write to a temp file and `mv`: `sed 's/…' "$file" > "$tmp" && mv "$tmp" "$file"`.
- **`while read` and missing trailing newlines:** `while IFS= read -r line` silently skips the last line if the file has no trailing newline. Use `while IFS= read -r line || [[ -n "$line" ]]` when reading files that users may hand-edit.
- **`date -r` vs `stat -c`:** macOS/FreeBSD have `date -r <file>` but no `stat -c`. GNU/Linux has `stat -c '%y'` but `date -r` expects a timestamp, not a file. Use a fallback chain: `date -r "$file" '+%F' 2>/dev/null || stat -c '%y' "$file" 2>/dev/null | cut -d' ' -f1`.
- **`awk` version flags:** BSD awk (FreeBSD) reads from stdin when given unrecognised flags like `--version` or `-W version`. Always redirect stdin from `/dev/null` when probing awk: `awk --version < /dev/null 2>/dev/null`.

## Keybindings

- **No modifier keys.** Do not use Ctrl, Alt, or Meta keybindings in fzf. Users run notenav inside tmux, terminal emulators, and window managers that may claim these combos, causing keys to be silently eaten. **Exceptions:** `ctrl-j` / `ctrl-k` are used for page-down/page-up across all fzf instances (main TUI and sub-popups) – no plain-key alternative exists for paging without conflicting with the modal key space, and these specific combos are rarely claimed by terminals. `shift-tab` pairs with `tab` for previous/next query preset – plain-key alternatives `[`/`]` cover the same action, but `shift-tab` is a standard expectation alongside `tab` and is not swallowed by terminals. Do not add further modifier-key exceptions.
- **Plain keys only.** Stick to letters, digits, symbols, and Shift variants (uppercase letters). (`ctrl-j`/`ctrl-k` for paging and `shift-tab` alongside `tab` are the sole exceptions – see above.)
- **Use the modal pattern.** notenav has eight input modes: command mode (plain keys), change mode (`c` prefix), filter-by mode (`f` prefix), marks mode (`m` prefix), display mode (`z` prefix), help mode (`?`), search mode (`/`), and content search mode (`/?`). Fit new bindings into this structure.
- **Use `.nn-mode` for prefix-mode state.** Mode state is stored in a single file `.nn-mode` (empty = command mode, `c`/`f`/`m`/`z` = prefix mode). Bindings read it with `m=$(cat .nn-mode)` and check with `test "$m" = z`. Mode entry writes the letter (`echo z > .nn-mode`), mode exit clears it (`: > .nn-mode`). All mode state operations must happen inside `transform[...]` as side effects before the `echo` that produces the fzf action string – never via `execute-silent` at the top level. **Search modes** (`/` and `/?`) use separate flag files `.nn-search` and `.nn-csearch` instead of `.nn-mode`, because they require unbinding/rebinding action keys. **Help overlay** uses `.nn-help` flag file – it is non-blocking (all keys work while help is showing). Content search is entered by pressing `?` while in search mode – the `?` binding checks `.nn-search`/`.nn-csearch` first, then `.nn-help`, then shows help. Bindings that need to be aware of all modes check the flag files first, then fall through to the `.nn-mode` check.
- **Double-press cancels.** Pressing a modal prefix key twice (`cc`, `ff`, `zz`) must exit that mode – identical to pressing the prefix then escape. This keeps mode entry/exit symmetric and discoverable. Exception: `mm` toggles the mark on the current item instead of cancelling, since marks mode uses `m` as both prefix and action.
- **Guard command-mode actions behind `test -z "$m"`.** When a binding has different behavior per mode, its `else` / fallback branch must check that the mode is empty before firing command-mode actions. Without this guard, keys leak through prefix modes – e.g., pressing `c` then `g` would trigger the command-mode `g` action instead of being ignored. Pattern: `if test "$m" = z; then ...; elif test -z "$m"; then ...; fi` (no bare `else`).
- **Never use `[ ]` inside `transform[...]`.** fzf's `transform[CMD]` uses bracket depth counting to find the closing `]`. Shell test syntax `[ expr ]` introduces extra brackets that confuse fzf's parsing, silently truncating the command. Use `test expr` instead – it is identical POSIX behavior without brackets. For complex logic, extract to a helper script.

## Workflow definitions

- Every value in `type.values` must have a corresponding `[type.<name>]` section with `icon`, `color`, and `description`.
- Every value in `status.values` must have a color in `[status.colors]` and entries in `filter_cycle` (unless intentionally omitted, like tombstone statuses).
- Lifecycle transitions (`forward`/`reverse`) must only reference values that exist in `status.values` or `priority.values`.
- Query preset `args` must only reference valid note types, statuses, and priority values from the same workflow.
- When adding a new built-in workflow, update these places: `config/workflows/` (TOML), `docs/workflows/` (doc page), the workflow table in `README.md`, the built-in workflow table in `docs/configuration.md`, the built-in name list in `nn init --help` (`lib/notenav.sh`), `docs/reference.md` (nn init argument description), the workflow file tables in `docs/install.md` and `docs/faq.md`, and the comment in `samples/user-config.toml`.

## Naming convention: `nn` vs `notenav`

Two names coexist by design – each is used where it fits best:

| Name | Scope | Used for |
|------|-------|----------|
| `nn` | Project-local, command-line | The CLI command (`bin/nn`), the project config directory (`.nn/`), and temp file prefixes |
| `notenav` | User-global, package identity | The XDG config directory (`~/.config/notenav/`), the Nix package name, the repo name, and all documentation/branding |

**Rationale:** `.nn/` is short and unobtrusive alongside `.git/`, `.vscode/`, etc. – users see it constantly and may type it. But `nn` is too terse and collision-prone for `~/.config/`, where the full name `notenav` is discoverable and unambiguous. This mirrors how many CLI tools use a short command name with a longer package/config name (e.g. `rg` → `ripgrep`).

**Rules:**
- New project-local paths (config, state, cache under the project root) use `.nn/`.
- New user-global paths (XDG config, data, cache) use `notenav/`.
- Documentation, error messages, and branding use "notenav" as the product name.
- The CLI command is always `nn`.

## Config system

There are exactly **two config scopes**, each with one or more files of identical shape:

- **User scope** – view preferences. `config/base.toml` ships notenav's defaults; `~/.config/notenav/config.toml` is the user's overrides. Both files have the same shape: `default_workflow`, `[defaults]`, `[ui]`, `[refresh]`, plus color overrides under `[type.<n>]`, `[status.colors]`, and `[priority.colors]`. base.toml is "the default user config" – nothing more.
- **Workflow scope** – schema. Built-in workflows in `config/workflows/*.toml` and project workflows in `.nn/workflow.toml` define `[meta]`, `[type]`, `[status]`, `[priority]`, and `[queries]`. Workflows can `extends` a built-in or remote URL.

The two scopes overlap **only** on color sub-keys: a user can personalize a workflow's palette via `[status.colors]`, `[priority.colors]`, or `[type.<n>] color = ...` without forking the workflow. No other cross-scope keys are allowed – workflows cannot set `[defaults]`/`[ui]`/`[refresh]` (security boundary against remote workflows), and user config cannot redefine workflow schema.

Both whitelists are enforced in `nn_load_config()` via `jq` projections; anything outside the whitelist is silently dropped.

The merge order is `base * workflow * user * project_queries`. Later layers override earlier on key collisions; project queries are applied last so they win on name collisions. Loaded once at startup and sealed for the session.

- New config keys must have a fallback default in the `nn_cfg` call (the `// "value"` pattern) and a corresponding entry in `config/base.toml` (user-scope key) or a workflow file (workflow-scope key).
- Document new config keys in `docs/configuration.md`.
- When adding or removing config properties, filter keys, or enum values, update the validation logic in `nn_doctor()` – it maintains hardcoded known-key lists and valid-value checks that must stay in sync.
- Filter keys (currently `type`, `status`, `priority`, `tag`) are listed in five places that must stay in sync: `--help` text, ad-hoc query parser, query preset startup validation, query preset runtime (both `apply_sq` and the header stats builder), and `nn_doctor()` validation.

### Config key naming

- **Favor enums over booleans.** A boolean locks you into two states forever. An enum can grow. Use a boolean like `wrap_preview = false` only if the setting is genuinely binary with no plausible third state; prefer `priority_plus = "demote"` over `priority_plus_demotes = true`, and `archive_visibility = "hide" | "show" | "only"` over `show_archive = false`. When in doubt, use a string enum. Note that *feature flags* (e.g. `priority.enabled`) that toggle a whole subsystem are the legitimate boolean case – future fine-grained control belongs in *separate* keys, not in an overloaded enum.
- **Use `snake_case`** for all config keys. No camelCase, no kebab-case.
- **Name keys for what they control, not how they're used.** `sort_by` (the field to sort on) is better than `sort_order` (ambiguous – ascending? the field?). `after_create` (what happens) is better than `auto_open` (vague).
- **Use positive names.** `wrap_preview` rather than `no_wrap` or `disable_preview_wrap`. Negated booleans (`no_*`, `disable_*`) are hard to reason about.
- **Group related keys under TOML tables.** Visual preferences go under `[ui]`, default view settings under `[defaults]`. Don't add top-level keys unless they're truly global (like `default_workflow`).
- **Keep the keyspace flat within a table.** Avoid deeply nested sub-tables for preferences. One level of nesting (`[ui]`, `[defaults]`) is typically enough for user-facing config.

## Documentation

- Use **en-dashes** (–), not em-dashes (—), in prose.
- Keep workflow doc pages (`docs/workflows/*.md`) in sync with their TOML files – type tables, status tables, lifecycle diagrams, and query preset tables must match the config.
- Status/type table descriptions should state what it *means*, not how to set it (avoid documenting keybinding mechanics in tables).
- All relative links in markdown must resolve to existing files.
- When adding or changing keybindings, update the `--bind` strings in the fzf invocation and the keybinding tables in `README.md` and `docs/tui.md`.
- When adding CLI subcommands or options, update the `--help` heredoc in `notenav_main()`, the CLI reference in `README.md`, and `docs/reference.md`.

## Standards compliance

- Follow the [XDG Base Directory Spec](https://specifications.freedesktop.org/basedir-spec/latest/): config via `${XDG_CONFIG_HOME:-$HOME/.config}`, data via `${XDG_DATA_HOME:-$HOME/.local/share}`.
- Respect `$NO_COLOR` ([no-color.org](https://no-color.org)).
- Error and warning messages go to stderr, not stdout.

## Audit commands

Slash commands in `.claude/commands/` for validating and reviewing the codebase. Convention: `check-*` = mechanical pass/fail validation, `review-*` = subjective quality judgment.

**Keep this table in sync when adding, renaming, or removing commands.**

| Command | Type | Scope |
|---------|------|-------|
| `/check-install-hints` | check | Validate distro-specific install hints against provisioning scripts |
| `/check-keybindings` | check | Validate fzf bindings: mode leak detection, README table sync, guideline compliance |
| `/check-links` | check | Validate all markdown relative and anchor links resolve |
| `/check-workflows` | check | Validate TOML integrity (values, lifecycle, extends) and config defaults match code |
| `/review-docs` | review | Doc quality, accuracy, and consistency across `.md` files and TOML comments |
| `/review-config-naming` | review | Config key names, types (bool vs enum), table structure, future-proofing |
| `/review-user-experience` | review | UX from the user's perspective: onboarding, feedback, errors, discoverability, friction |
| `/audit-code` | audit | Code quality: shell scripting, security, standards, CLI conventions |

## Versioning

- Version string is defined in the `VERSION` file at the repo root. `lib/notenav.sh` reads it at runtime; `flake.nix` reads it at build time. See [docs/releasing.md](docs/releasing.md) for the release process.
