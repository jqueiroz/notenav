# notenav (`nn`)

Your notes deserve a proper interface. Not a browser tab, not an Electron app – a fast, keyboard-driven TUI that feels like editing code. Finally, task and note management that's seamless and, dare we say, _fun_!

Filter by type, status, priority, and tags; search by filename or body contents; save and recall queries; perform inline actions – all without leaving the terminal. Friendly learning curve: with the default configuration, every keybinding is displayed on-screen.

Workflows are fully customizable – define your own entity types, statuses, priorities, colors, and lifecycle transitions via TOML config. Ships with built-in presets for common workflows.

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

**Option 2: Manual installation**

```bash
git clone https://github.com/jqueiroz/notenav.git ~/.local/share/notenav
ln -s ~/.local/share/notenav/bin/nn ~/.local/bin/nn
```

Requires bash 4+, [zk](https://github.com/zk-org/zk), [fzf](https://github.com/junegunn/fzf) 0.44+, [yq](https://github.com/mikefarah/yq) (yq-go, **not** yq-python), and [jq](https://github.com/jqlang/jq). See [docs/install.md](docs/install.md) for more details.

**Option 3: One-liner**

```bash
curl -fsSL https://raw.githubusercontent.com/jqueiroz/notenav/main/curl/install.sh | sh
```

Same dependencies as manual installation. See [docs/install.md](docs/install.md) for details.

## Getting started: the Compass workflow

Out of the box, `nn` uses **Compass** — a simple workflow built around three note types: **tasks** (actionable work), **ideas** (things to explore that may become tasks), and **references** (living documentation you revisit and update over time). Every note also carries a **status** (new, active, blocked, done) and an optional **priority** (1–4).

This is enough structure to manage a project without getting in the way. Triage new notes by promoting ideas into tasks, advance status with a single keypress, and use priority to keep focus on what matters. Notes that are done or removed are archived out of sight but still searchable.

Compass ships with built-in query presets — `p1-tasks`, `p1-ideas`, `p1-references`, `inbox` — so you can jump to useful views immediately. You can add your own presets in project or user config.

If Compass doesn't fit, switch to one of the other built-in workflows (**ado**, **gtd**, **zettelkasten**) or define your own. See [docs/configuration.md](docs/configuration.md) for the full workflow reference, and the [Compass workflow file](config/workflows/compass.toml) for the exact definitions.

## Usage

```bash
nn                              # faceted browser
nn type=task status=active      # ad-hoc query
nn backlog                      # query preset (from config)
nn type=task -i                 # interactive (fzf) ad-hoc query
nn --version                    # version info
```

## Configuration

All configuration is TOML. Project and user configuration are orthogonal – neither inherits from or overrides the other:

- **Project configuration** (`.nn/workflow.toml`) – defines the project's workflow, typically extending a built-in one with project-specific query presets and overrides.
- **User preferences** (`$XDG_CONFIG_HOME/notenav/config.toml`, defaulting to `~/.config/notenav/config.toml`) – personal preferences for visualization, editor, sorting, and grouping. Also defines a default/fallback workflow (used only when `nn` is invoked in directories lacking project configuration).

Ships with built-in workflows: **compass** (default – our favorite), **ado**, **gtd**, **zettelkasten**. Use a built-in preset or write your own – the built-in workflow files ([compass](config/workflows/compass.toml), [ado](config/workflows/ado.toml), [gtd](config/workflows/gtd.toml), [zettelkasten](config/workflows/zettelkasten.toml)) are good starting points and serve as reference for the format. See [docs/configuration.md](docs/configuration.md) for the full config and workflow reference.

## License

MIT
