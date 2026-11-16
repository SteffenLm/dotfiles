# Omarchy shell parity

> This repo is not installed on Omarchy machines. A real Omarchy install
> already ships its own shell, tmux, mise, and opencode configuration; the port
> documented here exists for the Ubuntu and CachyOS targets.

This machine is reached over SSH, so the goal is an Omarchy-like **terminal**
experience, not a desktop one. Only portable bash, readline, fzf, starship, and
tmux behavior is ported. Hyprland, desktop packages, and `omarchy-*` binaries
are out of scope.

Upstream is [`omacom/omarchy`](https://github.com/omacom/omarchy), branch
`quattro` (snapshot read 2026-11-13). Keep this branch in mind: Omarchy's
default branch is not `main`.

## Current state

The portable parity work is implemented and stowed on the non-Omarchy targets
(Ubuntu and CachyOS). CachyOS also gets the Alacritty appearance package and
theme switcher so the ANSI palette matches the Windows Terminal schemes.

- `bat` and `yt-dlp` are installed. On Ubuntu, `~/.local/bin/bat` resolves to
  `/usr/bin/batcat`.
- `./test.sh </dev/null` passes the full suite with `bat` available.
  `DISTRO=cachyos ./test.sh </dev/null` additionally exercises the CachyOS
  Alacritty config, theme switcher, and saved theme state.
- The live tmux server was reloaded in place with
  `tmux source-file ~/.config/tmux/tmux.conf`; the session and windows were
  kept. `prefix ?` opens the annotated pager popup on tmux 3.4.
- tmux 3.4 on Ubuntu 24.04 runs the full config, and the only version-sensitive
  option (`extended-keys-format`) is guarded for 3.5+. OpenCode's `system` theme
  inside tmux needs tmux 3.6 or newer; see
  [Versions and OpenCode's system theme](#versions-and-opencodes-system-theme).

## What is copied or adapted

| Upstream (`quattro`) | Local path | Status | Notes |
|---|---|---|---|
| `default/bash/inputrc` | `shell/.inputrc` → `~/.inputrc` | copied | Prefix history search on Up/Down, `menu-complete` on Tab, case-insensitive and colored completions. Read by every Readline program. |
| `default/bash/shell` (history) | `shell/.bashrc.d/history` | copied | `histappend`, `ignoreboth`, `HISTSIZE=32768`. |
| `default/bash/shell` (completion) | `shell/.bashrc.d/completion` | copied | Sources `/usr/share/bash-completion/bash_completion` when not already loaded. `set +h` lives in the existing mise snippet. |
| `default/bash/envs` | `shell/.bashrc.d/env` | adapted | `nvim`→`vim`→`vi` editor fallback, `xdg-open` as `BROWSER`, `BAT_THEME=ansi`, `MANROFFOPT=-c`, and a `MANPAGER` guarded on `bat` + `col`. `PATH` handling already exists in the loader; locale comes from the system environment. |
| `default/bash/aliases` | `shell/.alias.d/omarchy` | adapted | Portable alias subset (see below). |
| `default/bash/aliases` (`open`, `n`) | `shell/.bashrc.d/functions` | copied | Shell functions rather than aliases. |
| `default/bash/fns/compression` | `shell/.bashrc.d/functions`, `shell/.alias.d/omarchy` | copied | `compress()` and the `decompress` alias; tar.gz, not zip. |
| `default/bash/aliases` (`ff`, `eff`, `sff`) | `fzf/.alias.d/ff` | adapted | Only defined when both `fzf` and `bat` are present. |
| `default/bash/init` (starship) | `starship/.bashrc.d/starship` | adapted | Uses `starship init bash --print-full-init`. Mise, zoxide, and fzf init already live in their own snippets. |
| `config/starship.toml` | `starship/.config/starship.toml` | copied | Cyan directory/git prompt with `❯`. Needs a Nerd Font for the git glyphs. |
| `config/alacritty` | `alacritty/.config/alacritty` | adapted | CachyOS-only. Font, padding, and block cursor match Omarchy; window opacity (0.8), 100×30 dimensions, full decorations, and a host-specific title are restored from the previous config. Four palettes come from the tracked Windows Terminal JSON. `alacritty-theme` switches them live. |
| `config/tmux/tmux.conf` | `tmux/.config/tmux/tmux.conf` | adapted | Upstream keybindings and theme, plus a tmux < 3.5 guard for `extended-keys-format` and a local `?` command. |
| `bin/omarchy-menu-tmux-keybindings` | `tmux/.local/bin/tmux-keybindings` | adapted | Standalone bash/tmux utility: no `omarchy-*` binaries and no `OMARCHY_PATH` fallback. |

## Ported aliases and functions

Ported from Omarchy:

- directories: `..`, `...`, `....`
- tools: `t`, `mup`, `open()`, `n()`, `compress()`, `decompress`
- git: `g`, `gcm`, `gcam`, `gcad`
- fzf (when `fzf` and `bat` exist): `ff`, `eff`, `sff()`

`compress <path>` writes `<path>.tar.gz` next to the source and strips a
trailing slash; `decompress <archive>` is `tar -xzf`. These are **tar.gz**
helpers, not zip.

Deliberately skipped:

- aliases, app-specific: `c`, `cx`, `cy`, `d`, `r`
- aliases, Omarchy-only: `a`, `h`, `ic`, `ix`, `icx`
- `default/bash/init`: `try` and `$OMARCHY_PATH/default/bash/completions`
  (Omarchy-specific; mise, zoxide, and fzf init already live in their own
  snippets here)
- `default/bash/envs`: the locale bootstrap fallback (the system locale is
  already set in the environment)
- `default/bash/fns/ssh-reconnect` and `default/bash/fns/ssh-port-forwarding`
  (the `ssh` wrapper, `fip`, `dip`, `lip`): client-side helpers. The SSH client
  here is Windows, so installing them on the Ubuntu server does not help the
  Windows → Ubuntu workflow.
- `ff`'s `TERM=xterm-kitty` `kitty icat` image-preview branch; the port always
  uses the portable `bat` preview
- `tldr` (see Packages)

## Packages

- `bat` is in `packages.list`. On Ubuntu the binary is `batcat`, so the Ubuntu
  backend links `~/.local/bin/bat` → `batcat`; on Arch the binary is already
  `bat`.
- `yt-dlp` is in `packages.list`.
- On CachyOS, `cachyos-packages.list` adds `alacritty` and
  `ttf-jetbrains-mono-nerd`, and the `alacritty` stow package carries the
  appearance config and color themes. See [alacritty.md](./alacritty.md).
- `opencode` is not in `packages.list`; it is a mise tool tracked as `latest`
  in `mise/.config/mise/config.toml`, installed by `install.sh` after its Node
  dependency, and updated by `mup`. No OpenCode theme is tracked; select the
  built-in `system` theme so it inherits the terminal palette (see
  [windows-terminal.md](./windows-terminal.md)).
- `tldr` is intentionally excluded.
- The Windows Terminal Retro 82 scheme
  (`docs/windows-terminal-retro-82.json`) supplies the terminal palette that
  OpenCode's `system` theme and tmux inherit. Catppuccin, Catppuccin Latte,
  and Tokyo Night schemes are available in the same folder.

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

`prefix ?` opens a **pager popup**, not an interactive search menu: the popup
runs `tmux-keybindings --print | less -R`. Scroll with the pager and press `q`
to close it. The popup was verified on tmux 3.4 without restarting the server.

Reloading the config with `prefix q` or
`tmux source-file ~/.config/tmux/tmux.conf` is non-destructive: sessions,
windows, and panes stay. It re-appends `terminal-features` values, so a
reloaded server can show a duplicate `xterm-kitty:extkeys` entry. That is
cosmetic and clears on the next server restart.

### Versions and OpenCode's system theme

The config runs on tmux 3.4 (Ubuntu 24.04) and newer; it is verified on tmux
3.4 and 3.8. tmux 3.4 is enough for the config itself and for tmux's own ANSI
colors.

OpenCode's built-in `system` theme needs tmux **3.6 or newer** when it runs
inside tmux. tmux 3.4 answers the OSC 4 palette query from its own palette and
does not forward OSC 10/11 foreground/background queries, so `system` derives
wrong colors or falls back. tmux 3.6 forwards OSC 4 and asks the outer terminal
for OSC 10/11. Outside tmux, Windows Terminal answers directly, so `system`
works on 24.04.

Preferred fix: upgrade to Ubuntu 26.04 LTS, which ships tmux 3.6a.

Fallback: build tmux 3.8 user-locally. This does not touch the system package.

```sh
sudo apt-get install -y libevent-dev libncurses-dev pkg-config bison build-essential
mkdir -p ~/.local/opt
curl -fL https://github.com/tmux/tmux/releases/download/3.8/tmux-3.8.tar.gz |
  tar -xz -C /tmp
cd /tmp/tmux-3.8
./configure --prefix="$HOME/.local/opt/tmux-3.8"
make -j"$(nproc)"
make install
ln -sfn ~/.local/opt/tmux-3.8/bin/tmux ~/.local/bin/tmux
hash -r
command -v tmux   # expect ~/.local/bin/tmux
tmux -V           # expect tmux 3.8
```

`~/.local/bin` is prepended by the shell loader, so the symlink wins over
`/usr/bin/tmux`. A running tmux server keeps the old binary; run
`tmux kill-server` and start a new session to switch. **`tmux kill-server`
loses all sessions**, so do it when no work is running.

With Nix already in use, `nix profile install nixpkgs#tmux` is an alternative.
Do **not** install Ubuntu 26.04 `.deb` packages on 24.04.

## Refreshing from upstream

Raw files on branch `quattro`:

```text
https://raw.githubusercontent.com/omacom/omarchy/quattro/default/bash/inputrc
https://raw.githubusercontent.com/omacom/omarchy/quattro/default/bash/shell
https://raw.githubusercontent.com/omacom/omarchy/quattro/default/bash/init
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
DISTRO=cachyos env -u __DOTFILES_PROFILE_D_LOADED ./test.sh </dev/null

stow --no-folding -t "$HOME" shell tmux starship pkg mise eza zoxide fzf agents nix ubuntu
# CachyOS: replace "nix ubuntu" with "alacritty cachyos"
env -u __DOTFILES_PROFILE_D_LOADED bash -l
```

On CachyOS, also check the terminal:

```sh
alacritty-theme list
alacritty-theme tokyo-night
alacritty-theme retro-82
```

Run `bash -l` interactively: a non-interactive `bash -l` skips `~/.bashrc` by
design, so the interactive snippets do not load.

In the fresh shell:

- type `git`, press Up → prefix history search
- press Tab → menu-complete
- prompt shows the directory, git state, and `❯`
- `Ctrl-R` → fzf history
- `ff` → bat preview (`bat` is installed in the current setup)
- `MANPAGER` opens man pages through `bat`
- `tmux-keybindings --print | less -R` and tmux `prefix ?` → annotated keys
