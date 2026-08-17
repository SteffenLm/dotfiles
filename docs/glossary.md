# Glossary

Terms used across this repo's tmux/opencode docs.

- **stow package** — a directory in this repo (e.g. `dotfiles/tmux`,
  `dotfiles/opencode`) that mirrors home-directory paths. Running
  `stow dotfiles/<pkg>` from `~` symlinks its contents into the home tree.
- **TPM** — `tmux-plugins/tpm`, the tmux plugin manager. It clones plugins
  into `~/.tmux/plugins/` and wires the ones declared with `set -g @plugin`.
  Install new plugins with `prefix + I`, update with `prefix + U`.
- **prefix** — the tmux key that introduces commands. Here it stays the
  default `C-b`; composite bindings read like `prefix + e`.
- **tmux-agent-sidebar** — `hiroppy/tmux-agent-sidebar`; a sidebar tracking
  Claude Code, Codex, and OpenCode agent panes. `prefix + e` toggles the
  current window's sidebar, `prefix + E` toggles everywhere.
- **OpenCode bridge** — the plugin's small JS shim
  (`tmux-agent-sidebar.js`) loaded by opencode from
  `~/.config/opencode/plugins/`; it relays agent activity to the sidebar.
- **Catppuccin flavour** — one of the plugin's palettes. `mocha` (dark) is
  the default here; `latte` is the light variant toggled by `prefix + m`.
- **copy-mode** — tmux's scrollback/text-selection mode (`prefix + [`), here
  configured with vi-style keys.
- **worktree / worktrees** — git worktrees, which the sidebar can spawn an
  agent into and tear down from a single key.
