#!/usr/bin/env bash

set -euo pipefail

inbox_file="${TMUX_MESSAGE_INBOX_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/tmux/inbox.log}"
inbox_dir="$(dirname "$inbox_file")"

mkdir -p "$inbox_dir"

add_entry() {
	local event="${1:-event}"
	local latest=""
	local ts=""

	while IFS= read -r line; do
		latest="$line"
		break
	done < <(tmux show-messages 2>/dev/null || true)

	ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

	if [[ -n "$latest" ]]; then
		printf "%s\t%s\t%s\n" "$ts" "$event" "$latest" >>"$inbox_file"
	else
		printf "%s\t%s\t%s\n" "$ts" "$event" "(no tmux message text available)" >>"$inbox_file"
	fi

	tmux set-option -gq @has_msg 1
}

view_inbox() {
	if [[ ! -s "$inbox_file" ]]; then
		printf "No inbox messages.\nPress q to close.\n" | less -+F -R
		return
	fi

	if command -v bat >/dev/null 2>&1; then
		BAT_PAGER='less -+F -R' bat --style=plain --paging=always "$inbox_file"
	else
		less -+F -R "$inbox_file"
	fi
}

clear_inbox() {
	: >"$inbox_file"
	tmux set-option -gq @has_msg 0
}

case "${1:-}" in
add)
	shift || true
	add_entry "${1:-event}"
	;;
view)
	view_inbox
	;;
clear)
	clear_inbox
	;;
*)
	printf "Usage: %s {add [event]|view|clear}\n" "$0" >&2
	exit 1
	;;
esac
