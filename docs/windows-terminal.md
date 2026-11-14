# Windows Terminal setup for OpenCode and tmux

Windows Terminal drives the ANSI palette for SSH sessions from Windows.
OpenCode's built-in `system` theme and tmux both inherit that palette, so they
match without a tracked OpenCode theme. The appearance settings below also
mirror Omarchy's terminal setup.

## Available schemes

The schemes are extracted from Omarchy's theme sources
(`/usr/share/omarchy/themes/<theme>/colors.toml`) with the same mapping
Omarchy uses for its alacritty, ghostty, and kitty configs, so each one
matches the corresponding Omarchy theme exactly.

| Name | File | Notes |
|---|---|---|
| `Retro 82` | [windows-terminal-retro-82.json](./windows-terminal-retro-82.json) | Omarchy's Retro 82 theme. |
| `Catppuccin` | [windows-terminal-catppuccin.json](./windows-terminal-catppuccin.json) | Omarchy's Catppuccin theme (Mocha colors). |
| `Catppuccin Latte` | [windows-terminal-catppuccin-latte.json](./windows-terminal-catppuccin-latte.json) | Omarchy's Catppuccin Latte theme. |
| `Tokyo Night` | [windows-terminal-tokyo-night.json](./windows-terminal-tokyo-night.json) | Omarchy's Tokyo Night theme. |

## Add a scheme

1. Open Windows Terminal → **Settings** → **Open JSON file**.
2. Add one or more objects from the files above to the top-level `"schemes"`
   array.
3. Set the color scheme on the Ubuntu/CachyOS profile:

   ```json
   "colorScheme": "Retro 82"
   ```

Recent Windows Terminal versions also accept a light/dark pair, for example
`{"light": "Catppuccin Latte", "dark": "Catppuccin"}`.

Each file mirrors the corresponding Omarchy theme's terminal colors
(`alacritty.toml` / `ghostty.conf` / `kitty.conf`).

On CachyOS, the same JSON files are the source for the tracked Alacritty
themes, and `test.sh` verifies their palettes match. See
[alacritty.md](./alacritty.md) for the terminal config and the `alacritty-theme`
switcher.

## Match the Omarchy terminal look

Omarchy's alacritty, ghostty, and kitty configs share one appearance setup.
Windows Terminal has no shared profile file, so apply the same numbers to the
SSH profile, or to `profiles.defaults` to apply them everywhere:

```json
{
  "font": { "face": "JetBrainsMono Nerd Font", "size": 9 },
  "padding": "14",
  "cursorShape": "filledBox",
  "intenseTextStyle": "bold",
  "scrollbarState": "hidden",
  "bellStyle": "none"
}
```

| Setting | Omarchy source | Windows Terminal |
|---|---|---|
| Font | `JetBrainsMono Nerd Font` in all three | `font.face` |
| Size | `9` points in all three | `font.size` (points) |
| Padding | `14` (`window.padding.x/y`, `window-padding-x/y`, `window_padding_width`) | `padding` |
| Cursor | block (`cursor-style`, `cursor_shape`) | `cursorShape: "filledBox"` |
| Intense text | bold, not bright (all three select the bold face only) | `intenseTextStyle: "bold"` |
| Scrollbar | alacritty draws none; kitty only while scrolling | `scrollbarState: "hidden"` |
| Bell | silent (kitty `enable_audio_bell no`) | `bellStyle: "none"` |

Notes:

- Install `JetBrainsMono Nerd Font` on Windows first; otherwise Windows
  Terminal falls back to Consolas and prompt/eza glyphs break.
- `intenseTextStyle` defaults to `"bright"`, which brightens bold text without
  bolding it. Set `"bold"` to match Omarchy, where `ESC[1m` only selects the
  bold face.
- Windows Terminal cannot set cursor blink. Ghostty and kitty disable it
  (`cursor-style-blink = false`, `cursor_blink_interval 0`); on Windows, set
  **Control Panel → Keyboard → Speed → Cursor blink rate** to **None**.
- Padding is scaled by the display scale factor, so `14` is a close match, not
  a pixel-exact one.
