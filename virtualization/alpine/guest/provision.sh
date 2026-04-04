#!/bin/sh
#
# Provision an Alpine Linux VM for notenav testing.
#
# Run this inside the VM (as root):
#   sh provision.sh
#
# Or pipe over SSH from the host (from the repo root):
#   ssh -p 2225 root@localhost 'sh -s' < virtualization/alpine/guest/provision.sh

set -eu

echo "==> Enabling community repository..."
sed 's|^#\(.*community\)|\1|' /etc/apk/repositories > /tmp/repositories
mv /tmp/repositories /etc/apk/repositories

echo ""
echo "==> Installing packages..."
apk update
apk add \
  bash \
  gawk \
  fzf \
  jq \
  git \
  ripgrep \
  bat \
  curl

# yq-go: install from GitHub (Go binaries are statically linked, safe on musl)
if ! command -v yq >/dev/null 2>&1; then
  echo ""
  echo "==> Installing yq-go..."
  YQ_URL="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
  curl -fL -o /usr/local/bin/yq "$YQ_URL"
  chmod +x /usr/local/bin/yq
fi

echo ""
echo "==> Adding notenav to PATH..."
profile_line='export PATH="/root/notenav/bin:$PATH"'
if ! grep -qF "$profile_line" /root/.profile 2>/dev/null; then
  echo "$profile_line" >> /root/.profile
fi

echo ""
echo "==> Done!"
echo ""
echo "From the host, sync notenav into the VM:"
echo "  virtualization/alpine/sync.sh"
echo ""
echo "Then SSH in and test:"
echo "  ssh -p 2225 root@localhost"
echo "  nn doctor"
