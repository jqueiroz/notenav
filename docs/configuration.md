# Configuration

[Back to README](../README.md)

## Overview

All configuration is TOML, across two scopes:

- **Project** (`.nn/config.toml`) — defines the schema (built-in or custom), saved queries, and preset filters for the project.
- **User** (`~/.config/notenav/config.toml`) — personal preferences for visualization, editor, sorting, and grouping. Also defines a fallback schema, used in directories without project-level configuration.

Schemas define your workflow vocabulary: entity types, statuses, priorities, colors, and lifecycle transitions.

Both scopes are layered on top of notenav's base defaults, so you only need to specify what you want to change.

## Config resolution

At startup, configuration is assembled by deep-merging files in order (later values win):

| Layer | Path | Purpose |
|-------|------|---------|
| 1. Schema | *(selected schema file)* | Workflow vocabulary |
| 2. Base config | `$NOTENAV_ROOT/config/base.toml` | Ships with notenav |
| 3. User config | `~/.config/notenav/config.toml` | Personal preferences |
| 4. Project config | `.nn/config.toml` | Per-project overrides |

The project config is found by walking up from the current directory to the nearest `.nn/` directory.

See [`samples/profiles/user-config.toml`](../samples/profiles/user-config.toml) and [`samples/profiles/project-config.toml`](../samples/profiles/project-config.toml) for annotated examples.

## Schema files

Schemas define what entity types, statuses, and priorities are available and how they behave.

**Resolution order** (first match wins):

| Priority | Path |
|----------|------|
| 1. Project | `.nn/schemas/<name>.toml` |
| 2. User | `~/.config/notenav/schemas/<name>.toml` |
| 3. Built-in | `$NOTENAV_ROOT/config/schemas/<name>.toml` |

**Defining which schema to use:**

- In project config (`.nn/config.toml`): set `schema = "<name>"`
- In user config (`~/.config/notenav/config.toml`): set `default_schema = "<name>"` — used as fallback in directories without project-level configuration

## Schema reference

A schema file has four top-level sections: `[meta]`, `[entity]`, `[status]`, and `[priority]`.

### `[meta]`

Descriptive metadata. Not used at runtime but helps identify the schema.

```toml
[meta]
name = "My Workflow"
description = "Custom schema for my project"
```

| Key | Type | Description |
|-----|------|-------------|
| `name` | string | Display name |
| `description` | string | Short description |

### `[entity]`

Entity types are the categories of notes (e.g. task, idea, bug). Each entity is a sub-table under `[entity]`.

```toml
[entity]
default_color = "36"                          # fallback ANSI color
display_order = ["task", "idea", "reference"] # grouping order

[entity.task]
icon = "◆"
color = "36"           # ANSI color code
description = "Concrete, actionable unit of work"
```

| Key | Type | Description |
|-----|------|-------------|
| `default_color` | string | ANSI color code used for entity types not explicitly listed |
| `display_order` | array | Order for group headers when grouping by type |
| `[entity.<name>].icon` | string | Single character displayed in the list |
| `[entity.<name>].color` | string | ANSI color code (e.g. `"31"` = red, `"32"` = green) |
| `[entity.<name>].description` | string | What this entity type represents |

**Common ANSI color codes:** `31` red, `32` green, `33` yellow, `34` blue, `35` magenta, `36` cyan, `90` dim gray. Append `;1` for bold (e.g. `"31;1"` = bold red).

### `[status]`

Statuses represent the state of a note (e.g. new, active, done).

