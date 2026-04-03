#!/bin/sh
#
# Provision a FreeBSD VM for notenav testing.
#
# Run this inside the VM (as root):
#   sh provision.sh
#
# Or pipe over SSH from the host:
#   ssh -p 2222 localhost 'sh -s' < provision.sh

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
echo "==> Done!"
echo ""
echo "From the host, copy notenav into the VM:"
echo "  scp -r -P 2222 /path/to/notenav root@localhost:/root/notenav"
echo ""
echo "Then inside the VM:"
echo "  cd /root/notenav && bash bin/nn doctor"
