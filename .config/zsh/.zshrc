#------------------------------------------------------------------------------
# zinit
#------------------------------------------------------------------------------
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma-continuum
/zinit)…%f"
    command mkdir -p $HOME/.zinit
    command git clone https://github.com/zdharma-continuum/zinit $HOME/.zinit/bin && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%F" || \
        print -P "%F{160}▓▒░ The clone has failed.%F"
fi
if [[ -f "$HOME/.zinit/bin/zinit.zsh" ]]; then
  source "$HOME/.zinit/bin/zinit.zsh"
  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit
elif [[ -o interactive ]]; then
  print -P "%F{160}▓▒░ zinit unavailable; continuing without plugin manager.%f"
fi

#------------------------------------------------------------------------------
# zsh plugins via zinit
#------------------------------------------------------------------------------
# Load prompt immediately
zinit ice depth=1; zinit light spaceship-prompt/spaceship-prompt

# Turbo mode - load plugins after shell startup
zinit wait lucid light-mode for \
  atinit"ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20" \
  atload"_zsh_autosuggest_start" \
  zsh-users/zsh-autosuggestions \
  Aloxaf/fzf-tab \

#------------------------------------------------------------------------------
# ZSH copilot settings
#------------------------------------------------------------------------------
if (( ${+widgets[zsh_gh_copilot_explain]} )); then
  bindkey '^[|' zsh_gh_copilot_explain  # bind Alt+shift+\ to explain
fi
if (( ${+widgets[zsh_gh_copilot_suggest]} )); then
  bindkey '^[\' zsh_gh_copilot_suggest  # bind Alt+\ to suggest
fi

#------------------------------------------------------------------------------
# Theme settings
#------------------------------------------------------------------------------
export SPACESHIP_VI_MODE_SHOW="0"

#------------------------------------------------------------------------------
# User configuration
#------------------------------------------------------------------------------
export HYPHEN_INSENSITIVE="true"
export ENABLE_CORRECTION="true"
export COMPLETION_WAITING_DOTS="true"
export HIST_STAMPS="yyyy-mm-dd"
export HISTFILE=~/.zsh_history
export HISTFILESIZE=100000000
export HISTSIZE=100000000
export SAVEHIST=100000000
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt appendhistory
setopt SHARE_HISTORY
export HISTTIMEFORMAT="[%F %T] "
set -o vi

#------------------------------------------------------------------------------
# Custom bindings and exports
#------------------------------------------------------------------------------
alias grep='grep --color=auto'
alias cp='cp -i'
alias vim='nvim'
alias vi='nvim'
oc() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)"

  if [[ -n "$root" ]]; then
    (cd "$root" && opencode -c "$@")
  else
    opencode -c "$@"
  fi
}
clip() {
  if [[ -n "$TMUX" ]] && (( ${+commands[tmux]} )); then
    tmux load-buffer -w -
  else
    python -c 'import base64,sys; data=sys.stdin.buffer.read(); print(f"\033]52;c;{base64.b64encode(data).decode()}\a", end="")'
  fi
}
alias rm='rm --one-file-system --preserve-root'

export EDITOR=nvim
export VISUAL=nvim

#------------------------------------------------------------------------------
# uv - Python package installer and environment management
#------------------------------------------------------------------------------
export UV_CACHE_DIR="$HOME/.cache/uv"

#------------------------------------------------------------------------------
# Node path
#------------------------------------------------------------------------------
typeset -U path
typeset -g npm_prefix=""
if [[ -n "${NPM_CONFIG_PREFIX:-}" ]]; then
  npm_prefix="$NPM_CONFIG_PREFIX"
elif [[ -f "$HOME/.npmrc" ]]; then
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue

    case "$line" in
      prefix=*)
        npm_prefix="${line#prefix=}"
        ;;
      prefix\ =\ *)
        npm_prefix="${line#prefix = }"
        ;;
    esac

    [[ -n "$npm_prefix" ]] && break
  done < "$HOME/.npmrc"
