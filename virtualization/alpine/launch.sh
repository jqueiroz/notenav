#!/usr/bin/env bash
#
# Launch an Alpine Linux VM for interactive testing.
#
# Usage:
#   ./launch.sh            # boot (downloads image on first run)
#   ./launch.sh --fresh    # re-download the image before booting
#
# The VM boots to a serial console in your terminal.
# Login: root / alpine
#
# SSH is forwarded: ssh -p 2225 root@localhost
# To sync files in: ./sync.sh
# To quit QEMU:     Ctrl-a x

set -euo pipefail
cd "$(dirname "$0")"

ALPINE_BRANCH="v3.21"
ALPINE_RELEASE="3.21.0"
IMAGE_BASE="nocloud_alpine-${ALPINE_RELEASE}-x86_64-bios-cloudinit-r0.qcow2"
IMAGE_URL="https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/releases/cloud/${IMAGE_BASE}"
IMAGE_DIR="./images"
IMAGE_PATH="${IMAGE_DIR}/${IMAGE_BASE}"
SEED_ISO="${IMAGE_DIR}/seed.iso"

RAM="${RAM:-2G}"
CPUS="${CPUS:-2}"
SSH_PORT="${SSH_PORT:-2225}"

QEMU="$(command -v qemu-system-x86_64)" \
  || { echo "qemu-system-x86_64 not found. Run: nix-shell (or apt install qemu-system-x86)"; exit 1; }

KVM_ARGS=()
if [[ -e /dev/kvm ]]; then
  KVM_ARGS+=("-enable-kvm")
fi

download_image() {
  mkdir -p "$IMAGE_DIR"
  echo "Downloading Alpine Linux ${ALPINE_RELEASE} cloud image..."
  curl -L -o "$IMAGE_PATH" "$IMAGE_URL"
  echo "Resizing disk to 2G (Alpine ships ~250 MB)..."
  qemu-img resize "$IMAGE_PATH" 2G
  echo "Image ready: ${IMAGE_PATH}"
}

build_seed_iso() {
  local tmp
  tmp="$(mktemp -d)"
  cat > "${tmp}/meta-data" <<EOF
instance-id: notenav-test
local-hostname: alpine-test
EOF
  cat > "${tmp}/user-data" <<EOF
#cloud-config
ssh_pwauth: true
disable_root: false
growpart:
  mode: auto
  devices: ['/']
resize_rootfs: true
chpasswd:
  list: |
    root:alpine
  expire: false
runcmd:
  - echo 'root:alpine' | chpasswd
  - sed 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config > /tmp/sshd_config && mv /tmp/sshd_config /etc/ssh/sshd_config
  - sed 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config > /tmp/sshd_config && mv /tmp/sshd_config /etc/ssh/sshd_config
  - service sshd restart || true
EOF
  genisoimage -output "$SEED_ISO" -volid cidata -joliet -rock \
    "${tmp}/meta-data" "${tmp}/user-data" 2>/dev/null
  rm -rf "$tmp"
}

if [[ "${1:-}" == "--fresh" ]]; then
  rm -f "$IMAGE_PATH" "$SEED_ISO"
  download_image
elif [[ ! -f "$IMAGE_PATH" ]]; then
  download_image
fi

if [[ ! -f "$SEED_ISO" ]]; then
  build_seed_iso
fi

echo "Booting Alpine Linux ${ALPINE_RELEASE} (${RAM} RAM, ${CPUS} CPUs, SSH on port ${SSH_PORT})..."
echo "  Quit: Ctrl-a x  |  SSH: ssh -p ${SSH_PORT} root@localhost"
echo "  Login: root / alpine"
echo ""

sudo "$QEMU" \
  "${KVM_ARGS[@]}" \
  -m "$RAM" \
  -smp "$CPUS" \
  -nographic \
  -drive "file=${IMAGE_PATH},format=qcow2" \
  -drive "file=${SEED_ISO},media=cdrom" \
  -nic "user,hostfwd=tcp::${SSH_PORT}-:22"
