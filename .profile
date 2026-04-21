# ~/.profile: executed by Bourne-compatible login shells.
bashrc=~/.bashrc
if [ "$BASH" ] && [ -t 1 ] && [ -z "${ZSH_VERSION:-}" ]; then
  if command -v zsh >/dev/null 2>&1; then
    exec zsh
  elif [ -f "${bashrc}" ]; then
    . "${bashrc}"
  fi
fi

# mesg n 2> /dev/null || true
