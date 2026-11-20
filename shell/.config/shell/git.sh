# Git aliases
alias gs='git status'
alias ga='git add'
alias gb='git branch'
alias gc='git commit'
alias gca='git commit --amend'
alias gcaf='git commit --amend --no-edit'
alias gcs='SKIP=flake8,pydocstyle git commit'
alias gcsf='SKIP=flake8 git commit'
alias gcsdoc='SKIP=pydocstyle git commit'
alias gcsmsg='SKIP=prepare_commit_msg git commit'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gr='git restore'
alias grs='git restore --staged'
alias gp='git push'
alias gpu='git push -u origin HEAD'
alias gf='git fetch'
alias gpl='git pull'
alias grh='git reset HEAD'
alias gsl='git stash list'
alias gspu='git stash push -m'
alias gspo='git stash pop'
alias install_hooks='pre-commit install; pre-commit install --hook-type prepare-commit-msg --hook-type commit-msg'
alias remove_hooks='pre-commit uninstall; pre-commit uninstall --hook-type prepare-commit-msg --hook-type commit-msg'
alias gsync='git fetch upstream;git rebase upstream/main'
alias gmm='git fetch origin;git merge origin/main'

# Complete `gco` like `git checkout`.
if [ "$DOTFILES_SHELL" = zsh ]; then
    compdef _git gco=git-checkout
elif command -v __git_complete >/dev/null 2>&1; then
    __git_complete gco _git_checkout
fi
