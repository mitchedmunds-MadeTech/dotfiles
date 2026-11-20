# Atuin: encrypted shell history with better Ctrl-R search.
# --disable-up-arrow keeps Up on the shell's own prefix search.
# bash needs bash-preexec or ble.sh loaded first for atuin's hooks to fire.
if command -v atuin >/dev/null 2>&1; then
    if [ "$DOTFILES_SHELL" = zsh ]; then
        eval "$(atuin init zsh --disable-up-arrow)"
    elif [ -n "${bash_preexec_imported:-}${BLE_VERSION:-}" ]; then
        eval "$(atuin init bash --disable-up-arrow)"
    fi
fi
