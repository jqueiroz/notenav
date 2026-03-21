# notenav

Your notes deserve a proper interface. Not a browser tab, not an Electron app – a fast, keyboard-driven TUI that feels like editing code. Finally, task and note management that's seamless and, dare we say, _fun_!

Filter by type, status, priority, and tags; search by filename or body contents; save and recall queries; perform inline actions – all via vim-like keybindings, without leaving the terminal.

Schemas are fully customizable – define your own entity types, statuses, priorities, colors, and lifecycle transitions via TOML config. Ships with built-in presets for common workflows.

Works with any markdown files that use [YAML frontmatter](https://jekyllrb.com/docs/front-matter/) – fully compatible with Obsidian, Dendron, Jekyll, and similar tools. Built on [fzf](https://github.com/junegunn/fzf), with [zk](https://github.com/zk-org/zk) for indexing. For non-interactive usage (scripting, batch operations, LSP), we recommend that you use zk directly.

## Install

**Option 1: via [Nix](https://nixos.org/)** (recommended path – transparently handles all dependencies)

```bash
nix profile install github:jqueiroz/notenav
```

[Nix](https://nixos.org/) is a declarative package manager for Linux and macOS. Using Nix, you can install `nn` and all of its dependencies in isolation from your system packages. See [docs/install.md](docs/install.md) for NixOS and Home Manager options.

**Option 2: Manual installation**

```bash
git clone https://github.com/jqueiroz/notenav.git ~/.local/share/notenav
ln -s ~/.local/share/notenav/bin/nn ~/.local/bin/nn
```

Requires bash 4+, [zk](https://github.com/zk-org/zk), [fzf](https://github.com/junegunn/fzf) 0.44+, [yq](https://github.com/mikefarah/yq) (yq-go, **not** yq-python), and [jq](https://github.com/jqlang/jq). See [docs/install.md](docs/install.md) for all options (NixOS, Home Manager, one-liner) and full dependency details.

## Usage

```bash
nn                              # faceted browser
nn type=task status=active      # ad-hoc query
nn backlog                      # saved query (from config)
nn type=task -i                 # interactive (fzf) ad-hoc query
nn --version                    # version info
```

## Configuration

All configuration is TOML. Project and user configuration are orthogonal – neither inherits from or overrides the other:

- **Project configuration** (`.nn/`) – defines the schema (`.nn/schema.toml`, built-in or custom) and project-specific settings including saved queries (`.nn/config.toml`).
- **User preferences** (`$XDG_CONFIG_HOME/notenav/config.toml`, defaulting to `~/.config/notenav/config.toml`) – personal preferences for visualization, editor, sorting, and grouping. Also defines a default/fallback schema (used only when `nn` is invoked in directories without project configuration).

Schemas define your workflow vocabulary: entity types, statuses, priorities, colors, and lifecycle transitions. Ships with built-in schemas: **compass** (default – our favorite), **ado**, **gtd**, **zettelkasten**. Use a built-in preset or write your own – the built-in schema files ([compass](config/schemas/compass.toml), [gtd](config/schemas/gtd.toml), [zettelkasten](config/schemas/zettelkasten.toml)) are good starting points and serve as reference for the format. See [docs/configuration.md](docs/configuration.md) for the full config and schema reference.

## Platform support

Currently works on **Linux** and **macOS**. Windows support is planned – in the meantime, consider using [WSL](https://learn.microsoft.com/en-us/windows/wsl/).

## License

MIT
