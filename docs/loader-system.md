# Loader system, `custom/`, and stow commands

This document explains how the repo organizes shell config, where
machine-specific (non-committed) files live, and the exact stow commands to
use. Dotfiles are managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Stow packages and the directory layout

The repo root is the stow directory. Each **package** is a top-level folder
that mirrors home-directory paths relative to `~`:

```
dotfiles/
├── brew/ shell/ cargo/ nvm/ sdkman/ ubuntu/ eos/   # per-tool packages
├── nvim/ opencode/ tmux/                            # app config packages
├── custom/      # git-ignored, machine-specific (see below)
└── docs/        # ADRs + glossary (this file's friends)
```

For example `tmux/.tmux.conf` → `~/.tmux.conf`, and
`tmux/.config/tmux/toggle-flavour.sh` → `~/.config/tmux/toggle-flavour.sh`.

### Correct stow commands

Because stow rejects slashes in package names, **always run stow from inside
the repo** and pass the bare package name:

```sh
cd ~/dotfiles

stow <pkg>     # install package (create the symlinks)
stow -D <pkg>  # remove package (unlink)
stow -R <pkg>  # restow (unlink then re-link), e.g. after editing a folder's layout
```

Package names are the top-level folders: `shell`, `tmux`, `opencode`, `nvim`,
`brew`, `cargo`, `nvm`, `sdkman`, `ubuntu`, `eos`.

> ⚠️ Do NOT write `stow dotfiles/tmux` or `stow tmux` from anywhere other than
> `~/dotfiles` — the former errors with `Slashes are not permitted in package
> names`, and the latter needs the cwd to be the repo root.

The symlinks appear in home with a `dotfiles/<pkg>/...` prefix because stow's
default target is the *parent* of the stow directory (`~`), so it computes the
relative path through `~/dotfiles/...`.

## The loader system

The shell startup files are split into a tiny loader plus per-concern snippet
directories. `shell/.zshenv` and `shell/.zshrc` each contain a loop that
sources every file inside a home directory:

```zsh
# shell/.zshenv
DIRECTORY=$HOME/.zshenv.d
if [ -d "$DIRECTORY" ]; then
  for file in $DIRECTORY/**/*(-.); source $file
fi

# shell/.zshrc  (sources two directories)
DIRECTORY=$HOME/.zshrc.d
if [ -d "$DIRECTORY" ]; then
  for file in $DIRECTORY//**/*(-.); source $file
fi

DIRECTORY=$HOME/.alias.d
if [ -d "$DIRECTORY" ]; then
  for file in $DIRECTORY//**/*(-.); source $file
fi
```

Loading order:

| Loader | Sources | What runs |
|--------|---------|-----------|
| `shell/.zshenv` | `~/.zshenv.d/*` | before every zsh (env vars, paths) |
| `shell/.zshrc`  | `~/.zshrc.d/*`  | interactive shells (tool init) |
| `shell/.zshrc`  | `~/.alias.d/*`  | interactive shells (aliases) |

### The home manifold directories

`~/.zshrc.d` and `~/.alias.d` are **real directories** that act as a merge
point. Each tool package drops a single symlink into them, named after the
tool:

```
~/.zshrc.d/
├── brew    -> ../dotfiles/brew/.zshrc.d/brew
├── cargo   -> ../dotfiles/cargo/.zshrc.d/cargo
├── nvm     -> ../dotfiles/nvm/.zshrc.d/nvm
└── sdkman  -> ../dotfiles/sdkman/.zshrc.d/sdkman

~/.alias.d/
├── brew    -> ../dotfiles/brew/.alias.d/brew
├── sdkman  -> ../dotfiles/sdkman/.alias.d/sdkman
└── ubuntu  -> ../dotfiles/ubuntu/.alias.d/ubuntu
```

The loader sources everything in the directory, so each tool's snippet is
loaded automatically at shell startup — no per-tool edits to the loaders.

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
├── .zshenv.d/
│   ├── nix-os                   # source $HOME/.nix-profile nix.sh
│   ├── open-code                # NODE_EXTRA_CA_CERTS
│   └── proxy                    # HTTP(S)/FTP/ALL proxy exports
├── .zshrc.d/                    # (empty, ready for use)
└── .config/nix/nix.conf         # machine-specific nix settings
```

### How `custom/` reaches the loaders

`custom` is wired in two ways, depending on whether the target home directory
is exclusive to it or shared:

- **Exclusive directory** — `~/.zshenv.d` is a **whole-folder symlink** to the
  repo's `custom/.zshenv.d`:
  ```
  ~/.zshenv.d -> dotfiles/custom/.zshenv.d
  ```
  Nothing else writes to `~/.zshenv.d`, so the whole folder is linked.

- **Shared (manifold) directory** — since `~/.alias.d` also receives files
  from `brew`, `sdkman`, `ubuntu`, etc., `custom` must add **per-file symlinks**
  into the same real directory:
  ```
  ~/.alias.d/git -> ../dotfiles/custom/.alias.d/git
  ```

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
2. Add the snippet(s) under the right loader subdir
   (`<pkg>/.zshrc.d/<tool>`, `<pkg>/.alias.d/<tool>`, etc.).
3. Wire it into the home:
   ```sh
   cd ~/dotfiles && stow vim
   ```
4. If the snippet is machine-specific instead of shared, put a copy in
   `custom/` and link it manually (see above) rather than committing it.
5. Confirm with `ls -la ~/.zshrc.d` (or the relevant dir) that the new symlink
   resolves.
