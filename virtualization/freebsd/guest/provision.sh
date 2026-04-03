#!/bin/sh
#
# Provision a FreeBSD VM for notenav testing.
#
# Run this inside the VM (as root):
#   sh provision.sh
#
# Or pipe over SSH from the host (from the repo root):
#   ssh -p 2222 root@localhost 'sh -s' < virtualization/freebsd/guest/provision.sh

set -eu

echo "==> Installing packages..."
pkg install -y \
  bash \
  gawk \
  fzf \
  jq \
  go-yq \
  git \
  ripgrep \
  bat \
  curl \
  gmake

echo ""
echo "==> Enabling SSH (if not already)..."
sysrc sshd_enable="YES"
service sshd start 2>/dev/null || true

echo ""
echo "==> Setting root password to 'freebsd'..."
echo "freebsd" | pw usermod root -h 0

echo ""
echo "==> Configuring SSH to allow root login with password..."
sed_file="/etc/ssh/sshd_config"
tmp_file="${sed_file}.tmp"
sed 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "$sed_file" > "$tmp_file" && mv "$tmp_file" "$sed_file"
sed 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$sed_file" > "$tmp_file" && mv "$tmp_file" "$sed_file"
service sshd restart

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
echo "  virtualization/freebsd/sync.sh"
echo ""
echo "Then SSH in and test:"
echo "  ssh -p 2222 root@localhost"
echo "  nn doctor"
