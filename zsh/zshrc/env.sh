# Env vars
[[ -x /usr/libexec/java_home ]] && export JAVA_HOME=$(/usr/libexec/java_home)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# macOS /etc/zprofile runs path_helper, which rebuilds PATH with the /etc/paths
# directories first and everything already present pushed behind them. ~/.profile
# has added ~/.local/bin by then, so uv's env script finds it present and leaves
# it where path_helper put it — behind /usr/bin, where `python3` is the 3.9
# Command Line Tools build rather than the uv-managed default. Re-prepend after
# the fact; typeset -U keeps the first occurrence and drops the stale one.
typeset -U path PATH
path=("$HOME/.local/bin" $path)

# 1Password SSH agent (macOS host only).
# In devcontainers VS Code forwards $SSH_AUTH_SOCK itself, so this guard
# skips and we use the forwarded socket.
_op_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
[[ -S "$_op_sock" ]] && export SSH_AUTH_SOCK="$_op_sock"
unset _op_sock
