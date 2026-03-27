# Cubic Workflow

A symmetrical 4×4×4 workflow – four note types, four statuses, four priority levels. Designed for personal wikis and mixed-purpose notebooks where you need one extra note type beyond the Zenith basics: the **reminder**.

**Workflow file:** [`config/workflows/cubic.toml`](../../config/workflows/cubic.toml)

```toml
# Per-project – .nn/workflow.toml
extends = "cubic"
```

```toml
# As default for all projects – ~/.config/notenav/config.toml
default_workflow = "cubic"
```

## Philosophy

Cubic extends Zenith's three-type model with a fourth type – **reminder** – for time-sensitive prompts that don't fit neatly into tasks, ideas, or references. A reminder is a nudge to revisit something: follow up with a colleague, check on a deploy, review a draft after letting it sit. It's not a task (there may be nothing to "do"), and it's not a reference (it expires once acted on).

The 4×4×4 structure is easy to remember and covers the full range of personal knowledge work:

- **Ideas** capture early insights
- **Tasks** track concrete work
- **References** hold living documentation
- **Reminders** prompt timely follow-ups

Statuses and priorities match Zenith, so switching between the two workflows is seamless.

## Note Types

| Icon | Type | Description |
|------|------|-------------|
| ✦ | idea | Captures an early insight; may evolve into tasks or references |
| ◆ | task | Concrete, actionable unit of work |
| ▪ | reference | Living documentation; continually updated as understanding grows |
| ◎ | reminder | Time-sensitive prompt to revisit, follow up, or act on something |

### Choosing the right type

- **"Explore using SQLite for local caching"** → idea (early insight, needs exploration)
- **"Migrate user table to new schema"** → task (concrete work)
- **"Team onboarding checklist"** → reference (living doc)
- **"Follow up with Alex about API access"** → reminder (time-sensitive nudge)

## Statuses

Every note moves through a lifecycle: **new** → **active** → **done**. Notes can also be **blocked** (stuck on something external) or **removed** (soft-deleted, i.e. the note stays on disk but is hidden from normal views).

| Status | Meaning | Color |
|--------|---------|-------|
| new | Just captured, not yet started | dim |
| active | Currently being worked on | green |
| blocked | Waiting on something external | red |
| done | Completed (archived by default) | dim |
| removed | Soft-deleted | dim |

### Lifecycle

Press `a` to advance, `A` to reverse:

```
        ┌──────────────────────┐
        ▼                      │
      new ──▶ active ──▶ done ─┘
               ▲
      blocked ─┘
```

- **Forward (a):** new → active → done → new (loop). blocked → active.
- **Reverse (A):** done → active → new → done (loop). blocked → new.

The `removed` status has no lifecycle transitions – pressing `a`/`A` won't cycle into or out of it. You can still set it explicitly via change mode (`c`→`s`), bulk edit, or manual frontmatter edit.

## Priority

Four levels, P1 (highest) to P4 (lowest). Notes without a priority sort last.

| Level | Meaning | Color |
|-------|---------|-------|
| P1 | Critical | bold red |
| P2 | High | yellow |
| P3 | Medium | yellow |
| P4 | Low | yellow |

Press `+` to increase priority, `-` to decrease. Pressing `+` on an unprioritized note sets it to P4.

## Example Frontmatter

```yaml
---
title: "Follow up with Alex about API access"
type: reminder
status: active
priority: 2
tags: [team, api]
created: 2026-03-25
---
```

## Query Presets

Cubic ships with five built-in query presets:

| Preset | Filter | Purpose |
|--------|--------|---------|
| inbox | `priority=none` | Unprioritized notes awaiting triage |
| p1-tasks | `type=task priority=1` | Your highest-priority tasks |
| p1-ideas | `type=idea priority=1` | High-priority ideas worth exploring soon |
| reminders | `type=reminder` | All reminders – your follow-up queue |
| all-active | `status=active` | Everything currently in progress |

These can be overridden or cleared in project/user config. See [Configuration](../configuration.md#query-presets) for details.

## When to Use Cubic

Cubic is a good fit when:

- You want Zenith's simplicity but need a place for time-sensitive follow-ups
- Your notebook mixes tasks, ideas, documentation, and reminders
- You like the symmetry of a 4×4×4 structure

If you don't need reminders, [Zenith](zenith.md) is simpler. For software development, see [ADO](ado.md). For a process-oriented approach, see [GTD](gtd.md).
