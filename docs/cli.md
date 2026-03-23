# CLI Reference

[Back to README](../README.md)

## Synopsis

```
nn                                  interactive TUI (faceted browser)
nn <query-name>                     run a saved query preset
nn key=value ...                    ad-hoc filter (plain output)
nn key=value ... -i                 ad-hoc filter (interactive)
nn init [--user] [workflow]         create project or user config
nn doctor                           check setup and diagnose problems
nn --version                        show version
nn --help                           show usage
```

## Three operating modes

notenav has three primary modes of operation:

1. **Faceted browser** (`nn` with no arguments): full interactive TUI with filters, query presets, inline actions, and a live preview pane.
2. **Named query** (`nn <name>`): runs a query preset defined in config and outputs matching notes.
3. **Ad-hoc query** (`nn key=value ...`): filters notes by frontmatter fields; add `-i` for an interactive fzf picker.

---

## Commands

### `nn` – Interactive TUI

Launches the faceted browser. Requires a terminal (`$TERM` must not be `dumb`).

The TUI indexes all notes (via `zk list` when zk is installed, or via native frontmatter parsing otherwise), applies filters, and displays results in fzf with a preview pane showing note contents and – when zk is available – outgoing links and backlinks. All keybindings are displayed on-screen by default.

Notes are scoped by working directory: at the notebook root you see everything, from a subdirectory you see only that subtree.

### `nn <query-name>` – Named query

Runs a saved query preset by name. Query presets are defined in workflow, user, or project config under `[queries]`.

```bash
nn inbox              # run the "inbox" preset
nn p1-tasks           # run the "p1-tasks" preset
```

Named queries resolve their `args` and re-dispatch as ad-hoc filters. They can chain additional filters:

```bash
nn inbox tag=urgent   # inbox preset, further filtered by tag
```

Query presets can reference other presets. Maximum recursion depth is 5 to prevent circular references.

### `nn key=value ...` – Ad-hoc query

Filters notes by frontmatter fields and outputs results. Without `-i`, output is plain text suitable for piping and scripting. With `-i`, opens an interactive fzf picker.

```bash
nn type=task                      # all tasks
nn type=task status=active        # active tasks
nn priority=none                  # notes without a priority
nn tag=config                     # notes tagged "config"
nn type=task status=active -i     # same, but interactive
```

**Filter keys:**

| Key | Values | Notes |
|-----|--------|-------|
| `type` | any type from workflow config | exact match |
| `status` | any status from workflow config | exact match |
| `priority` | any priority level, or `none` | `none` matches notes without a priority set |
| `tag` | any tag name | matches notes with that tag |

Multiple filters are combined with AND logic. Multiple `tag=` filters are not supported in a single invocation – use the TUI's tag picker for multi-tag filtering.

**Options:**

| Flag | Description |
|------|-------------|
| `-i`, `--interactive` | Open results in an interactive fzf picker instead of plain output |
| `--` | Stop filter parsing; remaining arguments are passed through to `zk list` (when zk is available) |

**Plain output format:**

```
[type] [priority] [status] title
```

If priorities are disabled in the workflow, the priority column is omitted.

### `nn init` – Create project config

Creates `.nn/workflow.toml` in the current directory (or nearest existing `.nn/` parent).