fi

if [[ -z "$npm_prefix" ]]; then
  npm_prefix="$HOME/.local"
fi

if [[ -d "$npm_prefix/bin" ]]; then
  path+=("$npm_prefix/bin")
fi
#------------------------------------------------------------------------------
# Bin
#------------------------------------------------------------------------------
path=("$HOME/bin" $path)

#------------------------------------------------------------------------------
# Go Bin
#------------------------------------------------------------------------------
path+=("$HOME/go/bin")

#------------------------------------------------------------------------------
# SSH agent
#------------------------------------------------------------------------------
SSH_ENV="$HOME/.ssh/environment"
function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}
# Source SSH settings, if applicable
if [[ -f "${SSH_ENV}" ]]; then
    . "${SSH_ENV}" > /dev/null
fi

if [[ -z "${SSH_AGENT_PID:-}" || -z "${SSH_AUTH_SOCK:-}" || ! -S "${SSH_AUTH_SOCK}" ]] || ! kill -0 "${SSH_AGENT_PID}" 2>/dev/null; then
    if [[ -o interactive ]] && [[ -t 0 ]] && [[ -t 1 ]] && (( ${+commands[ssh-agent]} )); then
        start_agent
    fi
fi

#------------------------------------------------------------------------------
# less
#------------------------------------------------------------------------------
export LESS="eFRX"

#------------------------------------------------------------------------------
# FZF
#------------------------------------------------------------------------------
fzf_completions_path=/usr/share/fzf
if [ -d "$HOME/.nix-profile/share/fzf" ]; then
	fzf_completions_path=$HOME/.nix-profile/share/fzf
fi
if [[ -z "${ZSH_BENCHMARK_MODE:-}" ]]; then
  if [[ -f "${fzf_completions_path}/key-bindings.zsh" ]]; then
    source "${fzf_completions_path}/key-bindings.zsh"
  fi
  if [[ -f "${fzf_completions_path}/completion.zsh" ]]; then
    source "${fzf_completions_path}/completion.zsh"
  fi
fi
export FZF_DEFAULT_COMMAND="fd --type f -H -L --search-path /workspaces --search-path /root --search-path $PWD"
export FZF_DEFAULT_OPTS='--height 80% --layout=reverse --border'
export FZF_ALT_C_COMMAND="fd --type d -H -L --search-path /workspaces --search-path /root --search-path $PWD"
export FZF_ALT_C_OPTS="--preview 'fd -H -L . {} | exa -Tlo --git-ignore --time-style=iso --no-filesize --no-permissions --icons=always --color=always --stdin'"
export FZF_CTRL_T_COMMAND="fd -H -L --search-path /workspaces --search-path /root --search-path $PWD"
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"


#------------------------------------------------------------------------------
# Exa alias
#------------------------------------------------------------------------------
alias ls='exa -alo --time-style=iso --no-permissions --icons=always --color=always'
alias lst='exa -aTlo --git-ignore --time-style=iso --no-filesize --no-permissions --icons=always --color=always'

#------------------------------------------------------------------------------
# Don't use codespaces GITHUB_TOKEN
#------------------------------------------------------------------------------
unset GITHUB_TOKEN

#------------------------------------------------------------------------------
# Auto start tmux
#------------------------------------------------------------------------------
# Simple tmux auto-start: interactive TTY only; skip local WezTerm mux panes
if [[ -o interactive ]] && [[ -t 0 ]] && [[ -t 1 ]] && (( ${+commands[tmux]} )); then
  is_ssh_session=0
  is_wezterm_mux_session=0

  if [[ -n "$SSH_CONNECTION" ]]; then
    is_ssh_session=1
  fi

  if [[ -n "$WEZTERM_PANE" && "$is_ssh_session" -eq 0 ]]; then
    is_wezterm_mux_session=1
  fi

  if [[ -z "$TMUX" && -z "$TMUX_RESURRECT_RESTORE" && "$is_wezterm_mux_session" -eq 0 ]]; then
    if tmux has-session 2>/dev/null; then
      tmux attach
    else
      tmux new-session -s main
    fi
  fi
