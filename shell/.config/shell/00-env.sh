# Env vars. Sourced first (the 00- prefix) by both ~/.zshrc and ~/.bashrc.
[ -x /usr/libexec/java_home ] && JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null) && export JAVA_HOME
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
unset LESS

# Caps pytest-xdist's `-n auto` so several sessions running pytest at once
# share the cores and memory rather than oversubscribing them.
export PYTEST_XDIST_AUTO_NUM_WORKERS=4

# Move a directory to the front of PATH, dropping any later copy of it.
_dotfiles_path_prepend() {
    local dir="$1" rest=":$PATH:"
    [ -d "$dir" ] || return 0
    while case "$rest" in *":$dir:"*) true ;; *) false ;; esac; do
        rest="${rest/":$dir:"/:}"
    done
    rest="${rest#:}"; rest="${rest%:}"
    PATH="$dir${rest:+:$rest}"
    export PATH
}

# macOS's /etc/zprofile and /etc/profile run path_helper, which puts the
# /etc/paths directories first. ~/.local/bin then sits behind /usr/bin, where
# `python3` is the Command Line Tools build rather than the uv-managed default.
_dotfiles_path_prepend "$HOME/.local/bin"
# GNU coreutils from Homebrew, when installed, over the BSD ones.
[ -n "${HOMEBREW_PREFIX:-}" ] && _dotfiles_path_prepend "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"

# 1Password SSH agent (macOS host only).
# In devcontainers VS Code forwards $SSH_AUTH_SOCK itself, so this guard
# skips and we use the forwarded socket.
_op_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
[ -S "$_op_sock" ] && export SSH_AUTH_SOCK="$_op_sock"
unset _op_sock

# Node via nvm, when installed.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# mise: per-directory tool versions from mise.toml, ~/.config/mise as the default
command -v mise >/dev/null 2>&1 && eval "$(mise activate "$DOTFILES_SHELL")"