- Not portable: Omarchy hides window decorations (alacritty
  `decorations = "None"`, kitty `hide_window_decorations yes`); Windows Terminal
  always draws its own tabs and titlebar. `TERM = "xterm-256color"` is set on
  the server, not by the terminal.

## Terminal keybindings

Windows Terminal consumes some chords before SSH sees them. Merge these
actions and keybindings into the existing `actions` and `keybindings` arrays in
`settings.json` (Settings → **Open JSON file**); do not replace the arrays.

```json
"actions": [
  { "command": { "action": "sendInput", "input": "\u001b\r" }, "id": "User.SendAltEnter" },
  { "command": { "action": "sendInput", "input": "\u001b[13;2u" }, "id": "User.SendShiftEnter" },
  { "command": { "action": "sendInput", "input": "\u001b[13;4u" }, "id": "User.SendAltShiftEnter" }
],
"keybindings": [
  { "id": "User.SendAltEnter", "keys": "alt+enter" },
  { "id": "User.SendShiftEnter", "keys": "shift+enter" },
  { "id": "User.SendAltShiftEnter", "keys": "alt+shift+enter" },
  { "id": "unbound", "keys": "alt+left" },
  { "id": "unbound", "keys": "alt+right" },
  { "id": "unbound", "keys": "alt+up" },
  { "id": "unbound", "keys": "alt+down" },
  { "id": "unbound", "keys": "alt+shift+left" },
  { "id": "unbound", "keys": "alt+shift+right" },
  { "id": "unbound", "keys": "alt+shift+up" },
  { "id": "unbound", "keys": "alt+shift+down" },
  { "id": "unbound", "keys": "ctrl+alt+left" }
]
```

What each piece does:

- `alt+enter` normally toggles fullscreen in Windows Terminal. The `sendInput`
  action re-emits the legacy Alt+Enter encoding (`ESC CR`), so tmux receives
  `M-Enter` and runs its vertical split binding.
- `shift+enter` and `alt+shift+enter` have no legacy encoding: without help
  they are indistinguishable from `enter`. The `sendInput` actions send the
  Kitty/CSI-u forms `CSI 13;2u` and `CSI 13;4u`. This needs an application that
  understands CSI-u, and tmux 3.5+ for `extended-keys-format csi-u`.
- Unbinding the `alt+arrow` and `ctrl+alt+left` chords lets them reach tmux
  instead of moving or resizing Windows Terminal panes.

Newer Windows Terminal versions also accept `"keys"` directly on an action
entry. The `id` + `keybindings` form above is the compatible way to share the
same actions with the command palette.

### Conflicts with terminal applications

Windows Terminal's defaults vary slightly by version; check **Settings →
Actions** or `defaults.json` for the installed build. The defaults below are
from Windows Terminal 1.24.

| Chord | Windows Terminal default | Effect and fix |
|---|---|---|
| `alt+enter` | Toggle fullscreen | Bind to `sendInput "\u001b\r"` so tmux gets `M-Enter` (vertical split). |
| `alt+left` / `alt+right` | Move pane focus | Unbind; tmux uses them for previous/next window. |
| `alt+up` / `alt+down` | Move pane focus | Unbind; tmux uses them for previous/next session. |
| `alt+shift+left` / `alt+shift+right` | Resize pane | Unbind; tmux uses them for swap-window. |
| `alt+shift+up` / `alt+shift+down` | Resize pane | Unbind; no tmux binding, so they are free. |
| `ctrl+alt+left` | Previous pane (`MoveFocusPrevious`) | Unbind; tmux uses it for focus left. |
| `ctrl+alt+right` / `up` / `down` | Not bound | tmux uses them for pane focus; leave them alone. |
| `shift+enter` | Encoded as `enter` | Re-send `CSI 13;2u`; needs CSI-u support (see above). |
| `alt+shift+enter` | Encoded as `alt+enter` | Re-send `CSI 13;4u`; needs CSI-u support. |
| `ctrl+space` | Passes through, but the Windows IME may steal it | tmux's prefix is `C-Space`; use `C-b` (`prefix2`) or disable the IME toggle in Windows settings. |
| `ctrl+v` | Paste | Optional: unbind so Vim/Neovim get blockwise visual mode; `ctrl+shift+v` still pastes. |
| `ctrl+tab` / `ctrl+shift+tab` | Next/previous tab | Leave alone unless an application binds these chords. |
| `ctrl+shift+t` | New tab | Leave alone unless an application binds it. |
| `ctrl+alt+1` … `ctrl+alt+8` | Switch to tab 1–8 | Current default, not `ctrl+1`…`ctrl+9`. |
| `ctrl+shift+1` … `ctrl+shift+9` | New tab with profile 1–9 | Current default. |
| `ctrl+shift+c` / `ctrl+shift+v` | Copy / paste | Leave alone; `ctrl+c` also copies when a selection exists, otherwise it passes through. |

