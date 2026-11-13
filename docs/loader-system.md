# Loader system, packages, `custom/`, and stow commands

This document explains how the repo organizes shell config, how tools are
installed, where machine-specific (non-committed) files live, and the exact
stow commands to use. Dotfiles are managed with
[GNU Stow](https://www.gnu.org/software/stow/).

## Stow packages and the directory layout

The repo root is the stow directory. Each **package** is a top-level folder
that mirrors home-directory paths relative to `~`:

```
dotfiles/
├── shell/ starship/ pkg/ mise/     # shell loader + shared tool snippets
├── eza/ zoxide/ fzf/               # eza aliases, zoxide init/cd, fzf keys
├── tmux/                           # app config package
├── nix/                            # nix.conf + nix profile snippet
├── opencode/                       # tui.json + retro-82 theme
├── ubuntu/ cachyos/ omarchy/       # exactly one distro package per machine
├── packages.list                   # generic tool list (not a stow package)
├── install.sh                      # package install + one-time stow helper
├── test.sh                         # sandbox harness (see below)
├── custom/                         # git-ignored, machine-specific (see below)
└── docs/                           # glossary + this loader doc
```

For example `tmux/.config/tmux/tmux.conf` → `~/.config/tmux/tmux.conf`,
`tmux/.local/bin/tmux-keybindings` → `~/.local/bin/tmux-keybindings`,
`starship/.bashrc.d/starship` → `~/.bashrc.d/starship`,
`starship/.config/starship.toml` → `~/.config/starship.toml`,
`mise/.config/mise/config.toml` → `~/.config/mise/config.toml`,
`shell/.inputrc` → `~/.inputrc`,
`zoxide/.alias.d/zoxide` → `~/.alias.d/zoxide`,
`nix/.config/nix/nix.conf` → `~/.config/nix/nix.conf`, and
`opencode/.config/opencode/tui.json` → `~/.config/opencode/tui.json`.

### Correct stow commands

Because stow rejects slashes in package names, **always run stow from inside
the repo** and pass the bare package name:

```sh
cd ~/dotfiles

stow <pkg>     # install package (create the symlinks)
stow -D <pkg>  # remove package (unlink)
stow -R <pkg>  # restow (unlink then re-link), e.g. after editing a folder's layout
```

Shared package names are `shell`, `tmux`, `starship`, `pkg`, `mise`, `eza`,
`zoxide`, `fzf`, `nix`, and `opencode`. Distro package names are `ubuntu`,
`cachyos`, and `omarchy`;
stow **exactly one** of them.
To switch distros, unstow the old package first (`stow -D ubuntu`), because all
distro packages provide the same backend and `update-os` paths.

> ⚠️ Do NOT write `stow dotfiles/tmux` or `stow tmux` from anywhere other than
> `~/dotfiles` — the former errors with `Slashes are not permitted in package
> names`, and the latter needs the cwd to be the repo root.

The symlinks appear in home with a `dotfiles/<pkg>/...` prefix because stow's
default target is the *parent* of the stow directory (`~`), so it computes the
relative path through `~/dotfiles/...`.

A normal install stows the shared packages plus one distro package:

```sh
cd ~/dotfiles
stow --no-folding -t "$HOME" shell tmux starship pkg mise eza zoxide fzf nix opencode ubuntu
```

`install.sh <distro>` runs that command for you after installing tools. It also
backs up real shell/tmux files once, because stow refuses to replace regular
files.

## The loader system

The shell startup files are split into two tiny loaders plus per-concern
snippet directories. Bash needs two entry points because it reads different
files for login shells and for non-login interactive shells:

- `shell/.bash_profile` — login shells (TTY login, `ssh` with a PTY, `su -`).
- `shell/.bashrc` — non-login interactive shells (a terminal opened from the
  desktop, a tmux pane).

`shell/.bash_profile` sources `~/.profile.d`, marks it loaded, then sources
`~/.bashrc` if it exists. `shell/.bashrc` returns immediately when the shell is
not interactive; otherwise it sources `~/.profile.d` **once**, then
`~/.bashrc.d`, then `~/.alias.d`:

```bash
_source_dir() {
  local dir=$1 file
  [ -d "$dir" ] || return 0
  while IFS= read -r -d '' file; do
    . "$file"
  done < <(find -L "$dir" -type f -print0 2>/dev/null | LC_ALL=C sort -z)
}
```

The helper sources every regular file in a directory. It follows symlinks
(`-L`) because stow installs snippets as symlinks, and sorts with `LC_ALL=C
sort -z` so paths containing spaces work and load order is deterministic.
After the loaders run, each unsets the helper.

Loading order:

| Entry point | Shell kind | Sources (in order) | What runs |
|-------------|------------|--------------------|-----------|
| `.bash_profile` | login | `~/.profile.d/*` → `~/.bashrc` | env, then interactive config |
| `.bashrc` | non-login interactive | `~/.profile.d/*` (once) → `~/.bashrc.d/*` → `~/.alias.d/*` | env, tool init, aliases |
| `.bashrc` | non-interactive | nothing (returns early) | — |

The exported sentinel `__DOTFILES_PROFILE_D_LOADED` makes `~/.profile.d` load
exactly once: a login shell loads it in `.bash_profile`, and the `.bashrc` it
sources skips the second pass. Child shells inherit the flag.

Why not put everything in `.profile`? Login files are never read by a terminal
opened from the desktop (a non-login interactive shell), so aliases,
completion, prompt, and tool init would be missing there. Environment belongs
in `~/.profile.d`; interactive setup belongs in `~/.bashrc.d` and
`~/.alias.d`.

Starship is activated from `~/.bashrc.d/starship`, and is silently skipped when
the `starship` binary is absent. Mise is activated the same way from
`~/.bashrc.d/mise` (with command hashing disabled via `set +h` so newly
installed shims are always found), and is silently skipped when `mise` is
absent. Zoxide is initialized the same way from `~/.bashrc.d/zoxide`. Because
mise owns Java, its activation also exports `JAVA_HOME` for the selected
Temurin JDK. fzf's key
bindings (`Ctrl-R` history, `Ctrl-T` files, `Alt-C` directories) load from
`~/.bashrc.d/fzf`, preferring `/usr/share/fzf/key-bindings.bash` (Arch) and
falling back to `/usr/share/doc/fzf/examples/key-bindings.bash` (Ubuntu). The
`eza` alias block (`ls`, `lsa`, `lt`, `lta`) lives in `~/.alias.d/eza`, and
`~/.alias.d/zoxide` supplies the Omarchy `zd` wrapper plus `alias cd="zd"`.

Starship uses `starship init bash --print-full-init` and reads
`~/.config/starship.toml`, so the prompt matches Omarchy's directory, git, and
`❯` layout.

Readline behavior is not a loader snippet: `~/.inputrc` is read directly by
Bash (and other Readline programs). It turns Up/Down into prefix history
search, Tab into menu-complete, and enables colored, case-insensitive
completion. History (`~/.bashrc.d/history`) and completion
(`~/.bashrc.d/completion`) are split out of Omarchy's `default/bash/shell`.
`~/.bashrc.d/env` holds interactive environment variables (`EDITOR`,
`BROWSER`, `BAT_THEME`, `MANROFFOPT`, guarded `MANPAGER`), and
`~/.bashrc.d/functions` defines `open()` and `n()`.

The portable Omarchy aliases live in `~/.alias.d/omarchy`; `ff`, `eff`, and
`sff()` live in `~/.alias.d/ff` and are only defined when both `fzf` and `bat`
are installed. See [omarchy-parity.md](./omarchy-parity.md) for the
copied/adapted/skipped map.

### eza icons need a Nerd Font

`ls`, `lsa`, `lt`, and `lta` pass `--icons`, so they only render correctly when
the terminal's font provides Nerd Font glyphs. For a Windows Terminal session
over SSH, install a Nerd Font on Windows (for example `JetBrainsMono Nerd Font
Mono` from <https://www.nerdfonts.com/fonts>) and select it under **Settings →
Profiles → Defaults → Appearance → Font face**. The server does not need the
font: SSH transmits the glyphs and the client renders them.

### `~/.local/bin` on PATH

Both entry points prepend `$HOME/.local/bin` to `PATH` with a guard, so the
directory appears exactly once. This is where Ubuntu gets standalone tools that
are not in apt (`starship`, `mise`, `opencode`, `neovim`, `kubectl`) and where
the `fd` shim is created. Neovim is unpacked under `~/.local/opt` and reached
through a `~/.local/bin/nvim` symlink.

Distro-provided tools stay in `/usr/bin`; `~/.local/bin` only fills the gaps.

### The home manifold directories

`~/.profile.d`, `~/.bashrc.d`, and `~/.alias.d` are **real directories** that
act as merge points. Each package drops a single symlink into the relevant one,
named after the tool. Machine-local snippets from `custom/` and
`~/.config/dotfiles-local/` join them the same way.

```
~/.profile.d/
├── nix-os    -> ../dotfiles/nix/.profile.d/nix-os
├── open-code -> ../.config/dotfiles-local/profile.d/open-code
└── proxy     -> ../.config/dotfiles-local/profile.d/proxy

~/.bashrc.d/
├── completion -> ../dotfiles/shell/.bashrc.d/completion
├── env        -> ../dotfiles/shell/.bashrc.d/env
├── functions  -> ../dotfiles/shell/.bashrc.d/functions
├── fzf        -> ../dotfiles/fzf/.bashrc.d/fzf
├── history    -> ../dotfiles/shell/.bashrc.d/history
├── mise       -> ../dotfiles/mise/.bashrc.d/mise
├── pkg        -> ../dotfiles/pkg/.bashrc.d/pkg
├── starship   -> ../dotfiles/starship/.bashrc.d/starship
└── zoxide     -> ../dotfiles/zoxide/.bashrc.d/zoxide

~/.alias.d/
├── eza       -> ../dotfiles/eza/.alias.d/eza
├── ff        -> ../dotfiles/fzf/.alias.d/ff
├── omarchy   -> ../dotfiles/shell/.alias.d/omarchy
├── update-os -> ../dotfiles/ubuntu/.alias.d/update-os
└── zoxide    -> ../dotfiles/zoxide/.alias.d/zoxide
```

`~/.inputrc` is stowed directly from `shell/.inputrc`; it is not part of the
manifold loader. `~/.config/starship.toml` comes from the `starship` package.

The loader sources everything in each directory, so each tool's snippet is
loaded automatically at shell startup — no per-tool edits to the loaders.

## Packages and tools: `pkg`, `packages.list`, and the distro backends

The tool set is listed once, with generic names, in `packages.list` at the repo
root. That file is **not** a stow package and is never symlinked into `$HOME`.

`pkg` is a shell function loaded from `~/.bashrc.d/pkg`. It is a thin
dispatcher:

```sh
pkg install <pkg...>
pkg remove <pkg...>
pkg update
pkg upgrade
pkg search <term...>
pkg present <pkg...>
```

The dispatcher lazily sources exactly one backend:

```
~/.config/dotfiles/pkg-backend.sh
```

That symlink comes from the stowed distro package:

| Distro    | Backend                                              | Package manager                |
|-----------|------------------------------------------------------|--------------------------------|
| `ubuntu`  | `ubuntu/.config/dotfiles/pkg-backend.sh`             | `apt-get`                      |
| `cachyos` | `cachyos/.config/dotfiles/pkg-backend.sh`            | `pacman`                       |
| `omarchy` | `omarchy/.config/dotfiles/pkg-backend.sh`            | `pacman` + `omarchy-update`    |

Set `DOTFILES_PKG_BACKEND` to point at a different backend; `install.sh` uses
that to source the repo copy before the package is stowed.

Each backend owns:

- `PKG_MAP` — generic name → native package name (`fd` → `fd-find` on Ubuntu,
  `build-essential` → `base-devel` on Arch).
- `PKG_METHOD` — tools that need a non-repo installer (`github` or
  `installer`). Ubuntu uses it for `starship` (pinned GitHub release, SHA-256
  verified), `mise` (official `mise.run` installer, version pinned), `nix`
  (pinned single-user tarball installer with `--no-daemon
  --no-modify-profile`, so it never edits shell profiles), `opencode`
  (pinned GitHub release, SHA-256 verified), `neovim` (pinned GitHub release,
  SHA-256 verified, unpacked to `~/.local/opt/nvim-<version>` with an `nvim`
  symlink in `~/.local/bin`), and `kubectl` (pinned `dl.k8s.io` binary, SHA-256
  verified). On Arch, `opencode`, `neovim`, and `kubectl` come from the native
  repositories instead, so their versions can differ. `pkg present neovim`
  checks the `nvim` binary name. `pkg remove nix` deletes `/nix` and the
  per-user Nix state but keeps the tracked `~/.config/nix/nix.conf`.
- `_pkg_install`, `_pkg_remove`, `_pkg_update`, `_pkg_upgrade`, `_pkg_search`,
  `_pkg_present`.
- A sudo-or-root helper, plus dry-run support (`PKG_DRY_RUN=1`).

Ubuntu's `bat` package installs the binary as `batcat`; the backend links
`~/.local/bin/bat` to it, mirroring the `fd` → `fdfind` shim. This keeps
Omarchy's `ff` alias working without a `PKG_MAP` entry. `yt-dlp` is part of
`packages.list`; `tldr` is intentionally excluded.

`pkg update` syncs package state before an install. Ubuntu refreshes apt
indexes; CachyOS runs `pacman -Syu` (so installing does not leave a partial
upgrade); Omarchy runs `omarchy-update`.

`pkg upgrade` is what the per-distro alias calls:

```
~/.alias.d/update-os -> ../dotfiles/<distro>/.alias.d/update-os
```

All three aliases are `alias update-os='pkg upgrade'`; the backend decides
whether that means `apt-get update && apt-get upgrade`, `pacman -Syu`, or
`omarchy-update`.

`pkg present` checks command availability for standalone tools and the native
package database for repo packages. It exits non-zero if anything is missing.

### `install.sh`

`install.sh <distro>`:

1. validates the distro and sources its backend through the `pkg` dispatcher;
2. runs `pkg update`;
3. installs `stow` (needed for the next step) and every entry in
   `packages.list`;
4. backs up existing `~/.bashrc`, `~/.profile`, `~/.bash_profile`,
   `~/.inputrc`, `~/.tmux.conf`, `~/.config/tmux/tmux.conf`,
   `~/.config/starship.toml`, `~/.config/nix/nix.conf`,
   `~/.config/opencode/tui.json`,
   `~/.config/opencode/themes/retro-82.json`, and
   `~/.config/dotfiles/pkg-backend.sh` to `~/.dotfiles-backup-<timestamp>/`,
   skipping symlinks that already point at the current repo;
5. refuses to stow while `~/.profile.d` is still a whole-folder symlink, then
   stows `shell tmux starship pkg mise eza zoxide fzf nix opencode <distro>`
   with `--no-folding`.

Options: `--dry-run` prints every package/backup/stow command without running
it; `--no-stow` installs tools but stops before backup and stow. The script
never runs `chsh`; switching the login shell is a manual step after verifying
a fresh login shell.

## Testing the shell configuration

`./test.sh` is the sandbox harness. It stows the shared packages into a
temporary `$HOME`, runs login/non-login shell checks, and exercises tmux on an
isolated socket — it never touches the live home directory.

The automated checks cover the loader, readline (`~/.inputrc`), history and
completion, starship prompt/config, the interactive environment, the Omarchy
aliases and functions, the bat shim when `batcat`/`bat` is available, and the
tmux keybindings. With `bat` installed the suite currently passes cleanly.

```sh
./test.sh                                  # checks, then an interactive sandbox (TTY only)
env -u __DOTFILES_PROFILE_D_LOADED ./test.sh </dev/null  # automated run
KEEP=1 ./test.sh                           # keep the sandbox directory
REPO=/path/to/repo LIVE=/path/to/live ./test.sh          # override paths
```

With stdin redirected, the harness prints `RESULTS: <pass> passed, <fail>
failed` and exits without opening a shell. On a TTY it drops into the sandbox
shell after the checks so you can inspect aliases, `pkg`, zoxide, and tmux.

## The `custom/` folder (git-ignored, machine-specific)

`custom/` mirrors the same layout but holds files that are specific to this
machine (local aliases, local paths) and must **not** be committed. It is
excluded by the single line in `.gitignore`:

```
custom
```

It has two loadable subfolders, matching the loader system, plus local scratch
directories:

```
custom/
├── .alias.d/git                 # git-verify on/off
├── .archive/zsh_history-*       # old shell history
├── .profile.d/                  # (empty, ready for use)
└── .zshrc.d/                    # (empty, ready for use)
```

Language runtimes are owned by mise, not by `custom/`. The committed `mise`
package carries the global tool versions in
`mise/.config/mise/config.toml` (Node `26.13.1`, Temurin JDK
`21.0.13+9.0.LTS`, and Rust's `stable` channel); machine-specific overrides, if
ever needed, belong in `custom/`. Rust runs through rustup, which mise reuses at
`~/.rustup`/`~/.cargo`; `idiomatic_version_file_enable_tools = ["rust"]` makes
mise read a project's `rust-toolchain.toml`, so project pins win over the global
`stable` channel and are installed on demand (`.nvmrc` remains ignored). The apt
OpenJDK 21 JRE is retained for OS packages even though mise's JDK wins on
`PATH`.

### How `custom/` reaches the loaders

`~/.profile.d`, `~/.alias.d`, and `~/.bashrc.d` are real **manifold**
directories, so `custom` adds **per-file symlinks** named after the snippet:

```
~/.alias.d/git        -> ../dotfiles/custom/.alias.d/git
```

Adding a new machine-specific file = drop it into the matching `custom/`
subfolder, then create the home symlink with the appropriate `ln -s` (relative
target). Because it lives under `custom/`, it stays local and never gets
committed (`git status` stays clean).

## The `~/.config/dotfiles-local/` folder (private, outside the repo)

Corporate and otherwise sensitive machine files live **outside** the repo in
`~/.config/dotfiles-local/`, so they cannot be committed even by accident:

```
~/.config/dotfiles-local/
├── profile.d/open-code     # NODE_EXTRA_CA_CERTS -> certs/<corp>-ca.pem
├── profile.d/proxy         # HTTP(S)/FTP/ALL proxy exports
└── certs/<corp>-ca.pem     # corporate CA bundle
```

Link each snippet into the real `~/.profile.d` manifold:

```
~/.profile.d/open-code -> ../.config/dotfiles-local/profile.d/open-code
~/.profile.d/proxy     -> ../.config/dotfiles-local/profile.d/proxy
```

Other private files (for example `~/certs/<corp>-ca.pem`) may point here too.
Nothing in this directory is tracked, and it should never be copied into
`custom/` or committed.

## Adding a tool (summary recipe)

1. Create the package folder mirroring the home path, e.g.
   `mkdir -p vim/.config/vim`.
2. Add the snippet(s) under the right loader subdir:
   - `<pkg>/.profile.d/<tool>` — login/session environment;
   - `<pkg>/.bashrc.d/<tool>` — interactive tool init;
   - `<pkg>/.alias.d/<tool>` — aliases.
3. If the tool is installed with the shared tool set, add its generic name to
   `packages.list` and any native-name mapping to each backend.
4. Wire it into the home:
   ```sh
   cd ~/dotfiles && stow vim
   ```
5. If the snippet is machine-specific instead of shared, put a copy in
   `custom/` and link it manually (see above) rather than committing it.
6. Confirm with `ls -la ~/.bashrc.d` (or the relevant dir) that the new symlink
   resolves.

## Adding a distro

1. Create `<distro>/.config/dotfiles/pkg-backend.sh` with the backend contract
   above (maps, methods, commands, sudo helper, dry-run).
2. Add `<distro>/.alias.d/update-os` with `alias update-os='pkg upgrade'`.
3. Add the distro name to the validation in `install.sh`.
4. Test a dry run:
   ```sh
   ./install.sh <distro> --dry-run
   ```
