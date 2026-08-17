#!/usr/bin/env sh
# Toggle the Catppuccin flavour between latte (light) and mocha (dark).

if [ "$(tmux show-options -gv @catppuccin_flavor)" = "latte" ]; then
  tmux set-option -g @catppuccin_flavor "mocha"
else
  tmux set-option -g @catppuccin_flavor "latte"
fi

tmux set-option -g @catppuccin_reset "true"
bash ~/.tmux/plugins/tmux/catppuccin.tmux
