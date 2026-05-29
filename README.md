mcquinne/dotfiles
========

This is my `dotfiles`.  There are many like it, but this one is mine.

My dotfiles are installed and managed with Git.

**WARNING** This is my personal collection of dotfiles.  You're welcome 
to use it, but I don't recommend using it as-is or without understanding
what it does. This will clobber files in your home directory.

## Installation

```
curl -sL https://raw.githubusercontent.com/mcquinne/dotfiles/refs/heads/main/install.sh | bash
```

Or, if you prefer to look before leaping...

```
git clone https://github.com/mcquinne/dotfiles.git
cd dotfiles
./install.sh
```

# Updating

To update:

```
dotfiles update
```

## Organization

Everything in this project will be installed as-is to the corresponding file
under the home directory with a few exceptions (this file and the `install.sh` script).

Any pre-exsitsing files of the same name will be copied to `~/.dotfiles-backup`, then replaced.

## MacOSX

Files that are specific for MacOSX are excluded from other operating systems using Git sparse checkouts.  This behavior is controlled by the `install.sh` script.

## Local config

On occasion, some local settings may be desired outside of version control.  These can be added to the following files:

* `.bashrc.[pre|post]` - Local Bash includes, either before or after definitions in `.bashrc`
* `.zshrc.[pre|post]` - Local ZSH includes, either before or after definitions in `.zshrc`
* `.gitconfig.local` - Local Git Configuration
