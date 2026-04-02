#!/usr/bin/env bash

set -euo pipefail

resurrect_last="${HOME}/.local/share/tmux/resurrect/last"

if [ ! -e "${resurrect_last}" ]; then
	exit 0
fi

target_file="$(readlink -f "${resurrect_last}" 2>/dev/null || true)"
if [ -z "${target_file}" ] || [ ! -f "${target_file}" ]; then
	exit 0
fi

tmp_file="${target_file}.tmp"

awk 'BEGIN { FS = OFS = "\t" }
  $1 == "pane" && $7 ~ /^OC \|/ && $10 == "zsh" {
    $10 = "opencode"
    $NF = ":opencode -c"
  }
  { print }
' "${target_file}" >"${tmp_file}"

mv "${tmp_file}" "${target_file}"
