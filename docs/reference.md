# Reference

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

1. **Faceted browser** (`nn` with no arguments): full interactive TUI with filters, query presets, inline actions, and a live preview pane. See [TUI Reference](tui.md) for keybindings and details.
2. **Named query** (`nn <name>`): runs a query preset defined in config and outputs matching notes.
3. **Ad-hoc query** (`nn key=value ...`): filters notes by frontmatter fields; add `-i` for an interactive fzf picker.

---

## Commands

### `nn` – Interactive TUI

Launches the faceted browser. Requires a terminal (`$TERM` must not be `dumb`).

The TUI indexes all notes (via `zk list` when zk is installed, or via native frontmatter parsing otherwise), applies filters, and displays results in fzf with a preview pane showing note contents and – when zk is available – outgoing links and backlinks. All keybindings are displayed on-screen by default. See [TUI Reference](tui.md) for the full keybinding reference.

Notes are scoped by working directory: at the notebook root you see everything, from a subdirectory you see only that subtree.

### `nn <query-name>` – Named query

Runs a saved query preset by name. Query presets are defined in workflow or project config under `[queries]`.

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
| `tag` | any tag name | matches notes with that tag (OR when repeated) |

Multiple filters are combined with AND logic. Multiple `tag=` filters in the same invocation use OR logic – a note matches if it has *any* of the specified tags:

```bash
nn tag=backend tag=api              # notes tagged "backend" OR "api"
nn type=task tag=backend tag=api    # tasks tagged "backend" OR "api"
```

**Options:**

| Flag | Description |
|------|-------------|
| `-i`, `--interactive` | Open results in an interactive fzf picker instead of plain output |
| `--` | Stop filter parsing; remaining arguments are passed through to `zk list` (ignored without zk) |

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
| `workflow` | Built-in workflow name (`zenith`, `cuboid`, `ado`, `gtd`, `zettelkasten`) or HTTPS URL. Defaults to `zenith`. |

**Flags:**

| Flag | Description |
|------|-------------|
| `--user` | Create user config (`~/.config/notenav/config.toml`) instead of project config |
| `--help`, `-h` | Show init usage |

**Behavior:**

- **Project mode** (default): creates `.nn/workflow.toml` with `extends = "<workflow>"` and a commented-out sample query preset.
- **User mode** (`--user`): copies the annotated sample to `~/.config/notenav/config.toml` (respects `$XDG_CONFIG_HOME`). If a workflow argument is given, sets `default_workflow` in the created file.
- **Remote workflows**: when the argument is an HTTPS URL, the workflow is fetched, validated as TOML, and cached under `~/.cache/notenav/workflows/`. On first use, you'll be prompted to trust the URL. Trusted URLs are stored in `~/.config/notenav/trusted-sources`.
- **Existing file**: if the target config file already exists, `nn init` refuses to overwrite it. Edit the file directly or remove it and re-run. As a special case, if the existing config already references the same remote URL (`extends` in project mode, `default_workflow` in user mode), `nn init <url>` refreshes the cache without touching the config file.

**Examples:**

```bash
nn init                           # project config, extends zenith
nn init zettelkasten              # project config, extends zettelkasten
nn init https://example.com/w.toml  # project config, extends remote workflow
nn init --user                    # user config with default settings
nn init --user gtd                # user config, default_workflow = gtd
```

### `nn doctor` – Diagnostic checks

Validates setup and reports problems. Does not require a valid config, so it works even when configuration is broken.

```bash
nn doctor
```

**Validation phases:**

1. **Dependencies:** checks that required tools are installed and meet version requirements:
   - bash 4+
   - fzf 0.45+
   - yq (yq-go, **not** yq-python)
   - jq
   - gawk (GNU awk – required for `mktime()` and `strtonum()`)
   - sort, sed, tput
   - zk (optional – faster indexing and link graph)
   - curl (optional – needed for remote workflows)
   - inotifywait or fswatch (optional – auto-refresh in watch mode)
   - ripgrep (optional – faster content search when zk is not installed or configured)
   - bat or batcat (optional – default previewer; alternatives: glow, mdcat)

2. **Config:** validates configuration files:
   - User config (`~/.config/notenav/config.toml`): TOML parse check
   - Project config (`.nn/workflow.toml`): TOML parse check, `extends` resolution
   - `default_workflow` resolution from user config
   - Unrecognized top-level keys in either config file
   - Full config merge (workflow + user + project)

