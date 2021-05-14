# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

autoload bashcompinit && bashcompinit -u
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select

export ANTIGEN_INIT="$HOME/.antigen.zsh"
if [[ ! -f $ANTIGEN_INIT ]]; then
  echo "downloading antigen"
  curl -L git.io/antigen-nightly > "$ANTIGEN_INIT"
fi
export ANTIGEN_COMPINIT_OPTS="-u"
source "$ANTIGEN_INIT"

antigen bundle zsh-users/zsh-autosuggestions
antigen theme romkatv/powerlevel10k

antigen apply

source ~/code/aws/nesdis-osgs-osis-dev-5045/dev-nccf-automation/utils/mfa_functions.sh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/evan.mcquinn/.sdkman"
[[ -s "/Users/evan.mcquinn/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/evan.mcquinn/.sdkman/bin/sdkman-init.sh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

