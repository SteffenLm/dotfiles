# Alacritty on CachyOS

CachyOS uses Alacritty as its default terminal. This repo ships an optional
`alacritty` stow package with the same Retro 82, Catppuccin, Catppuccin Latte,
and Tokyo Night palettes as the Windows Terminal schemes in
[windows-terminal.md](./windows-terminal.md).

Ubuntu does not stow this package: the Ubuntu target is a headless SSH host.

## Packages

`cachyos-packages.list` adds these packages to the CachyOS install step:

```sh
sudo pacman -S --needed alacritty ttf-jetbrains-mono-nerd
```

`./install.sh cachyos` installs them through the CachyOS `pkg` backend. The
Nerd Font package provides the `JetBrainsMono Nerd Font` family used by the
config; `ttf-jetbrains-mono` is the unpatched font and does not provide the eza
and starship glyphs.

Verify the font:

```sh
fc-match 'JetBrainsMono Nerd Font'
# JetBrainsMonoNerdFont-Regular.ttf: "JetBrainsMono Nerd Font" "Regular"
```

## Stow package

The package maps:

```text
alacritty/.config/alacritty/alacritty.toml        -> ~/.config/alacritty/alacritty.toml
alacritty/.config/alacritty/themes/*.toml         -> ~/.config/alacritty/themes/*.toml
alacritty/.local/bin/alacritty-theme              -> ~/.local/bin/alacritty-theme
```

`alacritty.toml` holds the font, padding, cursor, and the import order:

```toml
[general]
import = [
  "~/.config/alacritty/themes/retro-82.toml",
  "~/.local/state/alacritty/current.toml",
]
```

Retro 82 is the fallback. The optional state file is loaded afterwards, so it
overrides the default without editing a tracked file. Alacritty skips missing
imports, so a fresh install starts on Retro 82.

The theme files contain only `[colors.*]` tables. They are generated from the
`docs/windows-terminal-*.json` files, which remain the source palettes. Cursor
text comes from the scheme background and selection text from the foreground,
matching how Windows Terminal renders both.

`install.sh` backs up an existing `~/.config/alacritty/alacritty.toml`. If you
already have files under `~/.config/alacritty/themes/` with the same names,
move them aside first: stow refuses to replace them and stops with a conflict.

## Switching themes

There is no Windows Terminal-style dropdown inside Alacritty. Use the
`alacritty-theme` helper instead:

```sh
alacritty-theme                  # pick with fzf
alacritty-theme list
alacritty-theme retro-82
alacritty-theme catppuccin
alacritty-theme catppuccin-latte
alacritty-theme tokyo-night
```

The helper:

1. writes a symlink at `~/.local/state/alacritty/current.toml`, so the choice
   survives restarts;
2. sends the selected theme to the running instance with
   `alacritty msg config "$(cat <theme>)"`, so open windows change immediately.

If Alacritty is not running, the saved state file takes effect on the next
launch. Runtime `import = [...]` changes are ignored by Alacritty, which is why
the helper sends the theme contents instead.

## Make it the default terminal

On KDE Plasma: **System Settings → Applications → Default Applications →
Terminal → Alacritty**.

On a window-manager edition, set `TERMINAL=alacritty` in its environment.

Check the default-terminal launcher:

```sh
xdg-terminal-exec --print-id
```

## OpenCode and tmux

Alacritty defines the 16 ANSI colors. tmux uses those names in its status and
border theme, starship uses named colors, and OpenCode's built-in `system`
theme reads the terminal palette. Once Alacritty uses one of these schemes,
select `system` in OpenCode (`/themes` → `system`) and everything matches
without per-application theme files.

## Verifying

```sh
DISTRO=cachyos ./test.sh </dev/null
alacritty-theme list
alacritty-theme tokyo-night
alacritty-theme retro-82
```

The test suite checks that the config and all four themes are stowed, that the
tracked theme files match the Windows Terminal JSON palettes, that the switcher
is executable and sends the selected theme to the running instance, and that
the CachyOS package list declares the Nerd Font.
