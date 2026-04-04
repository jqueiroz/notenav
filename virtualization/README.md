# Virtualization

Scripts for spinning up VMs to test notenav on non-native platforms.

## Common prerequisites

- QEMU (`nix-shell` in this directory provides it, or `apt install qemu-system-x86`)
- KVM recommended – `launch.sh` auto-detects `/dev/kvm` and enables it via sudo. Without KVM, boot is very slow (software emulation).
- On WSL2, use `nix-shell --command zsh` (not plain `nix-shell`) to avoid bash/zsh shell config conflicts

## FreeBSD

### Quick start

```bash
cd virtualization

# Enter a Nix shell with QEMU available (skip if QEMU is already installed)
nix-shell --command zsh

# Boot the FreeBSD VM (downloads the image on first run, ~600 MB)
freebsd/launch.sh
```

The VM boots to a serial console in your terminal. On first boot you need to set up the root account and enable SSH from the serial console:

```sh
# Set root password (default: freebsd)
passwd root

# Enable root SSH login with password
sed 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config > /tmp/sshd_config && mv /tmp/sshd_config /etc/ssh/sshd_config
sed 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config > /tmp/sshd_config && mv /tmp/sshd_config /etc/ssh/sshd_config
service sshd restart
```

### SSH workflow

Once SSH is enabled, it's easier to work from a second terminal:

```bash
# Provision the VM (installs gawk, fzf, jq, yq, etc.)
(cd "$(git rev-parse --show-toplevel)" && ssh -p 2222 root@localhost 'sh -s' < virtualization/freebsd/guest/provision.sh)

# Sync notenav into the VM (safe to run from anywhere in the repo)
virtualization/freebsd/sync.sh

# SSH in and test (provision.sh adds nn to PATH via .profile)
ssh -p 2222 root@localhost
nn doctor
nn --version
```

## Ubuntu

### Quick start

```bash
cd virtualization

# Enter a Nix shell with QEMU available (skip if QEMU is already installed)
nix-shell --command zsh

# Boot the Ubuntu VM (downloads the image on first run, ~600 MB)
ubuntu/launch.sh
```

Cloud-init configures the VM on first boot (takes ~30 seconds). Login: `ubuntu` / `ubuntu`. SSH is enabled by default.

### SSH workflow

```bash
# Provision the VM (installs gawk, fzf, jq, yq, etc.)
(cd "$(git rev-parse --show-toplevel)" && ssh -p 2223 ubuntu@localhost 'sh -s' < virtualization/ubuntu/guest/provision.sh)

# Sync notenav into the VM (safe to run from anywhere in the repo)
virtualization/ubuntu/sync.sh

# SSH in and test (provision.sh adds nn to PATH via .profile)
ssh -p 2223 ubuntu@localhost
nn doctor
nn --version
```

## Fedora

### Quick start

```bash
cd virtualization

# Enter a Nix shell with QEMU available (skip if QEMU is already installed)
nix-shell --command zsh

# Boot the Fedora VM (downloads the image on first run, ~450 MB)
fedora/launch.sh
```

Cloud-init configures the VM on first boot (takes ~30 seconds). Login: `fedora` / `fedora`. SSH is enabled by default.

### SSH workflow

```bash
# Provision the VM (installs gawk, fzf, jq, yq, etc.)
(cd "$(git rev-parse --show-toplevel)" && ssh -p 2224 fedora@localhost 'sh -s' < virtualization/fedora/guest/provision.sh)

# Sync notenav into the VM (safe to run from anywhere in the repo)
virtualization/fedora/sync.sh

# SSH in and test (provision.sh adds nn to PATH via .bash_profile)
ssh -p 2224 fedora@localhost
nn doctor
nn --version
```

## OpenBSD

### Quick start

```bash
cd virtualization

# Enter a Nix shell with QEMU available (skip if QEMU is already installed)
nix-shell --command zsh

# Boot the OpenBSD installer (downloads ISO on first run, ~600 MB)
openbsd/launch.sh
```

Unlike the other VMs, OpenBSD does not support cloud-init. The first boot runs the interactive installer (~5 minutes). At the `boot>` prompt, type `stty com0` then `boot` to redirect output to the serial console. Accept most defaults, set the root password to `openbsd`, and enable sshd. Before rebooting, run `echo 'stty com0' > /etc/boot.conf` to persist the serial console setting.

Subsequent runs boot directly from the installed disk:

```bash
openbsd/launch.sh
```

To reinstall from scratch:

```bash
openbsd/launch.sh --install
```

### SSH workflow

```bash
# Provision the VM (installs gawk, fzf, jq, yq, etc.)
(cd "$(git rev-parse --show-toplevel)" && ssh -p 2225 root@localhost 'sh -s' < virtualization/openbsd/guest/provision.sh)

# Sync notenav into the VM (safe to run from anywhere in the repo)
virtualization/openbsd/sync.sh

# SSH in and test (provision.sh adds nn to PATH via .profile)
ssh -p 2225 root@localhost
nn doctor
nn --version
```

## Configuration

Each `launch.sh` respects these environment variables:

| Variable   | Default          | Description              |
|------------|------------------|--------------------------|
| `RAM`      | `2G`             | VM memory                |
| `CPUS`     | `2`              | Number of virtual CPUs   |
| `SSH_PORT` | `2222` / `2223` / `2224` / `2225` | Host port forwarded to VM SSH |

## Tips

- Quit QEMU: `Ctrl-a x`
- Re-download the image: `<distro>/launch.sh --fresh`
- Images are stored in `<distro>/images/` (gitignored)
- Each distro uses a different SSH port (FreeBSD 2222, Ubuntu 2223, Fedora 2224, OpenBSD 2225) so all VMs can run simultaneously
