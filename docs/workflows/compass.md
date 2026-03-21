# Compass Workflow

The default notenav workflow. A simple workflow built around three note types, four statuses, and four priority levels – enough structure to manage a project without getting in the way.

**Workflow file:** [`config/workflows/compass.toml`](../../config/workflows/compass.toml)

```toml
# ~/.config/notenav/config.toml
# Use compass (this is the default – no config needed)
default_workflow = "compass"
```

## Philosophy

Every note is one of three things:

- A **task** – something concrete you need to do
- An **idea** – captures an early insight; enriched over time, may evolve into one or more tasks
- A **reference** – living documentation you maintain over time

This maps naturally to how most people think about their notes. Ideas may evolve into tasks as they become clearer. Tasks get done. References grow and change as understanding deepens.

**Capture first, organize later** – borrowing from [Getting Things Done](https://en.wikipedia.org/wiki/Getting_Things_Done): when you create a note, don't worry about priority – just get it down. Notes without a priority automatically appear in the **inbox** query preset. During triage, review the inbox and assign priorities; this moves notes into your working views, where they're visible alongside everything else you've already prioritized. The inbox empties as you triage, giving you a clear signal of what still needs attention.

## Entity Types

| Icon | Type | Description |
|------|------|-------------|
| ◆ | task | Concrete, actionable unit of work |
| ✦ | idea | Captures an early insight; enriched over time, may evolve into one or more tasks |
| ▪ | reference | Living documentation; continually updated as understanding grows |

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
title: "Refactor config loader"
type: task
status: active
priority: 2
tags: [backend, tech-debt]
created: 2026-03-18
---
```

## Query Presets

Compass ships with five built-in query presets – filtered views that appear in the query bar when you launch `nn`:

| Preset | Filter | Purpose |
|--------|--------|---------|
| inbox | `priority=none` | Unprioritized notes awaiting triage |
| p1-tasks | `type=task priority=1` | Your highest-priority tasks – the things to work on right now |
| p1-ideas | `type=idea priority=1` | High-priority ideas worth exploring soon |
| p1-references | `type=reference priority=1` | High-priority references that need attention |
| all-active | `status=active` | Everything currently in progress |

These can be overridden or cleared in project/user config. See [Configuration](../configuration.md#query-presets) for details.

## When to Use Compass

Compass is a good default when you don't have a specific methodology in mind. It works well for:

- Personal project management
- Mixed notebooks with tasks, brainstorming, and documentation
- Teams that want a simple, low-ceremony workflow

If you find yourself needing more structure, consider [GTD](gtd.md) for capture-and-process workflows, [ADO](ado.md) for software development, or [Zettelkasten](zettelkasten.md) for knowledge management.
