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

# Skipped for a stow dry run (-n). Failures below warn and do not fail the
# bootstrap.
case "${flags}" in
*n*) ;;
*)
  # Link the shared engineering standards from the IDEXX checkout, so the
  # global instructions can point at one stable path. The link follows
  # whichever branch the checkout has open.
  standards_src=${CODING_STANDARDS_SRC:-/workspaces/is-devsecops-cloudstack/docs/engineering}
  if [ -f "${standards_src}/coding-standards.md" ]; then
    mkdir -p "${HOME}/.config" && ln -sfn "${standards_src}" "${HOME}/.config/coding-standards" ||
      echo "warning: could not link ${standards_src}" >&2
  else
    echo "warning: ${standards_src}/coding-standards.md not found; coding standards not linked" >&2
  fi
  # Install workmux agent status hooks (Claude Code, OpenCode, ...). The setup
  # asks one question, so answer it.
  if command -v workmux >/dev/null 2>&1; then
    printf 'y\n' | workmux setup --hooks || echo "warning: workmux setup --hooks failed" >&2
  fi
  ;;
esac
