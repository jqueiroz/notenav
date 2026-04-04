#!/usr/bin/env bash
#
# Launch a NixOS VM for interactive testing.
#
# Usage:
#   ./launch.sh            # boot (builds image on first run via nix)
#   ./launch.sh --fresh    # rebuild the image before booting
#
# The VM boots to a serial console in your terminal.
# Login: nixos / nixos
#
# SSH is forwarded: ssh -p 2227 nixos@localhost
# To sync files in: ./sync.sh
# To quit QEMU:     Ctrl-a x
#
# NOTE: Unlike the other VMs, this one builds the image from a NixOS
# configuration (vm.nix) using nixos-generators. The first build takes
# several minutes; subsequent builds are fast (Nix caching).

set -euo pipefail
cd "$(dirname "$0")"

IMAGE_DIR="./images"
IMAGE_PATH="${IMAGE_DIR}/nixos.qcow2"
RESULT_LINK="${IMAGE_DIR}/result"

RAM="${RAM:-2G}"
CPUS="${CPUS:-2}"
SSH_PORT="${SSH_PORT:-2227}"

QEMU="$(command -v qemu-system-x86_64)" \
  || { echo "qemu-system-x86_64 not found. Run: nix-shell (or apt install qemu-system-x86)"; exit 1; }

KVM_ARGS=()
if [[ -e /dev/kvm ]]; then
  KVM_ARGS+=("-enable-kvm")
fi

build_image() {
  mkdir -p "$IMAGE_DIR"
  echo "Building NixOS VM image (first build may take several minutes)..."
  nix run github:nix-community/nixos-generators -- \
    -f qcow \
    -c "$(pwd)/vm.nix" \
    -o "$RESULT_LINK"
  cp "$RESULT_LINK/nixos.qcow2" "$IMAGE_PATH"
  chmod u+w "$IMAGE_PATH"
  rm -f "$RESULT_LINK"  # nix store symlink
  echo "Image ready: ${IMAGE_PATH}"
}

if [[ "${1:-}" == "--fresh" ]]; then
  rm -f "$IMAGE_PATH" "$RESULT_LINK"
  build_image
elif [[ ! -f "$IMAGE_PATH" ]]; then
  build_image
fi

echo "Booting NixOS (${RAM} RAM, ${CPUS} CPUs, SSH on port ${SSH_PORT})..."
echo "  Quit: Ctrl-a x  |  SSH: ssh -p ${SSH_PORT} nixos@localhost"
echo "  Login: nixos / nixos"
echo ""

sudo "$QEMU" \
  "${KVM_ARGS[@]}" \
  -m "$RAM" \
  -smp "$CPUS" \
  -nographic \
  -drive "file=${IMAGE_PATH},format=qcow2" \
  -nic "user,hostfwd=tcp::${SSH_PORT}-:22"
