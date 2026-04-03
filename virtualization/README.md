# Virtualization

Scripts for spinning up VMs to test notenav on non-native platforms.

## FreeBSD

### Prerequisites

- QEMU (`nix-shell` in this directory provides it, or `apt install qemu-system-x86`)
- KVM recommended – `launch.sh` auto-detects `/dev/kvm`. Without it, boot is very slow (software emulation). Your user must be in the `kvm` group (`sudo usermod -aG kvm $USER`, then restart your shell/WSL).

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

# Enable root SSH login
sed 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config > /tmp/sshd_config && mv /tmp/sshd_config /etc/ssh/sshd_config
service sshd restart
```

### SSH workflow

Once SSH is enabled, it's easier to work from a second terminal:

```bash
# Run these from the repo root
cd "$(git rev-parse --show-toplevel)"

# Provision the VM (installs gawk, fzf, jq, yq, etc.)
ssh -p 2222 root@localhost 'sh -s' < virtualization/freebsd/provision.sh

# Copy notenav into the VM (only tracked files, skips VM images)
git archive HEAD | ssh -p 2222 root@localhost 'mkdir -p /root/notenav && tar xf - -C /root/notenav'

# SSH in
ssh -p 2222 root@localhost

# Inside the VM: add nn to PATH and test
export PATH="/root/notenav/bin:$PATH"
nn doctor
nn --version
```

### Configuration

`launch.sh` respects these environment variables:

| Variable   | Default | Description              |
|------------|---------|--------------------------|
| `RAM`      | `2G`    | VM memory                |
| `CPUS`     | `2`     | Number of virtual CPUs   |
| `SSH_PORT` | `2222`  | Host port forwarded to VM SSH |

### Tips

- Quit QEMU: `Ctrl-a x`
- Re-download the image: `freebsd/launch.sh --fresh`
- Images are stored in `freebsd/images/` (gitignored)
- On WSL2, use `nix-shell --command zsh` (not plain `nix-shell`) to avoid bash/zsh shell config conflicts
