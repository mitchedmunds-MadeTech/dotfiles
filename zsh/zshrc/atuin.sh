# Atuin: encrypted shell history with better Ctrl-R search.
# --disable-up-arrow keeps general.sh's up-line-or-beginning-search binding on Up.
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi
