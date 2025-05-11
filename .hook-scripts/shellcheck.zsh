#!/usr/bin/env zsh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo -e "${RED}❌ shellcheck is not installed. Please install it first.${NC}"
    exit 1
fi

# Get shell scripts from git staged files
files=()
while IFS= read -r file; do
  if [[ -f "$file" ]] && [[ "$file" =~ \.(sh|bash|ksh|zsh)$ ]]; then
    files+=("$file")
  fi
done < <(git diff --cached --name-only --diff-filter=ACMR)

# Join array with newlines for output
files_str="${(F)files}"

if [ ${#files[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No shell scripts to check${NC}"
    exit 0
fi

# Run shellcheck on each file
exit_code=0
for file in "${files[@]}"; do
    echo "Checking $file..."
    if ! shellcheck -x "$file"; then
        exit_code=1
    fi
done

if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✓ All shell scripts passed shellcheck${NC}"
else
    echo -e "${RED}❌ Some shell scripts failed shellcheck${NC}"
fi

exit $exit_code
