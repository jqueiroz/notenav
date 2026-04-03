#!/usr/bin/env bash
#
# Launch a FreeBSD VM for interactive testing.
#
# Usage:
#   ./launch.sh            # boot (downloads image on first run)
#   ./launch.sh --fresh    # re-download the image before booting
#
# The VM boots to a serial console in your terminal. Log in as root
# (password: freebsd), then run provision.sh inside the VM.
#
# SSH is forwarded: ssh -p 2222 localhost
# To copy files in: git archive HEAD | ssh -p 2222 root@localhost 'tar xf - -C /root/notenav'
# To quit QEMU:     Ctrl-a x

set -euo pipefail
cd "$(dirname "$0")"

FREEBSD_VERSION="14.4"
IMAGE_BASE="FreeBSD-${FREEBSD_VERSION}-RELEASE-amd64-BASIC-CLOUDINIT-ufs.qcow2"
IMAGE_URL="https://download.freebsd.org/releases/VM-IMAGES/${FREEBSD_VERSION}-RELEASE/amd64/Latest/${IMAGE_BASE}.xz"
IMAGE_DIR="./images"
IMAGE_PATH="${IMAGE_DIR}/${IMAGE_BASE}"
SEED_ISO="${IMAGE_DIR}/seed.iso"

RAM="${RAM:-2G}"
CPUS="${CPUS:-2}"
SSH_PORT="${SSH_PORT:-2222}"

QEMU="$(command -v qemu-system-x86_64)" \
  || { echo "qemu-system-x86_64 not found. Run: nix-shell (or apt install qemu-system-x86)"; exit 1; }

KVM_ARGS=()
if [[ -e /dev/kvm ]]; then
  KVM_ARGS+=("-enable-kvm")
fi

download_image() {
  mkdir -p "$IMAGE_DIR"
  echo "Downloading FreeBSD ${FREEBSD_VERSION} VM image..."
  curl -L -o "${IMAGE_PATH}.xz" "$IMAGE_URL"
  echo "Decompressing..."
  xz -d "${IMAGE_PATH}.xz"
  echo "Image ready: ${IMAGE_PATH}"
}

build_seed_iso() {
  local tmp
  tmp="$(mktemp -d)"
  cat > "${tmp}/meta-data" <<EOF
instance-id: notenav-test
local-hostname: freebsd-test
EOF
  cat > "${tmp}/user-data" <<EOF
#cloud-config
ssh_pwauth: true
chpasswd:
  list: |
    root:freebsd
  expire: false
EOF
  genisoimage -output "$SEED_ISO" -volid cidata -joliet -rock \
    "${tmp}/meta-data" "${tmp}/user-data" 2>/dev/null
  rm -rf "$tmp"
}

if [[ "${1:-}" == "--fresh" ]]; then
  rm -f "$IMAGE_PATH" "${IMAGE_PATH}.xz" "$SEED_ISO"
  download_image
elif [[ ! -f "$IMAGE_PATH" ]]; then
  download_image
fi

if [[ ! -f "$SEED_ISO" ]]; then
  build_seed_iso
fi

echo "Booting FreeBSD ${FREEBSD_VERSION} (${RAM} RAM, ${CPUS} CPUs, SSH on port ${SSH_PORT})..."
echo "  Quit: Ctrl-a x  |  SSH: ssh -p ${SSH_PORT} localhost"
echo "  Login: root / freebsd"
echo ""

sudo "$QEMU" \
  "${KVM_ARGS[@]}" \
  -m "$RAM" \
  -smp "$CPUS" \
  -nographic \
  -drive "file=${IMAGE_PATH},format=qcow2" \
  -drive "file=${SEED_ISO},media=cdrom" \
  -nic "user,hostfwd=tcp::${SSH_PORT}-:22"
