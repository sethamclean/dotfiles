#!/usr/bin/env zsh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Thresholds in seconds (as integers representing tenths of a second)
ZSH_THRESHOLD=5  # 0.5 seconds
NVIM_THRESHOLD=3 # 0.3 seconds

# Test zsh startup time
{
  # Capture user CPU time in tenths of a second
  typeset -F SECONDS=0
  $(which zsh) -i -c exit
  integer zsh_time=$(printf "%.0f" $(( SECONDS * 10 )))
  echo "Zsh startup time: 0.${zsh_time}s"
  if (( zsh_time > ZSH_THRESHOLD )); then
    echo -e "${RED}❌ Zsh startup time (0.${zsh_time#-}s) exceeds threshold of 0.${ZSH_THRESHOLD}s${NC}"
    exit 1
  else
    echo -e "${GREEN}✓ Zsh startup time OK${NC}"
  fi
}

# Test neovim startup time
{
  typeset -F SECONDS=0
  $(which nvim) --headless -c 'quit'
  integer nvim_time=$(printf "%.0f" $(( SECONDS * 10 )))
  echo "Neovim startup time: 0.${nvim_time}s"
  if (( nvim_time > NVIM_THRESHOLD )); then
    echo -e "${RED}❌ Neovim startup time (0.${nvim_time#-}s) exceeds threshold of 0.${NVIM_THRESHOLD}s${NC}"
    exit 1
  else
    echo -e "${GREEN}✓ Neovim startup time OK${NC}"
  fi
}

exit 0
