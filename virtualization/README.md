# Virtualization

Scripts for spinning up VMs to test notenav on non-native platforms.

## FreeBSD

### Prerequisites

- QEMU (`nix-shell` in this directory provides it, or `apt install qemu-system-x86`)

### Quick start

```bash
cd virtualization

# Enter a Nix shell with QEMU available (skip if QEMU is already installed)
nix-shell

# Boot the FreeBSD VM (downloads the image on first run, ~350 MB)
freebsd/launch.sh

# --- inside the VM (log in as root, no password on first boot) ---
# Fetch the provisioning script and run it
fetch http://10.0.2.2:8080/provision.sh  # if you serve it, or:
# just paste/type it, or use SSH from the host (see below)
sh provision.sh
```

### SSH workflow

Once the VM is running, it's easier to work over SSH from a second terminal:

```bash
# Provision the VM
ssh -p 2222 localhost 'sh -s' < freebsd/provision.sh

# Copy notenav into the VM
scp -r -P 2222 "$(git rev-parse --show-toplevel)" localhost:/root/notenav

# SSH in and test
ssh -p 2222 localhost
cd /root/notenav && bash bin/nn doctor
```

Default root password after provisioning: `freebsd`

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
