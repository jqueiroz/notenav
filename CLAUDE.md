# notenav

TUI faceted browser for [zk](https://github.com/zk-org/zk) notebooks, built on fzf.

## Project Status

Early extraction – previously embedded as `zkq()` in zshrc (~1100 LOC). Now standalone at `~/Development/Projects/notenav/`. Packaged via Nix flake; also installable manually or via one-liner.

## Repo Layout

```
bin/nn              # Entry point: resolves root, sources lib, calls notenav_main
lib/notenav.sh      # Full implementation (~1100 LOC)
config/
  base.toml        # Base config (ships with notenav; user/project configs overlay on top)
  workflows/
    compass.toml    # Default workflow (task/idea/reference)
    ado.toml        # Azure DevOps preset
    gtd.toml        # Getting Things Done preset
    zettelkasten.toml # Zettelkasten preset
curl/
  install.sh       # curl-pipe-sh installer script
docs/
  install.md          # Full install instructions (requirements, all methods)
  configuration.md    # Config system + workflow reference
  workflows/          # Per-workflow documentation (compass.md, ado.md, etc.)
samples/
  user-config.toml      # Example ~/.config/notenav/config.toml
  workflows/
    project-workflow.toml # Example .nn/workflow.toml (extends a built-in)
    custom-workflow.toml  # Example .nn/workflow.toml (full custom definition)
.claude/
  commands/           # Claude Code slash commands (best-practices, audit-config, etc.)
flake.nix           # Nix package definition
CLAUDE.md           # This file
README.md           # Public-facing README
LICENSE             # MIT
.gitignore
```

## Dependencies

- **bash 4+** – uses `declare -A` (associative arrays), `mapfile`, and other bash 4+ features
- **zk** – note indexing, querying, LSP (the underlying note tool)
- **fzf** 0.44+ – TUI framework (transform, execute, rebind)
- **bat/batcat** – syntax-highlighted preview
- **yq** ([yq-go](https://github.com/mikefarah/yq), **not** [yq-python](https://github.com/kislyuk/yq)) – TOML→JSON conversion for config/workflow loading
- **jq** – JSON merging and querying for config system
- **awk**, **sort**, **sed** – data pipeline (POSIX + gawk `mktime`)

## Three Operating Modes

### 1. Faceted browser (`nn` with no args)

Full TUI with filters, query presets, inline actions. Creates a temp dir with helper scripts and state files, launches fzf with extensive keybindings.

### 2. Named query (`nn <name>`)

Looks up `<name>` in query presets (from workflow and user/project `[queries]` sections). Delegates to `notenav_main` with the query's key=value args.

### 3. Ad-hoc query (`nn key=value ...`)

Filters notes by frontmatter fields. Supports `-i` for interactive (fzf) mode, `--` to pass extra args to `zk list`.

## Data Flow

1. `zk list` outputs TSV with format: `type \t status \t priority \t tags \t title \t absPath \t modified \t created`
2. `filter.sh` applies awk conditions based on current filter state
3. Colored output piped to fzf via `.current` file
4. Actions (status cycle, priority bump) update frontmatter in-place via `action.sh`, then regenerate `.raw` and re-filter

## State Files (in temp dir)

| File | Purpose |
|------|---------|
| `.raw` | All notes from `zk list` (unfiltered TSV) |
| `.current` | Filtered + colored output displayed in fzf |
| `.header` / `.header-c` | Dynamic header (normal / "c" change mode) |
| `.border` | Border label with count stats |
| `.f_type`, `.f_status`, `.f_priority` | Current filter values |
| `.f_tags` | Selected tags (one per line) |
| `.f_sq` | Active query preset name |
| `.f_sort`, `.f_group`, `.f_archive` | View settings |
| `.f_match` / `.f_match_paths` | Body text search query and matching paths |
| `.queries` | Compiled query presets (name \t args) |
| `.pinned` | Paths pinned after actions (visible despite filter) |
| `.zk_path` / `.zk_fmt` | zk list args for reload |

## Helper Scripts (generated in temp dir)

| Script | Purpose |
|--------|---------|
| `filter.sh` | Core: applies filters, sorts, groups, builds header/stats |
| `action.sh` | Updates frontmatter field, regenerates data |
| `tags.sh` | Tag picker (multi-select sub-fzf) |
| `match.sh` / `match_search.sh` | Body text search with live fzf |
| `cyclestatus.sh` | Inline status advance/reverse |
| `bumppri.sh` | Priority increase/decrease |
| `bulkset.sh` / `fieldpick.sh` | Pick value + bulk apply |
| `bulkedit.sh` / `bulkedit_apply.sh` / `bulkedit_update.sh` | TSV bulk editor |
| `newnote.sh` | Note creation (type picker + title prompt) |
| `querypick.sh` | Fuzzy query picker |
| `reload_at.sh` | Reload + position cursor |
| `preview.sh` | File preview with links/backlinks |

## Keybindings (Faceted Browser)

**Navigation:** `j`/`k` move, `J`/`K` preview scroll, `H` wrap, `enter` open, `q` quit
**Filters:** `e`/`E` type, `s`/`S` status, `p`/`P` priority, `t`/`T` tags, `m`/`M` body search, `R`/`0` reset
**Query Presets:** `h`/`l` prev/next, `1`-`9` jump, `f` fuzzy pick
**Search:** `/` enter, `Esc` exit
**Actions:** `a`/`A` status cycle, `+`/`-` (or `<`/`>`) priority, `n` new note, `b` bulk edit
**Change mode:** `c` then `s`/`p`/`e` – set field on selected notes
**View:** `o` sort, `g` group, `z` archive toggle

## Frontmatter Schema

```yaml
---
title: "Note Title"
type: idea | task | reference
priority: 1-4
status: new | active | blocked | done | removed
tags: [feature-area]
created: 2026-03-18
---
```

## Query Presets

Query Presets are defined in `[queries.<name>]` sections across three layers (later wins on name collisions):

1. **Workflow queries** – built-in presets shipped with each workflow (e.g. compass has `p1-tasks`, `inbox`)
2. **User queries** (`~/.config/notenav/config.toml`) – personal, available everywhere
3. **Project queries** (`.nn/workflow.toml`) – team-shared, project-specific

```toml
[queries.backlog]
args = "tag=backlog"

[queries.active-bugs]
order = 5
args = "type=bug status=active"
```

Set `inherit = false` under `[queries]` in project or user config to clear workflow presets before merging.

## Source Reference

Extracted from `~/Environment/config/common/zsh.zshrc` (the former `zkq()` function). All internal naming has been changed from zkq to notenav/nn.

## Testing

```bash
# Verify installation
which nn                                      # should show bin/nn path
nn --version                                  # notenav 0.1.0-dev

# Test in a zk notebook
cd ~/Writing/obsidian-johnjq
nn                                            # interactive TUI
nn type=task                                  # ad-hoc query
nn backlog                                    # query preset
nn type=task -i                               # interactive ad-hoc
```

## Config System

Workflow and preferences are loaded from TOML files at startup via `nn_load_config()`.

**Workflow resolution:**
- `.nn/workflow.toml` defines the project workflow (full definition or `extends = "<builtin>"`)
- Falls back to user config `default_workflow`, then `"compass"`

**Preference merge** (later values win via jq deep merge):
1. Workflow values (base)
2. Base config: `$NOTENAV_ROOT/config/base.toml`
3. User config: `~/.config/notenav/config.toml`

The merged config is stored in `NN_CFG_JSON` and queried via `nn_cfg '.path.to.value'`.

Built-in workflows: `compass` (default), `ado`, `gtd`, `zettelkasten`.

## Conventions

- Entry point (`bin/nn`) stays minimal – all logic in `lib/notenav.sh`
- Internal temp files use per-session `mktemp -d` directories (cleaned up via EXIT trap)
- Query Presets: `[queries]` section in workflow/user config
- Version string in `NOTENAV_VERSION` variable at top of `lib/notenav.sh`
- Use en-dashes (–), not em-dashes (–), in prose
