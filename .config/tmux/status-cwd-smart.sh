#!/usr/bin/env bash

set -euo pipefail

path="${1:-}"
max="${2:-${TMUX_CWD_MAX:-36}}"
cache_ttl="${TMUX_CWD_CACHE_TTL:-3}"
git_timeout="${TMUX_GIT_TIMEOUT:-0.12}"

if [[ -z "$path" ]]; then
	path="$PWD"
fi

if [[ ! "$max" =~ ^[0-9]+$ ]] || [[ "$max" -lt 8 ]]; then
	max=36
fi

if [[ ! "$cache_ttl" =~ ^[0-9]+$ ]] || [[ "$cache_ttl" -lt 0 ]]; then
	cache_ttl=3
fi

normalize_path() {
	local input="$1"
	local output="$input"

	if [[ "$output" == "$HOME"* ]]; then
		output="~${output#"$HOME"}"
	fi

	if [[ "$output" != "/" ]]; then
		output="${output%/}"
	fi

	printf "%s" "$output"
}

truncate_path() {
	local input="$1"
	local width="$2"

	if ((${#input} <= width)); then
		printf "%s" "$input"
		return
	fi

	local slash="/"
	local base=""
	local rest="$input"

	if [[ ${input:0:1} == \~ && ${input:1:1} == / ]]; then
		base="~${slash}"
		rest="${input#~/}"
	elif [[ "$input" == /* ]]; then
		base="$slash"
		rest="${input#/}"
	fi

	if [[ -z "$rest" ]]; then
		printf "%s" "$input"
		return
	fi

	local prefix="${base}.../"
	local tail=""
	local candidate=""
	local segment=""
	local available=0
	local -a parts

	IFS='/' read -r -a parts <<<"$rest"

	for ((i = ${#parts[@]} - 1; i >= 0; i--)); do
		segment="${parts[i]}"
		if [[ -z "$tail" ]]; then
			candidate="$segment"
		else
			candidate="$segment/$tail"
		fi

		if ((${#prefix} + ${#candidate} <= width)); then
			tail="$candidate"
		else
			break
		fi
	done

	if [[ -z "$tail" ]]; then
		available=$((width - ${#prefix}))
		if ((available < 1)); then
			printf "%s" "${input:0:width}"
			return
		fi
		tail="${rest: -available}"
	fi

	printf "%s" "${prefix}${tail}"
}

format_branch_suffix() {
	local branch="$1"
	local available="$2"

	if ((available <= 1)); then
		printf ""
		return
	fi

	local branch_space=$((available - 1))
	if ((${#branch} <= branch_space)); then
		printf ":%s" "$branch"
		return
	fi

	if ((branch_space <= 3)); then
		printf ":%s" "${branch: -branch_space}"
		return
	fi

	printf ":...%s" "${branch: -$((branch_space - 3))}"
}

cache_key() {
	local input="$1"
	if command -v sha1sum >/dev/null 2>&1; then
		printf "%s" "$input" | sha1sum | awk '{print $1}'
	elif command -v md5sum >/dev/null 2>&1; then
		printf "%s" "$input" | md5sum | awk '{print $1}'
	else
		printf "%s" "$input" | cksum | awk '{print $1}'
	fi
}

git_quick() {
	if command -v timeout >/dev/null 2>&1; then
		timeout "${git_timeout}s" git -C "$path" "$@"
	else
		git -C "$path" "$@"
	fi
}

colorize_markers() {
	local markers="$1"
	local out=""
	local char=""

	for ((i = 0; i < ${#markers}; i++)); do
		char="${markers:i:1}"
		case "$char" in
		'*') out+="#[fg=colour220]*#[fg=colour250]" ;;
		'+') out+="#[fg=colour40]+#[fg=colour250]" ;;
		'^') out+="#[fg=colour220]^#[fg=colour250]" ;;
		'$') out+="#[fg=colour45]$#[fg=colour250]" ;;
		'M' | 'R' | 'C') out+="#[fg=colour207]${char}#[fg=colour250]" ;;
		'!') out+="#[fg=colour214]!#[fg=colour250]" ;;
		*) out+="$char" ;;
		esac
	done

	printf "%s" "$out"
}

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux"
mkdir -p "$cache_dir"

cache_file="$cache_dir/status-cwd-smart-$(cache_key "${path}|${max}")"
now_ts="$(date +%s)"

if [[ -f "$cache_file" ]]; then
	IFS=$'\t' read -r cached_ts cached_value <"$cache_file" || true
	if [[ -n "${cached_ts:-}" ]] && [[ "$cached_ts" =~ ^[0-9]+$ ]]; then
		if ((now_ts - cached_ts <= cache_ttl)); then
			printf "%s" "${cached_value:-}"
			exit 0
		fi
	fi
fi

display="$(normalize_path "$path")"

git_ref=""
markers=""
is_detached=false

if git_quick rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	git_ref="$(git_quick symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
	if [[ -z "$git_ref" ]]; then
		git_ref="$(git_quick rev-parse --short HEAD 2>/dev/null || true)"
		if [[ -n "$git_ref" ]]; then
			is_detached=true
		fi
	fi

	if ! git_quick diff --quiet --ignore-submodules -- >/dev/null 2>&1; then
		markers+="*"
	fi

	if ! git_quick diff --cached --quiet --ignore-submodules -- >/dev/null 2>&1; then
		markers+="+"
	fi

	ahead_count=""
	if git_quick rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
		ahead_count="$(git_quick rev-list --count '@{upstream}..HEAD' 2>/dev/null || true)"
		if [[ "$ahead_count" =~ ^[0-9]+$ ]] && ((ahead_count > 0)); then
			markers+="^"
		fi
	fi

	if git_quick rev-parse --verify --quiet refs/stash >/dev/null 2>&1; then
		markers+="$"
	fi

	git_dir="$(git_quick rev-parse --git-dir 2>/dev/null || true)"
	if [[ -n "$git_dir" ]]; then
		if [[ ! "$git_dir" = /* ]]; then
			git_dir="$path/$git_dir"
		fi

		if [[ -f "$git_dir/MERGE_HEAD" ]]; then
			markers+="M"
		fi

		if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]; then
			markers+="R"
		fi

		if [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
			markers+="C"
		fi
	fi

	if [[ "$is_detached" = true ]]; then
		markers+="!"
	fi
fi

path_width="$max"
markers_plain_part=""
if [[ -n "$git_ref" ]]; then
	if [[ -n "$markers" ]]; then
		markers_plain_part=" $markers"
	fi

	min_suffix=$((5 + ${#markers_plain_part}))
	if ((max > min_suffix)); then
		max_path_with_suffix=$((max - min_suffix))
		if ((${#display} > max_path_with_suffix)); then
			path_width="$max_path_with_suffix"
		fi
	fi
fi

display_path="$(truncate_path "$display" "$path_width")"

if [[ -z "$git_ref" ]]; then
	result="$display_path"
	printf "%s\t%s" "$now_ts" "$result" >"$cache_file"
	printf "%s" "$result"
	exit 0
fi

available_for_suffix=$((max - ${#display_path} - ${#markers_plain_part}))
branch_suffix="$(format_branch_suffix "$git_ref" "$available_for_suffix")"
markers_colored=""
if [[ -n "$markers" ]]; then
	markers_colored=" $(colorize_markers "$markers")"
fi

result="${display_path}${branch_suffix}${markers_colored}"
printf "%s\t%s" "$now_ts" "$result" >"$cache_file"
printf "%s" "$result"