```
nn init [workflow]
nn init --user [workflow]
nn init --help
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `workflow` | Built-in workflow name (`zenith`, `ado`, `gtd`, `zettelkasten`) or HTTPS URL. Defaults to `zenith`. |

**Flags:**

| Flag | Description |
|------|-------------|
| `--user` | Create user config (`~/.config/notenav/config.toml`) instead of project config |
| `--help`, `-h` | Show init usage |

**Behavior:**

- **Project mode** (default): creates `.nn/workflow.toml` with `extends = "<workflow>"` and a commented-out sample query preset.
- **User mode** (`--user`): copies the annotated sample to `~/.config/notenav/config.toml` (respects `$XDG_CONFIG_HOME`). If a workflow argument is given, sets `default_workflow` in the created file.
- **Remote workflows**: when the argument is an HTTPS URL, the workflow is fetched, validated as TOML, and cached under `~/.cache/notenav/workflows/`. On first use, you'll be prompted to trust the URL. Trusted URLs are stored in `~/.config/notenav/trusted-sources`.
- **Existing file**: if the target config file already exists, `nn init` refuses to overwrite it. Edit the file directly or remove it and re-run. As a special case, if `.nn/workflow.toml` already extends the same remote URL, `nn init <url>` refreshes the cache without touching the project config.

**Examples:**

```bash
nn init                           # project config, extends zenith
nn init zettelkasten              # project config, extends zettelkasten
nn init https://example.com/w.toml  # project config, extends remote workflow
nn init --user                    # user config with default settings
nn init --user gtd                # user config, default_workflow = gtd
```

### `nn doctor` – Diagnostic checks

Validates setup and reports problems. Runs before config loading, so it works even when configuration is broken.

```bash
nn doctor
```

**Validation phases:**

1. **Dependencies:** checks that required tools are installed and meet version requirements:
   - bash 4+
   - fzf 0.44+
   - yq (yq-go, **not** yq-python)
   - jq
   - gawk (GNU awk – required for `mktime()` and `strtonum()`)
   - sort, sed, git
   - zk (optional – faster indexing and link graph)
   - bat or batcat (optional – default previewer; alternatives: glow, mdcat)
   - curl (optional – required for remote workflows)

2. **Config:** validates configuration files:
   - User config (`~/.config/notenav/config.toml`): TOML parse check
   - Project config (`.nn/workflow.toml`): TOML parse check, `extends` resolution
   - `default_workflow` resolution from user config
   - Unrecognized top-level keys in either config file
   - Full config merge (workflow + user + project)

3. **Trusted sources:** lists URLs in the trusted-sources allow-list with cache status and fetch dates.

4. **Workflow integrity:** validates the merged workflow definition:
   - **Meta**: `schema` version is a supported positive integer, no unrecognized sub-keys
   - **Types**: all types have icon and color, no duplicates, `display_order` references valid types, no unrecognized sub-keys
   - **Statuses**: all statuses have colors, `initial` exists in values, `filter_cycle` and `archive` reference valid values, lifecycle transitions reference valid statuses, no unrecognized sub-keys
   - **Priority**: levels have colors, `filter_cycle` references valid values, lifecycle transitions valid, `unset_position` is `first` or `last`, no unrecognized sub-keys
   - **Defaults**: `sort_by`, `sort_reverse`, `group_by`, `show_archive`, and `wrap_preview` have valid values
   - **UI**: `exit_message`, `priority_plus`, `after_create`, and `previewer` have valid values; configured previewer tools are available
   - **Query presets**: filter args reference valid types/statuses/priorities, no unknown filter keys, `order` is numeric
   - ANSI color codes are syntactically valid throughout

5. **Notebook:** confirms a notebook is reachable from the current directory. With zk: checks the zk index. Without zk: looks for a `.zk/` or `.nn/` directory and counts markdown files.

**Output markers:**

| Marker | Meaning |
|--------|---------|
| `[✓]` | Check passed |
| `[!]` | Warning (non-fatal) |
| `[✗]` | Failure (will prevent normal operation) |

**Exit codes:**

| Code | Meaning |
|------|---------|
| 0 | All critical checks passed (warnings are OK) |
| 1 | One or more checks failed |

### `nn --version` / `nn -V`

Prints the version string and exits.

```
$ nn --version
notenav 0.1.0-dev
```

### `nn --help` / `nn -h`

Prints a usage summary and exits.

---

## TUI keybindings

The faceted browser uses a modal system with four modes: **command** (default), **change** (prefix `c`), **filter** (prefix `f`), and **display** (prefix `z`). Press `esc` to return to command mode from any prefix mode.

### Command mode

| Key | Action |
|-----|--------|
| `enter` | Open selected note in editor |
| `e` | Edit selected note (same as `enter`) |
| `n` | Create new note (title input, then type selection, then editor) |
| `a` | Advance status forward (follows `status.lifecycle.forward`) |
| `A` | Reverse status (follows `status.lifecycle.reverse`) |
| `+` / `>` | Bump priority in the `+` direction (see `priority_plus` setting) |
| `-` / `<` | Bump priority in the `-` direction |
| `t` | Filter by type (cycles through types) |
| `T` | Clear type filter |
| `s` | Filter by status (cycles through `filter_cycle`) |
| `S` | Clear status filter |
| `p` | Filter by priority (cycles through `filter_cycle`, then `none`) |
| `P` | Clear priority filter |
| `tab` / `shift-tab` | Next / previous query preset |
| `[` and `]` | Next / previous query preset (same as above) |
| `g` | Go-to query preset (opens picker) |
| `0` / `R` | Reset all filters and display settings to defaults |
| `1`–`9` | Jump to query preset by number |
| `space` | Toggle multi-select on current item |
| `b` | Bulk edit selected notes (opens editor with TSV of fields) |
| `j` / `k` | Move down / up |
| `ctrl-j` / `ctrl-k` | Page down / up |
| `J` / `K` | Scroll preview down / up |
| `esc` | Clear search query (or exit prefix mode) |
| `q` | Quit |

### Change mode (prefix `c`)

Press `c` to enter change mode. The prompt changes to `c `. Then press one of:

| Key | Action |
|-----|--------|
| `s` | Change status of selected note(s) via picker |
| `p` | Change priority of selected note(s) via picker |
| `t` | Change type of selected note(s) via picker |
| `esc` | Cancel, return to command mode |

### Filter mode (prefix `f`)

Press `f` to enter filter mode. The prompt changes to `f `. Then press one of:

| Key | Action |
|-----|--------|
| `t` | Filter by tags (multi-select picker, OR logic) |
| `c` | Filter by contents (live search of note body – uses `zk --match` when available, `rg`/`grep` otherwise) |
| `n` | Filter by name (substring match on note title, case-insensitive) |
| `esc` | Cancel, return to command mode |

### Display mode (prefix `z`)

Press `z` to enter display mode. The prompt changes to `z `. Then press one of:

| Key | Action |
|-----|--------|
| `o` | Cycle sort order: created, modified, title, priority |
| `r` | Toggle sort direction (ascending / descending) |
| `g` | Cycle grouping: none, type, status |
| `h` | Toggle visibility of archived statuses |
| `w` | Toggle title wrapping in preview |
| `esc` | Cancel, return to command mode |

### Interactive ad-hoc mode (`-i`)

A simplified set of keybindings for `nn key=value ... -i`:

| Key | Action |
|-----|--------|
| `enter` | Open note in editor |
| `/` | Enter search mode (type to filter) |
| `j` / `k` | Move down / up |
| `ctrl-j` / `ctrl-k` | Page down / up |
| `J` / `K` | Scroll preview down / up |
| `H` | Toggle title wrapping |
| `esc` | Exit search mode or clear query |
| `q` | Quit |

---

## Environment variables

### User-configurable

| Variable | Description | Default |
|----------|-------------|---------|
| `$EDITOR` | Editor for opening notes | auto-detect: nvim, vim, vi, nano, emacs |
| `$NO_COLOR` | Disable colored output (any value) | unset |
| `$XDG_CONFIG_HOME` | User config directory | `$HOME/.config` |
| `$XDG_CACHE_HOME` | Cache directory (remote workflows) | `$HOME/.cache` |

### File locations

| File | Path | Purpose |
|------|------|---------|
| Project config | `.nn/workflow.toml` | Workflow definition and project queries |
| User config | `$XDG_CONFIG_HOME/notenav/config.toml` | Personal preferences |
| Trusted sources | `$XDG_CONFIG_HOME/notenav/trusted-sources` | Allow-list for remote workflow URLs |
| Remote cache | `$XDG_CACHE_HOME/notenav/workflows/` | Cached remote workflow files |

---

## Exit codes

| Code | Context | Meaning |
|------|---------|---------|
| 0 | any | Success |
| 1 | `nn doctor` | One or more checks failed |
| 1 | `nn init` | Config already exists, invalid workflow name, or fetch failure |
| 1 | `nn <query>` | Query preset recursion too deep |
| 1 | `nn` (TUI) | Terminal not available (`$TERM` is `dumb`) |
| 130 | `nn` (TUI) | User quit with `q` or `ctrl-c` (normal fzf exit) |
