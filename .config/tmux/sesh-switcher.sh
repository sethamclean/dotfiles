#!/usr/bin/env bash
set -euo pipefail

current_session="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"

declare -A alerts_by_session
while IFS= read -r session_name; do
	[[ -z "$session_name" ]] && continue
	session_alerts="$(tmux display-message -p -t "$session_name" '#{session_alerts}' 2>/dev/null || true)"
	alerts_by_session["$session_name"]="$session_alerts"
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)

menu_rows=""
while IFS=$'\t' read -r src name; do
	[[ -z "$src" || -z "$name" ]] && continue
	marker=" "
	if [[ "$src" == "tmux" ]]; then
		if [[ "$name" != "$current_session" ]] && [[ -n "${alerts_by_session[$name]:-}" ]]; then
			marker=$'\033[38;5;220m\033[0m'
		fi
	fi
	menu_rows+="${marker}"$'\t'"${src}"$'\t'"${name}"$'\n'
done < <(sesh list -j | jq -r '.[] | [.Src, .Name] | @tsv')

if [[ -z "${menu_rows}" ]]; then
	exit 0
fi

selection_row="$(printf '%s' "$menu_rows" | fzf \
	--ansi \
	--delimiter=$'\t' \
	--with-nth=1,2,3 \
	--accept-nth=3 \
	--no-sort \
	--border \
	--height 100% \
	--prompt '⚡  ' \
	--header '   marks other-session activity' \
	--preview 'sesh preview {3}' \
	--preview-window 'right:55%' ||
	true)"

if [[ -z "${selection_row}" ]]; then
	exit 0
fi

sesh connect --switch "${selection_row}"
