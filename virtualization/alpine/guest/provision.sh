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
  yq \
  git \
  ripgrep \
  bat \
  curl

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
