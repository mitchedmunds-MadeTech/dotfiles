# Interactive zsh. Settings shared with bash live in ~/.config/shell/*.sh;
# zsh-only ones in ~/.config/shell/zsh/*.zsh.
# Split inspired by https://medium.com/codex/how-and-why-you-should-split-your-bashrc-or-zshrc-files-285e5cc3c843
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
setopt interactivecomments

DOTFILES_SHELL=zsh
for FILE in ~/.config/shell/*.sh(N) ~/.config/shell/functions/*.sh(N) ~/.config/shell/zsh/*.zsh(N); do
    source "$FILE"
done
unset FILE
