# Virtualization

Scripts for spinning up VMs to test notenav on non-native platforms.

## Common prerequisites

- QEMU (`nix-shell` in this directory provides it, or `apt install qemu-system-x86`)
- KVM recommended – `launch.sh` auto-detects `/dev/kvm`. Without it, boot is very slow (software emulation). Your user must be in the `kvm` group (`sudo usermod -aG kvm $USER`, then restart your shell/WSL).
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
# Run these from the repo root
cd "$(git rev-parse --show-toplevel)"

# Provision the VM (installs gawk, fzf, jq, yq, etc.)
ssh -p 2222 root@localhost 'sh -s' < virtualization/freebsd/provision.sh

# Copy notenav into the VM (only tracked files, skips VM images)
git archive HEAD | ssh -p 2222 root@localhost 'mkdir -p /root/notenav && tar xf - -C /root/notenav'

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
# Run these from the repo root
cd "$(git rev-parse --show-toplevel)"

# Provision the VM (installs gawk, fzf, jq, yq, etc.)
ssh -p 2223 ubuntu@localhost 'sh -s' < virtualization/ubuntu/provision.sh

# Copy notenav into the VM (only tracked files, skips VM images)
git archive HEAD | ssh -p 2223 ubuntu@localhost 'mkdir -p ~/notenav && tar xf - -C ~/notenav'

# SSH in and test (provision.sh adds nn to PATH via .profile)
ssh -p 2223 ubuntu@localhost
nn doctor
nn --version
```

## Configuration

Each `launch.sh` respects these environment variables:

| Variable   | Default          | Description              |
|------------|------------------|--------------------------|
| `RAM`      | `2G`             | VM memory                |
| `CPUS`     | `2`              | Number of virtual CPUs   |
| `SSH_PORT` | `2222` / `2223`  | Host port forwarded to VM SSH |

## Tips

- Quit QEMU: `Ctrl-a x`
- Re-download the image: `<distro>/launch.sh --fresh`
- Images are stored in `<distro>/images/` (gitignored)
- FreeBSD and Ubuntu use different SSH ports (2222 and 2223) so both VMs can run simultaneously
