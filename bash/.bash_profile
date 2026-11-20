# bash reads only this file for login shells (macOS Terminal, ssh), so pull in
# the shared login environment, then the interactive config.
[ -r "$HOME/.profile" ] && . "$HOME/.profile"
case $- in
    *i*) [ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc" ;;
esac
