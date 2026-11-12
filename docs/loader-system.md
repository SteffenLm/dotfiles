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
├── eza/ zoxide/                    # eza aliases + zoxide init/cd wrapper
├── tmux/                           # app config package
├── ubuntu/ cachyos/ omarchy/       # exactly one distro package per machine
├── packages.list                   # generic tool list (not a stow package)
├── install.sh                      # package install + one-time stow helper
├── custom/                         # git-ignored, machine-specific (see below)
└── docs/                           # glossary + this loader doc
```

For example `tmux/.config/tmux/tmux.conf` → `~/.config/tmux/tmux.conf`,
`starship/.bashrc.d/starship` → `~/.bashrc.d/starship`,
`mise/.config/mise/config.toml` → `~/.config/mise/config.toml`, and
`zoxide/.alias.d/zoxide` → `~/.alias.d/zoxide`.

### Correct stow commands

Because stow rejects slashes in package names, **always run stow from inside
the repo** and pass the bare package name:

```sh
cd ~/dotfiles

stow <pkg>     # install package (create the symlinks)
stow -D <pkg>  # remove package (unlink)
stow -R <pkg>  # restow (unlink then re-link), e.g. after editing a folder's layout
```

Shared package names are `shell`, `tmux`, `starship`, `pkg`, `mise`, `eza`, and
`zoxide`. Distro package names are `ubuntu`, `cachyos`, and `omarchy`; stow
**exactly one** of them.
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
stow --no-folding -t "$HOME" shell tmux starship pkg mise eza zoxide ubuntu
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
absent. Zoxide is initialized the same way from `~/.bashrc.d/zoxide`. The `eza`
alias block (`ls`, `lsa`, `lt`, `lta`) lives in `~/.alias.d/eza`, and
`~/.alias.d/zoxide` supplies the Omarchy `zd` wrapper plus `alias cd="zd"`.

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
are not in apt (`starship`, `mise`, `opencode`) and where the `fd` shim is
created.

Distro-provided tools stay in `/usr/bin`; `~/.local/bin` only fills the gaps.

### The home manifold directories

`~/.bashrc.d` and `~/.alias.d` are **real directories** that act as merge
points. Each tool package drops a single symlink into one of them, named after
the tool. `~/.profile.d` is normally a whole-folder symlink to
`custom/.profile.d` (see below); if it is a real directory, it acts as a merge
point the same way.

```
~/.profile.d/
└── ...   (machine-specific only; see custom/ below)

~/.bashrc.d/
├── mise     -> ../dotfiles/mise/.bashrc.d/mise
├── pkg      -> ../dotfiles/pkg/.bashrc.d/pkg
├── starship -> ../dotfiles/starship/.bashrc.d/starship
└── zoxide   -> ../dotfiles/zoxide/.bashrc.d/zoxide

~/.alias.d/
├── eza       -> ../dotfiles/eza/.alias.d/eza
├── update-os -> ../dotfiles/ubuntu/.alias.d/update-os
└── zoxide    -> ../dotfiles/zoxide/.alias.d/zoxide
```

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
  verified), `mise` (official `mise.run` installer, version pinned), and
  `opencode` (pinned GitHub release, SHA-256 verified). On Arch, `opencode`
  comes from the native `extra` repository instead, so its version can differ.
- `_pkg_install`, `_pkg_remove`, `_pkg_update`, `_pkg_upgrade`, `_pkg_search`,
  `_pkg_present`.
- A sudo-or-root helper, plus dry-run support (`PKG_DRY_RUN=1`).

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
   `~/.tmux.conf`, `~/.config/tmux/tmux.conf`, and
   `~/.config/dotfiles/pkg-backend.sh` to `~/.dotfiles-backup-<timestamp>/`,
   skipping symlinks that already point at the current repo;
5. stows `shell tmux starship pkg mise eza zoxide <distro>` with
   `--no-folding`.

Options: `--dry-run` prints every package/backup/stow command without running
it; `--no-stow` installs tools but stops before backup and stow. The script
never runs `chsh`; switching the login shell is a manual step after verifying
a fresh login shell.

## The `custom/` folder (git-ignored, machine-specific)

`custom/` mirrors the same layout but holds files that are specific to this
machine (corporate proxies/CAs, local aliases, local user names) and must
**not** be committed. It is excluded by the single line in `.gitignore`:

```
custom
```

It has three loadable subfolders, matching the loader system, plus any other
config paths it needs:

```
custom/
├── .alias.d/git                 # git-verify on/off   (corporate sslVerify)
├── .profile.d/
│   ├── nix-os                   # source $HOME/.nix-profile nix.sh
│   ├── open-code                # NODE_EXTRA_CA_CERTS
│   └── proxy                    # HTTP(S)/FTP/ALL proxy exports
├── .bashrc.d/                   # (empty, ready for use)
└── .config/nix/nix.conf         # machine-specific nix settings
```

Language runtimes are owned by mise, not by `custom/`. The committed `mise`
package carries the global tool versions in
`mise/.config/mise/config.toml` (currently Node `26.13.1`); machine-specific
overrides, if ever needed, belong in `custom/`. Rust (rustup) and Java (system
OpenJDK) are still managed outside mise.

### How `custom/` reaches the loaders

`custom` is wired in two ways, depending on whether the target home directory
is exclusive to it or shared:

- **Exclusive directory** — `~/.profile.d` is a **whole-folder symlink** to the
  repo's `custom/.profile.d`:
  ```
  ~/.profile.d -> dotfiles/custom/.profile.d
  ```
  Nothing else writes to `~/.profile.d`, so the whole folder is linked.

- **Shared (manifold) directory** — since `~/.alias.d` also receives files
  from `ubuntu`, `cachyos`, `omarchy`, and `custom`, `custom` must add
  **per-file symlinks** into the same real directory:
  ```
  ~/.alias.d/git -> ../dotfiles/custom/.alias.d/git
  ```
  The same applies to `~/.bashrc.d` if a local snippet is needed there.

- **Non-loader config** — paths outside the loader dirs are linked individually:
  ```
  ~/.config/nix/nix.conf -> ../../dotfiles/custom/.config/nix/nix.conf
  ```

Adding a new machine-specific file = drop it into the matching `custom/`
subfolder, then create the home symlink with the appropriate `ln -s` (relative
target). Because it lives under `custom/`, it stays local and never gets
committed (`git status` stays clean).

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
