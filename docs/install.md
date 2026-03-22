# Installation

[Back to README](../README.md)

## Requirements

- **bash 4+** – notenav is a bash script (your default shell can be anything; bash 4+ just needs to be installed). macOS ships with bash 3.2; use the Nix install path or `brew install bash`
- **[zk](https://github.com/zk-org/zk)** – used for indexing markdown files. Available via [Homebrew](https://formulae.brew.sh/formula/zk), [AUR](https://aur.archlinux.org/packages/zk), or [GitHub releases](https://github.com/zk-org/zk/releases) (not in apt/dnf)
- **[fzf](https://github.com/junegunn/fzf)** 0.44+ – TUI framework
- **[yq](https://github.com/mikefarah/yq)** (yq-go) – TOML→JSON conversion for config/workflow loading. **Must be [Mike Farah's yq](https://github.com/mikefarah/yq)** (written in Go), not the [Python yq wrapper](https://github.com/kislyuk/yq) — they are different tools that share the same name. Install via `brew install yq`, `go install github.com/mikefarah/yq/v4@latest`, or your package manager. Verify with `yq --version` (should show `v4.x.x`)
- **[jq](https://github.com/jqlang/jq)** – JSON merging/querying for config system
- **awk**, **sort**, **sed**, **git** – standard unix tools (gawk recommended)

## Optional dependencies

Not required, but progressively enhance the experience when installed.

- **[bat](https://github.com/sharkdp/bat)** – syntax-highlighted preview (called `batcat` on Debian/Ubuntu)
- **curl** – required for [remote workflows](configuration.md#extending-a-remote-workflow) (`nn init https://...`). Pre-installed on most systems

## Install

### Option 1: Nix (recommended – transparently handles all dependencies)

[Nix](https://nixos.org/) is a declarative package manager for Linux and macOS. Using Nix, you can install notenav and all of its dependencies in isolation from your system packages. If you don't have Nix yet, install it with the [official installer](https://nixos.org/download/) or [Determinate Systems installer](https://determinate.systems/nix-installer/) (which enables flakes by default).

**`nix profile` (imperative):**

```bash
nix profile install github:jqueiroz/notenav
```

**NixOS (`configuration.nix`):**

```nix
# /etc/nixos/configuration.nix
{
  inputs.notenav.url = "github:jqueiroz/notenav";

  # then in your config:
  environment.systemPackages = [ inputs.notenav.packages.${pkgs.system}.default ];
}
```

**Home Manager:**

```nix
# home.nix or flake-based home-manager config
{
  inputs.notenav.url = "github:jqueiroz/notenav";

  # then in your home config:
  home.packages = [ inputs.notenav.packages.${pkgs.system}.default ];
}
```

**Try without installing:**

```bash
nix run github:jqueiroz/notenav
```

### Option 2: One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/jqueiroz/notenav/main/curl/install.sh | sh
```

This clones to `~/.local/share/notenav` and symlinks `nn` into `~/.local/bin`. Run it again to update (essentially `git pull --ff-only`). Set `NOTENAV_DIR` or `NOTENAV_BIN` to customize paths.

### Option 3: Manual installation

```bash
git clone https://github.com/jqueiroz/notenav.git ~/.local/share/notenav
ln -s ~/.local/share/notenav/bin/nn ~/.local/bin/nn
```

Make sure `~/.local/bin` is on your `PATH`.

## Next steps

Verify the installation:

```bash
nn --version
nn doctor        # check dependencies, config, and notebook
```

notenav works out of the box with the default [Compass](workflows/compass.md) workflow. To customize, use `nn init` to scaffold config files:

```bash
nn init                    # create .nn/workflow.toml (extends compass)
nn init ado                # create .nn/workflow.toml (extends ado)
nn init --user             # create ~/.config/notenav/config.toml
nn init --user gtd         # create user config with gtd as default workflow
```

Or create them manually from the annotated examples: [`samples/user-config.toml`](../samples/user-config.toml) and [`samples/workflows/`](../samples/workflows/).

See [docs/configuration.md](configuration.md) for the full reference.
