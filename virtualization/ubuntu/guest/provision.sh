#!/bin/sh
#
# Provision an Ubuntu VM for notenav testing.
#
# Run this inside the VM:
#   sh provision.sh
#
# Or pipe over SSH from the host (from the repo root):
#   ssh -p 2223 ubuntu@localhost 'sh -s' < virtualization/ubuntu/guest/provision.sh

set -eu

echo "==> Installing packages..."
sudo apt-get update
sudo apt-get install -y \
  bash \
  gawk \
  jq \
  git \
  ripgrep \
  bat \
  curl

# fzf: Ubuntu ships an older version (0.44); notenav requires 0.45+
FZF_MIN="0.45"
fzf_ver=$(fzf --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true)
if [ -z "$fzf_ver" ] || ! printf '%s\n%s\n' "$FZF_MIN" "$fzf_ver" | sort -V | head -1 | grep -q "^${FZF_MIN}$"; then
  echo ""
  echo "==> Installing fzf from GitHub (Ubuntu's version is too old)..."
  FZF_URL="https://github.com/junegunn/fzf/releases/latest/download/fzf-$(uname -s | tr '[:upper:]' '[:lower:]')_amd64.tar.gz"
  curl -L "$FZF_URL" | sudo tar xz -C /usr/local/bin
else
  echo "==> fzf ${fzf_ver} already meets minimum (${FZF_MIN})"
fi

# yq-go is not in Ubuntu's repos; install from GitHub
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
if ! grep -qF "$profile_line" "$HOME/.profile" 2>/dev/null; then
  echo "$profile_line" >> "$HOME/.profile"
fi

echo ""
echo "==> Done!"
echo ""
echo "From the host, sync notenav into the VM:"
echo "  virtualization/ubuntu/sync.sh"
echo ""
echo "Then SSH in and test:"
echo "  ssh -p 2223 ubuntu@localhost"
echo "  nn doctor"
