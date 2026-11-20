# Prompt theme. oh-my-posh's bash init needs bash 4.2+, so macOS's /bin/bash
# (3.2) keeps the default prompt; `brew install bash` for a newer one.
if command -v oh-my-posh >/dev/null 2>&1 \
    && { [ "$DOTFILES_SHELL" = zsh ] \
         || [ "${BASH_VERSINFO[0]}${BASH_VERSINFO[1]}" -ge 42 ] 2>/dev/null; }; then
    eval "$(oh-my-posh init "$DOTFILES_SHELL" --config ~/.ohmyposhthemes/montys.omp.json)"
fi

if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook "$DOTFILES_SHELL")"
fi
