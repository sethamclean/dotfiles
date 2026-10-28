#!/usr/bin/env bash
# Claude Code status line: context window bar plus a smaller usage bar.
# Usage shows rate limits when the JSON has them, else session cost and
# prompt-cache hit ratio. Reads session JSON on stdin.
set -euo pipefail

input=$(cat)

# bar PCT WIDTH FILL EMPTY
bar() {
  local pct=$1 width=$2 fill=$3 empty=$4 filled i out=""
  ((pct > 100)) && pct=100
  filled=$((pct * width / 100))
  for ((i = 0; i < width; i++)); do
    if ((i < filled)); then out+=$fill; else out+=$empty; fi
  done
  printf '%s' "$out"
}

# color PCT: green < 30, orange < 50, red otherwise
color() {
  if (($1 < 30)); then
    printf '\033[32m'
  elif (($1 < 50)); then
    printf '\033[38;5;208m'
  else
    printf '\033[31m'
  fi
}
reset=$'\033[0m'
dim=$'\033[2m'

ctx=$(jq -r '(.context_window.used_percentage // 0) | floor' <<<"$input")
five=$(jq -r '.rate_limits.five_hour.used_percentage // empty | floor' <<<"$input")
week=$(jq -r '.rate_limits.seven_day.used_percentage // empty | floor' <<<"$input")
model=$(jq -r '.model.display_name // empty' <<<"$input")

printf '%sctx   %s %s%%%s %s%s%s\n' \
  "$(color "$ctx")" "$(bar "$ctx" 20 '█' '░')" "$ctx" "$reset" "$dim" "$model" "$reset"

if [[ -n $five || -n $week ]]; then
  five=${five:-0}
  week=${week:-0}
  printf '%suse   %s 5h %s%%  7d %s%%%s\n' \
    "$(color "$five")" "$(bar "$five" 10 '▮' '▯')" "$five" "$week" "$reset"
else
  cost=$(jq -r '.cost.total_cost_usd // 0' <<<"$input")
  hit=$(jq -r '(.prompt_cache.hit_ratio // 0) * 100 | floor' <<<"$input")
  printf '%suse   %s cache %s%%  $%.2f%s\n' \
    "$dim" "$(bar "$hit" 10 '▮' '▯')" "$hit" "$cost" "$reset"
fi

# Branch and linked-worktree name, from the session's own directory (not the
# script's cwd). Prints nothing outside a git repo.
dir=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
if [[ -n $dir ]] && paths=$(git -C "$dir" rev-parse --path-format=absolute \
  --git-dir --git-common-dir --show-toplevel 2>/dev/null); then
  {
    read -r git_dir
    read -r common_dir
    read -r top
  } <<<"$paths"
  branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null ||
    git -C "$dir" rev-parse --short HEAD 2>/dev/null || true)
  wt=""
  if [[ $git_dir != "$common_dir" ]]; then
    wt=$(jq -r '.worktree.name // empty' <<<"$input")
    wt=${wt:-${top##*/}}
  fi
  printf '%sgit   %s%s%s\n' "$dim" "${branch:-?}" "${wt:+  ⎇ wt:$wt}" "$reset"
fi
