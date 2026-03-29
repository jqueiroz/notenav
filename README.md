# notenav (`nn`)

Your notes deserve a proper interface. Not a browser tab, not an Electron app – a fast, keyboard-driven TUI that feels like editing code[^1]. Finally, task and note management that's seamless and, dare we say, _fun_!

Filter by type, status, priority, and tags; search by filename or body contents; save and recall queries; perform inline actions; select a note and edit it in your favorite editor – all without leaving the terminal. Friendly learning curve: with the default configuration, every keybinding is displayed on-screen.

Workflows are fully customizable: define your own note types, statuses, priorities, colors, and lifecycle transitions via TOML config. Ships with built-in presets for common workflows.

Works with any markdown files that use [YAML frontmatter](https://jekyllrb.com/docs/front-matter/) – compatible with Obsidian, Dendron, Jekyll, and similar tools. For non-interactive usage (scripting, batch operations, LSP), we recommend that you use zk directly.

## Try it out

No install needed – SSH into a live demo with a sample notebook (27 notes tracking the crew operations of the starship *Heart of Gold*):

```bash
ssh notenav.sh
```

Cycle filters (`t`, `s`, `p`), try query presets (`tab`/`shift-tab`), search by typing, and advance statuses with `a` – everything works out of the box.

Alternatively, after [installing](#install) `nn`, try it locally with the [demo notebook](https://github.com/jqueiroz/notenav-demo):

```bash
git clone https://github.com/jqueiroz/notenav-demo
cd notenav-demo
nn
```

## What you need

`nn` is a single bash script[^2] that runs on **Linux** and **macOS** (Windows via [WSL](https://learn.microsoft.com/en-us/windows/wsl/)). The only required dependencies are:

- **[fzf](https://github.com/junegunn/fzf)** 0.44+ – the TUI engine and beloved fuzzy finder
- **[yq](https://github.com/mikefarah/yq)**[^3], **[jq](https://github.com/jqlang/jq)** – config parsing

Everything else is optional and progressively enhances the experience:

- **[zk](https://github.com/zk-org/zk)** – faster indexed listing and link graph in preview
- **[bat](https://github.com/sharkdp/bat)** – syntax-highlighted markdown preview
- [and a few more](docs/install.md#optional-dependencies)

The Nix install path handles all of this automatically.

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

Requires bash 4+, [fzf](https://github.com/junegunn/fzf) 0.44+, [yq](https://github.com/mikefarah/yq)[^3], and [jq](https://github.com/jqlang/jq) to be installed and available on the PATH. [zk](https://github.com/zk-org/zk) is optional but recommended for faster indexing and link graph.
See [docs/install.md](docs/install.md) for more details.

**Option 3: Manual installation**

```bash
git clone https://github.com/jqueiroz/notenav.git ~/.local/share/notenav
ln -s ~/.local/share/notenav/bin/nn ~/.local/bin/nn
```

Same dependencies as the one-liner. See [docs/install.md](docs/install.md) for details.

## Getting started: the Zenith workflow

Out of the box, `nn` uses **Zenith** – a simple workflow built around three note types, four statuses, and four priority levels. This is enough structure to manage a project without getting in the way.

**Note types:** every note is one of:
- **task:** concrete, actionable unit of work
- **idea:** captures an early insight; enriched over time, may evolve into one or more tasks  <!-- alt: "needs exploration" -->
- **reference:** living documentation, continually updated as understanding grows

**Status:** every note moves through a lifecycle: **new** → **active** → **done**. Notes can also be **blocked** (stuck on something external) or **removed** (soft-deleted, i.e. the note stays on disk but it's hidden from normal views).

**Priority:** four levels (P1–P4).

**Inbox and triage:** borrowing from [Getting Things Done](https://en.wikipedia.org/wiki/Getting_Things_Done): capture first, organize later. When you create a note, don't worry about priority – just get it down. Notes without a priority automatically appear in the **inbox** query preset. During triage, review the inbox and assign priorities; this moves notes into your working views, where they're visible alongside everything else you've already prioritized. The inbox empties as you triage, giving you a clear signal of what still needs attention.

**Built-in query presets:** Zenith ships with `inbox`, `p1-tasks`, `p1-ideas`, `p1-references`, and `all-active`. You can add your own presets in project or user config.

**Frontmatter:** notes are plain markdown with YAML frontmatter:

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

If Zenith doesn't fit your requirements, explore our other built-in workflows or define your own – see [Configuration](#configuration) below.

## Main keybindings

| Key | Action |
|-----|--------|
| `enter` | Open note in your preferred editor |
| `e` | [**e**]dit note |
| `n` | Create [**n**]ew note |
| `a` / `A` | Advance / reverse status |
| `+` / `-` (or `<` / `>`) | Adjust priority up / down |
| `t` | Filter by [**t**]ype (`T` to clear) |
| `s` | Filter by [**s**]tatus (`S` to clear) |
| `p` | Filter by [**p**]riority (`P` to clear) |
| `0` or `R` | [**R**]eset all filters, pins, marks, and display settings |
| `tab` / `shift-tab` | Next / previous query preset |
| `[` and `]` | Next / previous query preset (same as above) |
| `g` | [**g**]o-to query preset |
| `1`–`9` | Jump to query preset by number |
| `c` then `s`/`p`/`t` | [**c**]hange status, priority, or type |
| `f` then `t`/`c`/`n` | [**f**]ilter-by tags, contents, or name |
| `m` then `m`/`a`/`d`/`D`/`f` | [**m**]ark: toggle, add selected, unmark selected, clear all, filter to marked |
| `z` then `o`/`r`/`g`/`h`/`w` | Display: order-by, reverse sort, group-by, toggle archived, toggle wrap |
| `esc` | Exit prefix mode, or clear query |
| `space` | Toggle multi-select |
| `r` | [**r**]efresh note list |
| `b` | [**b**]ulk edit (via your preferred editor) |
| `x` | Clear all pinned ghost rows |
| `X` | Restore pins from last clear (one-shot undo) |
| `j` / `k` | Move down / up |
| `J` / `K` | Scroll preview down / up |
| `ctrl-j` / `ctrl-k` | Page down / up |
| `q` | Quit |

These keybindings apply to all workflows, including custom ones. With the default configuration, every keybinding is displayed on-screen.

When an action like `a` (advance status) or `+` (bump priority) causes a note to no longer match your active filters, the note stays visible in its natural sort position as a **ghost row** with a yellow `pinned` badge. This means you never lose sight of what you just changed and the cursor never jumps. Pins accumulate across multiple actions and survive filter changes. Press `x` to clear all pins, or `R` to reset everything (i.e. filters, pins, sort, grouping, and display settings).

Editor defaults to `$EDITOR`, with reasonable fallbacks: nvim → vim → vi → nano → emacs[^4].

## Configuration

All configuration is TOML. Project and user configuration are entirely orthogonal – neither inherits from or overrides the other:

- **Project configuration** (`.nn/workflow.toml`): defines the project's workflow, typically extending a built-in one with project-specific query presets and overrides.
- **User preferences** (`$XDG_CONFIG_HOME/notenav/config.toml`, defaulting to `~/.config/notenav/config.toml`): personal preferences for visualization, editor, sorting, and grouping. Also defines a default/fallback workflow (used only when `nn` is invoked in directories lacking project configuration).

The `.nn/` directory is found by walking up from your current directory (like `.git/`), so `nn` works from any subdirectory. Notes are discovered recursively: at the notebook root you see everything, from a subdirectory you see only that subtree.

Ships with five built-in workflows. Use a preset as-is, extend it with overrides, or write your own. The built-in config files are self-documenting and the best way to learn the format.

| Workflow | Overview | Config |
|----------|----------|--------|
| **zenith** (default) | [docs/workflows/zenith.md](docs/workflows/zenith.md) | [config/workflows/zenith.toml](config/workflows/zenith.toml) |
| **cubic** | [docs/workflows/cubic.md](docs/workflows/cubic.md) | [config/workflows/cubic.toml](config/workflows/cubic.toml) |
| **ado** | [docs/workflows/ado.md](docs/workflows/ado.md) | [config/workflows/ado.toml](config/workflows/ado.toml) |
| **gtd** | [docs/workflows/gtd.md](docs/workflows/gtd.md) | [config/workflows/gtd.toml](config/workflows/gtd.toml) |
| **zettelkasten** | [docs/workflows/zettelkasten.md](docs/workflows/zettelkasten.md) | [config/workflows/zettelkasten.toml](config/workflows/zettelkasten.toml) |

See [docs/configuration.md](docs/configuration.md) for the full config and workflow reference, or [docs/faq.md](docs/faq.md) for common questions.

## CLI reference

### `nn init`

Scaffolds a project workflow file at `.nn/workflow.toml`. Accepts an optional workflow name: one of the built-in workflows (`zenith`, `cubic`, `ado`, `gtd`, `zettelkasten`) or an HTTPS URL for a remote workflow. Defaults to `zenith` when no workflow is specified.

```bash
nn init                 # .nn/workflow.toml extending zenith
nn init gtd             # .nn/workflow.toml extending gtd
nn init https://...     # fetch remote workflow, cache it, extend it
```

If the config file already exists, `nn init` refuses to overwrite it – edit the file directly or remove it first. As a special case, if the existing config already references the same remote URL, `nn init <url>` (or `nn init --user <url>`) refreshes the local cache without touching the config.

### `nn init --user`

Creates a user preferences file at `~/.config/notenav/config.toml` (respects `$XDG_CONFIG_HOME`), pre-populated from the annotated sample. An optional workflow argument sets the `default_workflow` key:

```bash
nn init --user          # create user config (default workflow: zenith)
nn init --user gtd      # create user config with gtd as the default workflow
```

User config defines personal preferences – editor, prompts, sorting, grouping, and a fallback workflow for directories without `.nn/workflow.toml`. See [docs/configuration.md](docs/configuration.md) for the full preferences reference.

### `nn doctor`

Validates your entire setup in one pass. Run it whenever something seems off: it checks dependencies, config files, workflow integrity, and your notebook.

```bash
nn doctor
```

### Other commands

```bash
nn --version                    # version info
nn --help                       # show usage
```

See [docs/reference.md](docs/reference.md) for the full CLI reference and [docs/tui.md](docs/tui.md) for TUI keybindings and details.

## License

MIT

[^1]: Well, not _all_ code editing. We're talking about the kind that sparks joy.
[^2]: The feeling of writing a faceted note navigator purely in Bash is almost, but not quite, entirely unlike joy. As you may have noticed from the messy commit history, Claude mostly deprived me of this feeling, and for that I am grateful.

    *Rest assured: no LLMs were harmed in the making of notenav.*
[^3]: This means Mike Farah's Go implementation – not the Python wrapper (kislyuk/yq). On Fedora, Arch, and Homebrew `yq` is the right one. On Ubuntu/Debian, `apt install yq` gives you the wrong one – use `snap install yq` or grab the binary from [GitHub releases](https://github.com/mikefarah/yq/releases).
[^4]: All in good spirit – emacs users, you know you can set `$EDITOR`.
