# notenav

TUI for navigating markdown notes with frontmatter annotations. Filter by type, status, priority, and tags; search body content; save and recall queries; perform inline actions — all via vim-like keybindings, without leaving the terminal.

Schemas are fully customizable — define your own entity types, statuses, priorities, colors, and lifecycle transitions via TOML config. Ships with built-in presets for common workflows.

Works with any markdown files that use [YAML frontmatter](https://jekyllrb.com/docs/front-matter/) — fully compatible with Obsidian, Dendron, Jekyll, and similar tools. Built on [fzf](https://github.com/junegunn/fzf), with [zk](https://github.com/zk-org/zk) for indexing. For non-interactive usage (scripting, batch operations, LSP), use zk directly.

## Install

**Option 1: via [Nix](https://nixos.org/)** (recommended path — transparently handles all dependencies)

```bash
nix profile install github:jqueiroz/notenav
```

[Nix](https://nixos.org/) is a declarative package manager for Linux and macOS. Using Nix, you can install notenav and all of its dependencies in isolation from your system packages. See [docs/install.md](docs/install.md) for NixOS and Home Manager options.

**Option 2: Manual installation**

```bash
git clone https://github.com/jqueiroz/notenav.git ~/.local/share/notenav
ln -s ~/.local/share/notenav/bin/nn ~/.local/bin/nn
```

Requires bash 4+, [zk](https://github.com/zk-org/zk), and [fzf](https://github.com/junegunn/fzf) 0.44+. See [docs/install.md](docs/install.md) for all options (NixOS, Home Manager, one-liner) and full dependency details.

## Usage

```bash
nn                              # faceted browser
nn type=task status=active      # ad-hoc query
nn backlog                      # saved query (from .nn/queries/)
nn type=task -i                 # interactive (fzf) ad-hoc query
nn --version                    # version info
```

## Configuration

Configuration has two layers: **schemas** define your workflow (entity types, statuses, priorities, lifecycle transitions), while **user/project config** controls preferences (default sort, editor, colors). Schemas are standalone TOML files — use a built-in preset or write your own from scratch. Preferences overlay via user and project configs so you only specify what you want to change.

Ships with built-in schemas: [**compass**](docs/schemas/compass.md) (default — our favorite), [**ado**](docs/schemas/ado.md), [**gtd**](docs/schemas/gtd.md), [**zettelkasten**](docs/schemas/zettelkasten.md). See [docs/configuration.md](docs/configuration.md) for the full config and schema reference.

## License

MIT
