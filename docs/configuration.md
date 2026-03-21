# Configuration

[Back to README](../README.md)

## Overview

All configuration is TOML. Project and user configuration are orthogonal – neither inherits from or overrides the other:

- **Project configuration** (`.nn/workflow.toml`) – defines the project's workflow, typically extending a built-in one with project-specific query presets and overrides.
- **User preferences** (`$XDG_CONFIG_HOME/notenav/config.toml`, defaulting to `~/.config/notenav/config.toml`) – personal preferences for visualization, editor, sorting, and grouping. Also defines a fallback workflow, used in directories without project configuration.

Both scopes are layered on top of notenav's base defaults, so you only need to specify what you want to change.

## Config resolution

At startup, two things happen:

1. **Workflow resolution** – if `.nn/workflow.toml` exists, it defines the project's workflow. It can be a full custom definition, or it can extend a built-in using the `extends` key. If no `.nn/workflow.toml` exists, the user config's `default_workflow` is used, falling back to `"compass"`.

2. **Preference merge** – preferences are assembled by deep-merging these layers in order (later values win):

   | Layer | Source | Wins on |
   |-------|--------|---------|
   | 1. Workflow | Built-in or extended workflow definition | — (base) |
   | 2. Base config | `$NOTENAV_ROOT/config/base.toml` | Workflow defaults |
   | 3. User config | `$XDG_CONFIG_HOME/notenav/config.toml` | Everything above |
   | 4. Project queries | `[queries]` from `.nn/workflow.toml` | All queries |

   User preferences can override individual workflow values (like colors) without replacing the entire workflow. Project queries are applied last so they always win on name collisions.

The `.nn/` directory is found by walking up from the current directory.

See [`samples/user-config.toml`](../samples/user-config.toml) and [`samples/workflows/project-workflow.toml`](../samples/workflows/project-workflow.toml) for annotated examples.

## Workflow files

Workflows define what entity types, statuses, and priorities are available and how they behave. The project workflow lives at `.nn/workflow.toml`.

`.nn/workflow.toml` can work in four ways:

**1. Extend a built-in workflow** – use a built-in as a base and override specific values:
```toml
extends = "gtd"

[status.colors]
next = "32;1"       # bold green instead of default
```

**2. Use a built-in as-is** – just the `extends` key, nothing else:
```toml
extends = "ado"
```

**3. Extend a remote workflow (GitHub gist)** *(planned – not yet implemented)*:
```toml
extends = "https://gist.githubusercontent.com/user/abc123/raw/workflow.toml"

[priority.colors]
1 = "31"            # override on top of the remote workflow
```

