
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"
# mise's shims, for editors and other apps that run without an interactive shell
[[ -x /opt/homebrew/bin/mise ]] && eval "$(/opt/homebrew/bin/mise activate zsh --shims)"
