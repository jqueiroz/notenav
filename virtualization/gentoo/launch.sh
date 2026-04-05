#!/usr/bin/env bash
#
# Launch a Gentoo VM for interactive testing.
#
# Usage:
#   ./launch.sh            # boot (downloads image on first run)
#   ./launch.sh --fresh    # re-download the image before booting
#
# The VM boots to a serial console in your terminal. On first boot,
# log in as root (no password) and run guest/provision.sh to set up
# SSH and install notenav dependencies.
#
# Requires OVMF_FD env var (set by nix-shell) – the Gentoo image is
# EFI-only and needs UEFI firmware.
#
# SSH is forwarded: ssh -p 2228 root@localhost
# To sync files in: ./sync.sh
# To quit QEMU:     Ctrl-a x

set -euo pipefail
cd "$(dirname "$0")"

AUTOBUILD_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds"
IMAGE_DIR="./images"
IMAGE_PATH="${IMAGE_DIR}/gentoo-console.qcow2"
SERIAL_CONFIGURED="${IMAGE_DIR}/.serial-configured"

RAM="${RAM:-2G}"
CPUS="${CPUS:-2}"
SSH_PORT="${SSH_PORT:-2228}"

[[ -z "${OVMF_FD:-}" ]] && { echo "OVMF_FD not set. Run: nix-shell --command zsh (from virtualization/)"; exit 1; }

QEMU="$(command -v qemu-system-x86_64)" \
  || { echo "qemu-system-x86_64 not found. Run: nix-shell"; exit 1; }

QEMU_NBD="$(command -v qemu-nbd)" \
  || { echo "qemu-nbd not found. Run: nix-shell"; exit 1; }

KVM_ARGS=()
if [[ -e /dev/kvm ]]; then
  KVM_ARGS+=("-enable-kvm")
fi

download_image() {
  mkdir -p "$IMAGE_DIR"
  echo "Finding latest Gentoo console image..."
  local latest_path
  latest_path=$(curl -fsSL "${AUTOBUILD_URL}/latest-qcow2.txt" \
    | grep -v '^#' | grep -v '^-' | grep 'console.*\.qcow2' | head -1 | awk '{print $1}')
  if [[ -z "$latest_path" ]]; then
    echo "Could not determine latest Gentoo console image." >&2
    echo "Check: ${AUTOBUILD_URL}/latest-qcow2.txt" >&2
    exit 1
  fi
  echo "Downloading ${latest_path##*/}..."
  if [[ "$latest_path" == *.xz ]]; then
    curl -fL "${AUTOBUILD_URL}/${latest_path}" | xz -d > "$IMAGE_PATH"
  else
    curl -fL -o "$IMAGE_PATH" "${AUTOBUILD_URL}/${latest_path}"
  fi
  rm -f "$SERIAL_CONFIGURED"
  echo "Image ready: ${IMAGE_PATH}"
}

# Patch GRUB on the EFI partition to enable serial console.
# Gentoo's image is EFI-only; kernel + grub.cfg live on /dev/nbd0p1.
configure_serial() {
  echo "Configuring serial console in disk image..."
  sudo modprobe nbd max_part=8 2>/dev/null || true
  sudo "$QEMU_NBD" -d /dev/nbd0 2>/dev/null || true
  sudo "$QEMU_NBD" -c /dev/nbd0 "$IMAGE_PATH"
  sleep 2

  local mnt
  mnt=$(mktemp -d)

  # EFI partition is p1; grub.cfg is at grub/grub.cfg on that partition
  if ! sudo mount /dev/nbd0p1 "$mnt" 2>/dev/null; then
    echo "Warning: could not mount EFI partition." >&2
    rmdir "$mnt"
    sudo "$QEMU_NBD" -d /dev/nbd0
    return 1
  fi

  local grub_cfg="$mnt/grub/grub.cfg"
  if [[ ! -f "$grub_cfg" ]]; then
    echo "Warning: grub.cfg not found at grub/grub.cfg on EFI partition." >&2
    sudo umount "$mnt"; rmdir "$mnt"
    sudo "$QEMU_NBD" -d /dev/nbd0
    return 1
  fi

  local tmp_cfg="${grub_cfg}.tmp"

  # Prepend serial terminal configuration
  printf 'serial --unit=0 --speed=115200\nterminal_input serial console\nterminal_output serial console\n\n' \
    | sudo tee "$tmp_cfg" > /dev/null
  sudo cat "$grub_cfg" | sudo tee -a "$tmp_cfg" > /dev/null

  # Append console=ttyS0 to all linux boot lines
  sudo sed 's|\(linux[^ ]* .*\)|\1 console=ttyS0,115200n8|' "$tmp_cfg" \
    | sudo tee "$grub_cfg" > /dev/null
  sudo rm -f "$tmp_cfg"

  sudo umount "$mnt"
  rmdir "$mnt"
  sudo "$QEMU_NBD" -d /dev/nbd0
  sleep 1  # wait for lock release
  touch "$SERIAL_CONFIGURED"
  echo "Serial console configured."
}

if [[ "${1:-}" == "--fresh" ]]; then
  rm -f "$IMAGE_PATH" "$SERIAL_CONFIGURED"
  download_image
elif [[ ! -f "$IMAGE_PATH" ]]; then
  download_image
fi

if [[ ! -f "$SERIAL_CONFIGURED" ]]; then
  configure_serial
fi

echo "Booting Gentoo (${RAM} RAM, ${CPUS} CPUs, SSH on port ${SSH_PORT})..."
echo "  Quit: Ctrl-a x  |  SSH: ssh -p ${SSH_PORT} root@localhost"
echo "  Login: root (no password)"
echo ""

sudo "$QEMU" \
  "${KVM_ARGS[@]}" \
  -m "$RAM" \
  -smp "$CPUS" \
  -nographic \
  -bios "$OVMF_FD" \
  -drive "file=${IMAGE_PATH},format=qcow2" \
  -nic "user,hostfwd=tcp::${SSH_PORT}-:22"
