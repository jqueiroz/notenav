#!/bin/sh
#
# Provision an Arch Linux VM for notenav testing.
#
# Run this inside the VM:
#   sh provision.sh
#
# Or pipe over SSH from the host (from the repo root):
#   ssh -p 2226 arch@localhost 'sh -s' < virtualization/arch/guest/provision.sh

set -eu

echo "==> Updating packages..."
sudo pacman -Syu --noconfirm

echo ""
echo "==> Installing packages..."
sudo pacman -S --noconfirm \
  bash \
  gawk \
  fzf \
  jq \
  go-yq \
  git \
  ripgrep \
  bat \
  curl

echo ""
echo "==> Adding notenav to PATH..."
profile_line='export PATH="$HOME/notenav/bin:$PATH"'
if ! grep -qF "$profile_line" "$HOME/.bash_profile" 2>/dev/null; then
  echo "$profile_line" >> "$HOME/.bash_profile"
fi

echo ""
echo "==> Done!"
echo ""
echo "From the host, sync notenav into the VM:"
echo "  virtualization/arch/sync.sh"
echo ""
echo "Then SSH in and test:"
echo "  ssh -p 2226 arch@localhost"
echo "  nn doctor"
