HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY        # Record timestamp of each command
setopt SHARE_HISTORY           # Share history across sessions
setopt INC_APPEND_HISTORY      # Append to history file immediately, not on shell exit
setopt HIST_IGNORE_DUPS        # Don't record consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS    # Drop older duplicate of a repeated command
setopt HIST_IGNORE_SPACE       # Don't record commands prefixed with a space
setopt HIST_REDUCE_BLANKS      # Strip extra whitespace from recorded commands
setopt HIST_VERIFY             # On expansion, reload the command line for editing instead of running
