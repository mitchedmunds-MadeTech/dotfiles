# Env vars
[[ -x /usr/libexec/java_home ]] && export JAVA_HOME=$(/usr/libexec/java_home)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
