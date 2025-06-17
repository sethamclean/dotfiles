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
source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

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
  dracula/zsh \
  Aloxaf/fzf-tab \
  loiccoyle/zsh-github-copilot

#------------------------------------------------------------------------------
# ZSH copilot settings
#------------------------------------------------------------------------------
bindkey '^[|' zsh_gh_copilot_explain  # bind Alt+shift+\ to explain
bindkey '^[\' zsh_gh_copilot_suggest  # bind Alt+\ to suggest

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
alias grep='grep --color=tty -d skip'
alias cp='cp -i'
alias vim='nvim'
alias vi='nvim'
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
export PATH="$PATH:$(npm config get prefix)/bin"
#------------------------------------------------------------------------------
# Bin
#------------------------------------------------------------------------------
export PATH="$HOME/bin/:$PATH"

#------------------------------------------------------------------------------
# Go Bin
#------------------------------------------------------------------------------
export PATH="$PATH:$HOME/go/bin/"

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
if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    #ps ${SSH_AGENT_PID} doesn't work under cywgin
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

#------------------------------------------------------------------------------
# less
#------------------------------------------------------------------------------
export LESS="eFRX"

#------------------------------------------------------------------------------
# Code not vi
#------------------------------------------------------------------------------
if [ "$TERM_PROGRAM" = "vscode" ]; then
  alias vi='code $@'
fi

#------------------------------------------------------------------------------
# FZF
#------------------------------------------------------------------------------
fzf_completions_path=/usr/share/fzf
if [ -d "$HOME/.nix-profile/share/fzf" ]; then
	fzf_completions_path=$HOME/.nix-profile/share/fzf
fi
source ${fzf_completions_path}/key-bindings.zsh
source ${fzf_completions_path}/completion.zsh
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
# Install GitHub CLI plugins
#------------------------------------------------------------------------------
if [ -x "$(which gh)" ]; then
    if ! gh extension list | grep -q "github/gh-copilot"; then
        gh extension install github/gh-copilot
    fi
fi

#------------------------------------------------------------------------------
# Auto start tmux
#------------------------------------------------------------------------------
# Simple tmux auto-start: attach if session exists, otherwise create
if [ -z "$TMUX" ] && [ -z "$TMUX_RESURRECT_RESTORE" ]; then
  if tmux has-session 2>/dev/null; then
    tmux attach
  else
    tmux new-session -s main
  fi
fi

#------------------------------------------------------------------------------
#`Zoxide`settings
#------------------------------------------------------------------------------
if [ -x "$(which zoxide)" ];
then
    function cd () {
      __zoxide_z $@
    }
    eval "$(zoxide init zsh)"
fi
export _ZO_FZF_OPTS="--preview 'exa -Tlo --time-style=iso --no-filesize --no-permissions --icons=always --color=always {2..}'"

#------------------------------------------------------------------------------
# zsh cd path
#------------------------------------------------------------------------------
setopt auto_cd
cdpath=($HOME /workspaces .. ../..)
autoload -U compinit 
compinit

#------------------------------------------------------------------------------
# Bat
#------------------------------------------------------------------------------
alias cat='bat'

#------------------------------------------------------------------------------
# Optimize compinit and completion loading
#------------------------------------------------------------------------------
# Only check for new completions once a day
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

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
