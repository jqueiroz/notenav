#!/bin/sh
#
# Provision a Fedora VM for notenav testing.
#
# Run this inside the VM:
#   sh provision.sh
#
# Or pipe over SSH from the host (from the repo root):
#   ssh -p 2224 fedora@localhost 'sh -s' < virtualization/fedora/guest/provision.sh

set -eu

echo "==> Installing packages..."
sudo dnf install -y \
  bash \
  gawk \
  fzf \
  jq \
  git \
  ripgrep \
  bat \
  curl

# yq-go is not in Fedora's repos; install from GitHub
if ! command -v yq >/dev/null 2>&1; then
  echo ""
  echo "==> Installing yq-go..."
  YQ_URL="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
  sudo curl -L -o /usr/local/bin/yq "$YQ_URL"
  sudo chmod +x /usr/local/bin/yq
fi

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
echo "  virtualization/fedora/sync.sh"
echo ""
echo "Then SSH in and test:"
echo "  ssh -p 2224 fedora@localhost"
echo "  nn doctor"
