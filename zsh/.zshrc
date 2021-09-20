HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

#------------------------------------------------------------------------------
# User configuration
#------------------------------------------------------------------------------

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
export LESS="-F -X $LESS"