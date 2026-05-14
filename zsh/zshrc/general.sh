# Search history binds
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down

# Move between words (Option + Left/Right)
bindkey "^[b" backward-word
bindkey "^[f" forward-word
# Delete word backward (Option + Backspace)
bindkey "^[^?" backward-kill-word
# Word Deletion (Forward: Option + Del)
bindkey '^[\(' kill-word
# Windows-style Line Clear (Escape key)
bindkey '\e' kill-whole-line
# Undo and Redo (Windows style but using Option)
bindkey "^[z" undo
bindkey "^[y" redo
