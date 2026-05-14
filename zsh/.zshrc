# Used this guide: https://medium.com/codex/how-and-why-you-should-split-your-bashrc-or-zshrc-files-285e5cc3c843
# Settings managed in zshrc folder
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
setopt interactivecomments

for FILE in ~/zshrc/**/*; do
    source $FILE
done

unset LESS;

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
