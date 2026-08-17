# Glossary

Terms used across this repo's tmux/opencode docs.

- **stow package** — a top-level directory in this repo (e.g. `tmux`,
  `opencode`, `shell`) that mirrors home-directory paths. Install with
  `cd ~/dotfiles && stow <pkg>` (run stow from inside the repo with the bare
  package name — `stow` rejects slashes, so not `stow dotfiles/tmux`). See
  [loader-system.md](./loader-system.md).
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
- **loader / loader system** — the pattern where `shell/.zshenv` sources
  `~/.zshenv.d/*` and `shell/.zshrc` sources `~/.zshrc.d/*` and
  `~/.alias.d/*`. Each tool drops a snippet into one of these directories and
  it loads automatically at startup.
- **manifold directory** — a home directory (`~/.zshrc.d`, `~/.alias.d`) that
  holds one per-tool symlink so snippets from many packages merge in one place
  the loader reads.
- **custom package** — the git-ignored `custom/` folder holding machine-specific
  files (proxies, CAs, local aliases, local user names) that must not be
  committed. Wired into the loaders via symlinks. See
  [loader-system.md](./loader-system.md).
