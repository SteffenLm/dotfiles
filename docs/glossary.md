# Glossary

Terms used across this repo's docs.

- **stow package** — a top-level directory in this repo (e.g. `tmux`, `shell`,
  `starship`, `pkg`, `mise`, `eza`, `zoxide`, `fzf`, `nix`, `opencode`,
  `ubuntu`) that mirrors
  home-directory paths. Install with `cd ~/dotfiles && stow <pkg>` (run stow
  from inside the repo with the bare package name — `stow` rejects slashes, so
  not `stow dotfiles/tmux`). See [loader-system.md](./loader-system.md).
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
- **`mise`** — the runtime-manager package. `~/.bashrc.d/mise` runs
  `mise activate bash` (after `set +h`), and
  `~/.config/mise/config.toml` holds the tracked global `[tools]` versions
  (Node `26.13.1`, Temurin JDK `21.0.13+9.0.LTS`, and Rust `stable`; activation
  also exports `JAVA_HOME`). Its
  `idiomatic_version_file_enable_tools = ["rust"]` setting makes mise read
  project `rust-toolchain.toml` pins. Skipped when `mise` is absent.
- **`nix`** — the package that tracks `~/.config/nix/nix.conf` (flakes,
  sandbox, aarch64 emulation) and `~/.profile.d/nix-os`, which
  sources `$HOME/.nix-profile/etc/profile.d/nix.sh` when Nix is installed and is
  silent otherwise. Nix itself is opt-in via `pkg install nix`, not part of
  `packages.list`.
- **`eza`** — the alias package (`~/.alias.d/eza`) that maps `ls`, `lsa`, `lt`,
  and `lta` to Omarchy's exact `eza` definitions. Skipped when `eza` is absent.
- **`zoxide`** — the package with two snippets: `~/.bashrc.d/zoxide` runs
  `zoxide init bash` (defining `z` and `zi`), and `~/.alias.d/zoxide` defines
  the `zd` function plus `alias cd="zd"`. Skipped when `zoxide` is absent.
- **`fzf`** — the package with two snippets: `~/.bashrc.d/fzf` loads the
  Ctrl-R/Ctrl-T/Alt-C key bindings, and `~/.alias.d/ff` adds the Omarchy `ff`,
  `eff`, and `sff()` helpers when both `fzf` and `bat` are present.
- **`opencode`** — the package that pins opencode's TUI configuration and theme.
  It tracks `~/.config/opencode/themes/retro-82.json`, a v1-format theme built
  from the Omarchy/`retro-82.nvim` Retro '82 palette, and a snapshot of
  `~/.config/opencode/cli.json` (`$schema` v2, theme `retro-82`). `cli.json` is
  global-only and v2 rewrites it with a temp file + `rename()`, so it is
  deliberately not stowed (see `opencode/.stow-local-ignore`); `install.sh`
  seeds it only when missing. `opencode.json` is user-managed and not tracked.
- **`bat`** — the syntax-highlighting pager used by `ff` previews and
  `MANPAGER`. Ubuntu installs the binary as `batcat`, so the Ubuntu backend
  links `~/.local/bin/bat` to it. `tldr` is intentionally not installed.
- **`inputrc`** — `shell/.inputrc`, stowed to `~/.inputrc`. Readline
  configuration read directly by Bash and other Readline programs: prefix
  history search on Up/Down, Tab menu-complete, case-insensitive completion,
  and colored completion listings.
- **`install.sh`** — the one-shot installer: `./install.sh <distro>`. Installs
  `packages.list`, backs up real shell/tmux files once, then stows the shared
  packages plus the chosen distro package. Supports `--dry-run` and
  `--no-stow`.
- **sandbox harness** — `test.sh`, which stows packages into a temporary
  `$HOME` and runs shell/tmux checks without touching the live home directory.
  With stdin redirected (`</dev/null`) it only runs the checks; on a TTY it
  also opens an interactive sandbox shell. `KEEP=1` preserves the sandbox.
- **`update-os`** — the per-distro alias for `pkg upgrade`. On Ubuntu it runs
  `apt-get update && apt-get upgrade`; on CachyOS `pacman -Syu`; on Omarchy
  `omarchy-update`.
- **prefix** — the tmux key that introduces commands. Here `C-Space`, with
  `C-b` available as the secondary prefix (`prefix2`); composite bindings read
  like `prefix + q`.
- **tmux config** — `tmux/.config/tmux/tmux.conf`, stowed to
  `~/.config/tmux/tmux.conf`. It follows Omarchy's `config/tmux/tmux.conf`
  (prefix, keybindings, status/border theme) with two local adaptations: a
  tmux < 3.5 guard around `extended-keys-format csi-u` and a `?` binding that
  runs `tmux-keybindings`. There are no plugins or local theme patches.
  Reloading with `prefix q` or `tmux source-file` is non-destructive; it can
  duplicate appended `terminal-features` entries until the server restarts.
- **`tmux-keybindings`** — `tmux/.local/bin/tmux-keybindings`, stowed to
  `~/.local/bin/tmux-keybindings`. A standalone port of Omarchy's
  `omarchy-menu-tmux-keybindings`: starts a throwaway tmux server, clears the
  key tables, sources the config, and prints annotated lines such as
  `PREFIX + q → Reload configuration`. Use `--print` for stdout; no
  `omarchy-*` binary is required. The `?` binding runs it as a pager popup
  (`--print | less -R`), not an interactive menu.
- **copy-mode** — tmux's scrollback/text-selection mode (`prefix + [`), here
  configured with vi-style keys.
- **worktree / worktrees** — git worktrees, used to run parallel agent
  sessions against separate branches.
- **loader / loader system** — the pattern where `shell/.bash_profile` sources
  `~/.profile.d/*` for login shells, and `shell/.bashrc` sources
  `~/.profile.d/*` (once), `~/.bashrc.d/*`, and `~/.alias.d/*` for interactive
  non-login shells. Each tool drops a snippet into one of these directories and
  it loads automatically at startup.
- **manifold directory** — a real home directory (`~/.profile.d`,
  `~/.bashrc.d`, `~/.alias.d`) that holds one per-tool symlink so snippets from
  many packages merge in one place the loader reads. `~/.profile.d` is a real
  directory in normal operation; a whole-folder symlink is a legacy state that
  `install.sh` refuses to stow through.
- **custom package** — the git-ignored `custom/` folder holding non-corporate
  machine-specific files such as local aliases that must not be committed.
  Wired into the manifold directories via per-file symlinks. See
  [loader-system.md](./loader-system.md).
- **`dotfiles-local`** — `~/.config/dotfiles-local/`, a private directory
  outside the repo for corporate proxy and CA settings. It holds
  `profile.d/proxy`, `profile.d/open-code`, and `certs/<corp>-ca.pem`; its
  snippets are linked into `~/.profile.d` manually and never committed.
- **Omarchy parity** — [omarchy-parity.md](./omarchy-parity.md), the map of
  which Omarchy `quattro` shell/tmux files are copied, adapted, or skipped for
  SSH terminal use. Desktop/Hyprland and `omarchy-*` binaries are out of scope.
