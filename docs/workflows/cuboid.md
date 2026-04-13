# Cuboid Workflow

[Back to README](../../README.md)

A 4×5×4 workflow – four note types, five statuses, four priority levels. Designed for personal wikis and mixed-purpose notebooks where you need one extra note type beyond the Zenith basics: the **ritual**.

**Workflow file:** [`config/workflows/cuboid.toml`](../../config/workflows/cuboid.toml)

```toml
# Per-project – .nn/workflow.toml
extends = "cuboid"
```

```toml
# As default for all projects – ~/.config/notenav/config.toml
default_workflow = "cuboid"
```

## Philosophy

Cuboid extends Zenith's three-type model with a fourth type – **ritual** – for recurring practices and routines you want to keep top of mind. A ritual is something you revisit regularly as part of your rhythm: review your inbox, water the plants, check on a long-running deploy, journal before bed. It's not a task (there's no finish line) and it's not a reference (you act on it, not just read it).

The four note types cover the full range of personal knowledge work:

- **Ideas** capture early insights
- **Tasks** track concrete work
- **References** hold living documentation
- **Rituals** track recurring practices

Statuses and priorities match Zenith, so switching between the two workflows is seamless.

## Note Types

| Icon | Type | Description |
|------|------|-------------|
| ✦ | idea | Captures an early insight; may evolve into tasks or references |
| ◆ | task | Concrete, actionable unit of work |
| ▪ | reference | Living documentation; continually updated as understanding grows |
| ◎ | ritual | Recurring practice or routine to revisit regularly |

### Choosing the right type

- **"Explore using SQLite for local caching"** → idea (early insight, needs exploration)
- **"Migrate user table to new schema"** → task (concrete work)
- **"Team onboarding checklist"** → reference (living doc)
- **"Review inbox and triage new notes"** → ritual (recurring routine)

## Statuses

Every note moves through a lifecycle: **new** → **active** → **done**. Notes can also be **blocked** (stuck on something external) or **removed** (soft-deleted, i.e. the note stays on disk but is hidden from normal views).

| Status | Meaning | Color |
|--------|---------|-------|
| new | Not yet started | dim |
| active | Currently being worked on | green |
| blocked | Waiting on an external dependency | red |
| done | Completed – archived by default | dim |
| removed | Discarded or no longer relevant – tombstone, not part of the lifecycle or filter cycle | dim |

For **rituals**, statuses have a slightly different flavour: **active** means "part of my current routine," **new** means "considering adding this," and **done** means "I no longer do this" – not that it was completed once, but that the practice has been retired.

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
| P1 | Critical | bold-red |
| P2 | High | yellow |
| P3 | Medium | yellow |
| P4 | Low | yellow |

Press `+`/`-` to bump priority (direction depends on the [`priority_plus`](../configuration.md#priority-key-direction) setting). Pressing `+` or `-` on an unprioritized note sets it to P4 (the lowest level).

## Example Frontmatter

```yaml
---
title: "Review inbox and triage new notes"
type: ritual
status: active
tags: [daily, triage]
created: 2026-03-25
---
```

## Query Presets

Cuboid ships with five built-in query presets:

| Preset | Filter | Purpose |
|--------|--------|---------|
| inbox | `priority=none` | Unprioritized notes awaiting triage |
| p1-tasks | `type=task priority=1` | Your highest-priority tasks |
| p1-ideas | `type=idea priority=1` | High-priority ideas worth exploring soon |
| rituals | `type=ritual` | All rituals – your recurring practices |
| all-active | `status=active` | Everything currently in progress |

These can be overridden or cleared in project config. See [Configuration](../configuration.md#queries) for details.

## When to Use Cuboid

Cuboid is a good fit when:

- You want Zenith's simplicity but need a place for recurring routines and habits
- Your notebook mixes tasks, ideas, documentation, and rituals

If you don't need rituals, [Zenith](zenith.md) is simpler. For software development, see [ADO](ado.md). For a process-oriented approach, see [GTD](gtd.md).
