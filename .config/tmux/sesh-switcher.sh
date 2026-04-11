#!/usr/bin/env bash
set -euo pipefail

selection="$(sesh list -i | fzf \
	--no-sort \
	--ansi \
	--border \
	--height 100% \
	--prompt '⚡  ' \
	--header '  ctrl-t tmux  ctrl-c config  ctrl-z zoxide' \
	--bind 'ctrl-t:reload(sesh list -t -i)' \
	--bind 'ctrl-c:reload(sesh list -c -i)' \
	--bind 'ctrl-z:reload(sesh list -z -i)' \
	--preview 'sesh preview {}' \
	--preview-window 'right:55%' ||
	true)"

if [[ -z "${selection}" ]]; then
	exit 0
fi

sesh connect --switch "${selection}"
