# TUI Reference

[Back to README](../README.md)

## Keybindings

The faceted browser uses a modal system with eight modes: **command** (default), **change** (prefix `c`), **filter** (prefix `f`), **display** (prefix `z`), **mark** (prefix `m`), **help** (`?`), **search** (`/`), and **content search** (`/?`). Press `esc` to return to command mode from any other mode. Navigation keys (`j`/`k`, `ctrl-j`/`ctrl-k`, `space`) also exit the current prefix mode and perform their normal action.

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
| `tab` / `shift-tab` | Next / previous query preset |
| `[` and `]` | Next / previous query preset (same as above) |
| `g` | Go-to query preset (opens picker) |
| `0` | Clear all filters and return to the "all" view (preserves display settings, pins, and marks) |
| `R` | Full reset: clear all filters, pins, marks, and display settings to defaults |
| `1`–`9` | Jump to query preset by number |
| `space` | Toggle multi-select on current item |
| `r` | Refresh note list (re-index from disk) |
| `b` | Bulk edit selected notes (opens editor with markdown table) |
| `d` | Delete selected note(s) – single: `y/N` prompt; multi-select: lists targets, requires `YES` (see `delete_method` and `delete_confirm` settings) |
| `w` | Toggle preview wrap |
| `H` | Toggle header mode between `clean` (state only) and `guided` (keybinding hints) |
| `x` | Clear all pinned ghost rows |
| `X` | Restore pins from last clear (one-shot undo) |
| `j` / `k` | Move down / up |
| `ctrl-j` / `ctrl-k` | Page down / up |
| `J` / `K` | Scroll preview down / up |
| `/` | Enter search mode – fuzzy-filter the list by typing |
| `?` | Toggle help overlay – keybinding reference |
| `esc` | Exit search / prefix mode, or clear query |
| `q` | Quit |

### Change mode (prefix `c`)

Press `c` to enter change mode. The prompt changes to `c `. Then press one of:

| Key | Action |
|-----|--------|
| `s` | Change status of selected note(s) via picker |
| `p` | Change priority of selected note(s) via picker |
| `t` | Change type of selected note(s) via picker |
| `c` or `esc` | Cancel, return to command mode |

### Filter mode (prefix `f`)

Press `f` to enter filter mode. The prompt changes to `f `. Then press one of:

| Key | Action |
|-----|--------|
| `t` | Filter by type (picker with all types; select "all" to clear) |
| `s` | Filter by status (picker with all statuses; select "all" to clear) |
| `p` | Filter by priority (picker with all priorities + unset; select "all" to clear) |
| `#` | Filter by tags (multi-select picker; OR logic – matches notes with *any* selected tag) |
| `f` or `esc` | Cancel, return to command mode |

### Display mode (prefix `z`)

Press `z` to enter display mode. The prompt changes to `z `. Then press one of:

| Key | Action |
|-----|--------|
| `o` | Cycle sort order: created, modified, title, priority |
| `r` | Toggle sort direction (ascending / descending) |
| `g` | Cycle grouping: none, type, status |
| `h` | Toggle visibility of archived statuses |
| `w` | Toggle title wrapping in preview |
| `z` or `esc` | Cancel, return to command mode |

### Mark mode (prefix `m`)

Press `m` to enter mark mode. The prompt changes to `m `. Then press one of:

| Key | Action |
|-----|--------|
| `m` | Toggle mark on focused item and return to command mode |
| `a` | Mark all selected items (or focused if none selected) |
| `d` | Unmark all selected items (or focused if none selected) |
| `D` | Clear all marks |
| `f` | Toggle filter to show only marked items |
| `esc` | Cancel, return to command mode |

Marks are intentional, user-placed bookmarks – distinct from pins, which are automatic. Marked items display a magenta `marked` badge. Marks persist for the session; full reset (`R`) clears them. A mark count appears in the border label when marks are present (e.g., `15/42 · 2 marked`). Unlike pins, marks are purely visual badges – they do not create ghost rows. Facet filters apply normally to marked items. Use `mf` to narrow the view to only your bookmarks.

### Pinned ghost rows

When you perform an inline action – advance status (`a`/`A`), bump priority (`+`/`-`), or change a field via the picker (`c` then `s`/`p`/`t`) – the acted-on note may no longer match your active filters. Rather than vanishing, it stays visible **in place** as a ghost row with a yellow `pinned` badge. The list never reorders and the cursor never jumps.

**Accumulative:** each action adds to the set of pinned items. Advancing one note and then bumping another leaves both pinned.

**Sticky:** pins survive filter changes (cycling type, status, priority, tags, or content search). They persist until you explicitly clear them.

**Clearing pins:**

- `x` – clear all pins (ghost rows disappear, everything else stays)
- `X` – restore pins from the last clear (one-shot undo – the backup is consumed)
- `R` – full reset (clears pins, marks, all filters, sort order, grouping, and display settings)

**Grouping:** ghost rows appear in the group matching their *current* metadata. If you advance a task from "active" to "done" while filtering by status "active", the ghost row appears in the "done" group (when grouping by status is enabled).

**Count:** the match count in the border label (e.g., `15/42`) reflects genuinely matching notes only – ghost rows are not counted. A separate pin count appears when pins are present (e.g., `15/42 · 2 pinned`).

### Tags

Tags are free-form labels for cross-cutting concerns that don't fit neatly into type, status, or priority. Where those three facets are workflow-defined and single-valued (a note has exactly one type, one status, and at most one priority), tags are open-ended and combinable – a note can have any number of tags, and you define them as you go.