```toml
[status]
values = ["new", "active", "blocked", "done", "removed"]
display_order = ["active", "blocked", "new", "done", "removed"]
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
| `values` | array | All valid statuses a note can have |
| `display_order` | array | Order for group headers when grouping by status |
| `archive` | array | Statuses hidden by default; press `z` to toggle visibility |
| `filter_cycle` | array | Order when pressing `s` to cycle the filter (`"all"` is auto-prepended) |
| `default_color` | string | Fallback ANSI color for statuses not in `[status.colors]` |
| `[status.colors]` | table | ANSI color per status |
| `[status.lifecycle.forward]` | table | Transition map for `a` key (advance status) |
| `[status.lifecycle.reverse]` | table | Transition map for `A` key (reverse status) |

**Tombstone pattern:** A status can be in `values` but omitted from `filter_cycle` and `lifecycle`. This makes it reachable only via bulk edit or manual frontmatter change — useful for "removed" or "dropped" statuses that shouldn't appear in normal workflow.

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
"" = "4"         # bumping from unset starts at lowest
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
| `[priority.lifecycle.up]` | table | Transition map for `+` key; `""` key = bump from unset |
| `[priority.lifecycle.down]` | table | Transition map for `-` key |

Values can be numeric (`"1"`, `"2"`, `"3"`) or named (`"critical"`, `"high"`, `"low"`). To disable priority entirely, set `enabled = false` — this hides priority from the TUI and disables the `+`/`-` keybindings.

## Built-in schemas

notenav ships with four schemas. Define `schema` in your project config or `default_schema` in your user config to use one.

| Schema | Entities | Statuses | Priority | Use case |
|--------|----------|----------|----------|----------|
| **compass** (default) | task, idea, reference | new, active, blocked, done, removed | 1-4 | General-purpose task/idea tracking |
| **ado** | feature, task, bug | new, active, resolved, closed, removed | 1-4 | Azure DevOps-style work items |
| **gtd** | action, project, reference | inbox, next, waiting, someday, done, dropped | 1-3 | Getting Things Done workflow |
| **zettelkasten** | fleeting, literature, permanent | draft, review, mature, archived | *(disabled)* | Slip-box knowledge management |

## Creating a custom schema

1. Copy an existing schema as a starting point:
   ```bash
   cp samples/schemas/custom-schema.toml ~/.config/notenav/schemas/myworkflow.toml
   ```

2. Edit the file to define your entity types, statuses, priorities, and lifecycle transitions.

3. Define it in your config:
   ```toml
   # .nn/config.toml (project)
   schema = "myworkflow"
   ```

   Or as a user-level fallback:
   ```toml
   # ~/.config/notenav/config.toml
   default_schema = "myworkflow"
   ```

For a project-local schema, place it in `.nn/schemas/` instead — it will be found first.

See [`samples/schemas/custom-schema.toml`](../samples/schemas/custom-schema.toml) for a fully annotated example.

## Preferences reference

### `default_schema` / `schema`

Top-level keys that define which schema to use.

```toml
# In project config (.nn/config.toml):
schema = "ado"

# In user config (~/.config/notenav/config.toml):
default_schema = "compass"    # fallback for directories without project config
```

### `[defaults]`

Default view settings for the faceted browser.

```toml
[defaults]
sort_by = "created"       # created | modified | title | priority
group_by = "type"         # "" (none) | type | status
show_archive = false      # true to show archived statuses by default
```

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `sort_by` | string | `"created"` | Sort order for notes |
| `group_by` | string | `"type"` | Grouping in the list; `""` for no grouping |
| `show_archive` | boolean | `false` | Whether archived statuses are visible on launch |

### `[ui]`

TUI preferences.

```toml
[ui]
editor = ""        # empty = $EDITOR or nvim
prompt = ": "
```

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `editor` | string | `""` | Editor for opening notes; empty uses `$EDITOR` or falls back to `nvim` |
| `prompt` | string | `": "` | fzf prompt string |

### Overriding schema colors

You can override individual colors from the active schema without creating a full custom schema. These merge on top of the schema values.

```toml
# In user or project config (both work):

[entity.task]
color = "34"          # change tasks from cyan to blue

[status.colors]
active = "32;1"       # bold green for active

[priority.colors]
1 = "31"              # non-bold red for P1
```
