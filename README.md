# dotfiles

Personal config for zsh, git, vim, Claude Code, ccstatusline and oh-my-posh.
Organised as GNU stow packages so each tool's files live under their own subdir
and `stow` symlinks them into `$HOME`.

## Install

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` installs `stow`, `atuin` and `oh-my-posh` if missing (brew on macOS,
apt + curl installers on Linux), backs up any existing target files to
`~/.dotfiles-backup-<timestamp>/`, then symlinks each package into `$HOME`.

## Layout

```
git/         .gitconfig, .gitignore, .config/git/*.config (work/personal split)
zsh/         .zshrc, .zprofile, .profile, zshrc/*.sh
claude/      .claude/settings.json
ccstatusline/  .config/ccstatusline/settings.json
ohmyposh/    .ohmyposhthemes/montys.omp.json
vim/         .vimrc
```

## VS Code dev container integration

Set these once in your **host** VS Code `settings.json`:

```json
"dotfiles.repository": "<your-gh-user>/dotfiles",
"dotfiles.targetPath": "~/dotfiles",
"dotfiles.installCommand": "~/dotfiles/install.sh"
```

VS Code will clone this repo into every devcontainer / Codespace / Remote-SSH
host and run `install.sh` automatically.

## Persisting zsh history across container rebuilds

Add a named volume to your `devcontainer.json`:

```json
"mounts": [
  "source=zsh-history,target=/home/vscode/.zsh_history-vol,type=volume"
],
"postCreateCommand": "touch /home/vscode/.zsh_history-vol/.zsh_history && ln -sf /home/vscode/.zsh_history-vol/.zsh_history /home/vscode/.zsh_history"
```

Atuin's own SQLite history lives under `~/.local/share/atuin/`. Mount that path
the same way if you want Atuin history to survive rebuilds too, or use Atuin
sync (`atuin login` + `atuin sync`) for cross-machine sync.

## Per-package notes

- **zsh** — `.zshrc` sources every file under `~/zshrc/**`. Drop a new `.sh`
  file in `zshrc/` to extend.
- **git** — `~/git-worktrees/work/**` repos use the MadeTech identity, `~/git-worktrees/mitches-got-glitches/**` repos use the personal identity, via `includeIf`.
- **claude** — only `settings.json` is tracked here. Skills and slash commands
  are managed via Claude Code's plugin marketplaces (already configured in
  `extraKnownMarketplaces`) or as separate git repos under `~/.agents/`.
- **ccstatusline** — picked up automatically by Claude Code via the
  `statusLine` block in `claude/.claude/settings.json`. First run in a fresh
  container will `npx -y ccstatusline@latest` and apply this config.
- **ohmyposh** — `plugin.sh` only initialises oh-my-posh if the binary is on
  PATH; `install.sh` installs it for you.
- **atuin** — initialised from `zshrc/atuin.sh` with `--disable-up-arrow` so
  Up still runs zsh's prefix-search; Atuin only takes `Ctrl-R`.
