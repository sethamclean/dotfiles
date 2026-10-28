#!/usr/bin/env zsh

# Check that agents defined for both Claude Code and OpenCode have identical
# bodies. Only the frontmatter may differ between the two harnesses.
# Usage: check-agent-sync.zsh [claude_agents_dir] [opencode_agents_dir]

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

claude_dir=${1:-.claude/agents}
opencode_dir=${2:-.config/opencode/agents}

# Print a file without its leading frontmatter block.
body() {
  awk 'BEGIN { fm = 0 } fm < 2 && /^---$/ { fm++; next } fm >= 2 { print }' "$1"
}

result=0
checked=0
for claude_file in "$claude_dir"/*.md(N); do
  name=${claude_file:t}
  opencode_file="$opencode_dir/$name"
  [[ -f "$opencode_file" ]] || continue
  checked=$((checked + 1))
  if ! diff -q <(body "$claude_file") <(body "$opencode_file") > /dev/null; then
    echo -e "${RED}❌ Agent bodies differ: $claude_file vs $opencode_file${NC}"
    result=1
  fi
done

if (( result == 0 )); then
  echo -e "${GREEN}✓ $checked agent pair(s) in sync${NC}"
fi
exit $result
