# Colours: GNU ls/grep (Linux, or Homebrew coreutils put first by 00-env.sh)
# take --color; macOS's BSD ls takes -G.
if command -v dircolors >/dev/null 2>&1; then
    if [ -f "$HOME/.dircolors" ]; then
        eval "$(dircolors -b "$HOME/.dircolors")"
    else
        eval "$(dircolors -b)"
    fi
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
elif [ "$(uname -s)" = Darwin ]; then
    alias ls='ls -G'
fi

alias act='. .venv/bin/activate'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
if [ "$DOTFILES_SHELL" = zsh ]; then
    alias reload='. ~/.zshrc'
else
    alias reload='. ~/.bashrc'
fi
