# Glossary

Terms used across this repo's docs.

- **stow package** — a top-level directory in this repo (e.g. `tmux`, `shell`,
  `starship`, `pkg`, `eza`, `zoxide`, `ubuntu`) that mirrors home-directory
  paths. Install with `cd ~/dotfiles && stow <pkg>` (run stow from inside the
  repo with the bare package name — `stow` rejects slashes, so not
  `stow dotfiles/tmux`). See [loader-system.md](./loader-system.md).
- **distro package** — one of `ubuntu`, `cachyos`, or `omarchy`. It supplies
  the `pkg` backend and the `update-os` alias. Stow exactly one per machine.
- **`pkg`** — the shell function loaded from `~/.bashrc.d/pkg`. It dispatches
  `install`, `remove`, `update`, `upgrade`, `search`, and `present` to the
  active distro backend.
- **pkg backend** — `<distro>/.config/dotfiles/pkg-backend.sh`, stowed to
  `~/.config/dotfiles/pkg-backend.sh`. It owns the native package names
  (`PKG_MAP`), non-repo installers (`PKG_METHOD`), and the actual apt/pacman
  commands.
- **`packages.list`** — the repo-root list of generic tool names installed by
  `install.sh`. It is not a stow package and is never linked into `$HOME`.
- **`eza`** — the alias package (`~/.alias.d/eza`) that maps `ls`, `lsa`, `lt`,
  and `lta` to Omarchy's exact `eza` definitions. Skipped when `eza` is absent.
- **`zoxide`** — the package with two snippets: `~/.bashrc.d/zoxide` runs
  `zoxide init bash` (defining `z` and `zi`), and `~/.alias.d/zoxide` defines
  the `zd` function plus `alias cd="zd"`. Skipped when `zoxide` is absent.
- **`install.sh`** — the one-shot installer: `./install.sh <distro>`. Installs
  `packages.list`, backs up real shell/tmux files once, then stows the shared
  packages plus the chosen distro package. Supports `--dry-run` and
  `--no-stow`.
- **`update-os`** — the per-distro alias for `pkg upgrade`. On Ubuntu it runs
  `apt-get update && apt-get upgrade`; on CachyOS `pacman -Syu`; on Omarchy
  `omarchy-update`.
- **prefix** — the tmux key that introduces commands. Here `C-Space`, with
  `C-b` available as the secondary prefix (`prefix2`); composite bindings read
  like `prefix + q`.
- **tmux config** — `tmux/.config/tmux/tmux.conf`, stowed to
  `~/.config/tmux/tmux.conf`. It is a verbatim copy of Omarchy's
  `config/tmux/tmux.conf`, including upstream's status/border theme; there are
  no plugins or local patches. Upstream is the source of truth: refresh the
  repo copy by copying the upstream file into the repo, then restow if needed.
- **copy-mode** — tmux's scrollback/text-selection mode (`prefix + [`), here
  configured with vi-style keys.
- **worktree / worktrees** — git worktrees, used to run parallel agent
  sessions against separate branches.
- **loader / loader system** — the pattern where `shell/.bash_profile` sources
  `~/.profile.d/*` for login shells, and `shell/.bashrc` sources
  `~/.profile.d/*` (once), `~/.bashrc.d/*`, and `~/.alias.d/*` for interactive
  non-login shells. Each tool drops a snippet into one of these directories and
  it loads automatically at startup.
- **manifold directory** — a home directory (`~/.bashrc.d`, `~/.alias.d`, and
  `~/.profile.d` when it is a real directory) that holds one per-tool symlink
  so snippets from many packages merge in one place the loader reads. When
  `~/.profile.d` is a whole-folder symlink to `custom/.profile.d`, that folder
  is the manifold.
- **custom package** — the git-ignored `custom/` folder holding machine-specific
  files (proxies, CAs, local aliases, local user names) that must not be
  committed. Wired into the loaders via symlinks. See
  [loader-system.md](./loader-system.md).