3. **Trusted sources:** lists URLs in the trusted-sources allow-list with cache status and fetch dates.

4. **Workflow integrity:** validates the merged workflow definition:
   - **Meta**: `schema` version is a supported positive integer, no unrecognized sub-keys
   - **Types**: all types have icon and color, no duplicates, `display_order` references valid types and covers all values, no unrecognized sub-keys
   - **Statuses**: all statuses have colors, `initial` exists in values, `filter_cycle` and `archive` reference valid values, lifecycle transitions reference valid statuses, `display_order` covers all values, description keys reference valid statuses, no unrecognized sub-keys
   - **Priority**: levels have colors, `filter_cycle` references valid values, lifecycle transitions valid, `unset_position` is `first` or `last`, no unrecognized sub-keys
   - **Defaults**: `sort_by`, `sort_reverse`, `group_by`, `show_archive`, and `wrap_preview` have valid values
   - **UI**: `command_prompt` and `search_prompt` do not contain characters stripped at runtime; `exit_message`, `priority_plus`, `after_create`, `previewer`, and `previewer_flags` have valid values; configured previewer tools (bat/batcat, glow, mdcat, custom) are checked for availability
   - **Query presets**: filter args reference valid types/statuses/priorities, no unknown filter keys, `order` is numeric
   - Color values are valid (named colors or ANSI codes) throughout

5. **Notebook:** confirms a notebook is reachable from the current directory by looking for `.nn/workflow.toml`. Reports the notebook root, markdown file count, and active backend (zk or native).

6. **Notes:** scans markdown files and checks frontmatter values against the workflow definition. Reports notes with unrecognized type, status, or priority values (summary counts, the unknown values found, and up to 5 example file paths). Priority is only checked when enabled in the workflow. Notes with no type or status are reported as informational. Scans up to 2000 files.

**Output markers:**

| Marker | Meaning |
|--------|---------|
| `[✓]` | Check passed |
| `[-]` | Info (optional dependency not found) |
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
notenav X.Y.Z
```

### `nn --help` / `nn -h`

Prints a usage summary and exits.

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
| Ignore file | `.nnignore` | Exclude files/directories from the index |
| Trusted sources | `$XDG_CONFIG_HOME/notenav/trusted-sources` | Allow-list for remote workflow URLs |
| Remote cache | `$XDG_CACHE_HOME/notenav/workflows/` | Cached remote workflow files |

### `.nnignore`

Place a `.nnignore` file at the notebook root (next to `.nn/`) to exclude files
and directories from notenav's index. Works with both the native and zk
backends, and applies to all three modes (TUI, named query, ad-hoc).

`CLAUDE.md` files are always excluded by default, even without a `.nnignore`
file. Standard metadata directories (`.git`, `.zk`, `.obsidian`,
`node_modules`, `.nn`) are also always pruned.

**Pattern syntax** – one pattern per line:

| Pattern | Meaning | Example |
|---------|---------|---------|
| `name` | Exclude files with this exact basename | `README.md` |
| `name/` | Prune directory (skip everything under it) | `templates/` |
| `*.glob` | Shell glob on basename (`*` and `?`) | `*.draft.md` |
| `path/to/file` | Match relative path suffix | `old/archive.md` |

Notes:

- `#` begins a comment – everything from `#` to end of line is ignored.
  Inline comments are supported: `templates/  # skip these` works.
  Literal `#` in filenames is not supported.
- Blank lines and whitespace-only lines are ignored.
- Glob patterns are matched against the **basename** only.
  Patterns like `foo/*.md` (glob + path) are not supported – use a
  directory pattern (`foo/`) or an exact path pattern instead.

**Example `.nnignore`:**

```
# Skip templates and archive
templates/
archive/

# Ignore draft files
*.draft.md

# Ignore a specific file
notes/scratch/old-ideas.md
```

Run `nn doctor` to verify your `.nnignore` is being picked up and how many
patterns it contains.

---

## Exit codes

| Code | Context | Meaning |
|------|---------|---------|
| 0 | any | Success |
| 1 | `nn doctor` | One or more checks failed |
| 1 | `nn init` | Config already exists or fetch/write failure |
| 2 | `nn init` | Invalid arguments (unknown flag, bad workflow name) |
| 1 | `nn <query>` | Query preset recursion too deep |
| 1 | `nn` (TUI) | Terminal not available (`$TERM` is `dumb` or unset) |
| 130 | `nn` (TUI) | User quit with `q` or `ctrl-c` (normal fzf exit) |
