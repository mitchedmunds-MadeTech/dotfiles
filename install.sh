#!/usr/bin/env bash
# Install or update dotfiles by symlinking each package into $HOME via GNU stow.
# Existing files at target paths are moved to ~/.dotfiles-backup-<timestamp>/
# rather than overwritten.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(git zsh ssh claude ccstatusline ohmyposh vim)
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
OS="$(uname -s)"

log()  { printf '[dotfiles] %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

ensure_tool() {
    local tool="$1" brew_pkg="${2:-$1}" apt_pkg="${3:-$1}"
    if have "$tool"; then return; fi
    case "$OS" in
        Darwin)
            have brew || { log "brew not found; install Homebrew first: https://brew.sh"; exit 1; }
            log "Installing $brew_pkg via brew"
            brew install "$brew_pkg"
            ;;
        Linux)
            if have apt-get; then
                log "Installing $apt_pkg via apt-get"
                sudo apt-get update -qq
                sudo apt-get install -y "$apt_pkg"
            else
                log "Unsupported Linux distro; install '$tool' manually"
                exit 1
            fi
            ;;
        *) log "Unsupported OS: $OS"; exit 1 ;;
    esac
}

install_atuin() {
    # Opt-in: re-enable with `INSTALL_ATUIN=1 ./install.sh`.
    [ "${INSTALL_ATUIN:-0}" = "1" ] || return
    if have atuin; then return; fi
    case "$OS" in
        Darwin) brew install atuin ;;
        Linux)  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh ;;
    esac
}

install_oh_my_posh() {
    if have oh-my-posh; then return; fi
    case "$OS" in
        Darwin) brew install oh-my-posh ;;
        Linux)  curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin" ;;
    esac
}

# Back up any existing real file/dir at a target path before stow runs.
# Stale symlinks pointing somewhere other than DOTFILES_DIR are removed.
backup_conflicts() {
    local pkg target_rel target backed_up=0
    for pkg in "${PACKAGES[@]}"; do
        while IFS= read -r -d '' src_file; do
            target_rel="${src_file#"$DOTFILES_DIR/$pkg/"}"
            target="$HOME/$target_rel"
            if [[ -L "$target" ]]; then
                if [[ "$(readlink "$target")" != "$src_file" ]]; then
                    rm "$target"
                fi
            elif [[ -e "$target" ]]; then
                mkdir -p "$(dirname "$BACKUP_DIR/$target_rel")"
                mv "$target" "$BACKUP_DIR/$target_rel"
                backed_up=1
            fi
        done < <(find "$DOTFILES_DIR/$pkg" -type f -print0)
    done
    if [[ $backed_up -eq 1 ]]; then
        log "Existing files moved to $BACKUP_DIR"
    fi
}

ensure_tool stow stow stow
install_atuin
install_oh_my_posh

backup_conflicts

cd "$DOTFILES_DIR"
log "Stowing: ${PACKAGES[*]}"
stow -v -t "$HOME" "${PACKAGES[@]}"

log "Done. Open a new shell or run: exec zsh"
