# ADR-0002: Integrate tmux-agent-sidebar

## Status

Accepted (amended — OpenCode bridge wiring changed from in-repo copy to a
symlink into the TPM install)

## Context

We want a single tmux sidebar that tracks agent panes (Claude Code, Codex,
OpenCode) across sessions and windows, including status, prompts, Git state,
activity, and worktrees. We use OpenCode, so the OpenCode bridge is the part
that matters here.

An earlier version of this ADR tracked the bridge as a static copy inside the
repo (`dotfiles/opencode/.config/opencode/plugins/tmux-agent-sidebar.js`).
That approach is broken: the bridge discovers its binary by walking **up** from
the plugin file looking for `hook.sh`, falling back to `tmux-agent-sidebar` on
`PATH`. A repo copy is not colocated with `hook.sh`/the binary, and the binary
is not on `PATH`, so hooks would fail silently. The plugin must stay
colocated with its `hook.sh` and binary.

## Decision

- Declare `hiroppy/tmux-agent-sidebar` as a TPM plugin in `.tmux.conf`.
  Sidebar toggles: `prefix + e` (current window), `prefix + E` (everywhere).
- Wire the OpenCode bridge by symlinking the **installed** plugin's bridge
  file into opencode's plugin directory (the plugin's recommended setup):
  ```sh
  mkdir -p ~/.config/opencode/plugins
  ln -sf ~/.tmux/plugins/tmux-agent-sidebar/.opencode/plugins/tmux-agent-sidebar.js \
    ~/.config/opencode/plugins/tmux-agent-sidebar.js
  ```
- Do **not** track the bridge inside `dotfiles/opencode/` — the `opencode`
  package manages only `agents/`. The wiring command (above) is the repo's
  documentation of this step.

## Consequences

- The bridge always matches the installed plugin version and can locate its
  `hook.sh` + binary (both in the TPM install), so no binary path is needed.
- The bridge takes effect only after opencode is (re)started — a running
  session does not pick up new plugins. No edit to `opencode.json` is required.
- If the sidebar plugin is reinstalled/updated via TPM, the home symlink
  should be re-created (re-run the `ln -sf`).
- Requires TPM and a `prefix + I` install before the plugin works.
- `~/.config/opencode/plugins/` points outside the repo, so it is machine-local
  and not managed by stow.
