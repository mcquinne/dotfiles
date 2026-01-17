#!/bin/bash

# default settings
DOTFILES_PROFILE=${DOTFILES_PROFILE:-default}
DOTFILES_SRC=${DOTFILES_SRC:-https://github.com/mcquinne/dotfiles.git}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-main}

banner() {
cat <<"EOF"

   __| | ___ | |_ / _(_) | ___  ___
  / _` |/ _ \| __| |_| | |/ _ \/ __|
 | (_| | (_) | |_|  _| | |  __/\__ \
  \__,_|\___/ \__|_| |_|_|\___||___/

EOF
}

dotfiles() {
  git --git-dir=$HOME/.dotfiles --work-tree=$HOME $@
}

error_exit() {
  echo $1
  exit ${2:-1}
}

preflight() {
  command -v git > /dev/null || error_exit "ERROR: git not found, install git and try again."
  command -v curl > /dev/null || error_exit "ERROR: curl not found, install curl and try again."
}

install() {
  preflight
  if [ ! -d $HOME/.dotfiles ]; then
    git clone --bare $DOTFILES_SRC $HOME/.dotfiles
    dotfiles config --local core.sparseCheckout true
    dotfiles config --local status.showUntrackedFiles no
    cat > $HOME/.dotfiles/info/sparse-checkout <<EOF
/*
!LICENSE
!README.md
!install*
!dotfiles.*cfg
!Dccuments*
!AppData*
!**/*.ps1
EOF

    # exclude macosx only config
    if [[ $OSTYPE != darwin* ]]; then
      cat >> $HOME/.dotfiles/info/sparse-checkout << EOF
!Library
!.iterm2
EOF
    fi
  fi
  
  dotfiles checkout
  if [ $? = 0 ]; then
    echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dotfiles-backup/{}
  fi

  # dotfiles settings
  echo "export DOTFILES_PROFILE=$DOTFILES_PROFILE" > $HOME/.dotfiles_settings
}

# initialze vim
init_vim() {
  if command -v vim &> /dev/null && \
    ! [ -d "$HOME/.vim/bundle/Vundle.vim" ]; then
    vim || [ -d "$HOME/.vim/bundle/Vundle.vim" ]
  fi
}

main() {
  if [ -e "$DOTFILES_CFG" ]; then
    source $DOTFILES_CFG
  elif [ -e "dotfiles.$PROFILE.cfg" ]; then
    source dotfiles.$PROFILE.cfg
  else
    true
  fi

  install
  source $HOME/.dotfiles_settings

#   init_vim
  banner
  echo "Installed!"
}

main
