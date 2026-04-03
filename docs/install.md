# Installation

[Back to README](../README.md)

## Requirements

- **bash 4+:** notenav is a bash script (your default shell can be anything; bash 4+ just needs to be installed). macOS ships with bash 3.2; use the Nix install path or `brew install bash`. On FreeBSD, install via `pkg install bash`
- **[fzf](https://github.com/junegunn/fzf)** 0.45+: TUI framework
- **[yq](https://github.com/mikefarah/yq)** (yq-go): TOML→JSON conversion for config/workflow loading. **Must be [Mike Farah's yq](https://github.com/mikefarah/yq)** (written in Go), not the [Python yq wrapper](https://github.com/kislyuk/yq) – they are different tools that share the same name. Install via `brew install yq`, `go install github.com/mikefarah/yq/v4@latest`, or your package manager. Verify with `yq --version` (should show `v4.x.x`)
- **[jq](https://github.com/jqlang/jq):** JSON merging/querying for config system
- **awk**, **sort**, **sed**, **tput:** standard unix tools (gawk required – notenav uses `mktime()` and `strtonum()`). On FreeBSD, install via `pkg install gawk`

## Optional dependencies

Not required, but progressively enhance the experience when installed.

- **[zk](https://github.com/zk-org/zk):** faster indexed listing, body text search via `--match`, and link graph in preview pane. Available via [Homebrew](https://formulae.brew.sh/formula/zk), [AUR](https://aur.archlinux.org/packages/zk), or [GitHub releases](https://github.com/zk-org/zk/releases). Without zk, notenav uses its own frontmatter parser and `rg`/`grep` for search
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** (`rg`): faster content search (`?` key) when zk is not installed or configured. Without rg, notenav falls back to `grep`. Recommended for large notebooks
- **[bat](https://github.com/sharkdp/bat):** syntax-highlighted preview (default; called `batcat` on Debian/Ubuntu). Alternatives: [glow](https://github.com/charmbracelet/glow), [mdcat](https://codeberg.org/flausch/mdcat) – see [previewer configuration](configuration.md#previewer)
- **curl:** required for [remote workflows](configuration.md#remote-workflows) (`nn init https://...`). Pre-installed on most systems
- **inotifywait** (Linux), **fswatch** (macOS), or **fswatch** (FreeBSD): enables real-time auto-refresh when notes change on disk (`refresh.mode = "watch"`). Without any, auto-refresh silently falls back to manual (`r` key). Install via `inotify-tools` (apt/dnf), `fswatch` (Homebrew), or `pkg install fswatch` (FreeBSD)

## Install

### Option 1: Nix (recommended – transparently handles all dependencies)

[Nix](https://nixos.org/) is a declarative package manager for Linux and macOS. Using Nix, you can install notenav and all of its dependencies in isolation from your system packages. If you don't have Nix yet, install it with the [official installer](https://nixos.org/download/) or [Determinate Systems installer](https://determinate.systems/nix-installer/) (which enables flakes by default).

**`nix profile` (imperative):**

```bash
nix profile install github:jqueiroz/notenav/stable
```

**NixOS (`configuration.nix`):**

```nix
# /etc/nixos/configuration.nix
{
  inputs.notenav.url = "github:jqueiroz/notenav/stable";

  # then in your config:
  environment.systemPackages = [ inputs.notenav.packages.${pkgs.system}.default ];
}
```

**Home Manager:**

```nix
# home.nix or flake-based home-manager config
{
  inputs.notenav.url = "github:jqueiroz/notenav/stable";

  # then in your home config:
  home.packages = [ inputs.notenav.packages.${pkgs.system}.default ];
}
```

**Try without installing:**

```bash
nix run github:jqueiroz/notenav/stable
```

### Option 2: One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/jqueiroz/notenav/stable/curl/install.sh | sh
```

This clones to `~/.local/share/notenav` and symlinks `nn` into `~/.local/bin`. Run it again to update (essentially `git pull --ff-only`). Set `NOTENAV_DIR` or `NOTENAV_BIN` to customize paths.

### Option 3: Manual installation

```bash
git clone --branch stable https://github.com/jqueiroz/notenav.git ~/.local/share/notenav
ln -s ~/.local/share/notenav/bin/nn ~/.local/bin/nn
```

Make sure `~/.local/bin` is on your `PATH`.

## Next steps

Verify the installation:

```bash
nn --version
nn doctor        # check dependencies, config, and notebook
```

If you'd like to explore the TUI before setting up your own notebook, try the [demo notebook](https://github.com/jqueiroz/notenav-demo):

```bash
git clone https://github.com/jqueiroz/notenav-demo
cd notenav-demo
nn
```

notenav works out of the box with the default [Zenith](workflows/zenith.md) workflow. To customize, use `nn init` to scaffold config files:

```bash
nn init                    # create .nn/workflow.toml (extends zenith)
nn init ado                # create .nn/workflow.toml (extends ado)
nn init --user             # create ~/.config/notenav/config.toml
nn init --user gtd         # create user config with gtd as default workflow
```

Or start from the built-in workflows and annotated samples:

| File | Description |
|------|-------------|
| [config/workflows/zenith.toml](../config/workflows/zenith.toml) | Built-in Zenith workflow (default) |
| [config/workflows/cuboid.toml](../config/workflows/cuboid.toml) | Built-in Cuboid workflow |
| [config/workflows/ado.toml](../config/workflows/ado.toml) | Built-in ADO workflow |
| [config/workflows/gtd.toml](../config/workflows/gtd.toml) | Built-in GTD workflow |
| [config/workflows/zettelkasten.toml](../config/workflows/zettelkasten.toml) | Built-in Zettelkasten workflow |
| [samples/workflows/project-workflow.toml](../samples/workflows/project-workflow.toml) | Annotated project config template |
| [samples/user-config.toml](../samples/user-config.toml) | Annotated user preferences template |

See [docs/configuration.md](configuration.md) for the full reference.