fi

#------------------------------------------------------------------------------
#`Zoxide`settings
#------------------------------------------------------------------------------
if (( ${+commands[zoxide]} )); then
    function cd () {
      __zoxide_z "$@"
    }
    eval "$(zoxide init zsh)"
fi
export _ZO_FZF_OPTS="--preview 'exa -Tlo --time-style=iso --no-filesize --no-permissions --icons=always --color=always {2..}'"

#------------------------------------------------------------------------------
# zsh cd path
#------------------------------------------------------------------------------
setopt auto_cd
cdpath=($HOME /workspaces .. ../..)

#------------------------------------------------------------------------------
# Bat
#------------------------------------------------------------------------------
alias cat='bat'

#------------------------------------------------------------------------------
# Optimize compinit and completion loading
#------------------------------------------------------------------------------
autoload -U compinit
compinit -C

zsh_refresh_compinit() {
  rm -f "${ZDOTDIR:-$HOME}/.zcompdump"
  compinit
}

# Load bashcompinit only if needed (for AWS completion)
if [[ -x /usr/sbin/aws_completer ]]; then
  autoload bashcompinit && bashcompinit
  complete -C '/usr/sbin/aws_completer' aws
fi

#------------------------------------------------------------------------------
# Searxng config
#------------------------------------------------------------------------------
export SEARXNG_API_URL="http://localhost:8080/search"

#------------------------------------------------------------------------------
# Quick Reference Documentation
#------------------------------------------------------------------------------
quickref() {
  local edit_mode=0
  local query=""
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -e|--edit)
        edit_mode=1
        shift
        ;;
      *)
        query="$1"
        shift
        ;;
    esac
  done

  local ref_dir=~/Documents/obsidian-vault/main/quick-ref
  
  if [[ -d "$ref_dir" ]]; then
    if [[ -z "$query" ]]; then
      # If no search query is provided, show all files with fzf
      local selected_file=$(find "$ref_dir" -type f | fzf --preview 'bat -n --color=always {}')
    else
      # If search query is provided, use it as search term for fzf
      local selected_file=$(find "$ref_dir" -type f | fzf -q "$query" -1 --preview 'bat -n --color=always {}')
    fi

    if [[ -n "$selected_file" ]]; then
      if [[ $edit_mode -eq 1 ]]; then
        nvim "$selected_file"
      else
        bat --paging=always "$selected_file"
      fi
    elif [[ -n "$query" ]]; then
      echo "No matching reference file found for: $query"
    fi
  else
    echo "Reference directory not found: $ref_dir"
    echo "Please create it and add your reference files."
  fi
}
#------------------------------------------------------------------------------
# AWS Profile 
#------------------------------------------------------------------------------
# Source AWS profile from .env_aws_profile if it exists
if [[ -f "$HOME/.env_aws_profile" ]]; then
  source "$HOME/.env_aws_profile"
fi

#------------------------------------------------------------------------------
# AWS Profile selector with fzf
#------------------------------------------------------------------------------
aws-profile() {
  local profile=$(aws configure list-profiles | fzf --height 40% --layout=reverse --border)
  if [[ -n "$profile" ]]; then
    echo "export AWS_PROFILE=$profile" > "$HOME/.env_aws_profile"
    source "$HOME/.env_aws_profile"
    echo "AWS Profile set to: $profile and written to ~/.env_aws_profile"
  fi
}

#------------------------------------------------------------------------------
# Vectorcode configuration
#------------------------------------------------------------------------------
export VECTOR_DB_URI="chromadb://localhost:8000"


#------------------------------------------------------------------------------
# direnv bootstrap
#------------------------------------------------------------------------------
if (( ${+commands[direnv]} )); then
  eval "$(direnv hook zsh)"
fi
