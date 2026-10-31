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

# Install workmux agent status hooks (Claude Code, OpenCode, ...). The setup
# asks one question, so answer it. Skipped for a stow dry run (-n) or without
# workmux; a failure here does not fail the bootstrap.
case "${flags}" in
*n*) ;;
*)
  if command -v workmux >/dev/null 2>&1; then
    printf 'y\n' | workmux setup --hooks || echo "warning: workmux setup --hooks failed" >&2
  fi
  ;;
esac
