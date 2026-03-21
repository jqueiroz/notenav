# notenav (`nn`)

Your notes deserve a proper interface. Not a browser tab, not an Electron app – a fast, keyboard-driven TUI that feels like editing code. Finally, task and note management that's seamless and, dare we say, _fun_!

Filter by type, status, priority, and tags; search by filename or body contents; save and recall queries; perform inline actions – all without leaving the terminal. Friendly learning curve: with the default configuration, every keybinding is displayed on-screen.

Workflows are fully customizable: define your own entity types, statuses, priorities, colors, and lifecycle transitions via TOML config. Ships with built-in presets for common workflows.

Works with any markdown files that use [YAML frontmatter](https://jekyllrb.com/docs/front-matter/) – fully compatible with Obsidian, Dendron, Jekyll, and similar tools. Built on [fzf](https://github.com/junegunn/fzf), with [zk](https://github.com/zk-org/zk) for indexing. For non-interactive usage (scripting, batch operations, LSP), we recommend that you use zk directly.

## Platform support

Currently works on **Linux** and **macOS**. Windows support is planned – in the meantime, consider using [WSL](https://learn.microsoft.com/en-us/windows/wsl/).

## Install

**Option 1: via [Nix](https://nixos.org/)** (recommended path – handles all dependencies)

Nix installs packages in isolated, immutable environments, avoiding conflicts with system dependencies and ensuring reproducibility. If you don't have Nix yet, install it with the [official installer](https://nixos.org/download/) or [Determinate Systems installer](https://determinate.systems/nix-installer/) (which enables [flakes](https://wiki.nixos.org/wiki/Flakes) by default). Then, install `nn` by running:

```bash
nix profile install github:jqueiroz/notenav
```

This command uses Nix's imperative interface (`nix profile`). If you prefer a fully declarative setup, see the NixOS or Home Manager instructions in [docs/install.md](docs/install.md).

**Option 2: One-liner**

```bash
curl -fsSL https://raw.githubusercontent.com/jqueiroz/notenav/main/curl/install.sh | sh
```

Requires bash 4+, [zk](https://github.com/zk-org/zk), [fzf](https://github.com/junegunn/fzf) 0.44+, [yq](https://github.com/mikefarah/yq) (yq-go, **not** yq-python), and [jq](https://github.com/jqlang/jq) to be on the PATH.
See [docs/install.md](docs/install.md) for more details.

**Option 3: Manual installation**

```bash
git clone https://github.com/jqueiroz/notenav.git ~/.local/share/notenav
ln -s ~/.local/share/notenav/bin/nn ~/.local/bin/nn
```

Same dependencies as the one-liner. See [docs/install.md](docs/install.md) for details.

## Getting started: the Compass workflow

Out of the box, `nn` uses **Compass** – a simple workflow built around three note types, four statuses, and four priority levels. This is enough structure to manage a project without getting in the way.

**Note types** – every note is one of:
- **task** – concrete, actionable unit of work
- **idea** – captures an early insight; enriched over time, may evolve into one or more tasks  <!-- alt: "needs exploration" -->
- **reference** – living documentation, continually updated as understanding grows

**Status** – every note moves through a lifecycle: **new** → **active** → **done**. Notes can also be **blocked** (stuck on something external) or **removed** (soft-deleted, i.e. the note stays on disk but it's hidden from normal views).

**Priority** – four levels (P1–P4).

**Inbox and triage** – borrowing from [Getting Things Done](https://en.wikipedia.org/wiki/Getting_Things_Done): capture first, organize later. When you create a note, don't worry about priority – just get it down. Notes without a priority automatically appear in the **inbox** query preset. During triage, review the inbox and assign priorities; this moves notes into your working views, where they're visible alongside everything else you've already prioritized. The inbox empties as you triage, giving you a clear signal of what still needs attention.

**Built-in query presets** – Compass ships with `inbox`, `p1-tasks`, `p1-ideas`, `p1-references`, and `all-active`. You can add your own presets in project or user config.

**Frontmatter** – notes are plain markdown with YAML frontmatter:

```yaml
---
title: "Refactor config loader"
type: task
status: active
priority: 2
tags: [config, cleanup]
created: 2026-03-18
---
```

If Compass doesn't fit your requirements, explore our other built-in workflows or define your own – see [Configuration](#configuration) below.

## Main keybindings

| Key | Action |
|-----|--------|
| `enter` | Open note in your preferred editor |
| `n` | Create new note |
| `a` / `A` | Advance / reverse status |
| `+` / `-` (or `<` / `>`) | Adjust priority up / down |
| `e` | Filter by [**e**]ntity type |
| `s` | Filter by [**s**]tatus |
| `p` | Filter by [**p**]riority |
| `t` | Filter by [**t**]ags |
| `m` | Search note body |
| `h` / `l` | Previous / next query preset |
| `f` | Fuzzy-pick query preset |
| `o` / `g` / `z` | Sort / group / toggle archive |
| `b` | Bulk edit |
| `q` | Quit |

These keybindings apply to all workflows, including custom ones. With the default configuration, every keybinding is displayed on-screen.

Editor defaults to `$EDITOR`, with reasonable fallbacks: nvim → vim → vi → nano → emacs[^1].

## Configuration

All configuration is TOML. Project and user configuration are orthogonal – neither inherits from or overrides the other:

- **Project configuration** (`.nn/workflow.toml`) – defines the project's workflow, typically extending a built-in one with project-specific query presets and overrides.
- **User preferences** (`$XDG_CONFIG_HOME/notenav/config.toml`, defaulting to `~/.config/notenav/config.toml`) – personal preferences for visualization, editor, sorting, and grouping. Also defines a default/fallback workflow (used only when `nn` is invoked in directories lacking project configuration).

Ships with four built-in workflows. Use a preset as-is, extend it with overrides, or write your own – the config files are good starting points and serve as reference for the format.

| Workflow | Overview | Config |
|----------|----------|--------|
| **compass** (default) | [docs/workflows/compass.md](docs/workflows/compass.md) | [config/workflows/compass.toml](config/workflows/compass.toml) |
| **ado** | [docs/workflows/ado.md](docs/workflows/ado.md) | [config/workflows/ado.toml](config/workflows/ado.toml) |
| **gtd** | [docs/workflows/gtd.md](docs/workflows/gtd.md) | [config/workflows/gtd.toml](config/workflows/gtd.toml) |
| **zettelkasten** | [docs/workflows/zettelkasten.md](docs/workflows/zettelkasten.md) | [config/workflows/zettelkasten.toml](config/workflows/zettelkasten.toml) |

See [docs/configuration.md](docs/configuration.md) for the full config and workflow reference.

## CLI reference

```bash
nn                              # interactive TUI
nn type=task status=active      # ad-hoc query
nn backlog                      # query preset (from config)
nn type=task -i                 # interactive (fzf) ad-hoc query
nn --version                    # version info
```

## License

MIT

[^1]: All in good spirit – emacs users, you know you can set `$EDITOR`.
