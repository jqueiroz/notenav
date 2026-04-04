#!/usr/bin/env bash
#
# Sync committed notenav files into the NixOS VM.
# Safe to run from any directory within the repo.

set -euo pipefail

SSH_PORT="${SSH_PORT:-2227}"
REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

echo "Syncing notenav into NixOS VM (port ${SSH_PORT})..."
git -C "$REPO_ROOT" archive HEAD \
  | ssh -p "$SSH_PORT" nixos@localhost 'rm -rf ~/notenav && mkdir -p ~/notenav && tar xf - -C ~/notenav'
echo "Done."
