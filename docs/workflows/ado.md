# ADO Workflow

Inspired by [Azure DevOps](https://azure.microsoft.com/en-us/products/devops/) work item types and state transitions.

**Workflow file:** [`config/workflows/ado.toml`](../../config/workflows/ado.toml)

```toml
# Per-project – .nn/workflow.toml
extends = "ado"
```

```toml
# As default for all projects – ~/.config/notenav/config.toml
default_workflow = "ado"
```

## Philosophy

A software development workflow with three work item types (feature, task, bug) and a linear state progression (new → active → resolved → closed). Mirrors how teams track work in Azure DevOps, Jira, or similar tools – but in your local notes.

This is useful when your notes are primarily about tracking software work items and you want the same mental model you use in your project management tool.

## Note Types

| Icon | Type | Description |
|------|------|-------------|
| ◇ | feature | Planned capability or improvement – a user-visible change |
| ◆ | task | Discrete unit of work – an implementation step |
| ✖ | bug | Defect to fix |

### Choosing the right type

- **"Add dark mode support"** → feature (user-visible capability)
- **"Write migration script for user table"** → task (implementation step)
- **"Login fails when password contains special characters"** → bug (defect)

## Statuses

Linear progression mirroring the ADO work item lifecycle:

| Status | Meaning | Color |
|--------|---------|-------|
| new | Created, not yet started | dim |
| active | In progress | green |
| resolved | Done, pending verification | blue |
| closed | Verified and complete (archived by default) | dim |
| removed | Cancelled or invalid | dim |

### Lifecycle

Press `a` to advance, `A` to reverse:

```
      new ──▶ active ──▶ resolved ──▶ closed
       ▲                                 │
       └─────────────────────────────────┘
```

- **Forward (a):** new → active → resolved → closed → new (loop).
- **Reverse (A):** closed → resolved → active → new → closed (loop).

This is a fully connected cycle – you can reopen closed items by advancing past closed back to new, or reverse step by step.

## Priority

Four levels, matching typical issue tracker severity:

| Level | Meaning | Color |
|-------|---------|-------|
| P1 | Critical – drop everything | bold red |
| P2 | High – do soon | yellow |
| P3 | Medium – normal priority | yellow |
| P4 | Low – when time allows | dim |

## Example Frontmatter

```yaml
---
title: "API returns 500 on empty request body"
type: bug
status: active
priority: 1
tags: [api, backend]
created: 2026-03-18
---
```

## Query Presets

ADO ships with three built-in query presets:

| Preset | Filter | Purpose |
|--------|--------|---------|
| active-bugs | `type=bug status=active` | Bugs currently being worked on – the fire list |
| p1-features | `type=feature priority=1` | Critical features that need attention |
| new-items | `status=new` | Recently created items awaiting triage |

These can be overridden or cleared in project/user config. See [Configuration](../configuration.md#queries) for details.

## When to Use ADO

ADO is a good fit when:

- Your notes track software development work items
- You want a familiar new → active → resolved → closed flow
- You need clear separation between features, tasks, and bugs

For more general note-taking, see [Zenith](zenith.md). For a process-oriented approach, see [GTD](gtd.md).
