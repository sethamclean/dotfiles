#!/usr/bin/env bash

set -euo pipefail

inbox_file="${TMUX_MESSAGE_INBOX_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/tmux/inbox.log}"
inbox_dir="$(dirname "$inbox_file")"

mkdir -p "$inbox_dir"

add_entry() {
	local event="${1:-event}"
	local latest=""
	local ts=""
	local formatted=""

	latest="$(select_message "$event")"

	ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

	formatted="$(format_message "$latest")"

	if [[ -n "$formatted" ]]; then
		printf "%s\t%s\t%s\n" "$ts" "$event" "$formatted" >>"$inbox_file"
	else
		printf "%s\t%s\t%s\n" "$ts" "$event" "(no tmux message text available)" >>"$inbox_file"
	fi

	tmux set-option -gq @has_msg 1
}

select_message() {
	local event="$1"
	local line=""
	local first_non_noise=""

	while IFS= read -r line; do
		if is_noise_message "$event" "$line"; then
			continue
		fi
		if [[ -z "$first_non_noise" ]]; then
			first_non_noise="$line"
		fi
		if [[ "$event" == "error" ]] && is_likely_error_line "$line"; then
			printf "%s" "$line"
			return
		fi
		if [[ "$event" != "error" ]]; then
			printf "%s" "$line"
			return
		fi
	done < <(tmux show-messages 2>/dev/null || true)

	printf "%s" "$first_non_noise"
}

is_likely_error_line() {
	local message="$1"

	if [[ "$message" == *"error"* ]] ||
		[[ "$message" == *"failed"* ]] ||
		[[ "$message" == *"unknown"* ]] ||
		[[ "$message" == *"can't"* ]] ||
		[[ "$message" == *"no such"* ]] ||
		[[ "$message" == *"returned "* ]]; then
		return 0
	fi

	return 1
}

is_noise_message() {
	local event="$1"
	local message="$2"

	if [[ "$message" == *"command: show-messages"* ]] ||
		[[ "$message" == *"command: show-options "* ]] ||
		[[ "$message" == *"command: show-options -"* ]] ||
		[[ "$message" == *"message-inbox.sh add "* ]] ||
		[[ "$message" == *"command: set-option -gq @has_msg 1"* ]] ||
		[[ "$message" == *"command: set-option -gq @has_msg 0"* ]] ||
		[[ "$message" == *"command: list-sessions"* ]] ||
		[[ "$message" == *"command: list-sessions -F"* ]] ||
		[[ "$message" == *"command: list-clients -F"* ]] ||
		[[ "$message" == *"command: set-option -gq @dual_time "* ]] ||
		[[ "$message" == *"command: set-option -gq @other_session_activity_hint "* ]] ||
		[[ "$message" == *"command: run-shell -b \"/root/.config/tmux/message-inbox.sh add "* ]]; then
		return 0
	fi

	if [[ "$event" == "display" ]] &&
		[[ "$message" == *"command: display-message -p "* ]]; then
		return 0
	fi

	return 1
}

format_message() {
	local message="$1"
	local formatted="$message"

	if [[ "$formatted" == *" command: "* ]]; then
		formatted="tmux command: ${formatted#* command: }"
	elif [[ "$formatted" == *": "* ]]; then
		formatted="${formatted#*: }"
	fi

	printf "%s" "$formatted"
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

clean_inbox() {
	local tmp_file=""
	local ts=""
	local event=""
	local message=""

	if [[ ! -f "$inbox_file" ]]; then
		return
	fi

	tmp_file="$(mktemp)"

	while IFS=$'\t' read -r ts event message; do
		if [[ -z "$ts" ]]; then
			continue
		fi
		if is_noise_message "$event" "$message"; then
			continue
		fi
		printf "%s\t%s\t%s\n" "$ts" "$event" "$(format_message "$message")" >>"$tmp_file"
	done <"$inbox_file"

	mv "$tmp_file" "$inbox_file"

	if [[ -s "$inbox_file" ]]; then
		tmux set-option -gq @has_msg 1
	else
		tmux set-option -gq @has_msg 0
	fi
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
clean)
	clean_inbox
	;;
*)
	printf "Usage: %s {add [event]|view|clear|clean}\n" "$0" >&2
	exit 1
	;;
esac
