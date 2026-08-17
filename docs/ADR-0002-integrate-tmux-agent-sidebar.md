# ADR-0002: Integrate tmux-agent-sidebar

## Status

Accepted

## Context

We want a single tmux sidebar that tracks agent panes (Claude Code, Codex,
OpenCode) across sessions and windows, including status, prompts, Git state,
activity, and worktrees. The repo is a dotfiles repo managed with stow, and we
wanted the integration to live in the repo rather than the plugin's default
ad-hoc install. We also use OpenCode, so the OpenCode bridge is the part that
matters here.

## Decision

- Declare `hiroppy/tmux-agent-sidebar` as a TPM plugin in `.tmux.conf`.
  Sidebar toggles: `prefix + e` (current window), `prefix + E` (everywhere).
- Track the OpenCode bridge in-dotfiles: copy the plugin's
  `.opencode/plugins/tmux-agent-sidebar.js` into
  `dotfiles/opencode/.config/opencode/plugins/` (mirroring how the
  `opencode/agents` are already managed) and let stow symlink it into
  `~/.config/opencode/plugins/`.

## Consequences

- The OpenCode bridge is a versioned copy in the repo; it should be re-synced
  from the plugin when the sidebar is updated.
- The bridge takes effect once opencode is (re)started; no edit to
  `opencode.json` is currently required.
- Requires TPM and a `prefix + I` install before the plugin works.
