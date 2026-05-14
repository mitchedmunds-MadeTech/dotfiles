# Env vars
[[ -x /usr/libexec/java_home ]] && export JAVA_HOME=$(/usr/libexec/java_home)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# 1Password SSH agent (macOS host only).
# In devcontainers VS Code forwards $SSH_AUTH_SOCK itself, so this guard
# skips and we use the forwarded socket.
_op_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
[[ -S "$_op_sock" ]] && export SSH_AUTH_SOCK="$_op_sock"
unset _op_sock
