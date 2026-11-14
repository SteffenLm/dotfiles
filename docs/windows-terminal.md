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

## Select the system theme in OpenCode

Select `system` once in each terminal:

- Press `Ctrl+P`, choose **Open settings**, then **Theme**; or run `/themes`.
- Pick `system`.

OpenCode asks the terminal for its foreground, background, and ANSI palette and
derives the theme from it. The picker only lists `system` when the terminal
answers those queries. This repo ships no OpenCode theme and no fallback on
purpose: the terminal palette is the single source of truth, the same model
tmux uses with ANSI color names.

`~/.config/opencode/cli.json` is owned by OpenCode; this repo never tracks or
seeds it.

## Keybindings live in cli.json

Keybindings are user state in the live `~/.config/opencode/cli.json`. Add them
there (merge with any existing keys):

```json
"keybinds": {
  "session.tab.previous": ["alt+h"],
  "session.tab.next": ["alt+l"]
}
```

### Windows Terminal conflicts

Windows Terminal intercepts some chords before OpenCode sees them:

| Chord | Windows Terminal action |
|---|---|
| `ctrl+tab` / `ctrl+shift+tab` | Switch terminal tabs |
| `ctrl+shift+t` | New terminal tab |
| `ctrl+1` … `ctrl+9` | Switch terminal tab/profile |
| `ctrl+shift+c` / `ctrl+shift+v` | Copy / paste |

Fix a conflict by removing or rebinding the Windows Terminal action (Settings →
Actions) so the chord reaches the app, or by choosing another binding in
`cli.json`. The `alt+h` / `alt+l` bindings above avoid these chords.
