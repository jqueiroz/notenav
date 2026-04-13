# Adding a Built-in Workflow

[Back to README](../README.md)

Step-by-step guide for adding a new built-in workflow to notenav.

## 1. Create the workflow TOML

Add `config/workflows/<name>.toml`. Use an existing workflow as a template (e.g. [`zenith.toml`](../config/workflows/zenith.toml)). The file must define:

- **`[meta]`** – `name`, `description`, `schema_version = 1`
- **`[type]`** – `default_color`, `values` array, and a `[type.<name>]` section for each value with `icon`, `color`, `description`
- **`[status]`** – `values`, `initial`, `archive`, `filter_cycle`, `default_color`, plus `[status.colors]`, `[status.descriptions]`, `[status.lifecycle.forward]`, `[status.lifecycle.reverse]`
- **`[priority]`** – `values`, `filter_cycle`, `unset_position`, `default_color`, plus `[priority.colors]`, `[priority.lifecycle.up]`, `[priority.lifecycle.down]` (or set `enabled = false` to disable priority entirely – see `zettelkasten.toml`)
- **`[queries.*]`** – at least a few built-in query presets with `order` and `args`

### Validation rules

- Every entry in `type.values` needs a matching `[type.<name>]` section.
- Every entry in `status.values` needs a color in `[status.colors]` and should have a description in `[status.descriptions]` (recommended for built-in workflows; optional for custom workflows).
- Lifecycle transitions must only reference values that exist in `status.values` or `priority.values`.
- Query preset `args` must only reference valid types, statuses, and priorities from the same workflow.
- Tombstone statuses (e.g. `removed`) can be omitted from `filter_cycle` and lifecycle transitions.

## 2. Create the workflow documentation

Add `docs/workflows/<name>.md`. Follow the structure of existing docs (e.g. [`zenith.md`](workflows/zenith.md)):

1. Title and one-line summary
2. Workflow file link (relative path to the TOML)
3. Usage snippets (project config and user config)
4. Philosophy section – explain the mental model
5. Note types table (icon, type, description)
6. Statuses table and lifecycle diagram (ASCII art)
7. Priority table (or note that it's disabled)
8. Example frontmatter
9. Query presets table
10. "When to Use" section with cross-references to other workflows

## 3. Update the README workflow table

In `README.md`, add a row to the built-in workflows table (under "## Configuration"):

```markdown
| **<name>** | [docs/workflows/<name>.md](docs/workflows/<name>.md) | [config/workflows/<name>.toml](config/workflows/<name>.toml) |
```

Also update the count ("Ships with N built-in workflows") and any inline lists of workflow names (e.g. in the `nn init` CLI reference section).

## 4. Update the configuration.md workflow table

In `docs/configuration.md`, add a row to the "## Built-in workflows" table:

```markdown
| **<name>** | type1, type2, ... | status1, status2, ... | priority range | One-line use case |
```

Also update the count at the top of that section.

## 5. Update `nn init --help`

In `lib/notenav.sh`, find the `nn init` help text (search for `built-in name`) and add the new workflow name to the parenthetical list. `zenith` comes first (as the default); the rest are ordered by relatedness, not alphabetically.

## Summary checklist

Steps 1–5 above cover the main changes. The remaining files need minor updates (workflow name lists and table rows):

| # | File | What to update |
|---|------|----------------|
| 1 | `config/workflows/<name>.toml` | Create workflow definition |
| 2 | `docs/workflows/<name>.md` | Create workflow documentation |
| 3 | `README.md` | Add table row, update count, update `nn init` name list |
| 4 | `docs/configuration.md` | Add table row, update count |
| 5 | `lib/notenav.sh` | Update `nn init --help` workflow name list |
| 6 | `docs/reference.md` | Update `nn init` argument workflow name list |
| 7 | `docs/install.md` | Add row to built-in workflow file table |
| 8 | `docs/faq.md` | Add row to built-in workflow file table |
| 9 | `samples/user-config.toml` | Update workflow name list in comment |

The workflow list itself is dynamically discovered from `config/workflows/*.toml` at runtime, so no code changes are needed beyond the help text.

## Testing

After adding the workflow, verify it works:

```bash
nn doctor                      # should validate the new workflow
nn init <name>                 # should create .nn/workflow.toml extending it
nn                             # should launch the TUI with correct types/statuses/priorities
```