Trade-off: unbinding the Alt+Arrow chords disables Windows Terminal's own pane
focus and resize. The intent is to use tmux panes instead. If you still want
Windows Terminal panes, rebind `Terminal.MoveFocus*` and
`Terminal.ResizePane*` to a non-conflicting chord such as
`ctrl+alt+shift+arrows` rather than keeping the defaults.

## SSH port forwarding for dev servers

`ng serve` listens on Ubuntu at port 4200, but the browser is on Windows. Plain
SSH does not discover listening ports the way VS Code's Ports tab does, so
forward them explicitly. Run this on **Windows**:

```sh
ssh -L 4200:127.0.0.1:4200 user@ubuntu
```

`-L` opens the listener on the Windows side and resolves the target on Ubuntu.
Do not use `-R` on Ubuntu for this: a reverse forward would need an SSH server
running on Windows. If local port 4200 is busy, map another one, for example
`-L 14200:127.0.0.1:4200`, and open `http://localhost:14200`.

To make the forward automatic, add it to `%USERPROFILE%\.ssh\config` on
Windows:

```text
Host ubuntu
    HostName <host>
    User <user>
    LocalForward 4200 127.0.0.1:4200
    ExitOnForwardFailure yes
```

Add one `LocalForward` line per port (or pass several `-L` flags).
`ExitOnForwardFailure yes` makes SSH fail instead of silently connecting
without the forward, which is what happens when the local port is busy. Keep
`ng serve` inside tmux: after a connection drop, reconnect with the same
command and the forward returns to the still-running server.

## Select the system theme in OpenCode

Select `system` once in each terminal:

- Press `Ctrl+P`, choose **Open settings**, then **Theme**; or run `/themes`.
- Pick `system`.

OpenCode asks the terminal for its foreground, background, and ANSI palette and
derives the theme from it. The picker only lists `system` when the terminal
answers those queries. This repo ships no OpenCode theme and no fallback on
purpose: the terminal palette is the single source of truth, the same model
tmux uses with ANSI color names.

Outside tmux, Windows Terminal answers those queries directly. Inside tmux the
answers come from tmux: tmux 3.4 answers the OSC 4 palette query from its own
palette and does not forward OSC 10/11 foreground/background queries, so
`system` can look wrong or fall back. tmux 3.6 and newer forward OSC 4 and ask
the outer terminal for OSC 10/11. Ubuntu 24.04 ships tmux 3.4; Ubuntu 26.04
ships 3.6a. See [omarchy-parity.md](./omarchy-parity.md#versions-and-opencodes-system-theme)
for the upgrade and user-local build fallback.

`~/.config/opencode/cli.json` is owned by OpenCode; this repo never tracks or
seeds it.

## OpenCode keybindings live in cli.json

Keybindings are user state in the live `~/.config/opencode/cli.json`. Add them
there (merge with any existing keys):

```json
"keybinds": {
  "session.tab.previous": ["alt+h"],
  "session.tab.next": ["alt+l"]
}
```

Terminal-level conflicts (Alt+Enter, the Alt+Arrow keys, Shift+Enter) and their
`unbound`/`sendInput` fixes are covered in
[Terminal keybindings](#terminal-keybindings). The `alt+h` / `alt+l` bindings
above avoid the remaining tab and clipboard chords.

If a chord still does not reach OpenCode, remove or rebind the Windows Terminal
action (Settings → Actions), or pick another binding in `cli.json`.
