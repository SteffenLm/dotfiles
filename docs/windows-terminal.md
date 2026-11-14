# Windows Terminal palette for OpenCode and tmux

Windows Terminal drives the ANSI palette for SSH sessions from Windows.
OpenCode's built-in `system` theme and tmux both inherit that palette, so they
match without a tracked OpenCode theme.

## Add the Retro 82 scheme

1. Open Windows Terminal → **Settings** → **Open JSON file**.
2. Add the object from
   [windows-terminal-retro-82.json](./windows-terminal-retro-82.json) to the
   top-level `"schemes"` array.
3. Set the color scheme on the Ubuntu/CachyOS profile:

   ```json
   "colorScheme": "Retro 82"
   ```

The palette mirrors Omarchy's current Retro 82 terminal colors
(`alacritty.toml` / `ghostty.conf` / `kitty.conf`).

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
