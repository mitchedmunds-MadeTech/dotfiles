# dotfiles

Personal config for bash, zsh, git, ssh, vim, oh-my-posh and (optionally)
Claude Code. Works on macOS and Linux (including fresh cloud workspaces and
devcontainers). Each tool's files live in their own package directory, and
`install.sh` symlinks them into `$HOME` one file at a time.

## Install

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh               # Claude config linked only if Claude Code is installed
./install.sh --claude      # always link the Claude Code + ccstatusline config
./install.sh --no-claude   # never link it (or DOTFILES_CLAUDE=0)
./install.sh --uninstall [package...]   # remove the links: all, or just those packages
```

Needs only bash, `find` and (for oh-my-posh on Linux) `curl`: no sudo, no
GNU stow, no package manager. It creates `~/.local/bin`, installs oh-my-posh if
missing (brew on macOS, the official installer into `~/.local/bin` on Linux;
a failure is a warning, not fatal), moves any file in the way to
`~/.dotfiles-backup-<timestamp>/`, and links each package. Re-running it is safe.
`--uninstall` removes only links that point into this repo and restores
nothing; the files they replaced are in those backup directories.
Atuin is opt-in: `INSTALL_ATUIN=1 ./install.sh`.

## Layout

```
shell/         .profile (login env, POSIX sh) and .config/shell/*.sh, shared by bash and zsh
zsh/           .zshrc, .zprofile, .config/shell/zsh/*.zsh (zsh-only)
bash/          .bashrc, .bash_profile, .config/shell/bash/*.bash (bash-only)
git/           .gitconfig, .config/git/{ignore,*.config} (work/personal identities)
ssh/           .ssh/config and the public keys that select 1Password keys
vim/           .vimrc
ohmyposh/      .ohmyposhthemes/montys.omp.json
claude/        .claude/settings.json                  (optional)
ccstatusline/  .config/ccstatusline/settings.json     (optional)
```

## Machine-specific config

Nothing tracked here depends on where things live on disk. Per-machine tweaks
go in untracked files:

- `~/.gitconfig.local`: included last by `.gitconfig`, so it overrides
  anything (for example a different default identity on a personal machine).
- `~/.config/shell/local.sh`: sourced by both shells if present.

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

- **shell / zsh / bash**: `~/.zshrc` and `~/.bashrc` source
  `~/.config/shell/*.sh` and `functions/*.sh`, then their own
  `zsh/*.zsh` or `bash/*.bash`. `$DOTFILES_SHELL` tells a shared file which
  shell it is in. Drop a new file in the right directory to extend.
  oh-my-posh needs bash 4.2+, so macOS's `/bin/bash` (3.2) keeps the plain
  prompt; `brew install bash` for the themed one.
- **git**: identity follows the repo's remote URL, not its path. Work is the
  default; any remote under `mitches-got-glitches/` uses the personal identity
  and key. Needs git 2.36+ (`hasconfig:`). Global ignores are in
  `~/.config/git/ignore`, git's default location.
- **ssh**: uses 1Password's agent at `~/.1password/agent.sock` when that socket
  exists (native on Linux; `install.sh` links the macOS socket there), and
  otherwise whatever `$SSH_AUTH_SOCK` holds, such as a forwarded agent.
- **claude**: only `settings.json` is tracked. Skills and slash commands come
  from Claude Code's plugin marketplaces (configured in
  `extraKnownMarketplaces`) or separate repos under `~/.agents/`. To remove it
  from a machine, run `./install.sh --uninstall claude ccstatusline`.
- **ccstatusline**: picked up by Claude Code via the `statusLine` block in
  `claude/.claude/settings.json`; the first run fetches it with `npx`.
- **atuin**: initialised from `shell/.config/shell/atuin.sh` with
  `--disable-up-arrow`, so Up keeps the shell's prefix search and Atuin only
  takes `Ctrl-R`. In bash it needs bash-preexec or ble.sh loaded first.
