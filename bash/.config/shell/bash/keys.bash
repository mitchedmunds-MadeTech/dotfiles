# bash counterpart of zsh/keys.zsh, through readline.
bind '"\e[A": history-search-backward'   # Up: prefix search
bind '"\e[B": history-search-forward'    # Down
bind '"\eb": backward-word'              # Option+Left
bind '"\ef": forward-word'               # Option+Right
bind '"\e\C-?": backward-kill-word'      # Option+Backspace
bind '"\ez": undo'                       # Option+z
