#!/bin/sh
#
# Provision an OpenBSD VM for notenav testing.
#
# Run this inside the VM (as root):
#   sh provision.sh
#
# Or pipe over SSH from the host (from the repo root):
#   ssh -p 2225 root@localhost 'sh -s' < virtualization/openbsd/guest/provision.sh

set -eu

echo "==> Installing packages..."
pkg_add \
  bash \
  gawk \
  fzf \
  jq \
  git \
  ripgrep \
  bat \
  curl

# yq-go is not in OpenBSD ports; install from GitHub
echo ""
echo "==> Installing yq-go..."
ftp -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_openbsd_amd64
chmod +x /usr/local/bin/yq

echo ""
echo "==> Enabling serial console for headless boot..."
echo "stty com0 115200" > /etc/boot.conf
# Also enable serial getty so the console works after boot
echo 'tty00   "/usr/libexec/getty std.115200"   vt220   on  secure' >> /etc/ttys

echo ""
echo "==> Configuring SSH to allow root login with password..."
sed_file="/etc/ssh/sshd_config"
tmp_file="${sed_file}.tmp"
sed 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "$sed_file" > "$tmp_file" && mv "$tmp_file" "$sed_file"
sed 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$sed_file" > "$tmp_file" && mv "$tmp_file" "$sed_file"
rcctl restart sshd

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
echo "  virtualization/openbsd/sync.sh"
echo ""
echo "Then SSH in and test:"
echo "  ssh -p 2225 root@localhost"
echo "  nn doctor"