Remote workflows will require explicit allow-listing in your user config (see [Remote workflows](#remote-workflows) below) and will use a local cache to avoid network fetches on every startup.

**4. Full custom definition** – no `extends` key, define everything from scratch:
```toml
[meta]
name = "My Workflow"

[entity]
# ...
```

If no `.nn/workflow.toml` exists, the user config's `default_workflow` is used (defaults to `"compass"`).

By design, there is no support for a user-global workflows directory – projects are self-contained.

## Workflow reference

A workflow file has four top-level sections: `[meta]`, `[entity]`, `[status]`, and `[priority]`.

### `[meta]`

Descriptive metadata. Not used at runtime but helps identify the workflow.

```toml
[meta]
name = "My Workflow"
description = "Custom workflow for my project"
```

| Key | Type | Description |
|-----|------|-------------|
| `name` | string | Display name |
| `description` | string | Short description |

### `[entity]`

Entity types are the categories of notes (e.g. task, idea, bug). Each entity type is a sub-table under `[entity]`.

```toml
[entity]
default_color = "36"                          # fallback ANSI color
values = ["task", "idea", "reference"]        # valid types; array order = display order

[entity.task]
icon = "◆"
color = "36"           # ANSI color code
description = "Concrete, actionable unit of work"
```

| Key | Type | Description |
|-----|------|-------------|
| `values` | array | Valid entity types; array order is used as the default display order |
| `default_color` | string | ANSI color code used for entity types not explicitly listed |
| `display_order` | array | *(optional)* Override group header order; defaults to `values` order |
| `[entity.<name>].icon` | string | Single character displayed in the list |
| `[entity.<name>].color` | string | ANSI color code (e.g. `"31"` = red, `"32"` = green) |
| `[entity.<name>].description` | string | What this entity type represents |

**Common ANSI color codes:** `31` red, `32` green, `33` yellow, `34` blue, `35` magenta, `36` cyan, `90` dim gray. Append `;1` for bold (e.g. `"31;1"` = bold red).

### `[status]`

Statuses represent the state of a note (e.g. new, active, done).

```toml
[status]
values = ["new", "active", "blocked", "done", "removed"]
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
| `display_order` | array | *(optional)* Override group header order; defaults to `values` order |
| `archive` | array | Statuses hidden by default; press `z` to toggle visibility |
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

Values can be numeric (`"1"`, `"2"`, `"3"`) or named (`"critical"`, `"high"`, `"low"`). To disable priority entirely, set `enabled = false` – this hides priority from the TUI and disables the `+`/`-` keybindings.

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

1. **Workflow** – built-in presets from the active workflow
2. **User config** (`~/.config/notenav/config.toml`) – personal queries, available everywhere
3. **Project config** (`.nn/workflow.toml`) – team-shared, project-specific

Same-name queries at a later layer fully replace the earlier one. For example, defining `[queries.inbox]` in your project config overrides the workflow's `inbox` preset.

**Clearing workflow presets:** If you want to start fresh without the workflow's built-in queries, set `inherit = false`:

```toml
# .nn/workflow.toml — clear workflow presets, define only your own
[queries]
inherit = false

[queries.my-custom]
args = "type=task status=active"
```

This removes all workflow-level queries before merging. Queries defined in the same file (or higher layers) still apply. The `inherit` key itself is stripped from the final config.

## Built-in workflows

notenav ships with four workflows. Use `extends` in `.nn/workflow.toml` or `default_workflow` in your user config to select one.

| Workflow | Entities | Statuses | Priority | Use case |
|--------|----------|----------|----------|----------|
| **compass** (default) | task, idea, reference | new, active, blocked, done, removed | 1-4 | General-purpose task/idea tracking |
| **ado** | feature, task, bug | new, active, resolved, closed, removed | 1-4 | Azure DevOps-style work items |
| **gtd** | action, project, reference | inbox, next, waiting, someday, done, dropped | 1-3 | Getting Things Done workflow |
| **zettelkasten** | fleeting, literature, permanent | draft, review, mature, archived | *(disabled)* | Slip-box knowledge management |

## Creating a custom workflow

The `extends` key is optional. If present, it deep-merges your definitions on top of the base workflow. If absent, your file is the entire workflow definition.

**Extending a built-in:**

```toml
# .nn/workflow.toml
extends = "compass"

# Override just what you need
[entity.bug]
icon = "✖"
color = "31"
description = "Defect to fix"
```

`extends` can chain – for example, a remote workflow can itself extend a built-in. The chain always terminates at a built-in or a full definition. Maximum recursion depth is 5 (currently non-configurable – please [file an issue](https://github.com/jqueiroz/notenav/issues) if you have a genuine use case for higher depth).

**Full custom workflow (no `extends`):**

```bash
cp samples/workflows/custom-workflow.toml .nn/workflow.toml
```

Then edit `.nn/workflow.toml` to define your entity types, statuses, priorities, and lifecycle transitions. See [`samples/workflows/custom-workflow.toml`](../samples/workflows/custom-workflow.toml) for a fully annotated example.

## Remote workflows *(planned)*

Remote workflow extends (`extends = "https://..."`) is not yet implemented. When available, `.nn/workflow.toml` will be able to extend workflows hosted on GitHub gists or GitLab snippets, with a local cache and explicit URL allow-listing for security.

## Preferences reference

### `default_workflow`

User config key that defines the fallback workflow for directories without a `.nn/workflow.toml`.

```toml
# ~/.config/notenav/config.toml
default_workflow = "compass"    # this is the default
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
editor = ""              # empty = $EDITOR or nvim
command_prompt = ": "    # prompt in normal (command) mode
search_prompt = "/ "     # prompt in search mode
```

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `editor` | string | `""` | Editor for opening notes; empty uses `$EDITOR` or falls back to `nvim` |
| `command_prompt` | string | `": "` | fzf prompt string in normal (command) mode |
| `search_prompt` | string | `"/ "` | fzf prompt string in search mode |

### Overriding workflow colors

You can override individual colors without writing a full custom workflow. In `.nn/workflow.toml`, use `extends` and override what you need:

```toml
# .nn/workflow.toml
extends = "compass"

[entity.task]
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
