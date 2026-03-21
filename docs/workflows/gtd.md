# GTD Workflow

Based on David Allen's [Getting Things Done](https://gettingthingsdone.com/) methodology.

**Workflow file:** [`config/workflows/gtd.toml`](../../config/workflows/gtd.toml)

```bash
# In ~/.config/notenav/config.toml or .nn/workflow.toml
default_workflow = "gtd"
```

## Philosophy

GTD is built on a simple principle: your brain is for having ideas, not holding them. Everything goes into a trusted system, then gets processed into the right bucket.

The key insight in this workflow: **entity = what it is, status = which GTD list it lives on.** A note's entity type describes its nature (action, project, reference), while its status describes where it sits in the GTD workflow.

## Entity Types

| Icon | Type | Description |
|------|------|-------------|
| ◆ | action | Single concrete action – a physical, visible next step |
| ◈ | project | Multi-step outcome – anything requiring more than one action |
| ▪ | reference | Non-actionable reference material – kept for future lookup |

### Choosing the right type

- **"Call the dentist"** → action (one step, clearly defined)
- **"Plan kitchen renovation"** → project (multiple steps, needs breakdown)
- **"Company holiday policy"** → reference (no action needed, just information)

## Statuses (GTD Lists)

Each status maps to a GTD list:

| Status | GTD List | Meaning | Color |
|--------|----------|---------|-------|
| inbox | Inbox | Captured but not yet processed | yellow |
| next | Next Actions | Ready to do – the immediate to-do list | green |
| waiting | Waiting For | Delegated or blocked on someone else | blue |
| someday | Someday/Maybe | Interesting but not committed to now | dim |
| done | Done | Completed (archived by default) | dim |
| dropped | Dropped | Tombstone – decided not to do | dim |

### Lifecycle

Press `a` to advance (clarify/complete), `A` to reverse (reopen/defer):

```
      inbox ──▶ next ──▶ done
        ▲         ▲
  waiting ─┘  someday ─┘
```

- **Forward (a):** inbox → next → done. waiting → next. someday → next. done/dropped → inbox (reopen).
- **Reverse (A):** done → next → inbox → someday → dropped. waiting → inbox.

The `dropped` status is the GTD equivalent of "removed" – a tombstone for items you've decided not to pursue. It has no forward lifecycle; pressing `a` on a dropped item sends it back to inbox for reconsideration.

## Priority

Three levels only. GTD favors context and energy level over rigid priority schemes, so this is kept intentionally light.

| Level | Meaning | Color |
|-------|---------|-------|
| P1 | Must do | bold red |
| P2 | Should do | yellow |
| P3 | Could do | dim |

## The GTD Workflow in notenav

### 1. Capture

Create notes freely with `n`. Everything starts in **inbox**. Don't worry about categorization yet – just get it out of your head.

### 2. Clarify

Filter to inbox notes (`s` to cycle to inbox status). For each item, ask: "Is this actionable?"

- **Yes, one step** → set type to `action`, advance to `next` with `a`
- **Yes, multiple steps** → set type to `project`, advance to `next`
- **No, but useful** → set type to `reference`, advance to `next` (or `someday`)
- **No, not needed** → set status to `dropped` via bulk edit

### 3. Organize

Use priority (`+`/`-`) to flag urgent items. Use tags for contexts (e.g., `@phone`, `@computer`, `@errands`).

### 4. Review

Filter by status to review each list. The weekly review is the backbone of GTD – process inbox to zero, review next/waiting/someday lists.

### 5. Do

Filter to `next` actions. Pick based on context (tags), time available, and energy.

## Example Frontmatter

```yaml
---
title: "Call plumber about kitchen leak"
type: action
status: next
priority: 1
tags: [home, phone]
created: 2026-03-18
---
```

## Query Presets

GTD ships with four built-in query presets aligned to the core GTD lists:

| Preset | Filter | Purpose |
|--------|--------|---------|
| next-actions | `type=action status=next` | Actions ready to do — your immediate to-do list |
| inbox | `status=inbox` | Unclarified captures awaiting processing |
| waiting | `status=waiting` | Delegated items or things blocked on others |
| someday | `status=someday` | Parked ideas — review during weekly review |

These can be overridden or cleared in project/user config. See [Configuration](../configuration.md#query-presets) for details.

## When to Use GTD

GTD works best when you have a high volume of heterogeneous inputs – work tasks, personal errands, ideas, delegated items – and need a reliable system to process them all. It scales from a handful of notes to hundreds.

If you don't need the full GTD list structure, [Compass](compass.md) is simpler. If you're focused on software development, see [ADO](ado.md).
