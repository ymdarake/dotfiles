# Use powerline
USE_POWERLINE="true"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
else
  export PS1="%10F%m%f:%09F%1~%f \$ "
fi

# Built-in commands
alias ll='ls -GFhla'
alias cl='clear'
alias grep='grep --color=auto'

# Custom commands
alias cdpr='cd ~/workspace/projects'
alias cdw='cd ~/workspace'

alias dup='docker-compose up -d'
alias dwn='docker-compose down'

alias nrs='npm run serve'

alias exa='exa -laT --icons --git-ignore -I .git'

# Langs

############ goenv ############
if [[ -e "$HOME/.goenv" ]]; then
# https://github.com/syndbg/goenv/blob/master/INSTALL.md
# git clone https://github.com/syndbg/goenv.git ~/.goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"
fi
###############################


######### Android #######
alias adb='~/Library/Android/sdk/platform-tools/adb'
#########################

export PATH="$PATH:/Users/ymdarake/workspace/meta/flutter/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion




export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"


# Secrets (optional)
if [[ -f "$HOME/.config/zsh/secrets.zsh" ]]; then
  source "$HOME/.config/zsh/secrets.zsh"
fi
if [[ -f "$HOME/.config/zsh/secrets.local.zsh" ]]; then
  source "$HOME/.config/zsh/secrets.local.zsh"
fi

# Added by Antigravity
export PATH="/Users/ymdarake/.antigravity/antigravity/bin:$PATH"

# Claude binary location
export PATH="$HOME/.local/bin:$PATH"


export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH=$PATH:$HOME/.maestro/bin
