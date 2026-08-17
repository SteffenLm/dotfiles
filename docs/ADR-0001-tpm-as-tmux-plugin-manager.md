# ADR-0001: Manage tmux config and plugins via TPM and stow

## Status

Accepted

## Context

The dotfiles repo had no tmux configuration at all, and no plugin manager.
The `tmux-agent-sidebar` plugin (see ADR-0002) requires tmux 3.0+ and is
distributed as a TPM plugin. We also want a coordinated, restartable tmux
setup that fits the repo's existing stow-managed layout.

tmux 3.7b is already installed via linuxbrew; `gh` and `fzf` are present.

## Decision

- Create a `tmux` stow package (`dotfiles/tmux/.tmux.conf`) that stows to
  `~/.tmux.conf` via `stow dotfiles/tmux`.
- Adopt TPM (`tmux-plugins/tpm`) as the plugin manager, cloned into
  `~/.tmux/plugins/`.
- Respect the stow + TPM boundary: stow manages only config files
  (`~/.tmux.conf`, `~/.config/tmux/toggle-flavour.sh`); TPM owns the real
  git clones under `~/.tmux/plugins/`. The `tmux` package never stows a
  `~/.tmux` tree, avoiding conflicts.

## Consequences

- New plugins are declared with `set -g @plugin` and installed via
  `prefix + I`.
- Adding tmux settings requires editing one tracked file and re-stowing.
- TPM clones live outside version control (managed by TPM itself).
