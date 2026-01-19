# we're zsh
export MYSHELL='zsh'

# No beeps
unsetopt BEEP

# Autoload compinit
autoload -U compinit
compinit -u

## Correct command spelling errors
setopt correct
unsetopt correctall

# Autoload functions
# fpath=($HOME/.shell/functions $fpath)
# autoload -U $HOME/.shell/functions/*(:t)

# Source shell includes
ZSH_INCLUDES=$HOME/.shell/includes
while read -r file; do
  source "$file"
done < <(find ${ZSH_INCLUDES} -type f | sort)
