#!/usr/bin/env bash

set -euo pipefail

path="${1:-}"
max="${2:-${TMUX_CWD_MAX:-36}}"

if [[ -z "$path" ]]; then
	path="$PWD"
fi

if [[ ! "$max" =~ ^[0-9]+$ ]] || [[ "$max" -lt 8 ]]; then
	max=36
fi

display="$path"
if [[ "$display" == "$HOME"* ]]; then
	display="~${display#"$HOME"}"
fi

if [[ "$display" != "/" ]]; then
	display="${display%/}"
fi

if ((${#display} <= max)); then
	printf "%s" "$display"
	exit 0
fi

slash="/"
base=""
rest="$display"
if [[ ${display:0:1} == \~ && ${display:1:1} == / ]]; then
	base="~${slash}"
	rest="${display#~/}"
elif [[ "$display" == "/"* ]]; then
	base="$slash"
	rest="${display#/}"
fi

if [[ -z "$rest" ]]; then
	printf "%s" "$display"
	exit 0
fi

prefix="${base}.../"
IFS='/' read -r -a parts <<<"$rest"

tail=""
for ((i = ${#parts[@]} - 1; i >= 0; i--)); do
	segment="${parts[i]}"
	if [[ -z "$tail" ]]; then
		candidate="$segment"
	else
		candidate="$segment/$tail"
	fi

	if ((${#prefix} + ${#candidate} <= max)); then
		tail="$candidate"
	else
		break
	fi
done

if [[ -z "$tail" ]]; then
	available=$((max - ${#prefix}))
	if ((available < 1)); then
		printf "%s" "${display:0:max}"
		exit 0
	fi
	tail="${rest: -available}"
fi

printf "%s" "${prefix}${tail}"
