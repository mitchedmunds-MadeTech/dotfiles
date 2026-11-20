# Login environment shared by every shell. POSIX sh only: bash reads this via
# ~/.bash_profile, zsh via ~/.zprofile, and Linux display managers run it
# under dash.

# Homebrew: Apple Silicon, Intel macOS, then Linuxbrew.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew \
             /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$_brew" ]; then
        eval "$("$_brew" shellenv)"
        break
    fi
done
unset _brew

[ -d "$HOME/.local/bin" ] && case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH"; export PATH ;;
esac
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# mise's shims, for editors and other apps that run without an interactive shell
if command -v mise >/dev/null 2>&1; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(mise activate zsh --shims)"
    else
        eval "$(mise activate bash --shims)"
    fi
fi
