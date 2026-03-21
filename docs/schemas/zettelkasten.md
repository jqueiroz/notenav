# Zettelkasten Schema

Based on Niklas Luhmann's [Zettelkasten](https://en.wikipedia.org/wiki/Zettelkasten) (slip-box) method for knowledge management.

**Schema file:** [`config/schemas/zettelkasten.toml`](../../config/schemas/zettelkasten.toml)

```bash
# In ~/.config/notenav/config.toml or .nn/config.toml
default_schema = "zettelkasten"
```

## Philosophy

The Zettelkasten method treats notes as atomic, interconnected ideas. Each note should express one idea clearly enough that it makes sense on its own. Value emerges from the connections between notes, not from hierarchical organization.

In this schema:

- **Entity type** captures where the note is in the knowledge pipeline: fleeting capture → literature notes → permanent ideas.
- **Status** captures the note's maturity: how developed and reviewed it is.
- **Priority is disabled** – in a Zettelkasten, notes gain importance through their connections, not through explicit ranking.

## Entity Types

| Icon | Type | Description |
|------|------|-------------|
| ◇ | fleeting | Quick capture – a thought, observation, or reminder to process later |
| ▪ | literature | Notes from a source – a book, article, talk, or conversation |
| ◆ | permanent | Atomic, fully developed idea – written in your own words |

### The note progression

Notes typically evolve through entity types:

1. **Fleeting notes** are captured quickly throughout the day. They're rough, incomplete, and meant to be processed soon.
2. **Literature notes** summarize ideas from a specific source. They capture what someone else said, in your words, with a citation.
3. **Permanent notes** are your own ideas – atomic, self-contained, and written to be understood without context. Each permanent note connects to others, forming a web of knowledge.

Not every note follows this progression. Some fleeting notes get discarded. Some permanent notes are written directly. The types help you see where your unprocessed material is.

## Statuses

Linear maturity progression – how developed and reviewed a note is:

| Status | Meaning | Color |
|--------|---------|-------|
| draft | First pass – rough, possibly incomplete | yellow |
| review | Needs another look – check clarity, add links | blue |
| mature | Well-developed, connected, ready to build on | green |
| archived | No longer actively maintained (archived by default) | dim |

### Lifecycle

Press `a` to advance maturity, `A` to reverse:

```
      draft ──▶ review ──▶ mature ──▶ archived
        ▲                                 │
        └─────────────────────────────────┘
```

All statuses participate in the lifecycle – there are no tombstones. Archived notes can be brought back to draft for reworking.

## Priority

Disabled. In a Zettelkasten, a note's importance is determined by how densely connected it is to other notes – not by an explicit priority label. Use [zk](https://github.com/zk-org/zk) link features to discover which notes are most referenced.

## Example Frontmatter

```yaml
---
title: "Emergence arises from simple rules applied locally"
type: permanent
status: mature
tags: [complexity, systems-thinking]
created: 2026-03-18
---
```

## Working with the Zettelkasten Schema

### Daily capture

Throughout the day, create fleeting notes with `n` for anything that catches your attention. Don't worry about quality – just capture. These start as `draft`.

### Processing sessions

Filter to fleeting notes in draft status. For each one:

- **Discard** if it's no longer relevant
- **Expand** into a literature note if it came from a source
- **Develop** into a permanent note if it's your own idea
- **Advance maturity** with `a` as you refine it

### Linking

The real power of a Zettelkasten comes from connections. Use your editor to add `[[wiki-links]]` between related permanent notes. Over time, clusters of densely connected notes reveal your areas of deep understanding.

### Review

Filter to `review` status to find notes that need another pass. Check for clarity, add links to related notes, and advance to `mature` when satisfied.

## When to Use Zettelkasten

This schema is for knowledge management and intellectual work – research, writing, learning. It works best when:

- You read widely and want to build on what you learn
- You value long-term knowledge accumulation over task completion
- You write to think, not just to record

If your notes are primarily tasks and to-dos, [Compass](compass.md) or [GTD](gtd.md) will serve you better.
