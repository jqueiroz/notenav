#!/usr/bin/env bash
#
# Sync committed notenav files into the Alpine VM.
# Safe to run from any directory within the repo.

set -euo pipefail

SSH_PORT="${SSH_PORT:-2225}"
REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

echo "Syncing notenav into Alpine VM (port ${SSH_PORT})..."
git -C "$REPO_ROOT" archive HEAD \
  | ssh -p "$SSH_PORT" root@localhost 'rm -rf /root/notenav && mkdir -p /root/notenav && tar xf - -C /root/notenav'
echo "Done."
