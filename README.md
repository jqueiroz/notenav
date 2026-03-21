# notenav

TUI for navigating markdown notes with frontmatter annotations. Filter by type, status, priority, and tags; search body content; save and recall queries; perform inline actions — all without leaving the terminal.

For non-interactive usage (scripting, batch operations, LSP), use [zk](https://github.com/zk-org/zk) directly — notenav builds on top of zk.

Schemas are fully customizable — define your own entity types, statuses, priorities, colors, and lifecycle transitions via TOML config. Ships with built-in presets for common workflows (GTD, Azure DevOps, Zettelkasten) or write your own.

Built on [fzf](https://github.com/junegunn/fzf), with [zk](https://github.com/zk-org/zk) for indexing.

> **Early development** — extracted from a personal zshrc. Not yet packaged for general use.

## Install

**Option 1: via [Nix](https://nixos.org/)** (recommended — transparently handles all dependencies)

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

Schemas are fully customizable via TOML files — define entity types, statuses, priorities, colors, and lifecycle transitions. Config layers (base, user, project) merge so you only specify what you want to change.

Ships with built-in schemas: **compass** (default), **ado**, **gtd**, **zettelkasten**. See [docs/configuration.md](docs/configuration.md) for the full config and schema reference.

## License

MIT
