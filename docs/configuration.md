# Configuration

[Back to README](../README.md)

## Overview

All configuration is TOML. Project and user configuration are orthogonal – neither inherits from or overrides the other:

- **Project configuration** (`.nn/workflow.toml`): defines the project's workflow, typically extending a built-in one with project-specific query presets and overrides.
- **User preferences** (`$XDG_CONFIG_HOME/notenav/config.toml`, defaulting to `~/.config/notenav/config.toml`): personal preferences for visualization, editor, sorting, and grouping. Also defines a fallback workflow, used in directories without project configuration.

Both scopes are layered on top of notenav's base defaults, so you only need to specify what you want to change.

## Config resolution

At startup, two things happen:

1. **Workflow resolution:** if `.nn/workflow.toml` exists, it defines the project's workflow. It can be a full custom definition, or it can extend a built-in using the `extends` key. If no `.nn/workflow.toml` exists, the user config's `default_workflow` is used, falling back to `"zenith"`.

2. **Preference merge:** preferences are assembled by deep-merging these layers in order (later values win):

   | Layer | Source | Wins on |
   |-------|--------|---------|
   | 1. Base config | `$NOTENAV_ROOT/config/base.toml` | — (base) |
   | 2. Workflow | Built-in or extended workflow definition | Base defaults |
   | 3. User config | `$XDG_CONFIG_HOME/notenav/config.toml` | Everything above |
   | 4. Project queries | `[queries]` from `.nn/workflow.toml` | All queries |

   User preferences can override individual workflow values (like colors) without replacing the entire workflow. Project queries are applied last so they always win on name collisions.

The `.nn/` directory is found by walking up from the current directory.

The quickest way to get started is `nn init`:

```bash
nn init                    # create .nn/workflow.toml (extends zenith)
nn init gtd                # create .nn/workflow.toml (extends gtd)
nn init --user             # create ~/.config/notenav/config.toml
```

Or start from the annotated examples: [`samples/user-config.toml`](../samples/user-config.toml) and [`samples/workflows/project-workflow.toml`](../samples/workflows/project-workflow.toml).

## Workflow files

Workflows define what note types, statuses, and priorities are available and how they behave. The project workflow lives at `.nn/workflow.toml`.

`.nn/workflow.toml` can work in four ways:

**1. Extend a built-in workflow:** use a built-in as a base and override specific values:
```toml
extends = "gtd"

[status.colors]
next = "32;1"       # bold green instead of default
```

**2. Use a built-in as-is:** just the `extends` key, nothing else:
```toml
extends = "ado"
```

**3. Extend a remote workflow (GitHub gist, raw URL, etc.)**:
```toml
extends = "https://gist.githubusercontent.com/user/abc123/raw/workflow.toml"

[priority.colors]
1 = "31"            # override on top of the remote workflow
```

