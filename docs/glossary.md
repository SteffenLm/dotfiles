# Glossary

Terms used across this repo's docs.

- **stow package** — a top-level directory in this repo (e.g. `tmux`, `shell`,
  `starship`, `pkg`, `mise`, `eza`, `zoxide`, `fzf`, `nix`, `agents`, `ubuntu`)
  that mirrors home-directory paths. Install with `cd ~/dotfiles && stow <pkg>` (run stow
  from inside the repo with the bare package name — `stow` rejects slashes, so
  not `stow dotfiles/tmux`). See [loader-system.md](./loader-system.md).
- **distro package** — one of `ubuntu` or `cachyos`. It supplies the `pkg`
  backend and the `update-os` alias. Stow exactly one per machine. Omarchy is
  deliberately not a target; a real Omarchy install already ships its own
  shell, tmux, mise, and opencode configuration.
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
  (Node `26.13.1`, Temurin JDK `21.0.13+9.0.LTS`, Rust `stable`, and opencode
  `latest`; activation also exports `JAVA_HOME`). Its
  `idiomatic_version_file_enable_tools = ["rust"]` setting makes mise read
  project `rust-toolchain.toml` pins. `install.sh` installs opencode from the
  tracked config with `mise --cd mise/.config/mise install opencode`; the other
  tools are installed on demand with `mise install`, and `mup` updates the
  tracked tools. Skipped when `mise` is absent.
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
- **`opencode`** — a mise-managed terminal agent, tracked as `latest` in
  `~/.config/mise/config.toml`. It is not a stow package: no CLI config or
  theme is tracked. `~/.config/opencode/cli.json` is owned by OpenCode;
  keybindings are set there by hand. The built-in `system` theme derives colors
  from the terminal palette, like tmux, so no theme file is shipped.
  `opencode.json` is user-managed and not tracked. See
  [windows-terminal.md](./windows-terminal.md).
- **Windows Terminal scheme** — one of the palettes in
  `docs/windows-terminal-*.json`: `Retro 82`, `Catppuccin`,
  `Catppuccin Latte`, and `Tokyo Night`. Each is extracted from the matching
  Omarchy theme (`/usr/share/omarchy/themes/<theme>/colors.toml`). Paste the
  object into `"schemes"` and select it with `"colorScheme"`. Windows Terminal
  answers OpenCode's palette queries, so the `system` theme inherits the same
  colors tmux uses.
- **`agents`** — the stow package for agent skills. It vendors the
  `engineering/` and `productivity/` skills from `mattpocock/skills` into
  `~/.agents/skills/`, and keeps a local `grilling` fork that asks one question
  at a time. `agents/update.sh` refreshes the tree; `agents/check-grilling.sh`
  guards the fork. See [skills.md](./skills.md).
- **skill** — a `SKILL.md` directory (or a root-level `*.md` file) advertised to
  the agent by ID. OpenCode discovers global skills in `~/.agents/skills`,
  `~/.claude/skills`, and `~/.config/opencode/skills`, plus project skills in
  `.opencode/skills`, `.agents/skills`, and `.claude/skills`. Later sources win
  on duplicate IDs; bodies are not merged. See [skills.md](./skills.md).
- **`grilling` local fork** — the vendored `grilling` skill keeps the
  one-question-at-a-time interview flow that upstream replaced with
  round-by-round "frontier" batches in `a4b2009a1` (2026-07-16). The last
  upstream one-at-a-time version is `170ad4865` (2026-07-13). The
  `metadata.local-fork` marker and `agents/check-grilling.sh` make the fork
  explicit. See [skills.md](./skills.md).
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
  `DISTRO` selects the distro package to stow (default `ubuntu`; use
  `DISTRO=cachyos` for the Arch backend). With stdin redirected (`</dev/null`)
  it only runs the checks; on a TTY it also opens an interactive sandbox shell.
  `KEEP=1` preserves the sandbox.
- **`update-os`** — the per-distro alias for `pkg upgrade`. On Ubuntu it runs
  `apt-get update && apt-get upgrade`; on CachyOS `pacman -Syu`.
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
