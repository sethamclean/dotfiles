#!/usr/bin/env bash

set -uo pipefail

cleanup() {
	tmux set-option -gu @other_session_activity_updater_pid >/dev/null 2>&1 || true
}

existing_pid="$(tmux show-option -gqv @other_session_activity_updater_pid 2>/dev/null || true)"
if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
	exit 0
fi

tmux set-option -gq @other_session_activity_updater_pid "$$"
trap cleanup EXIT
trap 'cleanup; exit 0' TERM INT

while tmux list-sessions >/dev/null 2>&1; do
	current_session=""
	while IFS=$'\t' read -r is_active client_session; do
		if [[ "$is_active" == "1" ]] && [[ -n "$client_session" ]]; then
			current_session="$client_session"
			break
		fi
	done < <(tmux list-clients -F $'#{?client_active,1,0}\t#{client_session}' 2>/dev/null || true)
	has_other_activity=0

	while IFS=$'\t' read -r session_name session_alerts; do
		if [[ -z "$session_name" ]] || [[ "$session_name" == "$current_session" ]]; then
			continue
		fi
		if [[ -n "$session_alerts" ]]; then
			has_other_activity=1
			break
		fi
	done < <(tmux list-sessions -F $'#{session_name}\t#{session_alerts}' 2>/dev/null || true)

	if [[ "$has_other_activity" -eq 1 ]]; then
		tmux set-option -gq @other_session_activity_hint '#[fg=colour220] (⌃B S)#[default]'
	else
		tmux set-option -gq @other_session_activity_hint ''
	fi

	sleep 2 || true
done
