# Use powerline
USE_POWERLINE="true"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi

# Built-in commands
alias ll='ls -GFhla'
alias cl='clear'
alias grep='grep --color=auto'

# Custom commands
alias cdpr='cd ~/workspace/projects'

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


