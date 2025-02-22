# Created by newuser for 5.8.1
# .zshrc
autoload -Uz compinit
compinit

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

alias ls='ls --color=auto'
alias ll='ls -la'
alias l='ls -l'

PS1='%n@%m:%~$ '
