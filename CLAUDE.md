# notenav

TUI faceted browser for [zk](https://github.com/zk-org/zk) notebooks, built on fzf.

## Project Status

Early extraction — previously embedded as `zkq()` in zshrc (~1100 LOC). Now standalone at `~/Development/Projects/notenav/`. Functional but not yet packaged for general use.

## Repo Layout

```
bin/nn              # Entry point: resolves root, sources lib, calls notenav_main
lib/notenav.sh      # Full implementation (~1100 LOC)
config/
  config.toml       # Default config (ships with notenav)
  schemas/
    default.toml    # Default schema (task/idea/reference)
    ado.toml        # Azure DevOps preset
    gtd.toml        # Getting Things Done preset
    zettelkasten.toml # Zettelkasten preset
samples/
  user-config.toml    # Example ~/.config/notenav/config.toml
  project-config.toml # Example .nn/config.toml
  custom-schema.toml  # Example custom schema
CLAUDE.md           # This file
README.md           # Public-facing README
LICENSE             # MIT
.gitignore
```

## Dependencies

- **bash 4+** — uses `declare -A` (associative arrays), `mapfile`, and other bash 4+ features
- **zk** — note indexing, querying, LSP (the underlying note tool)
- **fzf** 0.44+ — TUI framework (transform, execute, rebind)
- **bat/batcat** — syntax-highlighted preview
- **yq** (yq-go) — TOML→JSON conversion for config/schema loading
- **jq** — JSON merging and querying for config system
- **awk**, **sort**, **sed** — data pipeline (POSIX + gawk `mktime`)

## Three Operating Modes

### 1. Faceted browser (`nn` with no args)

Full TUI with filters, saved queries, inline actions. Creates a temp dir with helper scripts and state files, launches fzf with extensive keybindings.

### 2. Named query (`nn <name>`)

Looks up `<name>` in `.nn/queries/` directories (inherited from git root down to cwd). Delegates to `notenav_main` with the query's key=value args.

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
| `.f_sq` | Active saved query name |
| `.f_sort`, `.f_group`, `.f_archive` | View settings |
| `.f_match` / `.f_match_paths` | Body text search query and matching paths |
| `.f_history` | Filter state stack for undo |
| `.queries` | Compiled saved queries (name \t args) |
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
**Saved queries:** `h`/`l` prev/next, `1`-`9` jump, `f` fuzzy pick
**Search:** `/` enter, `Esc` exit
**Actions:** `a`/`A` status cycle, `+`/`-` priority, `n` new note, `b` bulk edit
**Change mode:** `c` then `s`/`p`/`e` — set field on selected notes
**View:** `o` sort, `g` group, `z` archive toggle, `u` undo

## Frontmatter Schema

```yaml
---
title: "Note Title"
type: idea | task | reference
priority: 1-5
status: new | active | blocked | validating | done | removed
tags: [feature-area]
created: 2026-03-18
---
```

## Saved Queries

Saved queries live in `.nn/queries/` directories, inherited from git root down to cwd (deeper dirs override). Each file = query name, contents = `key=value` args (one per line). Optional `# N` first line sets display order (default 100, lower = first).

Example (`.nn/queries/backlog`):
```
tag=backlog
```

Example with sort order (`.nn/queries/tasks-p1`):
```
# 10
type=task priority=1
```

## Source Reference

Extracted from `~/Environment/config/common/zsh.zshrc` (the former `zkq()` function). All internal naming has been changed from zkq to notenav/nn.

## Testing

```bash
# Verify installation
which nn                                      # should show bin/nn path
nn --version                                  # notenav 0.1.0-dev

# Test in a zk notebook
cd ~/Writing/obsidian-johnjq
nn                                            # faceted browser
nn type=task                                  # ad-hoc query
nn backlog                                    # saved query
nn type=task -i                               # interactive ad-hoc
```

## Config System

Schema and preferences are loaded from TOML files at startup via `nn_load_config()`.

**Config resolution order** (later values win via jq deep merge):
1. Schema file (base) — determined by config `schema`/`default_schema` key
2. Default config: `$NOTENAV_ROOT/config/config.toml`
3. User config: `~/.config/notenav/config.toml`
4. Project config: `.nn/config.toml` (closest `.nn` dir walking up from cwd)

**Schema resolution** (first match wins):
1. `.nn/schemas/<name>.toml` — project-local
2. `~/.config/notenav/schemas/<name>.toml` — user-global
3. `$NOTENAV_ROOT/config/schemas/<name>.toml` — built-in

The merged config is stored in `NN_CFG_JSON` and queried via `nn_cfg '.path.to.value'`.

Built-in schemas: `default`, `ado`, `gtd`, `zettelkasten`.

## Conventions

- Entry point (`bin/nn`) stays minimal — all logic in `lib/notenav.sh`
- Internal temp files use `/tmp/.nn-` prefix
- Saved query dirs: `.nn/queries/`
- Version string in `NOTENAV_VERSION` variable at top of `lib/notenav.sh`