**Motivation:** type, status, and priority answer *what*, *where*, and *how urgent*. Tags answer *about what* – they let you slice your notes by project, area, technology, context, or anything else that cuts across the workflow's built-in facets. For example, a task, an idea, and a reference might all be tagged `backend`; a GTD action and a project might both be tagged `@phone`.

**Frontmatter format:** tags are specified in YAML frontmatter using either inline array or multi-line list syntax:

```yaml
# Inline array (preferred for short lists)
tags: [backend, api, tech-debt]

# Multi-line list (equivalent)
tags:
  - backend
  - api
  - tech-debt
```

Quoted values (`tags: ["backend", "api"]`) are also accepted – quotes are stripped during parsing.

**Filtering in the TUI:** press `f` then `#` to open a multi-select tag picker. The picker lists every tag found in the notebook. Use `space`/`tab` to toggle tags, `enter` to apply. Previously selected tags appear at the top and are pre-selected.

Tag filtering uses **OR logic** – selecting `backend` and `api` shows notes tagged with *either* (or both). Tags combine with other active filters using AND logic: if you also filter by `type=task`, you see tasks tagged `backend` OR `api`. Active tags appear in magenta in the filter status line.

**Filtering on the command line:** use `tag=` in ad-hoc queries or query presets:

```bash
nn tag=backend                      # notes tagged "backend"
nn tag=backend tag=api              # notes tagged "backend" OR "api"
nn type=task tag=backend            # tasks tagged "backend"
```

**In query presets:**

```toml
[queries.backend]
args = "tag=backend"

[queries.api-work]
args = "type=task tag=backend tag=api"    # tasks tagged backend OR api
```

**Clearing tags:** tag filters reset when you switch query presets, press `0` (clear preset), or press `R` (full reset). In the tag picker, `esc` cancels without changing the filter.

**In bulk edit:** the bulk edit table (`b` key) shows tags as a space-separated column. Edit directly – changes are written back to frontmatter as a YAML inline array.

**Tag conventions:** tags are plain strings with no special naming rules. Avoid commas, brackets, and quotes in tag names – these characters are stripped during YAML parsing. Some patterns that work well:

- **By area:** `backend`, `frontend`, `infra`, `docs`
- **By project:** `project-alpha`, `migration`, `onboarding`
- **By context (GTD-style):** `@phone`, `@computer`, `@errands`
- **By theme:** `tech-debt`, `security`, `performance`

### Search mode (`/`)

Press `/` to enter search mode. The prompt changes to `/ ` and the header collapses to show search-specific help. Type to fuzzy-filter the visible note list. Arrow keys and `ctrl-j`/`ctrl-k` still navigate during search.

| Key | Action |
|-----|--------|
| `?` | Switch to content search (live grep of note bodies) |
| `enter` | Open the focused note, clear query, return to command mode |
| `tab` | Keep the fuzzy filter active and return to command mode |
| `esc` | Cancel search, clear query, return to command mode |

When you exit search mode via `tab`, the query stays in fzf's input – the list remains filtered. Press `esc` in command mode to clear it. This lets you quickly narrow the list by title: type a query, press `tab`, then do normal command-mode actions on the narrowed set.

### Help mode (`?`)

Press `?` to toggle the help overlay – a keybinding reference showing all available keys grouped by section (filters, display, actions, keys). Press `?` again, `esc`, or any navigation key to dismiss.

Help mode uses `.nn-mode` value `h`. While help is showing, action keys are blocked – you must exit help first.

### Content search mode (`/?`)

Press `/` to enter search mode, then `?` to switch to content search. The prompt changes to `/? ` and fzf switches to live-grep mode – each keystroke searches note bodies using `rg`/`grep` (or `zk --match` when available). The list updates to show only notes containing the query. Any text already typed in search mode carries over as the initial content search query.

| Key | Action |
|-----|--------|
| `enter` | Open the focused note, return to command mode |
| `tab` | Persist the content filter and return to command mode |
| `esc` | Cancel search, return to command mode |

When you exit via `tab`, the content query is saved as a pipeline-level filter (shown as `?:` in the header). This filter survives reloads and individual filter changes (cycling type, status, priority, tags). It is cleared by preset switches (`tab`/`shift-tab`, `1`–`9`), `0` (clear preset), or `R` (full reset). You can also clear it by entering `/?` with an empty query and pressing `tab`.

### Interactive ad-hoc mode (`-i`)

A simplified set of keybindings for `nn key=value ... -i`:

| Key | Action |
|-----|--------|
| `enter` | Open note in editor |
| `/` | Enter search mode (type to filter) |
| `tab` / `:` | Keep search filter active and return to browsing |
| `j` / `k` | Move down / up |
| `ctrl-j` / `ctrl-k` | Page down / up |
| `J` / `K` | Scroll preview down / up |
| `H` | Toggle title wrapping |
| `esc` | Exit search mode or clear query |
| `q` | Quit |

## Header display density

The `ui.initial_header_mode` setting controls the header on launch. Press `H` to toggle between modes at any time.

- **`clean`** (default) – three lines: query presets, active filter/display state (with `?:help` hint), and result stats. Only non-default filter values are shown; when everything is at defaults, the filter line reads "Filters: (none)". When a prefix mode is active (`c`/`f`/`z`/`m`), a fourth line appears temporarily with sub-key hints.
- **`guided`** – condenses each section to one line with keybinding hints (e.g. `[t]ype`, `[a]dvance`). When a prefix mode is active, the relevant section temporarily expands to show sub-key hints, then collapses on exit.
