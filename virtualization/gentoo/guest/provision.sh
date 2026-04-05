#!/bin/sh
#
# Provision a Gentoo VM for notenav testing.
#
# Run this inside the VM (as root):
#   sh provision.sh
#
# Or pipe over SSH from the host (from the repo root):
#   ssh -p 2228 root@localhost 'sh -s' < virtualization/gentoo/guest/provision.sh
#
# NOTE: Gentoo compiles packages from source by default. Using --getbinpkg
# to prefer pre-built binaries where available, but provisioning may still
# take longer than other distros.

set -eu

# Fix DNS: break systemd-resolved symlink and use public DNS
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "==> Setting root password to 'gentoo'..."
echo "gentoo" | passwd --stdin root 2>/dev/null \
  || echo 'root:gentoo' | chpasswd

echo ""
echo "==> Configuring SSH..."
sed_file="/etc/ssh/sshd_config"
tmp_file="${sed_file}.tmp"
sed 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "$sed_file" > "$tmp_file" && mv "$tmp_file" "$sed_file"
sed 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$sed_file" > "$tmp_file" && mv "$tmp_file" "$sed_file"
rc-service sshd restart 2>/dev/null || systemctl restart sshd 2>/dev/null || true

echo ""
echo "==> Syncing Portage tree..."
emerge-webrsync --quiet

echo ""
echo "==> Installing packages (preferring binpkgs)..."
emerge --getbinpkg --quiet \
  sys-apps/gawk \
  app-shells/fzf \
  app-misc/jq \
  dev-vcs/git \
  sys-apps/ripgrep \
  sys-apps/bat \
  net-misc/curl

# yq-go is not in Gentoo's repos; install from GitHub
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
echo "  virtualization/gentoo/sync.sh"
echo ""
echo "Then SSH in and test:"
echo "  ssh -p 2228 root@localhost"
echo "  nn doctor"
