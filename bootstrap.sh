#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
flags=${1-}

# Backup ~/.profile if it exists and is not a symlink
if [ -f "${HOME}/.profile" ] && [ ! -L "${HOME}/.profile" ]; then
  backup_file="${HOME}/.profile.backup.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing .profile to ${backup_file}"
  mv "${HOME}/.profile" "${backup_file}"
fi

stow "${flags}" --no-folding --target="${HOME}" .
