# Compass Schema

The default notenav schema. A simple three-way categorization that covers most personal note-taking and task-management needs.

**Schema file:** [`config/schemas/compass.toml`](../../config/schemas/compass.toml)

```toml
# ~/.config/notenav/config.toml
# Use compass (this is the default – no config needed)
default_schema = "compass"
```

## Philosophy

Every note is one of three things:

- A **task** – something concrete you need to do
- An **idea** – something you're exploring that isn't actionable yet
- A **reference** – living documentation you maintain over time

This maps naturally to how most people think about their notes. Ideas may evolve into tasks as they become clearer. Tasks get done. References grow and change as understanding deepens.

## Entity Types

| Icon | Type | Description |
|------|------|-------------|
| ◆ | task | Concrete, actionable unit of work |
| ✦ | idea | Needs further exploration/research; may evolve into one or more tasks |
| ▪ | reference | Living documentation; continually updated as understanding grows |

## Statuses

| Status | Meaning | Color |
|--------|---------|-------|
| new | Just captured, not yet started | dim |
| active | Currently being worked on | green |
| blocked | Waiting on something external | red |
| done | Completed (archived by default) | dim |
| removed | Tombstone – only reachable via bulk edit | dim |

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

The `removed` status has no lifecycle transitions – it's a tombstone, reachable only through bulk edit or manual frontmatter changes.

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

Compass ships with four built-in query presets — filtered views that appear in the query bar when you launch `nn`:

| Preset | Filter | Purpose |
|--------|--------|---------|
| p1-tasks | `type=task priority=1` | Your highest-priority tasks — the things to work on right now |
| p1-ideas | `type=idea priority=1` | High-priority ideas worth exploring soon |
| p1-references | `type=reference priority=1` | High-priority references that need attention |
| inbox | `priority=none` | Unprioritized notes awaiting triage |

These can be overridden or cleared in project/user config. See [Configuration](../configuration.md#query-presets) for details.

## When to Use Compass

Compass is a good default when you don't have a specific methodology in mind. It works well for:

- Personal project management
- Mixed notebooks with tasks, brainstorming, and documentation
- Teams that want a simple, low-ceremony workflow

If you find yourself needing more structure, consider [GTD](gtd.md) for capture-and-process workflows, [ADO](ado.md) for software development, or [Zettelkasten](zettelkasten.md) for knowledge management.
