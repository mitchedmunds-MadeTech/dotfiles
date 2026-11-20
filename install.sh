#!/usr/bin/env bash
# Install or update dotfiles by symlinking each package's files into $HOME.
#
#   ./install.sh               core packages; Claude ones only if Claude Code is present
#   ./install.sh --claude      also link the Claude Code + ccstatusline config
#   ./install.sh --no-claude   never link them
#
# Works on macOS and Linux (apt, dnf, yum or none) with no sudo and no GNU stow:
# every file is linked individually, so directories such as ~/.ssh or ~/.claude
# stay real directories and nothing a tool writes there lands in this repo.
# Existing files at target paths are moved to ~/.dotfiles-backup-<timestamp>/.
# Runs under macOS's bash 3.2.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_PACKAGES="shell zsh bash git ssh vim ohmyposh"
CLAUDE_PACKAGES="claude ccstatusline"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
OS="$(uname -s)"
CLAUDE="${DOTFILES_CLAUDE:-auto}"

log()  { printf '[dotfiles] %s\n' "$*"; }
warn() { printf '[dotfiles] warning: %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() { sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; }

for arg in "$@"; do
    case "$arg" in
        --claude)    CLAUDE=1 ;;
        --no-claude) CLAUDE=0 ;;
        -h|--help)   usage; exit 0 ;;
        *) warn "unknown argument: $arg"; usage; exit 1 ;;
    esac
done

if [ "$CLAUDE" = "auto" ]; then
    if have claude || [ -d "$HOME/.claude" ]; then CLAUDE=1; else CLAUDE=0; fi
fi
PACKAGES="$CORE_PACKAGES"
[ "$CLAUDE" = "1" ] && PACKAGES="$PACKAGES $CLAUDE_PACKAGES"

# Optional extras. A failure here is a warning, never a reason to skip linking.
install_oh_my_posh() {
    have oh-my-posh && return 0
    case "$OS" in
        Darwin) have brew && brew install oh-my-posh ;;
        Linux)
            have curl || { warn "curl not found; skipping oh-my-posh"; return 1; }
            # The installer refuses a target directory that does not exist yet.
            mkdir -p "$HOME/.local/bin"
            curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
            ;;
    esac
}

install_atuin() {
    # Opt-in: `INSTALL_ATUIN=1 ./install.sh`.
    [ "${INSTALL_ATUIN:-0}" = "1" ] || return 0
    have atuin && return 0
    case "$OS" in
        Darwin) have brew && brew install atuin ;;
        Linux)  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh ;;
    esac
}

# Link one file, backing up whatever real file or foreign link is in the way.
link_file() {
    local src="$1" rel="$2" target="$HOME/$2"
    if [ "$target" -ef "$src" ]; then
        return 0
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
        mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
        mv "$target" "$BACKUP_DIR/$rel"
        log "backed up ~/$rel"
    fi
    mkdir -p "$(dirname "$target")"
    ln -s "$src" "$target"
}

link_package() {
    local pkg="$1" src rel
    while IFS= read -r -d '' src; do
        rel="${src#"$DOTFILES_DIR/$pkg/"}"
        link_file "$src" "$rel"
    done < <(find "$DOTFILES_DIR/$pkg" -type f ! -name .DS_Store -print0)
}

# Earlier versions linked the zsh snippets into ~/zshrc/. Drop those links
# once they dangle, and the directory if nothing else is in it.
remove_legacy_links() {
    local link
    [ -d "$HOME/zshrc" ] || return 0
    while IFS= read -r -d '' link; do
        [ -e "$link" ] || rm "$link"
    done < <(find "$HOME/zshrc" -type l -print0)
    find "$HOME/zshrc" -depth -type d -empty -exec rmdir {} \; 2>/dev/null || true
}

# 1Password's agent socket lives at an awkward path on macOS. Give it the same
# path it has on Linux so ssh/config and env.sh only need to know one.
link_1password_socket() {
    local mac_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    [ "$OS" = "Darwin" ] || return 0
    [ -e "$HOME/.1password/agent.sock" ] && return 0
    [ -d "$(dirname "$mac_sock")" ] || return 0
    mkdir -p "$HOME/.1password"
    ln -sfn "$mac_sock" "$HOME/.1password/agent.sock"
}

mkdir -p "$HOME/.local/bin"
install_oh_my_posh || warn "oh-my-posh not installed; the prompt falls back to the default"
install_atuin || warn "atuin not installed"

log "Linking: $PACKAGES"
for pkg in $PACKAGES; do
    link_package "$pkg"
done
remove_legacy_links
link_1password_socket
chmod 700 "$HOME/.ssh" 2>/dev/null || true

[ -d "$BACKUP_DIR" ] && log "Replaced files are in $BACKUP_DIR"
[ "$CLAUDE" = "1" ] || log "Skipped Claude config (pass --claude to link it)"
log "Done. Open a new shell, or run: exec \"\$SHELL\" -l"
