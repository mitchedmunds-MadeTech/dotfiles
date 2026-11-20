# Interactive bash. Settings shared with zsh live in ~/.config/shell/*.sh;
# bash-only ones in ~/.config/shell/bash/*.bash.
case $- in
    *i*) ;;
    *) return ;;
esac

# Distro defaults (Debian/Ubuntu/Amazon Linux ship useful bits here).
[ -r /etc/bashrc ] && . /etc/bashrc

# bash-completion: Homebrew's, then the distro's.
if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
    . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
elif [ -r /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

DOTFILES_SHELL=bash
for FILE in "$HOME"/.config/shell/*.sh "$HOME"/.config/shell/functions/*.sh "$HOME"/.config/shell/bash/*.bash; do
    [ -r "$FILE" ] && . "$FILE"
done
unset FILE
