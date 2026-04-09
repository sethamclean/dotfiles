#!/usr/bin/env bash

set -euo pipefail

existing_pid="$(tmux show-option -gqv @dual_time_updater_pid 2>/dev/null || true)"
if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
	exit 0
fi

tmux set-option -gq @dual_time_updater_pid "$$"
trap 'tmux set-option -gu @dual_time_updater_pid >/dev/null 2>&1 || true' EXIT

while tmux list-sessions >/dev/null 2>&1; do
	utc_time="$(TZ='UTC0' date +'%H:%M')"
	ny_time="$(TZ='EST5EDT' date +'%H:%M')"
	tmux set-option -gq @dual_time "UTC ${utc_time} | NY ${ny_time}"
	sleep 5
done
