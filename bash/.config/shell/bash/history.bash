# bash counterpart of zsh/history.zsh.
HISTFILE="$HOME/.bash_history"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignorespace:erasedups   # skip space-prefixed commands, drop older duplicates
HISTTIMEFORMAT='%F %T '              # record timestamps
shopt -s histappend                  # append rather than overwrite on exit
shopt -s histverify                  # on expansion, reload the line for editing instead of running
shopt -s checkwinsize

# Append each command as it runs, so sessions share history like zsh's SHARE_HISTORY.
case ";${PROMPT_COMMAND:-};" in
    *"history -a"*) ;;
    *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
