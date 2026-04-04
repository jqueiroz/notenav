#!/usr/bin/env bash
#
# Launch an OpenBSD VM for interactive testing.
#
# Usage:
#   ./launch.sh            # boot from installed disk
#   ./launch.sh --install  # (re)create disk and boot the installer
#   ./launch.sh --fresh    # re-download ISO, recreate disk, and boot the installer
#
# OpenBSD does not support cloud-init, so the first boot runs the
# interactive installer via VNC (~5 minutes). After install, all
# interaction is via SSH.
#
# SSH is forwarded: ssh -p 2225 root@localhost
# To sync files in: ./sync.sh
# To quit QEMU:     Ctrl-a x

set -euo pipefail
cd "$(dirname "$0")"

OPENBSD_VERSION="7.8"
OPENBSD_SHORT="${OPENBSD_VERSION//.}"
ISO_BASE="cd${OPENBSD_SHORT}.iso"
ISO_URL="https://cdn.openbsd.org/pub/OpenBSD/${OPENBSD_VERSION}/amd64/${ISO_BASE}"
IMAGE_DIR="./images"
ISO_PATH="${IMAGE_DIR}/${ISO_BASE}"
DISK_PATH="${IMAGE_DIR}/openbsd.qcow2"
DISK_SIZE="10G"

RAM="${RAM:-2G}"
CPUS="${CPUS:-2}"
SSH_PORT="${SSH_PORT:-2225}"
VNC_DISPLAY="${VNC_DISPLAY:-0}"

QEMU="$(command -v qemu-system-x86_64)" \
  || { echo "qemu-system-x86_64 not found. Run: nix-shell (or apt install qemu-system-x86)"; exit 1; }

KVM_ARGS=()
if [[ -e /dev/kvm ]]; then
  KVM_ARGS+=("-enable-kvm")
fi

download_iso() {
  mkdir -p "$IMAGE_DIR"
  echo "Downloading OpenBSD ${OPENBSD_VERSION} install ISO..."
  curl -L -o "$ISO_PATH" "$ISO_URL"
  echo "ISO ready: ${ISO_PATH}"
}

create_disk() {
  mkdir -p "$IMAGE_DIR"
  echo "Creating ${DISK_SIZE} disk image..."
  qemu-img create -f qcow2 "$DISK_PATH" "$DISK_SIZE"
}

INSTALL_MODE=false

if [[ "${1:-}" == "--fresh" ]]; then
  rm -f "$ISO_PATH" "$DISK_PATH"
  download_iso
  create_disk
  INSTALL_MODE=true
elif [[ "${1:-}" == "--install" ]]; then
  rm -f "$DISK_PATH"
  [[ ! -f "$ISO_PATH" ]] && download_iso
  create_disk
  INSTALL_MODE=true
elif [[ ! -f "$DISK_PATH" ]]; then
  [[ ! -f "$ISO_PATH" ]] && download_iso
  create_disk
  INSTALL_MODE=true
fi

if [[ "$INSTALL_MODE" == true ]]; then
  VNC_PORT=$((5900 + VNC_DISPLAY))
  echo "Booting OpenBSD ${OPENBSD_VERSION} installer (${RAM} RAM, ${CPUS} CPUs)..."
  echo "  VNC: connect to localhost:${VNC_PORT} (display :${VNC_DISPLAY})"
  echo "  Quit: Ctrl-C"
  echo ""
  echo "  Install tips:"
  echo "    - Set root password to: openbsd"
  echo "    - Enable sshd: yes (default)"
  echo "    - Use whole disk, auto layout"
  echo "    - Default set: -game* -x* (to speed up install)"
  echo "    - After install completes, type 'halt' – then re-run this script without --install"
  echo ""

  sudo "$QEMU" \
    "${KVM_ARGS[@]}" \
    -m "$RAM" \
    -smp "$CPUS" \
    -display "vnc=:${VNC_DISPLAY}" \
    -device virtio-rng-pci \
    -drive "file=${DISK_PATH},format=qcow2" \
    -cdrom "$ISO_PATH" \
    -boot d \
    -nic "user,hostfwd=tcp::${SSH_PORT}-:22"
else
  echo "Booting OpenBSD ${OPENBSD_VERSION} (${RAM} RAM, ${CPUS} CPUs, SSH on port ${SSH_PORT})..."
  echo "  Quit: Ctrl-a x  |  SSH: ssh -p ${SSH_PORT} root@localhost"
  echo ""

  sudo "$QEMU" \
    "${KVM_ARGS[@]}" \
    -m "$RAM" \
    -smp "$CPUS" \
    -nographic \
    -device virtio-rng-pci \
    -drive "file=${DISK_PATH},format=qcow2" \
    -nic "user,hostfwd=tcp::${SSH_PORT}-:22"
fi
