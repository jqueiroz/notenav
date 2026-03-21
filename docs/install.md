# Installation

[Back to README](../README.md)

## Requirements

- **bash 4+** -- notenav is a bash script (your default shell can be anything; bash 4+ just needs to be installed). macOS ships bash 3.2; use the Nix install path or `brew install bash`
- **[zk](https://github.com/zk-org/zk)** -- used for indexing markdown files. Available via [Homebrew](https://formulae.brew.sh/formula/zk), [AUR](https://aur.archlinux.org/packages/zk), or [GitHub releases](https://github.com/zk-org/zk/releases) (not in apt/dnf)
- **[fzf](https://github.com/junegunn/fzf)** 0.44+ -- TUI framework
- **awk**, **sort**, **sed**, **git** -- standard unix tools (gawk recommended)

## Optional dependencies

Not required, but progressively enhance the experience when installed.

- **[bat](https://github.com/sharkdp/bat)** -- syntax-highlighted preview (called `batcat` on Debian/Ubuntu)

## Install

### Nix (recommended -- transparently handles all dependencies)

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

### Git clone

```bash
git clone https://github.com/jqueiroz/notenav.git ~/.local/share/notenav
ln -s ~/.local/share/notenav/bin/nn ~/.local/bin/nn
```

Make sure `~/.local/bin` is on your `PATH`.

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/jqueiroz/notenav/main/install.sh | sh
```

This clones to `~/.local/share/notenav` and symlinks `nn` into `~/.local/bin`. Run it again to update. Set `NOTENAV_DIR` or `NOTENAV_BIN` to customize paths.
