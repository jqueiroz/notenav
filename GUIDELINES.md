# notenav Development Guidelines

Rules and conventions for contributing to notenav.

## Architecture

- Entry point (`bin/nn`) stays minimal – all logic in `lib/notenav.sh`.
- Helper scripts are generated into a per-session `mktemp -d` directory, cleaned up via `EXIT` trap.
- Config values are precomputed once at startup (`nn_precompute_workflow`) and written to temp files (`nn_write_workflow_files`) – helper scripts read flat files, never re-parse TOML/JSON at runtime.

## Shell scripting

- Target **bash 4+**. Use `#!/usr/bin/env bash` (not hardcoded `/bin/bash`).
- Quote all variable expansions. Use `local var; var=$(cmd)` so `local` doesn't mask exit codes.
- Use `mktemp` for temp files – never predictable names in `/tmp`.
- Sanitize user-supplied or config-derived values before interpolating into AWK/sed expressions (escape `\` and `"`).
- Use `mv "$file.tmp" "$file"` for atomic writes.

## Keybindings

- **No modifier keys.** Do not use Ctrl, Alt, or Meta keybindings in fzf. Users run notenav inside tmux, terminal emulators, and window managers that may claim these combos, causing keys to be silently eaten.
- **Plain keys only.** Stick to letters, digits, symbols, and Shift variants (uppercase letters).
- **Use the modal pattern.** notenav has three input modes: command mode (plain keys), search mode (`/`), and change mode (`c` prefix). Fit new bindings into this structure.

## Workflow definitions

- Every value in `entity.values` must have a corresponding `[entity.<name>]` section with `icon`, `color`, and `description`.
- Every value in `status.values` must have a color in `[status.colors]` and entries in `filter_cycle` (unless intentionally omitted, like tombstone statuses).
- Lifecycle transitions (`forward`/`reverse`) must only reference values that exist in `status.values` or `priority.values`.
- Query preset `args` must only reference valid entity types, statuses, and priority values from the same workflow.

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

- Project config (`.nn/workflow.toml`) and user config (`~/.config/notenav/config.toml`) are orthogonal – project defines the workflow, user defines personal preferences. Neither inherits from nor overrides the other.
- New config keys must have a fallback default in the `nn_cfg` call (the `// "value"` pattern) and a corresponding entry in `config/base.toml` or the workflow file.
- Document new config keys in `docs/configuration.md`.

## Documentation

- Use **en-dashes** (–), not em-dashes (—), in prose.
- Keep workflow doc pages (`docs/workflows/*.md`) in sync with their TOML files – entity tables, status tables, lifecycle diagrams, and query preset tables must match the config.
- Status/entity table descriptions should state what it *means*, not how to set it (avoid documenting keybinding mechanics in tables).
- All relative links in markdown must resolve to existing files.

## Standards compliance

- Follow the [XDG Base Directory Spec](https://specifications.freedesktop.org/basedir-spec/latest/): config via `${XDG_CONFIG_HOME:-$HOME/.config}`, data via `${XDG_DATA_HOME:-$HOME/.local/share}`.
- Respect `$NO_COLOR` ([no-color.org](https://no-color.org)).
- Error and warning messages go to stderr, not stdout.

## Versioning

- Version string lives in `NOTENAV_VERSION` at the top of `lib/notenav.sh` and must match the version in `flake.nix`.
