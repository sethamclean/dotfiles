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
zinit ice depth=1; zinit light spaceship-prompt/spaceship-prompt
zinit light zsh-users/zsh-autosuggestions
zinit light dracula/zsh
zinit light Aloxaf/fzf-tab

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
# Pyenv
#------------------------------------------------------------------------------
if [ -z $POETRY_ACTIVE ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command -v pyenv 1>/dev/null 2>&1; then
      eval "$(pyenv init -)"
    fi
fi

pyinstall(){
 PYTHON_CONFIGURE_OPTS='--enable-shared' LDFLAGS="-Wl,-rpath=$HOME/.pyenv/versions/$1/lib" pyenv install $1
}

#------------------------------------------------------------------------------
# Bin
#------------------------------------------------------------------------------
export PATH="$PATH:$HOME/bin/"

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
export FZF_CTRL_T_COMMAND="fd --type f -H -L --search-path /workspaces --search-path /root --search-path $PWD"
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
if [ "$TMUX" = "" ]; then tmux new-session -A -s main; fi

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
# Auto completion
#------------------------------------------------------------------------------
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit

#------------------------------------------------------------------------------
# AWS autocomplete
#------------------------------------------------------------------------------
complete -C '/usr/sbin/aws_completer' aws