Remote workflows require explicit trust via an allow-list and use a local cache – see [Remote workflows](#remote-workflows) below. Use `nn init <url>` to fetch and cache a remote workflow.

**4. Full custom definition:** no `extends` key, define everything from scratch:
```toml
[meta]
name = "My Workflow"

[type]
# ...
```

If no `.nn/workflow.toml` exists, the user config's `default_workflow` is used (defaults to `"zenith"`).

By design, there is no support for a user-global workflows directory – projects are self-contained.

## Workflow reference

A workflow file has four main sections – `[type]`, `[status]`, `[priority]`, and `[meta]` – plus optional `[queries]` presets and an `extends` key for inheritance.

### `[meta]`

Identifies the workflow and declares its schema version.

```toml
[meta]
name = "My Workflow"
description = "Custom workflow for my project"
schema = 1
```

| Key | Type | Description |
|-----|------|-------------|
| `name` | string | Display name |
| `description` | string | Short description |
| `schema` | integer | Schema version (default: `1`). notenav rejects workflows with a version it does not support. |

### `[type]`

Note types are the categories of notes (e.g. task, idea, bug). Each type is a sub-table under `[type]`.

```toml
[type]
default_color = "36"                          # fallback ANSI color
values = ["task", "idea", "reference"]        # valid types; array order = display order

[type.task]
icon = "◆"
color = "36"           # ANSI color code
description = "Concrete, actionable unit of work"
```

| Key | Type | Description |
|-----|------|-------------|
| `values` | array | Valid note types; array order is used as the default display order |
| `default_color` | string | ANSI color code used for types not explicitly listed |
| `display_order` | array | *(optional)* Override display order (group headers and stats bar); defaults to `values` order |
| `[type.<name>].icon` | string | Single character displayed in the list |
| `[type.<name>].color` | string | ANSI color code (e.g. `"31"` = red, `"32"` = green) |
| `[type.<name>].description` | string | What this type represents |

**Common ANSI color codes:** `31` red, `32` green, `33` yellow, `34` blue, `35` magenta, `36` cyan, `90` dim gray. Append `;1` for bold (e.g. `"31;1"` = bold red).

### `[status]`

Statuses represent the state of a note (e.g. new, active, done).

```toml
[status]
values = ["new", "active", "blocked", "done", "removed"]
initial = "new"
archive = ["done", "removed"]
filter_cycle = ["new", "active", "blocked", "done"]
default_color = "90"

[status.colors]
new = "90"
active = "32"
blocked = "31"
done = "90"
removed = "90"

[status.lifecycle.forward]
new = "active"
active = "done"
done = "new"
blocked = "active"

[status.lifecycle.reverse]
done = "active"
active = "new"
new = "done"
blocked = "new"
```

| Key | Type | Description |
|-----|------|-------------|
| `values` | array | All valid statuses; array order is used as the default display order |
| `initial` | string | Starting status assigned when pressing `a` on a note that has no status |
| `display_order` | array | *(optional)* Override display order (group headers); defaults to `values` order |
| `archive` | array | Statuses hidden by default; press `zh` to toggle visibility |
| `filter_cycle` | array | Order when pressing `s` to cycle the filter (`"all"` is auto-prepended) |
| `default_color` | string | Fallback ANSI color for statuses not in `[status.colors]` |
| `[status.colors]` | table | ANSI color per status |
| `[status.lifecycle.forward]` | table | Transition map for `a` key (advance status) |
| `[status.lifecycle.reverse]` | table | Transition map for `A` key (reverse status) |

**Tombstone pattern:** A status can be in `values` but omitted from `filter_cycle` and `lifecycle`. This makes it reachable only via bulk edit or manual frontmatter change – useful for "removed" or "dropped" statuses that shouldn't appear in normal workflow.

### `[priority]`

Priority levels for ranking notes. Can be disabled entirely.

```toml
[priority]
values = ["1", "2", "3", "4"]
filter_cycle = ["1", "2", "3", "4"]
unset_position = "last"
default_color = "33"

[priority.colors]
1 = "31;1"       # bold red
2 = "33"         # yellow
3 = "33"
4 = "33"

[priority.labels]    # optional
1 = "P!"
2 = "P+"

[priority.lifecycle.up]
4 = "3"
3 = "2"
2 = "1"

[priority.lifecycle.down]
1 = "2"
2 = "3"
3 = "4"
```

| Key | Type | Description |
|-----|------|-------------|
| `enabled` | boolean | Set to `false` to disable priority entirely (default: `true`) |
| `values` | array | Valid priority levels; array order = sort order (first = highest) |
| `filter_cycle` | array | Order when pressing `p` to cycle the filter (`"all"` is auto-prepended) |
| `unset_position` | string | Where unprioritized notes sort: `"first"` or `"last"` |
| `default_color` | string | Fallback ANSI color for priorities not in `[priority.colors]` |
| `[priority.colors]` | table | ANSI color per priority level |
| `[priority.labels]` | table | Optional short display labels; omit to show `P{value}` (e.g. "P1") |
| `[priority.lifecycle.up]` | table | Transition map: move toward higher urgency (lower number) |
| `[priority.lifecycle.down]` | table | Transition map: move toward lower urgency (higher number) |

Values can be numeric (`"1"`, `"2"`, `"3"`) or named (`"critical"`, `"high"`, `"low"`). To disable priority entirely, set `enabled = false` – this hides priority from the TUI and disables the `+`/`-` keybindings.

Which key maps to which lifecycle table depends on the [`priority_plus`](#priority-key-direction) setting in `[ui]`.

### `[queries]`

Query presets are saved filtered views that appear in the TUI query bar. Each workflow ships with built-in presets, and you can add your own in user or project config.

```toml
[queries.my-view]
order = 50           # lower = earlier in the query bar (default: 100)
args = "type=task status=active"
```

| Key | Type | Description |
|-----|------|-------------|
| `order` | number | Sort position in the query bar (default: `100`, lower = first) |
| `args` | string | Filter arguments as key=value pairs |

**Merge order** (later wins on name collisions):

1. **Workflow:** built-in presets from the active workflow
2. **User config** (`~/.config/notenav/config.toml`): personal queries, available everywhere
3. **Project config** (`.nn/workflow.toml`): team-shared, project-specific

Same-name queries at a later layer fully replace the earlier one. For example, defining `[queries.inbox]` in your project config overrides the workflow's `inbox` preset.

**Clearing workflow presets:** If you want to start fresh without the workflow's built-in queries, set `inherit = false` in your project or user config:

```toml
# .nn/workflow.toml — clear workflow presets, define only your own
[queries]
inherit = false

[queries.my-custom]
args = "type=task status=active"
```

This removes all workflow-level queries before merging. Queries defined in the same file (or higher layers) still apply. The `inherit` key itself is stripped from the final config. Setting `inherit = false` in user config (`~/.config/notenav/config.toml`) strips workflow queries globally across all projects.

## Built-in workflows

notenav ships with four workflows. Use `extends` in `.nn/workflow.toml` or `default_workflow` in your user config to select one.

| Workflow | Types | Statuses | Priority | Use case |
|--------|----------|----------|----------|----------|
| **zenith** (default) | task, idea, reference | new, active, blocked, done, removed | 1-4 | General-purpose task/idea tracking |
| **ado** | feature, task, bug | new, active, resolved, closed, removed | 1-4 | Azure DevOps-style work items |
| **gtd** | action, project, reference | inbox, next, waiting, someday, done, dropped | 1-3 | Getting Things Done workflow |
| **zettelkasten** | fleeting, literature, permanent | draft, review, mature, archived | *(disabled)* | Slip-box knowledge management |

## Creating a custom workflow

The `extends` key is optional. If present, it deep-merges your definitions on top of the base workflow. If absent, your file is the entire workflow definition.

**Extending a built-in:**

```toml
# .nn/workflow.toml
extends = "zenith"

# Override just what you need
[type.bug]
icon = "✖"
color = "31"
description = "Defect to fix"
```

`extends` can chain – for example, a remote workflow can itself extend a built-in. The chain always terminates at a built-in or a full definition. Maximum recursion depth is 5 (currently non-configurable – please [file an issue](https://github.com/jqueiroz/notenav/issues) if you have a genuine use case for higher depth).

**Full custom workflow (no `extends`):**

```bash
cp samples/workflows/custom-workflow.toml .nn/workflow.toml
```

Then edit `.nn/workflow.toml` to define your note types, statuses, priorities, and lifecycle transitions. See [`samples/workflows/custom-workflow.toml`](../samples/workflows/custom-workflow.toml) for a fully annotated example.

## Remote workflows

`.nn/workflow.toml` can extend workflows hosted at any HTTPS URL (GitHub gists, GitLab snippets, raw URLs, etc.):

```toml
extends = "https://gist.githubusercontent.com/user/abc123/raw/workflow.toml"
```

**Security model:** notenav never fetches URLs at runtime. Downloads happen only via `nn init`:

```bash
# Project: fetch and create .nn/workflow.toml extending the URL
nn init https://gist.githubusercontent.com/user/abc123/raw/workflow.toml

# User: fetch and set as default_workflow in ~/.config/notenav/config.toml
nn init --user https://gist.githubusercontent.com/user/abc123/raw/workflow.toml
```

On first use, you'll be prompted to trust the URL. Trusted URLs are stored in `~/.config/notenav/trusted-sources` (one per line). The downloaded file is validated as TOML and cached under `~/.cache/notenav/workflows/`.

To refresh the project cache, run `nn init <url>` again – if `.nn/workflow.toml` already extends the same URL, the cache is refreshed without overwriting your project config.

**Paths:**

| File | Path |
|------|------|
| Allow-list | `$XDG_CONFIG_HOME/notenav/trusted-sources` |
| Cache | `$XDG_CACHE_HOME/notenav/workflows/` |

`nn doctor` reports on trusted sources and cache status.

## Preferences reference

### `default_workflow`

User config key that defines the fallback workflow for directories without a `.nn/workflow.toml`. Can be a built-in name or a remote URL (fetched via `nn init --user <url>`).

```toml
# ~/.config/notenav/config.toml
default_workflow = "zenith"    # built-in name (default)
default_workflow = "https://gist.githubusercontent.com/user/abc123/raw/workflow.toml"  # remote URL
```

### `[defaults]`

Default view settings.

```toml
[defaults]
sort_by = "created"       # created | modified | title | priority
sort_reverse = false      # true to reverse the default sort direction
group_by = ""             # "" (none) | type | status
show_archive = false      # true to show archived statuses by default
wrap_preview = false      # true to wrap the preview pane by default
```

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `sort_by` | string | `"created"` | Sort order for notes |
| `sort_reverse` | boolean | `false` | Whether to reverse the default sort direction |
| `group_by` | string | `""` | Grouping in the list; `""` for no grouping |
| `show_archive` | boolean | `false` | Whether archived statuses are visible on launch |
| `wrap_preview` | boolean | `false` | Whether the preview pane wraps long lines on launch |

### `[ui]`

TUI preferences.

```toml
[ui]
editor = ""              # empty = $EDITOR, then nvim/vim/vi/nano/emacs
command_prompt = ": "    # prompt in normal (command) mode
search_prompt = "/ "     # prompt in ad-hoc interactive mode
exit_message = "none"    # "none" or "fortune"
priority_plus = "demote" # what the + key does to priority
after_create = "edit"    # "edit" or "none"
previewer = ["bat", "glow", "mdcat"]  # fallback list; tries each in order
previewer_custom_command = "" # command when previewer includes "custom"
```

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `editor` | string | `""` | Editor for opening notes; empty uses `$EDITOR`, then falls back to nvim → vim → vi → nano → emacs |
| `command_prompt` | string | `": "` | fzf prompt string in normal (command) mode |
| `search_prompt` | string | `"/ "` | fzf prompt string in ad-hoc interactive mode (`nn ... -i`) |
| `exit_message` | string | `"none"` | What to show on exit: `"none"` or `"fortune"` (a fun quote) |
| `priority_plus` | string | `"demote"` | What the `+` key does to priority (see below) |
| `after_create` | string | `"edit"` | What to do after creating a note: `"edit"` (open in editor) or `"none"` |
| `previewer` | string or array | `["bat", "glow", "mdcat"]` | Previewer fallback list – tries each in order, uses first one found (see below) |
| `previewer_custom_command` | string | `""` | Command to run for the `"custom"` previewer entry (file path passed as `$1`) |

#### Priority key direction

The `+`/`-` keys (and their `>`/`<` aliases) bump a note's priority. The `priority_plus` setting controls which direction `+` moves:

| Value | `+` / `>` does | `-` / `<` does |
|-------|----------------|----------------|
| `"demote"` (default) | Lower urgency (e.g. P1→P2) | Raise urgency (e.g. P2→P1) |
| `"promote"` | Raise urgency (e.g. P2→P1) | Lower urgency (e.g. P1→P2) |

Both values use the same lifecycle tables (`[priority.lifecycle.up]` and `[priority.lifecycle.down]`) – the setting only controls which table the `+`/`-` and `>`/`<` keys map to.

#### Previewer

The `previewer` setting controls which tool renders markdown in the preview pane. It accepts a **fallback list** – notenav tries each entry in order and uses the first one found on `$PATH`.

A single string (e.g. `previewer = "bat"`) is also accepted and is equivalent to a one-element list.

| Value | Tool | Notes |
|-------|------|-------|
| `"bat"` (default) | [bat](https://github.com/sharkdp/bat) (or batcat) | Syntax-highlighted plain text; fast |
| `"glow"` | [glow](https://github.com/charmbracelet/glow) | Rendered markdown with styling; slower than bat |
| `"mdcat"` | [mdcat](https://codeberg.org/flausch/mdcat) | Rendered markdown; supports inline images in kitty/iTerm2; slightly slower than bat |
| `"plain"` | cat | No highlighting or rendering |
| `"custom"` | user-defined | Runs `previewer_custom_command` with the file path as `$1` |

If no entry in the list is available, the preview falls back to `cat`. Use `nn doctor` to check which previewers are installed.

> **Performance note:** bat is near-instant because it only syntax-highlights. glow and mdcat fully parse and render markdown, which adds a slight delay each time you move to a new note. Choose based on whether you prefer speed or rendered output.

**Examples:**

```toml
# Rendered markdown with bat fallback
previewer = ["glow", "bat"]

# Custom previewer with bat fallback
previewer = ["custom", "bat"]
previewer_custom_command = "glow -s light -w 80"
```

For the `"custom"` entry, the command string is evaluated by the shell, so you can include flags. The file path is appended as the final argument. If the custom command is not found, the next entry in the list is tried.

### `[refresh]`

Controls how the TUI detects external changes to notes (edits in another terminal, syncs via Dropbox/git, etc.).

```toml
[refresh]
mode = "watch"         # "watch" | "poll" | "manual"
poll_interval = 30     # seconds between polls (poll mode only)
max_files = 0          # disable auto-refresh above this note count (0 = no limit)
```

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `mode` | string | `"watch"` | Refresh strategy: `"watch"` (filesystem events via inotifywait/fswatch), `"poll"` (periodic check), or `"manual"` (only on `r` key) |
| `poll_interval` | integer | `30` | Seconds between polls in poll mode |
| `max_files` | integer | `0` | Disable auto-refresh when the notebook has more notes than this; `0` means no limit. Manual refresh (`r` key) always works regardless of this setting. |

**Mode details:**

- **`watch`** (default) – uses `inotifywait` (Linux) or `fswatch` (macOS) to detect `.md` file changes in real time, with 1-second debouncing. If neither tool is installed, silently degrades to `manual` at runtime.
- **`poll`** – checks every `poll_interval` seconds whether any `.md` file is newer than the last index. Only triggers a reload when something actually changed.
- **`manual`** – no automatic refresh. Press `r` in command mode to reload.

In all modes, pressing `r` in command mode triggers an immediate manual refresh.

### Overriding workflow colors

You can override individual colors without writing a full custom workflow. In `.nn/workflow.toml`, use `extends` and override what you need:

```toml
# .nn/workflow.toml
extends = "zenith"

[type.task]
color = "34"          # change tasks from cyan to blue

[status.colors]
active = "32;1"       # bold green for active

[priority.colors]
1 = "31"              # non-bold red for P1
```

User config can also override colors – these merge on top of the workflow values:

```toml
# ~/.config/notenav/config.toml
[status.colors]
active = "32;1"       # personal preference, applies to all projects
```
