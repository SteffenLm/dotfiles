# Omarchy shell parity

This machine is reached over SSH, so the goal is an Omarchy-like **terminal**
experience, not a desktop one. Only portable bash, readline, fzf, starship, and
tmux behavior is ported. Hyprland, desktop packages, and `omarchy-*` binaries
are out of scope.

Upstream is [`omacom/omarchy`](https://github.com/omacom/omarchy), branch
`quattro` (snapshot read 2026-11-13). Keep this branch in mind: Omarchy's
default branch is not `main`.

## What is copied or adapted

| Upstream (`quattro`) | Local path | Status | Notes |
|---|---|---|---|
| `default/bash/inputrc` | `shell/.inputrc` → `~/.inputrc` | copied | Prefix history search on Up/Down, `menu-complete` on Tab, case-insensitive and colored completions. Read by every Readline program. |
| `default/bash/shell` (history) | `shell/.bashrc.d/history` | copied | `histappend`, `ignoreboth`, `HISTSIZE=32768`. |
| `default/bash/shell` (completion) | `shell/.bashrc.d/completion` | copied | Sources `/usr/share/bash-completion/bash_completion` when not already loaded. `set +h` lives in the existing mise snippet. |
| `default/bash/envs` | `shell/.bashrc.d/env` | adapted | `nvim`→`vim`→`vi` editor fallback, `xdg-open` as `BROWSER`, `BAT_THEME=ansi`, `MANROFFOPT=-c`, and a `MANPAGER` guarded on `bat` + `col`. Locale and `PATH` handling already exist in the loader. |
| `default/bash/aliases` | `shell/.alias.d/omarchy` | adapted | Portable alias subset (see below). |
| `default/bash/aliases` (`open`, `n`) | `shell/.bashrc.d/functions` | copied | Shell functions rather than aliases. |
| `default/bash/aliases` (`ff`, `eff`, `sff`) | `fzf/.alias.d/ff` | adapted | Only defined when both `fzf` and `bat` are present. |
| `default/bash/init` (starship) | `starship/.bashrc.d/starship` | adapted | Uses `starship init bash --print-full-init`. Mise, zoxide, and fzf init already live in their own snippets. |
| `config/starship.toml` | `starship/.config/starship.toml` | copied | Cyan directory/git prompt with `❯`. Needs a Nerd Font for the git glyphs. |
| `config/tmux/tmux.conf` | `tmux/.config/tmux/tmux.conf` | adapted | Upstream keybindings and theme, plus a tmux < 3.5 guard for `extended-keys-format` and a local `?` command. |
| `bin/omarchy-menu-tmux-keybindings` | `tmux/.local/bin/tmux-keybindings` | adapted | Standalone bash/tmux utility: no `omarchy-*` binaries and no `OMARCHY_PATH` fallback. |

## Ported aliases and functions

Ported from Omarchy:

- directories: `..`, `...`, `....`
- tools: `t`, `mup`, `open()`, `n()`
- git: `g`, `gcm`, `gcam`, `gcad`
- fzf (when `fzf` and `bat` exist): `ff`, `eff`, `sff()`

Deliberately skipped:

- app-specific: `c`, `cx`, `cy`, `d`, `r`
- Omarchy-only: `a`, `h`, `ic`, `ix`, `icx`

## Packages

- `bat` is in `packages.list`. On Ubuntu the binary is `batcat`, so the Ubuntu
  backend links `~/.local/bin/bat` → `batcat`; on Arch the binary is already
  `bat`.
- `yt-dlp` is in `packages.list`.
- `tldr` is intentionally excluded.

## tmux

`tmux/.config/tmux/tmux.conf` follows upstream, with two deliberate changes:

```tmux
if-shell -F '#{>=:#{version},3.5}' 'set -g extended-keys-format csi-u'

bind -N "Show Tmux keybindings" ? display-popup -E -w 80% -h 70% \
  -T "Tmux keybindings" "tmux-keybindings --print | less -R"
```

`tmux-keybindings` resolves `TMUX_CONF`, then `~/.config/tmux/tmux.conf`. It
starts a throwaway tmux server on a temporary socket, clears the default key
tables, sources the config, and prints annotated bindings. `--print` writes to
stdout; without it, the script pages through `less` when interactive.

`tmux-keybindings` must be on `PATH`, so `~/.local/bin` has to be present in the
tmux server's environment. It normally is, because the shell loaders prepend it
before tmux is started.

## Refreshing from upstream

Raw files on branch `quattro`:

```text
https://raw.githubusercontent.com/omacom/omarchy/quattro/default/bash/inputrc
https://raw.githubusercontent.com/omacom/omarchy/quattro/default/bash/shell
https://raw.githubusercontent.com/omacom/omarchy/quattro/default/bash/envs
https://raw.githubusercontent.com/omacom/omarchy/quattro/default/bash/aliases
https://raw.githubusercontent.com/omacom/omarchy/quattro/config/starship.toml
https://raw.githubusercontent.com/omacom/omarchy/quattro/config/tmux/tmux.conf
https://raw.githubusercontent.com/omacom/omarchy/quattro/bin/omarchy-menu-tmux-keybindings
```

When refreshing:

1. Diff the upstream file against the local copy.
2. Keep the tmux 3.5 `extended-keys-format` guard and the local `?` command.
3. Keep the `fzf` + `bat` guard in `fzf/.alias.d/ff`.
4. Re-run `./test.sh </dev/null` and the manual checks below.

## Verifying

```sh
cd ~/dotfiles
env -u __DOTFILES_PROFILE_D_LOADED ./test.sh </dev/null

stow --no-folding -t "$HOME" shell starship fzf tmux
env -u __DOTFILES_PROFILE_D_LOADED bash -l
```

In the fresh shell:

- type `git`, press Up → prefix history search
- press Tab → menu-complete
- prompt shows the directory, git state, and `❯`
- `Ctrl-R` → fzf history
- `ff` → bat preview (after `bat` is installed)
- `tmux-keybindings --print | less -R` and tmux `prefix ?` → annotated keys
