# 1. Define the path for GNU bin
GNU_PATH="/opt/homebrew/opt/coreutils/libexec/gnubin"
[[ -d "$GNU_PATH" ]] && export PATH="$GNU_PATH:$PATH"

# 2. Check if the specific file exists OR if it's in the path
if [[ -x "$GNU_PATH/dircolors" ]] || command -v dircolors >/dev/null; then

  # Check for ~/.dircolors, use -b for Zsh/Bash compatible output
  if [[ -f "$HOME/.dircolors" ]]; then
    eval "$(dircolors -b "$HOME/.dircolors")"
  else
    eval "$(dircolors -b)"
  fi

    # Set common color aliases (GNU ls uses --color)
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias act='. .venv/bin/activate'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias reload='. ~/.zshrc'
