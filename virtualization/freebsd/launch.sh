#!/usr/bin/env bash
#
# Launch a FreeBSD VM for interactive testing.
#
# Usage:
#   ./launch.sh            # boot (downloads image on first run)
#   ./launch.sh --fresh    # re-download the image before booting
#
# The VM boots to a serial console in your terminal. Log in as root
# (no password on first boot), then run provision.sh inside the VM.
#
# SSH is forwarded: ssh -p 2222 localhost
# To copy files in: scp -P 2222 file localhost:/root/
# To quit QEMU:     Ctrl-a x

set -euo pipefail
cd "$(dirname "$0")"

FREEBSD_VERSION="14.4"
IMAGE_BASE="FreeBSD-${FREEBSD_VERSION}-RELEASE-amd64.qcow2"
IMAGE_URL="https://download.freebsd.org/releases/VM-IMAGES/${FREEBSD_VERSION}-RELEASE/amd64/Latest/${IMAGE_BASE}.xz"
IMAGE_DIR="./images"
IMAGE_PATH="${IMAGE_DIR}/${IMAGE_BASE}"

RAM="${RAM:-2G}"
CPUS="${CPUS:-2}"
SSH_PORT="${SSH_PORT:-2222}"

QEMU="$(command -v qemu-system-x86_64)" \
  || { echo "qemu-system-x86_64 not found. Run: nix-shell (or apt install qemu-system-x86)"; exit 1; }

KVM_FLAG=""
if [[ -e /dev/kvm ]]; then
  KVM_FLAG="-enable-kvm"
fi

download_image() {
  mkdir -p "$IMAGE_DIR"
  echo "Downloading FreeBSD ${FREEBSD_VERSION} VM image..."
  curl -L -o "${IMAGE_PATH}.xz" "$IMAGE_URL"
  echo "Decompressing..."
  xz -d "${IMAGE_PATH}.xz"
  echo "Image ready: ${IMAGE_PATH}"
}

if [[ "${1:-}" == "--fresh" ]]; then
  rm -f "$IMAGE_PATH" "${IMAGE_PATH}.xz"
  download_image
elif [[ ! -f "$IMAGE_PATH" ]]; then
  download_image
fi

echo "Booting FreeBSD ${FREEBSD_VERSION} (${RAM} RAM, ${CPUS} CPUs, SSH on port ${SSH_PORT})..."
echo "  Quit: Ctrl-a x  |  SSH: ssh -p ${SSH_PORT} localhost"
echo ""

sudo "$QEMU" \
  $KVM_FLAG \
  -m "$RAM" \
  -smp "$CPUS" \
  -nographic \
  -drive "file=${IMAGE_PATH},format=qcow2" \
  -nic "user,hostfwd=tcp::${SSH_PORT}-:22"
