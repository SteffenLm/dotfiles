#!/usr/bin/env bash
# Sandbox harness for the bash shell configuration.
# Usage: ./test.sh
#   ./test.sh </dev/null  # automated run; no interactive sandbox shell
#   KEEP=1 ./test.sh      # keep the sandbox dir after exit

set -u

REPO=${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
LIVE=${LIVE:-$HOME/dotfiles}

STOW=$(command -v stow) || { echo "missing: stow"; exit 1; }
TMUX=$(command -v tmux) || { echo "missing: tmux"; exit 1; }
[ -d "$REPO/shell" ] || { echo "bad REPO: $REPO"; exit 1; }

TEST_PATH=/usr/local/bin:/usr/bin:/bin
sbx=$(mktemp -d "${TMPDIR:-/tmp}/bash-starship-test.XXXXXX")
TSOCK=dotfiles-test
cleanup() {
  "$TMUX" -L "$TSOCK" kill-server 2>/dev/null || true
  if [ "${KEEP:-0}" = 1 ]; then
    echo "sandbox kept: $sbx"
    return
  fi
  rm -rf "$sbx"
}
trap cleanup EXIT INT TERM

# Keep Ubuntu's /etc/bash.bashrc sudo hint out of captured output.
: > "$sbx/.hushlogin"
: > "$sbx/.sudo_as_admin_successful"

# Simulate the machine-local profile.d snippets without touching live.
mkdir -p "$sbx/.profile.d" "$sbx/.bashrc.d" "$sbx/.local/bin"
for f in proxy open-code; do
  src="$HOME/.config/dotfiles-local/profile.d/$f"
  [ -f "$src" ] && cp "$src" "$sbx/.profile.d/$f"
done
printf 'export TEST_PROFILE_D=loaded\n' > "$sbx/.profile.d/00-test"

# Exercise the new ~/.local/bin PATH prepend without depending on brew.
if command -v starship >/dev/null 2>&1; then
  ln -s "$(command -v starship)" "$sbx/.local/bin/starship"
else
  cat > "$sbx/.local/bin/starship" <<'SH'
#!/bin/sh
[ "$1" = init ] && [ "$2" = bash ] && printf 'export STARSHIP_SHELL=bash\n'
SH
  chmod +x "$sbx/.local/bin/starship"
fi

# Mirror the Ubuntu batcat shim so bat-dependent snippets can be exercised.
if command -v batcat >/dev/null 2>&1; then
  ln -s "$(command -v batcat)" "$sbx/.local/bin/bat"
elif command -v bat >/dev/null 2>&1; then
  ln -s "$(command -v bat)" "$sbx/.local/bin/bat"
fi

# Extra edge cases for manual/auto checks.
printf 'export SPACE_OK=1\n' > "$sbx/.bashrc.d/with space"
ln -s "$sbx/does-not-exist" "$sbx/.bashrc.d/zz-dangling"

cd "$REPO" || exit 1
echo "stowing into $sbx ..."
"$STOW" --no-folding -t "$sbx" shell tmux starship pkg mise eza zoxide fzf nix ubuntu || exit 1

pass=0
fail=0
ck() {
  if [ "$2" = "$3" ]; then
    printf 'PASS  %s\n' "$1"
    pass=$((pass + 1))
  else
    printf 'FAIL  %s\n        want [%s]\n        got  [%s]\n' "$1" "$2" "$3"
    fail=$((fail + 1))
  fi
}
run() { HOME="$sbx" INPUTRC="$sbx/.inputrc" PATH="$TEST_PATH" "$@" 2>"$sbx/err"; }
errs() { grep -vE 'cannot set terminal process group|no job control in this shell' "$sbx/err" 2>/dev/null; }
tm() { HOME="$sbx" PATH="$sbx/.local/bin:$TEST_PATH" SHELL=/bin/bash "$TMUX" -L "$TSOCK" "$@"; }

echo
echo "--- automatic checks ---"

o=$(run bash -l -i -c 'printf "%s|%s|%s" "${__DOTFILES_PROFILE_D_LOADED:-}" "${TEST_PROFILE_D:-}" "${STARSHIP_SHELL:-}"')
ck ".bash_profile loads profile.d once + starship" "1|loaded|bash" "$o"
ck "login stderr clean" "" "$(errs)"

o=$(run bash -i -c 'printf "%s|%s|%s" "${__DOTFILES_PROFILE_D_LOADED:-}" "${TEST_PROFILE_D:-}" "${STARSHIP_SHELL:-}"')
ck "non-login interactive loads profile.d + starship" "1|loaded|bash" "$o"
ck "terminal stderr clean" "" "$(errs)"

o=$(run bash -c 'printf "%s" "${TEST_PROFILE_D:-unset}"')
ck "non-interactive ignores rc" "unset" "$o"

o=$(run bash -i -c 'alias update-os >/dev/null 2>&1 && printf yes || printf no')
ck "update-os alias present" "yes" "$o"

o=$(run bash -i -c 'pkg present jq >/dev/null 2>&1 && printf yes || printf no')
ck "pkg present works" "yes" "$o"

o=$(run bash -i -c 'command -v z >/dev/null 2>&1 && command -v zi >/dev/null 2>&1 && command -v zd >/dev/null 2>&1 && printf yes || printf no')
ck "zoxide z/zi/zd present" "yes" "$o"

o=$(run bash -i -c 'bind -X 2>/dev/null | grep -cE "C-r|C-t"')
ck "fzf Ctrl-R/Ctrl-T bound" "2" "$o"

o=$(run bash -i -c 'bind -s 2>/dev/null | grep -cF "\\ec"')
ck "fzf Alt-C bound" "1" "$o"

if [ -e "$sbx/.bashrc.d/fzf" ]; then
  ck "fzf snippet stowed" "present" "present"
else
  ck "fzf snippet stowed" "present" "missing"
fi

o=$(run bash -i -c 'alias ls 2>/dev/null')
ck "eza ls alias" "alias ls='eza -lh --group-directories-first --icons=auto'" "$o"

o=$(run bash -i -c 'alias lsa 2>/dev/null')
ck "eza lsa alias" "alias lsa='ls -a'" "$o"

o=$(run bash -i -c 'alias cd 2>/dev/null')
ck "zoxide cd alias" "alias cd='zd'" "$o"

o=$(run bash -i -c 'cd /tmp && pwd')
ck "cd real dir uses builtin" "/tmp" "$o"

o=$(run bash -i -c 'case ":$PATH:" in *":$HOME/.local/bin:"*) printf yes ;; *) printf no ;; esac')
ck "local bin on PATH" "yes" "$o"

if [ ! -e "$sbx/packages.list" ]; then
  ck "packages.list not stowed" "absent" "absent"
else
  ck "packages.list not stowed" "absent" "present"
fi

o=$(run bash -i -c 'printf "%s" "${SPACE_OK:-none}"')
ck "path with spaces sourced" "1" "$o"
ck "dangling symlink silent" "" "$(errs)"

o=$(run bash -i -c 'printf "%s" "${STARSHIP_SHELL:-none}"')
ck "starship optional init ran" "bash" "$o"

o=$(PATH=/usr/bin:/bin HOME="$sbx" SNIPPET="$sbx/.bashrc.d/starship" bash -c '. "$SNIPPET" && printf ok' 2>"$sbx/err")
ck "missing starship is silent" "ok" "$o"
ck "missing starship stderr clean" "" "$(errs)"

o=$(PATH=/usr/bin:/bin HOME="$sbx" SNIPPET="$sbx/.bashrc.d/mise" bash -c '. "$SNIPPET" && printf ok' 2>"$sbx/err")
ck "missing mise is silent" "ok" "$o"
ck "missing mise stderr clean" "" "$(errs)"

o=$(PATH=/usr/bin:/bin HOME="$sbx" SNIPPET="$sbx/.profile.d/nix-os" bash -c '. "$SNIPPET" && printf ok' 2>"$sbx/err")
ck "missing nix is silent" "ok" "$o"
ck "missing nix stderr clean" "" "$(errs)"

if [ -e "$sbx/.profile.d/nix-os" ]; then
  ck "nix profile snippet stowed" "present" "present"
else
  ck "nix profile snippet stowed" "present" "missing"
fi

if [ -e "$sbx/.config/nix/nix.conf" ]; then
  ck "nix config stowed" "present" "present"
else
  ck "nix config stowed" "present" "missing"
fi

if [ -e "$sbx/.inputrc" ]; then
  ck "inputrc stowed" "present" "present"
else
  ck "inputrc stowed" "present" "missing"
fi

o=$(run bash -i -c 'bind -v 2>/dev/null | grep -c "^set completion-ignore-case on$"')
ck "inputrc completion-ignore-case" "1" "$o"

o=$(run bash -i -c 'bind -v 2>/dev/null | grep -c "^set menu-complete-display-prefix on$"')
ck "inputrc menu-complete-display-prefix" "1" "$o"

o=$(run bash -i -c 'bind -p 2>/dev/null | grep -cF "\"\\e[A\": history-search-backward"')
ck "inputrc arrow prefix search" "1" "$o"

o=$(run bash -i -c 'printf "%s|%s|%s|%s" "$HISTSIZE" "$HISTCONTROL" "$(shopt -q histappend && echo yes)" "$HISTFILESIZE"')
ck "history settings" "32768|ignoreboth|yes|32768" "$o"

o=$(run bash -i -c 'printf "%s" "${BASH_COMPLETION_VERSINFO:-}"')
ck "bash-completion loaded" "yes" "$([ -n "$o" ] && printf yes || printf no)"

if [ -e "$sbx/.config/starship.toml" ]; then
  ck "starship config stowed" "present" "present"
else
  ck "starship config stowed" "present" "missing"
fi

if command -v starship >/dev/null 2>&1; then
  o=$(HOME="$sbx" PATH="$sbx/.local/bin:$TEST_PATH" starship prompt 2>/dev/null | grep -c '❯' || true)
  ck "starship prompt renders ❯" "1" "$o"
fi

editor=$(PATH="$sbx/.local/bin:$TEST_PATH" bash -c 'if command -v nvim >/dev/null 2>&1; then printf nvim; elif command -v vim >/dev/null 2>&1; then printf vim; else printf vi; fi')
o=$(HOME="$sbx" INPUTRC="$sbx/.inputrc" PATH="$TEST_PATH" \
  EDITOR='' SUDO_EDITOR='' BROWSER='' BAT_THEME='' MANPAGER='' MANROFFOPT='' \
  bash -i -c 'printf "%s" "${EDITOR:-}"' 2>/dev/null)
ck "env EDITOR fallback" "$editor" "$o"

if PATH="$TEST_PATH" command -v xdg-open >/dev/null 2>&1; then
  browser=xdg-open
else
  browser=
fi
o=$(HOME="$sbx" INPUTRC="$sbx/.inputrc" PATH="$TEST_PATH" \
  EDITOR='' SUDO_EDITOR='' BROWSER='' BAT_THEME='' MANPAGER='' MANROFFOPT='' \
  bash -i -c 'printf "%s" "${BROWSER:-}"' 2>/dev/null)
ck "env BROWSER" "$browser" "$o"

o=$(HOME="$sbx" INPUTRC="$sbx/.inputrc" PATH="$TEST_PATH" \
  EDITOR='' SUDO_EDITOR='' BROWSER='' BAT_THEME='' MANPAGER='' MANROFFOPT='' \
  bash -i -c 'printf "%s|%s" "${BAT_THEME:-}" "${MANROFFOPT:-}"' 2>/dev/null)
ck "env bat/man settings" "ansi|-c" "$o"

o=$(HOME="$sbx" INPUTRC="$sbx/.inputrc" PATH="$TEST_PATH" \
  EDITOR='' SUDO_EDITOR='' BROWSER='' BAT_THEME='' MANPAGER='' MANROFFOPT='' \
  bash -i -c 'printf "%s" "${MANPAGER:-}"' 2>/dev/null)
if [ -e "$sbx/.local/bin/bat" ]; then
  ck "env MANPAGER uses bat" "sh -c 'col -bx | bat -l man -p'" "$o"
else
  ck "env MANPAGER guarded without bat" "" "$o"
fi

o=$(run bash -i -c 'for a in "g" "gcm" "gcam" "gcad" "mup" "t" ".." "..." "...."; do alias "$a" >/dev/null 2>&1 || exit 1; done; printf yes')
ck "omarchy aliases present" "yes" "$o"

o=$(run bash -i -c 'type -t open >/dev/null 2>&1 && type -t n >/dev/null 2>&1 && printf yes || printf no')
ck "functions open/n present" "yes" "$o"

o=$(run bash -i -c 'alias ff >/dev/null 2>&1 && printf yes || printf no')
if [ -e "$sbx/.local/bin/bat" ]; then
  ck "ff alias present with bat" "yes" "$o"
  o=$(run bash -i -c 'alias eff >/dev/null 2>&1 && type -t sff >/dev/null 2>&1 && printf yes || printf no')
  ck "eff/sff present with bat" "yes" "$o"
else
  ck "ff alias guarded without bat" "no" "$o"
fi

echo
echo "--- tmux checks (isolated socket: $TSOCK) ---"
tmux -L "$TSOCK" kill-server 2>/dev/null || true
if tm new-session -d 2>"$sbx/tmux.err"; then
  ck "tmux: starts with sandbox config" "ok" "ok"
else
  ck "tmux: starts with sandbox config" "ok" "failed: $(cat "$sbx/tmux.err")"
fi

ck "tmux: panes use bash" "bash" "$(tm list-panes -F '#{pane_current_command}' 2>/dev/null | head -1)"
ck "tmux: prefix" "C-Space" "$(tm show-options -gv prefix 2>/dev/null)"
ck "tmux: prefix2" "C-b" "$(tm show-options -gv prefix2 2>/dev/null)"
ck "tmux: base-index 1" "1" "$(tm show-options -gv base-index 2>/dev/null)"
ck "tmux: pane-base-index 1" "1" "$(tm show-options -gwv pane-base-index 2>/dev/null)"
ck "tmux: status on top" "top" "$(tm show-options -gv status-position 2>/dev/null)"
ck "tmux: history-limit 50000" "50000" "$(tm show-options -gv history-limit 2>/dev/null)"
ck "tmux: detach-on-destroy off" "off" "$(tm show-options -gv detach-on-destroy 2>/dev/null)"
ck "tmux: mouse on" "on" "$(tm show-options -gv mouse 2>/dev/null)"
ck "tmux: mode-keys vi" "vi" "$(tm show-options -gwv mode-keys 2>/dev/null)"
ck "tmux: default-terminal" "tmux-256color" "$(tm show-options -gv default-terminal 2>/dev/null)"
ck "tmux: no plugin declarations" "0" "$(tm show-options -g 2>/dev/null | grep -c '@plugin' || true)"
ck "tmux: q reloads config" "1" "$(tm list-keys -T prefix q 2>/dev/null | grep -c 'source-file.*config/tmux/tmux.conf' || true)"
ck "tmux: clipboard terminal feature" "1" "$(tm show-options -gv terminal-features 2>/dev/null | grep -c '^\*:clipboard$' || true)"
ck "tmux-keybindings executable" "yes" "$([ -x "$sbx/.local/bin/tmux-keybindings" ] && printf yes || printf no)"

o=$(HOME="$sbx" PATH="$sbx/.local/bin:$TEST_PATH" tmux-keybindings --print 2>"$sbx/tmk.err" | grep -c 'PREFIX + q' || true)
ck "tmux-keybindings lists prefix q" "1" "$o"

o=$(HOME="$sbx" PATH="$sbx/.local/bin:$TEST_PATH" tmux-keybindings --print 2>/dev/null | grep -c 'Show Tmux keybindings' || true)
ck "tmux-keybindings includes notes" "1" "$o"

echo
echo "RESULTS: $pass passed, $fail failed"
echo
echo "Sandbox HOME: $sbx"

if [ -t 0 ]; then
  echo "Entering interactive bash (non-login). Try these, then 'exit':"
  echo "  echo \$STARSHIP_SHELL                # expect: bash"
  echo "  echo \$TEST_PROFILE_D                # expect: loaded"
  echo "  echo \$HTTP_PROXY                    # seeded from ~/.config/dotfiles-local/profile.d/proxy"
  echo "  alias update-os                      # distro-specific pkg upgrade"
  echo "  pkg present jq                       # expect: jq: installed"
  echo "  alias ls                             # expect: eza -lh ..."
  echo "  type z zd                            # zoxide functions"
  echo "  cd /tmp && pwd                       # real dir uses builtin cd"
  echo "  echo \$__DOTFILES_PROFILE_D_LOADED   # expect: 1"
  echo "  env -u __DOTFILES_PROFILE_D_LOADED bash -l   # fresh login in sandbox"
  echo "  env -u __DOTFILES_PROFILE_D_LOADED bash      # fresh terminal in sandbox"
  echo
  echo "tmux (isolated server, sandbox config, socket '$TSOCK'):"
  echo "  tmux -L $TSOCK ls                      # server is already running"
  echo "  tmux -L $TSOCK attach                  # enter the Omarchy tmux config"
  echo "  tmux -L $TSOCK show-options -gv prefix # expect: C-Space"
  echo "  tmux -L $TSOCK kill-server             # optional, cleanup does it anyway"
  echo "  # inside: prefix q reloads; prefix c opens window 1 (1-based); status is on top"
  echo

  HOME="$sbx" bash -i

  echo
  echo "sandbox shell exited."
fi
