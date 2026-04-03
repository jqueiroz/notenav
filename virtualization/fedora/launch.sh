#!/usr/bin/env bash
#
# Launch a Fedora VM for interactive testing.
#
# Usage:
#   ./launch.sh            # boot (downloads image on first run)
#   ./launch.sh --fresh    # re-download the image before booting
#
# The VM boots to a serial console in your terminal.
# Login: fedora / fedora
#
# SSH is forwarded: ssh -p 2224 fedora@localhost
# To sync files in: ./sync.sh
# To quit QEMU:     Ctrl-a x

set -euo pipefail
cd "$(dirname "$0")"

FEDORA_VERSION="42"
IMAGE_BASE="Fedora-Cloud-Base-Generic-${FEDORA_VERSION}-1.1.x86_64.qcow2"
IMAGE_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_VERSION}/Cloud/x86_64/images/${IMAGE_BASE}"
IMAGE_DIR="./images"
IMAGE_PATH="${IMAGE_DIR}/${IMAGE_BASE}"
SEED_ISO="${IMAGE_DIR}/seed.iso"

RAM="${RAM:-2G}"
CPUS="${CPUS:-2}"
SSH_PORT="${SSH_PORT:-2224}"

QEMU="$(command -v qemu-system-x86_64)" \
  || { echo "qemu-system-x86_64 not found. Run: nix-shell (or apt install qemu-system-x86)"; exit 1; }

KVM_ARGS=()
if [[ -e /dev/kvm ]]; then
  KVM_ARGS+=("-enable-kvm")
fi

download_image() {
  mkdir -p "$IMAGE_DIR"
  echo "Downloading Fedora ${FEDORA_VERSION} cloud image..."
  curl -L -o "$IMAGE_PATH" "$IMAGE_URL"
  echo "Image ready: ${IMAGE_PATH}"
}

build_seed_iso() {
  local tmp
  tmp="$(mktemp -d)"
  cat > "${tmp}/meta-data" <<EOF
instance-id: notenav-test
local-hostname: fedora-test
EOF
  cat > "${tmp}/user-data" <<EOF
#cloud-config
ssh_pwauth: true
chpasswd:
  list: |
    fedora:fedora
  expire: false
users:
  - name: fedora
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
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

echo "Booting Fedora ${FEDORA_VERSION} (${RAM} RAM, ${CPUS} CPUs, SSH on port ${SSH_PORT})..."
echo "  Quit: Ctrl-a x  |  SSH: ssh -p ${SSH_PORT} fedora@localhost"
echo "  Login: fedora / fedora"
echo ""

sudo "$QEMU" \
  "${KVM_ARGS[@]}" \
  -m "$RAM" \
  -smp "$CPUS" \
  -nographic \
  -drive "file=${IMAGE_PATH},format=qcow2" \
  -drive "file=${SEED_ISO},media=cdrom" \
  -nic "user,hostfwd=tcp::${SSH_PORT}-:22"
