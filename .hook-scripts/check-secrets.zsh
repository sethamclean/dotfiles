#!/usr/bin/env zsh

# Check if rg is available
if ! command -v rg &> /dev/null; then
    echo "ripgrep (rg) is not installed. Please install it first."
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Run ripgrep for each pattern type
found_secrets=0

# Get staged files
files=$(git diff --cached --name-only 2>/dev/null | grep -F -v "check-secrets.zsh" || true)

if [[ -n "$files" ]]; then
    # Create a temporary directory to store the staged content
    temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/git-secrets.XXXXXXXXXX")
    if [[ ! "$temp_dir" || ! -d "$temp_dir" ]]; then
        echo "Failed to create temporary directory" >&2
        exit 1
    fi
 
    # Ensure temp_dir is under /tmp or $TMPDIR
    if [[ ! "$temp_dir" =~ ^(${TMPDIR:-/tmp})/git-secrets\. ]]; then
        echo "Unsafe temporary directory created: $temp_dir" >&2
        exit 1
    fi

    # Make sure we only remove the specific temporary directory we created
    cleanup() {
        if [[ -d "$temp_dir" && "$temp_dir" =~ ^(${TMPDIR:-/tmp})/git-secrets\. ]]; then
            rm -rf "$temp_dir"
        fi
    }
    trap cleanup EXIT

    # Get staged content for each file
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            # Create the directory structure
            mkdir -p "$(dirname "$temp_dir/$file")"
            git show ":$file" > "$temp_dir/$file"
        fi
    done <<< "$files"

    # Check for AWS Access Keys (20 uppercase alphanumeric characters)
    if rg '[A-Z0-9]{20}' "$temp_dir" --no-messages --with-filename; then
        echo -e "${RED}❌ Potential AWS Access Key found${NC}"
        found_secrets=1
    fi

    # Check for AWS Secret Keys (40 base64 characters)
    if rg '[A-Za-z0-9+/]{40}' "$temp_dir" --no-messages --with-filename; then
        echo -e "${RED}❌ Potential AWS Secret Key found${NC}"
        found_secrets=1
    fi

    # Check for API tokens and keys
    if rg -i '(api_key|api_token|access_token|secret_key)\s*=\s*[A-Za-z0-9+/]{32,}' "$temp_dir" --no-messages --with-filename; then
        echo -e "${RED}❌ Potential API token/key found${NC}"
        found_secrets=1
    fi

    # Check for Private keys
    if rg -e "BEGIN.*PRIVATE KEY" "$temp_dir" --no-messages --with-filename; then
        echo -e "${RED}❌ Potential private key found${NC}"
        found_secrets=1
    fi

    # Check for Generic passwords
    if rg -i '(password|passwd|pwd)\s*=\s*['"'"'"][^'"'"'"]*['"'"'"]' "$temp_dir" --no-messages --with-filename; then
        echo -e "${RED}❌ Potential password found${NC}"
        found_secrets=1
    fi

    # Check for Environment variables containing secrets
    if rg -i 'export\s+(API_KEY|SECRET|TOKEN|PASSWORD)\s*=' "$temp_dir" --no-messages --with-filename; then
        echo -e "${RED}❌ Potential secret in environment variable found${NC}"
        found_secrets=1
    fi
fi

if [[ $found_secrets -eq 0 ]]; then
  echo -e "${GREEN}✓ No secrets detected${NC}"
  exit 0
else
  echo -e "${YELLOW}⚠️  Please remove any sensitive data before committing!${NC}"
  exit 1
fi
