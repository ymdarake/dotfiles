# .zshrc
export PS1="%10F%m%f:%09F%1~%f \$ "

# Built-in commands
alias ll='ls -GFhla'
alias cl='clear'
alias grep='grep --color=auto'

# Custom commands
alias cdpr='cd ~/dev/projects'

alias dup='docker-compose up -d'
alias dwn='docker-compose down'

alias nrs='npm run serve'
