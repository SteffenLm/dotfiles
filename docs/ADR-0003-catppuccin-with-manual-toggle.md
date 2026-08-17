# ADR-0003: Catppuccin theme with a manual dark/light toggle

## Status

Accepted

## Context

We wanted a status-line theme and the ability to switch between light and dark
modes. Catppuccin tmux was chosen for its palette. No Nerd Font is installed,
so the plugin's icon glyphs must be overridden off. The terminal emulator is
not guaranteed to report a color scheme, so automatic `client-dark-theme` /
`client-light-theme` hooks are not relied upon.

We also decided to keep the default `C-b` prefix (avoiding `C-a` collisions
with zsh line-start and nvim increment-number) and to ship a curated subset of
general tmux settings rather than a maximal config.

## Decision

- Use `catppuccin/tmux#v2.3.0` as a TPM plugin (falling back to a manual
  `run` line if TPM installs conflict with the sidebar).
- Default flavour `mocha` (dark); toggle to `latte` (light) with
  `prefix + m` via `~/.config/tmux/toggle-flavour.sh`.
- Override separators and window flags with plain text/block glyphs so no
  Nerd Font is required.
- Approved general settings only: `mouse on`, `history-limit 5000`,
  `renumber-windows on`, `default-terminal tmux-256color`, `escape-time 10`,
  and vi copy-mode. Windows/panes remain 0-based.

## Consequences

- Theme switching is manual and works regardless of terminal theme reporting.
- Icons are intentionally plain; if a Nerd Font is installed later the
  overrides can be removed to restore richer glyphs.
- `prefix + m` is the only new keybinding; `prefix + e` / `E` come from the
  sidebar plugin.
