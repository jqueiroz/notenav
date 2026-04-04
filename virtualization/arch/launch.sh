#!/usr/bin/env bash
#
# Launch an Arch Linux VM for interactive testing.
#
# Usage:
#   ./launch.sh            # boot (downloads image on first run)
#   ./launch.sh --fresh    # re-download the image before booting
#
# The VM boots to a serial console in your terminal.
# Login: arch / arch
#
# SSH is forwarded: ssh -p 2226 arch@localhost
# To sync files in: ./sync.sh
# To quit QEMU:     Ctrl-a x

set -euo pipefail
cd "$(dirname "$0")"

IMAGE_BASE="Arch-Linux-x86_64-cloudimg.qcow2"
IMAGE_URL="https://geo.mirror.pkgbuild.com/images/latest/${IMAGE_BASE}"
IMAGE_DIR="./images"
IMAGE_PATH="${IMAGE_DIR}/${IMAGE_BASE}"
SEED_ISO="${IMAGE_DIR}/seed.iso"

RAM="${RAM:-2G}"
CPUS="${CPUS:-2}"
SSH_PORT="${SSH_PORT:-2226}"

QEMU="$(command -v qemu-system-x86_64)" \
  || { echo "qemu-system-x86_64 not found. Run: nix-shell (or apt install qemu-system-x86)"; exit 1; }

KVM_ARGS=()
if [[ -e /dev/kvm ]]; then
  KVM_ARGS+=("-enable-kvm")
fi

download_image() {
  mkdir -p "$IMAGE_DIR"
  echo "Downloading Arch Linux cloud image..."
  curl -fL -o "$IMAGE_PATH" "$IMAGE_URL"
  echo "Image ready: ${IMAGE_PATH}"
}

build_seed_iso() {
  local tmp
  tmp="$(mktemp -d)"
  cat > "${tmp}/meta-data" <<EOF
instance-id: notenav-test
local-hostname: arch-test
EOF
  cat > "${tmp}/user-data" <<EOF
#cloud-config
ssh_pwauth: true
chpasswd:
  list: |
    arch:arch
  expire: false
users:
  - name: arch
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

echo "Booting Arch Linux (${RAM} RAM, ${CPUS} CPUs, SSH on port ${SSH_PORT})..."
echo "  Quit: Ctrl-a x  |  SSH: ssh -p ${SSH_PORT} arch@localhost"
echo "  Login: arch / arch"
echo ""

sudo "$QEMU" \
  "${KVM_ARGS[@]}" \
  -m "$RAM" \
  -smp "$CPUS" \
  -nographic \
  -drive "file=${IMAGE_PATH},format=qcow2" \
  -drive "file=${SEED_ISO},media=cdrom" \
  -nic "user,hostfwd=tcp::${SSH_PORT}-:22"
